-- 0034 Security: internal functions are not callable by the app login.
--
-- PostgreSQL lets everyone EXECUTE a new function unless told otherwise.
-- auth_api and payments_api were locked down (0011, 0016), but app_private
-- was not, so the public `sidra_app` login (it ships in every APK) could call
-- internal SECURITY DEFINER helpers directly, for example
--   app_private.create_account(…, role, superadmin, password, …)  → any account, even a super admin
--   app_private.complete_and_unlock(user, lesson, reason)         → finish anyone's lesson
--   app_private.find_user_by_identifier(phone)                    → phone number → account id
--   app_private.int_setting(key, …)                               → a setting's value inside a cast error
--
-- From now on nothing in app_private is executable by default. Granted back:
-- SECURITY DEFINER helpers that security rules themselves call (row
-- policies, CHECK constraints, column defaults, caller-rights functions),
-- and functions that run with the caller's own rights anyway.

-- Never reveal a setting through an error message.
create or replace function app_private.int_setting(p_key text, p_default int)
returns int
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select coalesce((select case when value ~ '^-?[0-9]{1,9}$' then value::int end
                   from org_settings where key = p_key), p_default)
$$;

revoke execute on all functions in schema app_private from public, anonymous, authenticated, sidra_app;
alter default privileges in schema app_private revoke execute on functions from public;

do $$
declare
  v_needed text[];
  v_more text[];
  r record;
begin
  -- Helpers named in row policies, CHECK constraints and column defaults.
  select coalesce(array_agg(distinct m[1]), '{}') into v_needed
  from (
    select regexp_matches(coalesce(qual, '') || ' ' || coalesce(with_check, ''),
                          'app_private\.([a-z_0-9]+)\(', 'g') m
    from pg_policies
    union all
    select regexp_matches(pg_get_constraintdef(oid), 'app_private\.([a-z_0-9]+)\(', 'g')
    from pg_constraint where contype = 'c'
    union all
    select regexp_matches(pg_get_expr(adbin, adrelid), 'app_private\.([a-z_0-9]+)\(', 'g')
    from pg_attrdef
  ) s;

  -- Plus the app's own entry points, and whatever functions that run with
  -- the caller's rights (not SECURITY DEFINER) call in turn.
  v_needed := v_needed || array['authenticate', 'jwt_sub', 'current_user_id',
                                'current_app_role', 'has_permission', 'is_admin',
                                'is_superadmin', 'is_console_user'];
  for i in 1..5 loop
    select coalesce(array_agg(distinct m[1]), '{}') into v_more
    from (
      select regexp_matches(p.prosrc, 'app_private\.([a-z_0-9]+)\(', 'g') m
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
      where not p.prosecdef
        and (n.nspname = 'public' or (n.nspname = 'app_private' and p.proname = any (v_needed)))
    ) s
    where not m[1] = any (v_needed);
    exit when cardinality(v_more) = 0;
    v_needed := v_needed || v_more;
  end loop;

  -- Never these, whatever references them.
  v_needed := array(select unnest(v_needed)
                    except select unnest(array['create_account', 'complete_and_unlock',
                                               'find_user_by_identifier', 'checked_identifier']));

  for r in select p.oid::regprocedure as fn
           from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'app_private' and p.prokind = 'f'
             -- functions without SECURITY DEFINER can do no more than the
             -- caller already may, so they are harmless to expose
             and (p.proname = any (v_needed) or not p.prosecdef)
             and p.prorettype <> 'trigger'::regtype loop
    execute format('grant execute on function %s to sidra_app, authenticated, anonymous', r.fn);
  end loop;
end $$;

-- The payments server's login keeps what it had through payments_api only.
