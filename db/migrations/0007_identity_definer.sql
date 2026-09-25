-- 0007 identity helper must not depend on the caller's schema privileges.
--
-- On Neon, the `authenticated` role has no USAGE on the `auth` schema
-- created by pg_session_jwt, so calling auth.user_id() as the caller fails
-- with "permission denied". The previous version swallowed that error and
-- returned NULL, which made every request look signed out.
--
-- Running the helper as its owner is safe: auth.user_id() only reads the
-- JWT claims of the CURRENT session, so a caller can only ever learn
-- their own identity.

create or replace function app_private.clerk_id()
returns text
language plpgsql stable security definer
set search_path = pg_catalog, pg_temp
as $$
begin
  return auth.user_id();
exception
  -- Only "no token in this session" maps to NULL. Anything else (e.g. a
  -- privilege problem) must surface instead of silently signing users out.
  when invalid_parameter_value or undefined_object or null_value_not_allowed then
    return null;
end;
$$;

revoke all on function app_private.clerk_id() from public;
grant execute on function app_private.clerk_id() to authenticated;
