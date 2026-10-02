-- 0048 One authoritative entitlement decision for paid courses (Phase 6,
-- Stage 1 — containment).
--
-- Defect (reproduced on live data 2026-10-01): access to a course was
-- decided only by "enrolment status is active" (app_private.is_enrolled).
-- Several staff paths set paid-course enrolments active with no payment
-- check — grant_enrolment, set_enrolment_status, bulk_enrol,
-- onboard_learners, reinstate_learner — so a learner with nothing paid could
-- read every lesson and file. Also, since 0041, the payer's OWN app reporting
-- "MarzPay says successful" verified the payment and opened the course
-- (a modified app could fake that).
--
-- Now:
--   * every enrolment carries a computed access state, recomputed by
--     triggers whenever a payment, refund, waiver, enrolment or course price
--     changes: not_enrolled | payment_required | payment_pending |
--     partially_paid | access_granted | waived | access_suspended |
--     access_expired | refund_review;
--   * is_enrolled (used by every lesson / assignment / portion / resource /
--     media check) requires has_access and, for repeating fees, a paid-up
--     period (access_until) — so no staff path can open a paid course
--     without payment or an explicit waiver;
--   * "partial payment opens the course" is an explicit per-course rule
--     (paid_access_min_percent, default 100 = full payment);
--   * waivers carry an effective period;
--   * a payer's app report is recorded but no longer verifies anything:
--     a trusted party (the payments Worker / server, or finance staff)
--     confirms with MarzPay first;
--   * preview lessons keep needing access (unchanged; opening them to all is
--     a separate decision).

alter table courses
  add column paid_access_min_percent int not null default 100
    check (paid_access_min_percent between 1 and 100);
grant update (paid_access_min_percent) on courses to authenticated, sidra_app;

alter table waivers
  add column effective_from date,
  add column effective_until date,
  add constraint waivers_effective_order
    check (effective_until is null or effective_from is null or effective_until >= effective_from);

alter table course_enrolments
  add column access_state text not null default 'not_enrolled'
    check (access_state in ('not_enrolled', 'payment_required', 'payment_pending', 'partially_paid',
                            'access_granted', 'waived', 'access_suspended', 'access_expired',
                            'refund_review')),
  add column has_access boolean not null default false,
  -- repeating fees: access lasts until this day (paid periods + grace)
  add column access_until date,
  add column access_reason text,
  add column access_checked_at timestamptz;

