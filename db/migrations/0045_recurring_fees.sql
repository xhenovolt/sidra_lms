-- 0045 Course fees that repeat: weekly, monthly, per term or every N days.
--
-- Before: a paid course had one price, and a learner's balance was
-- "price − payments − waivers" — every fee was one-time.
-- Now a course has a billing period. What a learner owes is the price per
-- period × the periods started since their billing start (capped by the
-- number of periods, if the course has one). Payments and waivers count
-- against that running total, so paying ahead simply covers later periods.
--   once      one payment (unchanged behaviour)
--   weekly    every 7 days
--   monthly   every calendar month
--   termly    every term (Settings: billing_term_days, default 91)
--   custom    every billing_interval_days days
-- A period left unpaid past the grace days (Settings: billing_grace_days,
-- default 7) pauses the course for that learner (only enrolments that came
-- from paying); paying reopens it. Learners are reminded when a period is
-- due and told when it is paused.

alter table courses
  add column billing_period text not null default 'once'
    check (billing_period in ('once', 'weekly', 'monthly', 'termly', 'custom')),
  add column billing_interval_days int check (billing_interval_days between 1 and 730),
  -- how many periods in all (e.g. 3 terms); null = for as long as enrolled
  add column billing_periods int check (billing_periods between 1 and 520),
  add constraint courses_custom_billing
    check (billing_period <> 'custom' or billing_interval_days is not null);
grant update (billing_period, billing_interval_days, billing_periods) on courses
  to authenticated, sidra_app;

alter table course_enrolments
  -- the first day of the learner's first period
  add column billing_start date,
  -- set when the course was paused for an unpaid period (paying lifts it)
  add column billing_suspended_at timestamptz;

-- Learners already enrolled when a course starts repeating begin their
-- first period that day (what they paid covers it).
create or replace function app_private.courses_billing_changed()
returns trigger
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if new.billing_period is distinct from old.billing_period then
    update course_enrolments set billing_start = current_date
    where course_id = new.id and billing_start is null;
  end if;
  return new;
end;
$$;
create trigger courses_billing_changed after update of billing_period on courses
  for each row execute function app_private.courses_billing_changed();

insert into org_settings (key, value, is_public) values
  ('billing_term_days', '91', false),
  ('billing_grace_days', '7', false)
on conflict (key) do nothing;

do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('public.set_org_setting(text, text)'::regprocedure);
  if position('  update org_settings set value = v' in v_src) = 0 then
    raise exception 'set_org_setting changed; update 0045';
  end if;
  execute replace(v_src, '  update org_settings set value = v',
$r$  if p_key = 'billing_term_days' and (v !~ '^\d+$' or v::int not between 7 and 366) then
    raise exception 'a term must be between 7 and 366 days' using errcode = 'PT422';
  end if;
  if p_key = 'billing_grace_days' and (v !~ '^\d+$' or v::int not between 0 and 90) then
    raise exception 'grace must be between 0 and 90 days' using errcode = 'PT422';
  end if;
  update org_settings set value = v$r$);
end $$;

-- ------------------------------------------------------------ periods --

create or replace function app_private.billing_step(c courses)
returns interval
language sql stable
set search_path = public, app_private, pg_temp
as $$
  select case c.billing_period
    when 'weekly' then interval '7 days'
    when 'monthly' then interval '1 month'
    when 'termly' then make_interval(days => greatest(app_private.int_setting('billing_term_days', 91), 1))
    when 'custom' then make_interval(days => coalesce(c.billing_interval_days, 30))
  end
$$;

-- Periods started between p_start and p_on (at least one).
create or replace function app_private.periods_due(c courses, p_start date, p_on date)
returns int
language sql stable
set search_path = public, app_private, pg_temp
as $$
  select case
    when c.billing_period = 'once' or p_on <= p_start then 1
    else least(coalesce(c.billing_periods, 100000),
               (select count(*)::int
                from generate_series(p_start::timestamp, p_on::timestamp, app_private.billing_step(c))))
  end
