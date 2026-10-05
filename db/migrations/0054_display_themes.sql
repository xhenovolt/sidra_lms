-- How Sidra looks:
--   * Everyone: light / dark, the free themes, text size and their own
--     wallpaper (kept on their phone).
--   * Premium themes (more colours, any colour, fonts, corners, wallpaper
--     dimming) are bought once with MarzPay. The price is set by the
--     superadmin; until then they are not on sale.
--   * The superadmin sets the organisation's default look (colour, accent,
--     mode, font, corners, wallpaper) for every phone, decides which themes
--     are free, and has every option.

-- -------------------------------------------------- the display settings --

insert into org_settings (key, value, is_public) values
  ('theme_seed', null, true),            -- '#RRGGBB' (null = Sidra teal)
  ('theme_accent', null, true),          -- '#RRGGBB'
  ('theme_mode', 'system', true),        -- system | light | dark
  ('theme_font', 'lora', true),          -- lora | amiri | system
  ('theme_radius', '12', true),          -- corner roundness, 0-28
  ('theme_wallpaper', null, true),       -- a built-in wallpaper id, or null
  ('theme_wallpaper_url', null, true),   -- an uploaded picture (public link)
  ('theme_dim', '0.85', true),           -- how much the page covers the wallpaper, 0-0.95
  ('theme_free_ids', 'teal,night,sand,ocean', true),
  ('themes_premium_price', null, true)   -- UGX; null = not on sale
on conflict (key) do nothing;

-- Only the superadmin changes the organisation's look.
create or replace function public.set_display_settings(p_values jsonb)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  k text;
  v text;
begin
  if not coalesce((select is_superadmin from users where id = app_private.current_user_id()), false) then
    raise exception 'only the superadmin can change the display' using errcode = 'PT403';
  end if;
  for k, v in select key, value #>> '{}' from jsonb_each(coalesce(p_values, '{}')) loop
    v := nullif(trim(v), '');
    if k not in ('theme_seed', 'theme_accent', 'theme_mode', 'theme_font', 'theme_radius', 'theme_wallpaper',
                 'theme_wallpaper_url', 'theme_dim', 'theme_free_ids', 'themes_premium_price') then
      raise exception 'unknown display setting %', k using errcode = 'PT422';
    end if;
    if (k in ('theme_seed', 'theme_accent') and v !~ '^#[0-9A-Fa-f]{6}$')
       or (k = 'theme_mode' and v not in ('system', 'light', 'dark'))
       or (k = 'theme_font' and v not in ('lora', 'amiri', 'system'))
       or (k = 'theme_radius' and (v !~ '^\d{1,2}$' or v::int > 28))
       or (k = 'theme_dim' and (v !~ '^0(\.\d+)?$' or v::numeric > 0.95))
       or (k = 'theme_wallpaper' and v !~ '^[a-z0-9_]{1,32}$')
       or (k = 'theme_wallpaper_url' and v !~ '^https://')
       or (k = 'theme_free_ids' and v !~ '^[a-z0-9_,]{1,400}$')
       or (k = 'themes_premium_price' and (v !~ '^\d+$' or v::int not between 500 and 10000000)) then
      raise exception 'invalid value for %', k using errcode = 'PT422';
    end if;
    update org_settings set value = v, updated_by = app_private.current_user_id(), updated_at = now()
    where key = k;
  end loop;
end;
$$;

-- --------------------------------------------- premium themes purchase --

create table user_entitlements (
  user_id uuid not null references users (id) on delete cascade,
  item text not null check (item in ('themes_premium')),
  payment_id uuid references payments (id) on delete set null,
  granted_by uuid references users (id) on delete set null,
  granted_at timestamptz not null default now(),
  primary key (user_id, item)
);
alter table user_entitlements enable row level security;
create policy user_entitlements_read on user_entitlements for select to public
  using (user_id = app_private.current_user_id() or app_private.has_permission('finance.view'));
grant select on user_entitlements to authenticated, sidra_app;

-- A payment is for a course, or for something in the app (a product).
alter table payments
  add column product text check (product in ('themes_premium'));

-- What the signed-in person has unlocked (the superadmin has everything).
create or replace function public.my_entitlements()
returns text[]
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select case
    when coalesce((select is_superadmin from users where id = app_private.current_user_id()), false)
      then array['themes_premium']
    else coalesce((select array_agg(item order by item) from user_entitlements
                   where user_id = app_private.current_user_id()), '{}')
  end
$$;

-- Buying premium themes: a MarzPay prompt for the superadmin's price.
create or replace function public.start_product_payment(p_product text, p_phone text)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  v_phone text := app_private.normalize_ug_phone(p_phone);
  v_price int;
  v_payment payments%rowtype;
