-- The signed-in profile now includes the profile picture. Without it the
-- app saved a new photo but kept showing the old one (it reloads the
-- profile after saving and found no picture field).
create or replace function auth_api._profile(p_user uuid)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select jsonb_build_object(
    'id', u.id, 'role', u.role, 'is_superadmin', u.is_superadmin,
    'display_name', u.display_name, 'username', u.username,
    'email', u.email, 'phone', u.phone, 'avatar_url', u.avatar_url,
    'must_change_password', coalesce(c.must_change, false))
  from users u left join app_private.credentials c on c.user_id = u.id
  where u.id = p_user
$$;