$$;

-- The balance as it stood on a day (the same columns as before, so every
-- caller keeps working; "fee" is now what was due by that day).
create or replace function app_private.course_balance_on(p_user_id uuid, p_course_id uuid, p_on date)
returns table (fee numeric, currency text, paid numeric, refunded numeric,
               waived numeric, outstanding numeric)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  with base as (
    select c,
           coalesce(e.fee_amount, case when c.access = 'paid' then c.price_amount end, 0) as price,
           coalesce(e.fee_currency, c.price_currency,
                    (select value from org_settings where key = 'currency'), 'UGX') as currency,
           coalesce(e.billing_start, e.enrolled_at::date, current_date) as start
    from courses c
    left join course_enrolments e on e.course_id = c.id and e.user_id = p_user_id
    where c.id = p_course_id
  ),
  due as (
    select b.price * app_private.periods_due(b.c, b.start, p_on) as fee, b.currency from base b
  ),
  paid as (
    select coalesce(sum(amount), 0) as v from payments
    where user_id = p_user_id and course_id = p_course_id and status = 'verified'
  ),
  refunded as (
    select coalesce(sum(r.amount), 0) as v from refunds r join payments p on p.id = r.payment_id
    where p.user_id = p_user_id and p.course_id = p_course_id and p.status = 'verified'
  ),
  waived as (
    select coalesce(sum(coalesce(w.amount, d.fee)), 0) as v
    from waivers w, due d
    where w.user_id = p_user_id and w.course_id = p_course_id and w.revoked_at is null
  )
  select d.fee, d.currency, paid.v, refunded.v, least(waived.v, d.fee),
         greatest(d.fee - (paid.v - refunded.v) - waived.v, 0)
  from due d, paid, refunded, waived
$$;

create or replace function app_private.course_balance(p_user_id uuid, p_course_id uuid)
returns table (fee numeric, currency text, paid numeric, refunded numeric,
               waived numeric, outstanding numeric)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select * from app_private.course_balance_on(p_user_id, p_course_id, current_date)
$$;