begin
  if v_me is null then raise exception 'not signed in' using errcode = 'PT401'; end if;
  if p_product is distinct from 'themes_premium' then
    raise exception 'unknown item' using errcode = 'PT404';
  end if;
  if exists (select 1 from user_entitlements where user_id = v_me and item = p_product) then
    raise exception 'you already have the premium themes' using errcode = 'PT409';
  end if;
  v_price := case when (select value from org_settings where key = 'themes_premium_price') ~ '^\d+$'
                  then (select value from org_settings where key = 'themes_premium_price')::int end;
  if v_price is null then
    raise exception 'premium themes are not on sale yet' using errcode = 'PT409';
  end if;
  if coalesce((select value from org_settings where key = 'marzpay_enabled'), 'true') <> 'true' then
    raise exception 'mobile-money payments are switched off' using errcode = 'PT409';
  end if;
  if v_phone is null then
    raise exception 'enter an MTN or Airtel Uganda number, e.g. 0772 123456' using errcode = 'PT422';
  end if;
  -- One prompt at a time.
  select * into v_payment from payments
  where user_id = v_me and product = p_product and method = 'marzpay' and status in ('initiated', 'processing');
  if found then return app_private.payment_json(v_payment); end if;
  insert into payments (user_id, product, amount, currency, method, status, phone, recorded_by, next_attempt_at,
                        note)
  values (v_me, p_product, v_price, 'UGX', 'marzpay', 'initiated', v_phone, v_me, now(), 'Premium themes')
  returning * into v_payment;
  perform pg_notify('sidra_payments', v_payment.id::text);
  return app_private.payment_json(v_payment);
end;
$$;

-- The latest payment for an item (for the app to follow).
create or replace function public.my_product_payment(p_product text)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select app_private.payment_json(p) from payments p
  where p.user_id = app_private.current_user_id() and p.product = p_product
  order by p.created_at desc limit 1
$$;

-- A confirmed purchase unlocks the item; a reversal takes it back.
create or replace function app_private.product_entitlement()
returns trigger
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if new.product is null then return null; end if;
  if new.status = 'verified' then
    insert into user_entitlements (user_id, item, payment_id)
    values (new.user_id, new.product, new.id)
    on conflict (user_id, item) do nothing;
  elsif new.status = 'reversed' then
    delete from user_entitlements where user_id = new.user_id and item = new.product and payment_id = new.id;
  end if;
  return null;
end;
$$;
create trigger payments_product_entitlement after insert or update of status on payments
  for each row execute function app_private.product_entitlement();

-- ------------------------------------------------- the books and receipts --

insert into ledger_accounts (code, name, type, is_system, description) values
  ('4200', 'App sales', 'income', true, 'Premium themes and other things bought in the app.')
on conflict (code) do nothing;

-- Product sales are App sales, not course fees.
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('app_private.ledger_post_payment(uuid)'::regprocedure);
  if position('app_private.line(app_private.account_id(''4000''), 0, p.amount, p.user_id, p.course_id)' in v_src) = 0
     or position('format(''Course fee from %s (%s)''' in v_src) = 0 then
    raise exception 'ledger_post_payment changed; update 0054';
  end if;
  v_src := replace(v_src,
    'app_private.line(app_private.account_id(''4000''), 0, p.amount, p.user_id, p.course_id)',
    'app_private.line(app_private.account_id(case when p.product is null then ''4000'' else ''4200'' end),
                      0, p.amount, p.user_id, p.course_id)');
  v_src := replace(v_src, 'format(''Course fee from %s (%s)''',
    'format(case when p.product is null then ''Course fee from %s (%s)'' else ''App purchase by %s (%s)'' end');
  execute v_src;
end $$;

create or replace function public.payment_receipt(p_payment_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare p payments%rowtype; v jsonb;
begin
  select * into p from payments where id = p_payment_id;
  if not found or (p.user_id is distinct from app_private.current_user_id()
                   and not app_private.has_permission('finance.view')) then
    raise exception 'receipt not found' using errcode = 'PT404';
  end if;
  if p.receipt_number is null then
    raise exception 'a receipt is issued once the payment is confirmed' using errcode = 'PT409';
  end if;
  select jsonb_build_object(
    'receipt_number', p.receipt_number,
    'org_name', (select value from org_settings where key = 'org_name'),
    'org_name_ar', (select value from org_settings where key = 'org_name_ar'),
    'org_phone', (select value from org_settings where key = 'support_phone'),
    'org_email', (select nullif(value, 'null') from org_settings where key = 'support_email'),
    'learner', u.display_name, 'learner_phone', u.phone,
    'course', coalesce(c.title, case p.product when 'themes_premium' then 'Premium themes' end),
    'product', p.product,
    'billing_period', c.billing_period,
    'amount', p.amount, 'currency', p.currency, 'method', p.method, 'provider', p.provider,
    'status', p.status, 'paid_on', coalesce(p.paid_on, p.verified_at::date),
    'confirmed_at', p.verified_at,
    'reference', p.reference,
    'provider_reference', p.external_reference,
    'covers_from', p.covers_from, 'covers_until', p.covers_until,
    'refunded', (select coalesce(sum(amount), 0) from refunds where payment_id = p.id),
    'received_by', vb.display_name)
  into v
  from users u
  left join courses c on c.id = p.course_id
  left join users vb on vb.id = p.verified_by
  where u.id = p.user_id;
  return v;
end;
$$;

create or replace function public.my_payment_history()
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select coalesce(jsonb_agg(app_private.payment_json(p) || jsonb_build_object(
           'course', coalesce(c.title, case p.product when 'themes_premium' then 'Premium themes' end),
           'product', p.product,
           'refunded', (select coalesce(sum(amount), 0) from refunds where payment_id = p.id))
         order by p.created_at desc), '[]')
  from payments p left join courses c on c.id = p.course_id
  where p.user_id = app_private.current_user_id()
    and p.status not in ('initiated')
$$;

select app_private.lock_down_functions();