-- A waiver counts toward what is owed only within its dates (an expired
-- full waiver must not keep a course open).
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('app_private.course_balance_on(uuid, uuid, date)'::regprocedure);
  if position('where w.user_id = p_user_id and w.course_id = p_course_id and w.revoked_at is null' in v_src) = 0 then
    raise exception 'course_balance_on changed; update 0048';
  end if;
  execute replace(v_src, 'where w.user_id = p_user_id and w.course_id = p_course_id and w.revoked_at is null',
    'where w.user_id = p_user_id and w.course_id = p_course_id and w.revoked_at is null
      and (w.effective_from is null or w.effective_from <= p_on)
      and (w.effective_until is null or w.effective_until >= p_on)');
end $$;

-- A reversal's suspension is about money: paying properly lifts it (like a
-- repeating fee's pause), instead of needing staff to reinstate.
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('public.reverse_payment(uuid, text)'::regprocedure);
  if position('  update course_enrolments e set status = ''suspended''' in v_src) = 0 then
    raise exception 'reverse_payment changed; update 0048';
  end if;
  execute replace(v_src, '  update course_enrolments e set status = ''suspended''',
    '  update course_enrolments e set status = ''suspended'', billing_suspended_at = now()');
end $$;

-- Paying opens the course once the course's rule is met: the whole amount,
-- or the share a course allows (paid_access_min_percent).
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('app_private.apply_payment_access(uuid, uuid)'::regprocedure);
  if position('  if v_bal.fee > 0 and v_bal.outstanding = 0 then' in v_src) = 0 then
    raise exception 'apply_payment_access changed; update 0048';
  end if;
  execute replace(v_src, '  if v_bal.fee > 0 and v_bal.outstanding = 0 then',
    '  if v_bal.fee > 0 and (v_bal.outstanding = 0
       or (v_course.billing_period = ''once'' and v_course.paid_access_min_percent < 100
           and (v_bal.paid - v_bal.refunded + v_bal.waived) * 100 >= v_bal.fee * v_course.paid_access_min_percent)) then');
end $$;

-- --------------------------------------------------- the one decision --

create or replace function app_private.recompute_access(p_user uuid, p_course uuid)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  e course_enrolments%rowtype;
  c courses%rowtype;
  v_grace int := greatest(app_private.int_setting('billing_grace_days', 7), 0);
  v_bal record;
  v_state text;
  v_access boolean := false;
  v_until date;
  v_reason text;
  v_info jsonb;
begin
  select * into e from course_enrolments where user_id = p_user and course_id = p_course;
  if not found then return; end if;
  select * into c from courses where id = p_course;

  if e.status = 'withdrawn' then
    v_state := 'not_enrolled';
  elsif e.status = 'suspended' then
    -- A reversed payment suspends the enrolment: that is for review.
    if exists (select 1 from payments p where p.user_id = p_user and p.course_id = p_course
               and p.status = 'reversed' and p.updated_at > now() - interval '30 days') then
      v_state := 'refund_review';
      v_reason := 'a payment was reversed';
    else
      v_state := 'access_suspended';
      v_reason := 'enrolment suspended';
    end if;
  elsif e.ends_at is not null and e.ends_at <= now() then
    v_state := 'access_expired';
  elsif c.access <> 'paid' then
    v_state := case when e.status in ('active', 'completed') then 'access_granted' else 'not_enrolled' end;
    v_access := v_state = 'access_granted';
  elsif exists (select 1 from waivers w
                where w.user_id = p_user and w.course_id = p_course and w.revoked_at is null
                  and w.amount is null
                  and (w.effective_from is null or w.effective_from <= current_date)
                  and (w.effective_until is null or w.effective_until >= current_date)) then
    v_state := 'waived';
    v_access := e.status in ('active', 'completed');
    v_reason := 'full waiver';
  else
    -- What was due by today, less the grace days for repeating fees.
    select * into v_bal from app_private.course_balance_on(
      p_user, p_course,
      case when c.billing_period = 'once' then current_date else current_date - v_grace end);
    if v_bal.fee <= 0 or v_bal.outstanding <= 0 then
      v_state := 'access_granted';
      v_access := e.status in ('active', 'completed', 'pending');
      if c.billing_period <> 'once' then
        v_info := app_private.billing_info(p_user, p_course);
        v_until := case when v_info->>'next_due_on' is not null
                        then (v_info->>'next_due_on')::date + v_grace - 1 end;
      end if;
    elsif c.billing_period = 'once' and c.paid_access_min_percent < 100
          and (v_bal.paid - v_bal.refunded + v_bal.waived) * 100 >= v_bal.fee * c.paid_access_min_percent then
      v_state := 'partially_paid';
      v_access := e.status in ('active', 'completed', 'pending');
      v_reason := format('%s%% paid meets the course rule (%s%%)',
                         floor((v_bal.paid - v_bal.refunded + v_bal.waived) * 100 / v_bal.fee), c.paid_access_min_percent);
    elsif exists (select 1 from payments p where p.user_id = p_user and p.course_id = p_course
                  and p.status in ('initiated', 'processing', 'pending')) then
      v_state := 'payment_pending';
      v_reason := 'a payment is waiting for verification';
    elsif exists (select 1 from payments p where p.user_id = p_user and p.course_id = p_course
                  and p.status = 'reversed' and p.updated_at > now() - interval '30 days') then
      v_state := 'refund_review';
      v_reason := 'a payment was reversed';
    elsif v_bal.paid - v_bal.refunded > 0 then
      v_state := 'partially_paid';
      v_reason := format('%s of %s paid', v_bal.paid - v_bal.refunded, v_bal.fee);
    else
      v_state := 'payment_required';
    end if;
  end if;

  update course_enrolments set
    access_state = v_state, has_access = v_access, access_until = v_until,
    access_reason = v_reason, access_checked_at = now()
  where id = e.id
    and (access_state, has_access, access_until, access_reason)
        is distinct from (v_state, v_access, v_until, v_reason);
end;
$$;

-- Paying, a waiver, a price change… reach the decision at once.
create or replace function app_private.recompute_access_trigger()
returns trigger
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare r record;
begin
  if tg_table_name = 'courses' then
    for r in select user_id from course_enrolments where course_id = new.id loop
      perform app_private.recompute_access(r.user_id, new.id);
    end loop;
  elsif tg_table_name = 'refunds' then
    perform app_private.recompute_access(p.user_id, p.course_id)
    from payments p where p.id = new.payment_id and p.course_id is not null;
  else
    if tg_op <> 'DELETE' and new.course_id is not null then
      perform app_private.recompute_access(new.user_id, new.course_id);
    end if;
    if tg_op <> 'INSERT' and old.course_id is not null
       and (tg_op = 'DELETE' or old.user_id <> new.user_id or old.course_id <> new.course_id) then
      perform app_private.recompute_access(old.user_id, old.course_id);
    end if;
  end if;
  return null;
end;
$$;

create trigger course_enrolments_access after insert or update of status, starts_at, ends_at, fee_amount, billing_start
  on course_enrolments for each row execute function app_private.recompute_access_trigger();
create trigger payments_access after insert or update of status, amount, course_id or delete
  on payments for each row execute function app_private.recompute_access_trigger();
create trigger refunds_access after insert on refunds
  for each row execute function app_private.recompute_access_trigger();
create trigger waivers_access after insert or update or delete on waivers
  for each row execute function app_private.recompute_access_trigger();
create trigger courses_access after update of access, price_amount, billing_period, billing_interval_days,
  billing_periods, paid_access_min_percent on courses
  for each row execute function app_private.recompute_access_trigger();

-- Every content check goes through here.
create or replace function app_private.is_enrolled(p_course_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select exists (
    select 1 from course_enrolments
    where course_id = p_course_id
      and user_id = app_private.current_user_id()
      and status in ('active', 'completed')
      and has_access
      and (access_until is null or access_until >= current_date)
      and (starts_at is null or starts_at <= now())
      and (ends_at is null or ends_at > now())
  )
$$;

-- Unchanged rules, now with the entitlement behind is_enrolled. (Preview
-- lessons still need access, as before: opening them to everyone is a
-- separate decision, not taken here.)
create or replace function app_private.can_read_lesson(p_lesson_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select exists (
    select 1 from lessons l
    join courses c on c.id = l.course_id
    where l.id = p_lesson_id
      and (
        app_private.is_course_staff(c.id)
        or (
          app_private.lesson_is_live(l.id)
          and app_private.is_enrolled(c.id)
          and (
            l.is_preview
            or c.progression = 'open'
            or exists (
              select 1 from lesson_unlocks u
              where u.lesson_id = l.id
                and u.user_id = app_private.current_user_id()
            )
          )
        )
      )
  )
$$;

-- The app's course list: a paid course without access shows as "pending"
-- (the pay card), never as open.
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('public.my_courses()'::regprocedure);
  if position('  select e.course_id, e.id, e.status,' in v_src) = 0 then
    raise exception 'my_courses changed; update 0048';
  end if;
  execute replace(v_src, '  select e.course_id, e.id, e.status,',
    '  select e.course_id, e.id,
    case when e.status in (''active'', ''completed'')
              and not (e.has_access and (e.access_until is null or e.access_until >= current_date))
         then ''pending''::enrolment_status else e.status end,');
end $$;

-- What the app shows on a course: the decision and why.
create or replace function public.my_course_access(p_course_id uuid)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select jsonb_build_object(
    'state', coalesce(e.access_state, 'not_enrolled'),
    'has_access', coalesce(e.has_access and (e.access_until is null or e.access_until >= current_date)
                           and e.status in ('active', 'completed'), false),
    'access_until', e.access_until, 'reason', e.access_reason,
    'enrolment_status', e.status)
  from (select 1) x
  left join course_enrolments e on e.course_id = p_course_id and e.user_id = app_private.current_user_id()
$$;
revoke all on function public.my_course_access(uuid) from public, anonymous;
grant execute on function public.my_course_access(uuid) to authenticated, sidra_app;

-- ------------------------------------- a payer's report is not proof --

-- The payer's app tells Sidra what MarzPay said; it is kept with the
-- payment, but only a trusted party confirms it (payments Worker / server
-- via payments_api.settle, or finance staff via marzpay_confirm).
create or replace function public.marzpay_result(
  p_payment_id uuid, p_status text, p_amount numeric, p_reference text,
  p_provider_ref text default null, p_fee numeric default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v payments%rowtype;
begin
  select * into v from payments
  where id = p_payment_id and user_id = app_private.current_user_id() and method = 'marzpay';
  if not found or v.provider_uuid is null then
    raise exception 'payment not found' using errcode = 'PT404';
  end if;
  if p_reference is distinct from v.reference::text then
    raise exception 'this MarzPay transaction belongs to another payment' using errcode = 'PT409';
  end if;
  update payments set
    provider_payload = coalesce(provider_payload, '{}') || jsonb_build_object('payer_report',
      jsonb_build_object('status', p_status, 'amount', p_amount, 'provider_ref', p_provider_ref,
                         'fee', p_fee, 'at', now())),
    updated_at = now() - interval '2 minutes' -- check it with MarzPay right away
  where id = v.id and status in ('initiated', 'processing')
  returning * into v;
  if not found then select * into v from payments where id = p_payment_id; end if;
  return app_private.payment_json(v) || jsonb_build_object('awaiting_verification', v.status = 'processing');
end;
$$;

-- Waivers name who approved, why, which course, and (now) for how long.
drop function public.grant_waiver(uuid, uuid, numeric, text);
create function public.grant_waiver(
  p_user_id uuid, p_course_id uuid, p_amount numeric, p_reason text,
  p_effective_from date default null, p_effective_until date default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v waivers%rowtype;
begin
  perform app_private.require('finance.manage_waiver');
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'give the reason for the waiver' using errcode = 'PT422';
  end if;
  insert into waivers (user_id, course_id, amount, reason, granted_by, effective_from, effective_until)
  values (p_user_id, p_course_id, p_amount, trim(p_reason), app_private.current_user_id(),
          p_effective_from, p_effective_until)
  returning * into v;
  perform app_private.apply_payment_access(p_user_id, p_course_id);
  return to_jsonb(v);
end;
$$;
revoke all on function public.grant_waiver(uuid, uuid, numeric, text, date, date) from public, anonymous;
grant execute on function public.grant_waiver(uuid, uuid, numeric, text, date, date) to authenticated, sidra_app;

-- --------------------------------------------- backfill every enrolment --

do $$
declare r record;
begin
  for r in select user_id, course_id from course_enrolments loop
    perform app_private.recompute_access(r.user_id, r.course_id);
  end loop;
end $$;

select app_private.lock_down_functions();