-- For the learner's pay card: the period, the price per period, how far the
-- payments reach and when the next period is due.
create or replace function app_private.billing_info(p_user_id uuid, p_course_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare
  c courses%rowtype;
  e course_enrolments%rowtype;
  v_price numeric;
  v_start date;
  v_bal record;
  v_covered int;
begin
  select * into c from courses where id = p_course_id;
  if not found then return '{}'; end if;
  select * into e from course_enrolments where course_id = p_course_id and user_id = p_user_id;
  v_price := coalesce(e.fee_amount, case when c.access = 'paid' then c.price_amount end, 0);
  v_start := coalesce(e.billing_start, e.enrolled_at::date, current_date);
  select * into v_bal from app_private.course_balance(p_user_id, p_course_id);
  v_covered := case when v_price > 0
                    then floor((v_bal.paid - v_bal.refunded + v_bal.waived) / v_price)::int end;
  return jsonb_build_object(
    'billing_period', c.billing_period,
    'billing_interval_days', case c.billing_period
      when 'weekly' then 7
      when 'termly' then app_private.int_setting('billing_term_days', 91)
      when 'custom' then c.billing_interval_days end,
    'billing_periods', c.billing_periods,
    'price_per_period', v_price,
    'billing_start', v_start,
    'periods_due', app_private.periods_due(c, v_start, current_date),
    'periods_covered', v_covered,
    -- the first day not paid for (null: one-time fee, or every period paid)
    'next_due_on', case
      when c.billing_period = 'once' or v_covered is null then null
      when c.billing_periods is not null and v_covered >= c.billing_periods then null
      else (v_start + v_covered * app_private.billing_step(c))::date end,
    'paused_for_fees', e.billing_suspended_at is not null and e.status = 'suspended');
end;
$$;

create or replace function public.my_course_balance(p_course_id uuid)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select to_jsonb(b) || app_private.billing_info(app_private.current_user_id(), p_course_id)
  from app_private.course_balance(app_private.current_user_id(), p_course_id) b
  where app_private.current_user_id() is not null
$$;

-- Paying opens the course, and reopens it when it was paused for fees.
-- (The learner's price per period is kept, so a later price change never
-- changes what an enrolled learner pays.)
create or replace function app_private.apply_payment_access(p_user_id uuid, p_course_id uuid)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_bal record; v_course courses%rowtype;
begin
  select * into v_course from courses where id = p_course_id;
  if not found or v_course.access <> 'paid' then return; end if;
  select * into v_bal from app_private.course_balance(p_user_id, p_course_id);
  if v_bal.fee > 0 and v_bal.outstanding = 0 then
    insert into course_enrolments (course_id, user_id, status, source, fee_amount, fee_currency, billing_start)
    values (p_course_id, p_user_id, 'active', 'payment', v_course.price_amount, v_bal.currency, current_date)
    on conflict (course_id, user_id) do update set
      status = case when course_enrolments.status in ('pending', 'withdrawn')
                      or (course_enrolments.status = 'suspended'
                          and course_enrolments.billing_suspended_at is not null)
                    then 'active'::enrolment_status else course_enrolments.status end,
      billing_suspended_at = case when course_enrolments.status = 'suspended'
                                  then null else course_enrolments.billing_suspended_at end,
      billing_start = coalesce(course_enrolments.billing_start, current_date),
      fee_amount = coalesce(course_enrolments.fee_amount, excluded.fee_amount),
      fee_currency = coalesce(course_enrolments.fee_currency, excluded.fee_currency);
  end if;
end;
$$;

-- ---------------------------------------------------------- reminders --

-- Reminds learners of a period now due; pauses courses unpaid past the
-- grace days. Run with the learner policies (staff activity, ≤ every 15
-- minutes). Returns how many were paused.
create or replace function app_private.enforce_billing()
returns int
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  r record;
  v_now record;
  v_late record;
  v_grace int := greatest(app_private.int_setting('billing_grace_days', 7), 0);
  n int := 0;
begin
  for r in
    select e.user_id, e.course_id, c.title
    from course_enrolments e join courses c on c.id = e.course_id
    where e.status = 'active' and e.source = 'payment'
      and c.access = 'paid' and c.billing_period <> 'once'
  loop
    select * into v_late from app_private.course_balance_on(r.user_id, r.course_id, current_date - v_grace);
    if v_late.outstanding > 0 then
      update course_enrolments set status = 'suspended', billing_suspended_at = now(), updated_at = now()
      where user_id = r.user_id and course_id = r.course_id and status = 'active';
      perform app_private.notify(r.user_id, 'fee_overdue', r.title,
        format('Your fee (%s %s) is overdue, so the course is paused. Pay to continue.',
               to_char(v_late.outstanding, 'FM999,999,999'), v_late.currency),
        jsonb_build_object('course_id', r.course_id));
      n := n + 1;
      continue;
    end if;
    select * into v_now from app_private.course_balance(r.user_id, r.course_id);
    if v_now.outstanding > 0 and not exists (
         select 1 from notifications where user_id = r.user_id and kind = 'fee_due'
           and data->>'course_id' = r.course_id::text and created_at > now() - interval '5 days') then
      perform app_private.notify(r.user_id, 'fee_due', r.title,
        format('A new period has started: %s %s is due within %s days.',
               to_char(v_now.outstanding, 'FM999,999,999'), v_now.currency, v_grace),
        jsonb_build_object('course_id', r.course_id));
    end if;
  end loop;
  return n;
end;
$$;

do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('public.run_learner_policies(boolean)'::regprocedure);
  if position('return app_private.evaluate_learner_policies();' in v_src) = 0 then
    raise exception 'run_learner_policies changed; update 0045';
  end if;
  execute replace(v_src, 'return app_private.evaluate_learner_policies();',
    'perform app_private.enforce_billing();
  return app_private.evaluate_learner_policies();');
end $$;

select app_private.lock_down_functions();
