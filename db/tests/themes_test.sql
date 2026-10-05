-- 0054: the superadmin sets the organisation's look; premium themes are
-- bought with MarzPay and unlocked by the confirmed payment.

select set_config('th.l', app_private.create_account('Theme Learner', '+256772780001', null, null,
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('th.s', app_private.create_account('Theme Super', null, null, 'th_super',
  'admin', true, 'staff-pass-1', false)::text, true);
select set_config('th.a', app_private.create_account('Theme Admin', null, null, 'th_admin',
  'learner', false, 'staff-pass-1', false)::text, true);
insert into user_roles (user_id, role_key) values
  (current_setting('th.a')::uuid, 'admin');

-- ------------------------------------------------ the organisation's look --
select pg_temp.login_as_id(current_setting('th.a')::uuid);
set local role authenticated;
select pg_temp.expect_error($q$select public.set_display_settings('{"theme_seed": "#123456"}')$q$, 'only the superadmin');
reset role;

select pg_temp.login_as_id(current_setting('th.s')::uuid);
set local role authenticated;
select public.set_display_settings('{"theme_seed": "#7B1FA2", "theme_mode": "dark", "theme_radius": "20",
  "theme_wallpaper": "dunes", "theme_dim": "0.8", "themes_premium_price": "15000"}');
select pg_temp.check((public.public_settings()->>'theme_seed') = '#7B1FA2'
  and (public.public_settings()->>'theme_mode') = 'dark'
  and (public.public_settings()->>'themes_premium_price') = '15000', 'every phone gets the new look');
select pg_temp.expect_error($q$select public.set_display_settings('{"theme_seed": "purple"}')$q$, 'invalid');
select pg_temp.expect_error($q$select public.set_display_settings('{"theme_radius": "90"}')$q$, 'invalid');
select pg_temp.expect_error($q$select public.set_display_settings('{"secret_key": "x"}')$q$, 'unknown');
select pg_temp.check(public.my_entitlements() = array['themes_premium'], 'the superadmin has every theme');
-- Not on sale until priced.
select public.set_display_settings('{"themes_premium_price": ""}');
reset role;

-- ------------------------------------------------- buying premium themes --
select pg_temp.login_as_id(current_setting('th.l')::uuid);
set local role authenticated;
select pg_temp.check(public.my_entitlements() = '{}', 'nothing unlocked yet');
select pg_temp.expect_error($q$select public.start_product_payment('themes_premium', '0772780001')$q$, 'not on sale');
reset role;
select pg_temp.login_as_id(current_setting('th.s')::uuid);
set local role authenticated;
select public.set_display_settings('{"themes_premium_price": "15000"}');
reset role;

select pg_temp.login_as_id(current_setting('th.l')::uuid);
set local role authenticated;
select set_config('th.p', (public.start_product_payment('themes_premium', '0772780001'))->>'id', true);
select pg_temp.check((select amount = 15000 and product = 'themes_premium' and course_id is null
                      from payments where id = current_setting('th.p')::uuid), 'a MarzPay request for the price');
select pg_temp.check((public.start_product_payment('themes_premium', '0772780001'))->>'id' = current_setting('th.p'),
  'one prompt at a time');
select pg_temp.check(public.my_product_payment('themes_premium')->>'status' = 'initiated', 'the app follows it');
select pg_temp.check(public.my_entitlements() = '{}', 'not unlocked before MarzPay confirms');
reset role;

select set_config('th.n', coalesce((select max(number) from journal_entries), 0)::text, true);
-- MarzPay confirms (as the payments Worker does).
update payments set status = 'verified', verified_at = now(), verified_via = 'payments_server', provider_fee = 450
where id = current_setting('th.p')::uuid;

select pg_temp.login_as_id(current_setting('th.l')::uuid);
set local role authenticated;
select pg_temp.check(public.my_entitlements() = array['themes_premium'], 'premium themes unlocked');
select pg_temp.check(public.payment_receipt(current_setting('th.p')::uuid)->>'course' = 'Premium themes',
  'a receipt for the purchase');
select pg_temp.check(jsonb_array_length(public.my_payment_history()) = 1, 'in the payment history');
select pg_temp.expect_error($q$select public.start_product_payment('themes_premium', '0772780001')$q$, 'already');
reset role;

select pg_temp.check((select sum(l.credit) from journal_lines l join journal_entries e on e.id = l.entry_id
                      join ledger_accounts a on a.id = l.account_id
                      where e.number > current_setting('th.n')::bigint and a.code = '4200') = 15000
  and (select sum(l.debit) from journal_lines l join journal_entries e on e.id = l.entry_id
       join ledger_accounts a on a.id = l.account_id
       where e.number > current_setting('th.n')::bigint and a.code = '5000') = 450,
  'booked as App sales, with the real MarzPay fee');

-- A reversal takes the themes back.
update payments set status = 'reversed', status_reason = 'chargeback' where id = current_setting('th.p')::uuid;
select pg_temp.check(not exists (select 1 from user_entitlements where user_id = current_setting('th.l')::uuid),
  'reversed: locked again');

