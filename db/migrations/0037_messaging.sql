-- 0037 Messaging: staff talk to each other inside Sidra instead of WhatsApp.
--
-- Direct chats (one per pair) and groups. Messages carry text and/or one
-- attachment: photo, video, voice note, audio or document, with replies,
-- read receipts and "delete for everyone". Only members can read a chat or
-- its files. Sending is idempotent (the phone's own message id), so a
-- resend after a dropped connection never duplicates. New messages reach
-- phones through Sidra's notifications (kind "message"), and an open chat
-- refreshes every few seconds.
--
-- Who can chat: staff (anyone who isn't only a learner). Learners can be
-- allowed later with the setting messaging_learners.

insert into org_settings (key, value, is_public) values
  ('messaging_enabled', 'true', false),
  ('messaging_learners', 'false', false)
on conflict (key) do nothing;

create table conversations (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('direct', 'group')),
  title text check (title is null or length(trim(title)) between 1 and 80),
  photo_asset_id uuid references media_assets (id) on delete set null,
  -- "userA:userB" (sorted) so a pair has one direct chat
  direct_key text unique,
  created_by uuid references users (id) on delete set null,
  created_at timestamptz not null default now(),
  last_message_at timestamptz,
  check ((kind = 'direct') = (direct_key is not null))
);

create table conversation_members (
  conversation_id uuid not null references conversations (id) on delete cascade,
  user_id uuid not null references users (id) on delete cascade,
  role text not null default 'member' check (role in ('admin', 'member')),
  joined_at timestamptz not null default now(),
  last_read_at timestamptz,
  muted boolean not null default false,
  left_at timestamptz,
  primary key (conversation_id, user_id)
);
create index conversation_members_user on conversation_members (user_id) where left_at is null;

create table messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references conversations (id) on delete cascade,
  sender_id uuid references users (id) on delete set null,
  client_id uuid not null,
  kind text not null default 'text'
    check (kind in ('text', 'image', 'video', 'voice', 'audio', 'document', 'system')),
  body text check (length(body) <= 4000),
  media_asset_id uuid references media_assets (id) on delete set null,
  file_name text,
  bytes bigint,
  duration_seconds numeric,
  reply_to_id uuid references messages (id) on delete set null,
  created_at timestamptz not null default now(),
  edited_at timestamptz,
  deleted_at timestamptz,
  unique (sender_id, client_id)
);
create index messages_conversation on messages (conversation_id, created_at desc);
create index messages_media on messages (media_asset_id) where media_asset_id is not null;

alter table conversations enable row level security;
alter table conversation_members enable row level security;
alter table messages enable row level security;

create or replace function app_private.is_member(p_conversation uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select exists (select 1 from conversation_members
                 where conversation_id = p_conversation
                   and user_id = app_private.current_user_id() and left_at is null)
$$;

-- May this person use messaging? Staff always; learners when allowed.
create or replace function app_private.can_message(p_user uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select coalesce((select value from org_settings where key = 'messaging_enabled'), 'true') = 'true'
     and exists (select 1 from users u where u.id = p_user and u.is_active and u.removed_at is null
                 and (u.role <> 'learner' or u.is_superadmin
                      or exists (select 1 from user_roles r where r.user_id = u.id)
                      or coalesce((select value from org_settings where key = 'messaging_learners'), 'false') = 'true'))
$$;

create policy conversations_read on conversations for select to public
  using (app_private.is_member(id));
create policy members_read on conversation_members for select to public
  using (app_private.is_member(conversation_id));
create policy messages_read on messages for select to public
  using (app_private.is_member(conversation_id));
grant select on conversations, conversation_members, messages to authenticated, sidra_app;

-- Chat files: only members (checked before every other rule).
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('app_private.can_read_media(uuid)'::regprocedure);
  if position('when exists (select 1 from submission_files f where f.media_asset_id = p_asset_id) then' in v_src) = 0 then
    raise exception 'can_read_media changed; update 0037';
  end if;
  execute replace(v_src,
    'when exists (select 1 from submission_files f where f.media_asset_id = p_asset_id) then',
    'when exists (select 1 from messages mm where mm.media_asset_id = p_asset_id) then
      exists (select 1 from messages mm
              where mm.media_asset_id = p_asset_id and mm.deleted_at is null
                and app_private.is_member(mm.conversation_id))
      or exists (select 1 from conversations cv where cv.photo_asset_id = p_asset_id
                 and app_private.is_member(cv.id))
    when exists (select 1 from submission_files f where f.media_asset_id = p_asset_id) then');
end $$;

create or replace function app_private.message_json(m messages)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select jsonb_build_object(
    'id', m.id, 'conversation_id', m.conversation_id, 'sender_id', m.sender_id,
    'sender_name', (select display_name from users where id = m.sender_id),
    'client_id', m.client_id, 'kind', m.kind,
    'body', case when m.deleted_at is null then m.body end,
    'media_asset_id', case when m.deleted_at is null then m.media_asset_id end,
    'file_name', case when m.deleted_at is null then m.file_name end,
    'bytes', m.bytes, 'duration_seconds', m.duration_seconds,
    'reply_to', (select jsonb_build_object('id', r.id, 'kind', r.kind,
                   'sender_name', (select display_name from users where id = r.sender_id),
                   'body', case when r.deleted_at is null then left(r.body, 120) end)
                 from messages r where r.id = m.reply_to_id),
    'created_at', m.created_at, 'edited_at', m.edited_at, 'deleted', m.deleted_at is not null,
    'mine', m.sender_id = app_private.current_user_id(),
    -- read by everyone else in the chat (for ✓✓)
    'read_by_all', not exists (
       select 1 from conversation_members cm
       where cm.conversation_id = m.conversation_id and cm.left_at is null
         and cm.user_id <> m.sender_id
         and (cm.last_read_at is null or cm.last_read_at < m.created_at)))
$$;

-- People I can start a chat with.
create or replace function public.chat_directory(p_search text default null)
returns setof jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.can_message(app_private.current_user_id()) then
    raise exception 'messaging is not available for your account' using errcode = 'PT403';
  end if;
  return query
    select jsonb_build_object('user_id', u.id, 'display_name', u.display_name,
                              'avatar_url', u.avatar_url, 'role', u.role)
    from users u
    where u.id <> app_private.current_user_id() and app_private.can_message(u.id)
      and (p_search is null or u.display_name ilike '%' || p_search || '%')
    order by u.display_name
    limit 200;
end;
$$;

-- Opens (or creates) the one direct chat with a person.
create or replace function public.open_direct_chat(p_user_id uuid)
returns uuid
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  v_key text;
  v_id uuid;
begin
  if not app_private.can_message(v_me) or not app_private.can_message(p_user_id) or p_user_id = v_me then
    raise exception 'you cannot message this person' using errcode = 'PT403';
  end if;
  v_key := least(v_me::text, p_user_id::text) || ':' || greatest(v_me::text, p_user_id::text);
  select id into v_id from conversations where direct_key = v_key;
  if v_id is null then
    insert into conversations (kind, direct_key, created_by) values ('direct', v_key, v_me)
    on conflict (direct_key) do nothing
    returning id into v_id;
    if v_id is null then select id into v_id from conversations where direct_key = v_key; end if;
    insert into conversation_members (conversation_id, user_id) values (v_id, v_me), (v_id, p_user_id)
    on conflict do nothing;
  end if;
  update conversation_members set left_at = null where conversation_id = v_id and user_id = v_me;
  return v_id;
end;
$$;

-- Creates a group; the creator is its admin.
create or replace function public.create_group_chat(p_title text, p_members uuid[])
returns uuid
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  v_id uuid;
  u uuid;
begin
  if not app_private.can_message(v_me) then
    raise exception 'messaging is not available for your account' using errcode = 'PT403';
  end if;
  if coalesce(trim(p_title), '') = '' then
    raise exception 'give the group a name' using errcode = 'PT422';
  end if;
  insert into conversations (kind, title, created_by) values ('group', trim(p_title), v_me)
  returning id into v_id;
  insert into conversation_members (conversation_id, user_id, role) values (v_id, v_me, 'admin');
  foreach u in array coalesce(p_members, '{}') loop
    if u <> v_me and app_private.can_message(u) then
      insert into conversation_members (conversation_id, user_id) values (v_id, u) on conflict do nothing;
    end if;
  end loop;
  insert into messages (conversation_id, sender_id, client_id, kind, body)
  values (v_id, v_me, gen_random_uuid(), 'system', 'created the group');
  update conversations set last_message_at = now() where id = v_id;
  return v_id;
end;
$$;

-- Group admin: add or remove people, rename. Anyone: leave.
create or replace function public.update_group_chat(
  p_conversation_id uuid, p_title text default null,
  p_add uuid[] default null, p_remove uuid[] default null)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  u uuid;
begin
  if not exists (select 1 from conversation_members cm join conversations c on c.id = cm.conversation_id
                 where cm.conversation_id = p_conversation_id and cm.user_id = v_me
                   and cm.role = 'admin' and cm.left_at is null and c.kind = 'group') then
    raise exception 'only the group''s admins can change it' using errcode = 'PT403';
  end if;
  if nullif(trim(p_title), '') is not null then
    update conversations set title = trim(p_title) where id = p_conversation_id;
  end if;
  foreach u in array coalesce(p_add, '{}') loop
    if app_private.can_message(u) then
      insert into conversation_members (conversation_id, user_id) values (p_conversation_id, u)
      on conflict (conversation_id, user_id) do update set left_at = null;
    end if;
  end loop;
  update conversation_members set left_at = now()
  where conversation_id = p_conversation_id and user_id = any (coalesce(p_remove, '{}')) and user_id <> v_me;
end;
$$;

create or replace function public.leave_chat(p_conversation_id uuid)
returns void
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  update conversation_members set left_at = now()
  where conversation_id = p_conversation_id and user_id = app_private.current_user_id()
$$;

-- Sends a message (idempotent by p_client_id). Returns the message.
create or replace function public.send_message(
  p_conversation_id uuid, p_client_id uuid, p_kind text default 'text',
  p_body text default null, p_media_asset_id uuid default null,
  p_file_name text default null, p_bytes bigint default null,
  p_duration_seconds numeric default null, p_reply_to_id uuid default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  v messages%rowtype;
  v_title text;
  r record;
begin
  if not app_private.is_member(p_conversation_id) or not app_private.can_message(v_me) then
    raise exception 'chat not found' using errcode = 'PT404';
  end if;
  select * into v from messages where sender_id = v_me and client_id = p_client_id;
  if found then return app_private.message_json(v); end if;
  if p_kind not in ('text', 'image', 'video', 'voice', 'audio', 'document') then
    raise exception 'unknown message type' using errcode = 'PT422';
  end if;
  if coalesce(trim(p_body), '') = '' and p_media_asset_id is null then
    raise exception 'empty message' using errcode = 'PT422';
  end if;
  if p_media_asset_id is not null
     and not exists (select 1 from media_assets where id = p_media_asset_id and uploaded_by = v_me) then
    raise exception 'attachment not found' using errcode = 'PT404';
  end if;
  if p_reply_to_id is not null
     and not exists (select 1 from messages where id = p_reply_to_id and conversation_id = p_conversation_id) then
    p_reply_to_id := null;
  end if;
  insert into messages (conversation_id, sender_id, client_id, kind, body, media_asset_id,
                        file_name, bytes, duration_seconds, reply_to_id)
  values (p_conversation_id, v_me, p_client_id, p_kind, nullif(trim(p_body), ''), p_media_asset_id,
          p_file_name, p_bytes, p_duration_seconds, p_reply_to_id)
  returning * into v;
  update conversations set last_message_at = v.created_at where id = p_conversation_id;
  update conversation_members set last_read_at = v.created_at
  where conversation_id = p_conversation_id and user_id = v_me;
  select coalesce(c.title, (select display_name from users where id = v_me)) into v_title
  from conversations c where c.id = p_conversation_id;
  for r in select user_id from conversation_members
           where conversation_id = p_conversation_id and user_id <> v_me
             and left_at is null and not muted loop
    perform app_private.notify(r.user_id, 'message', v_title,
      case when (select kind from conversations where id = p_conversation_id) = 'group'
           then (select display_name from users where id = v_me) || ': ' else '' end
      || coalesce(left(v.body, 120), case v.kind when 'image' then '📷 Photo' when 'video' then '🎥 Video'
                                                  when 'voice' then '🎤 Voice note' when 'audio' then '🎵 Audio'
                                                  else '📄 ' || coalesce(v.file_name, 'File') end),
      jsonb_build_object('conversation_id', p_conversation_id));
  end loop;
  return app_private.message_json(v);
end;
$$;

-- Messages of a chat, newest first, before a time (for scrolling back).
create or replace function public.chat_messages(
  p_conversation_id uuid, p_before timestamptz default null, p_after timestamptz default null,
  p_limit int default 50)
returns setof jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.is_member(p_conversation_id) then
    raise exception 'chat not found' using errcode = 'PT404';
  end if;
  return query
    select app_private.message_json(m) from messages m
    where m.conversation_id = p_conversation_id
      and (p_before is null or m.created_at < p_before)
      and (p_after is null or m.created_at > p_after or m.deleted_at > p_after)
    order by m.created_at desc
    limit least(greatest(p_limit, 1), 200);
end;
$$;

-- My chats, most recent first, with unread counts and the last message.
create or replace function public.my_chats()
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select jsonb_build_object(
    'id', c.id, 'kind', c.kind,
    'title', coalesce(c.title, other.display_name),
    'avatar_url', case when c.kind = 'direct' then other.avatar_url end,
    'other_user_id', other.id,
    'last_message_at', c.last_message_at,
    'muted', me.muted, 'is_admin', me.role = 'admin',
    'members', (select count(*) from conversation_members x
                where x.conversation_id = c.id and x.left_at is null),
    'unread', (select count(*) from messages m
               where m.conversation_id = c.id and m.sender_id is distinct from me.user_id
                 and m.deleted_at is null
                 and (me.last_read_at is null or m.created_at > me.last_read_at)),
    'last_message', (select app_private.message_json(m) from messages m
                     where m.conversation_id = c.id order by m.created_at desc limit 1))
  from conversation_members me
  join conversations c on c.id = me.conversation_id
  left join lateral (
    select u.id, u.display_name, u.avatar_url from conversation_members o
    join users u on u.id = o.user_id
    where c.kind = 'direct' and o.conversation_id = c.id and o.user_id <> me.user_id
    limit 1) other on true
  where me.user_id = app_private.current_user_id() and me.left_at is null
  order by c.last_message_at desc nulls last
$$;

create or replace function public.chat_members(p_conversation_id uuid)
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select jsonb_build_object('user_id', u.id, 'display_name', u.display_name,
                            'avatar_url', u.avatar_url, 'role', cm.role)
  from conversation_members cm join users u on u.id = cm.user_id
  where cm.conversation_id = p_conversation_id and cm.left_at is null
    and app_private.is_member(p_conversation_id)
  order by cm.role, u.display_name
$$;

create or replace function public.mark_chat_read(p_conversation_id uuid)
returns void
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  update conversation_members set last_read_at = now()
  where conversation_id = p_conversation_id and user_id = app_private.current_user_id();
  update notifications set read_at = now()
  where user_id = app_private.current_user_id() and kind = 'message' and read_at is null
    and data->>'conversation_id' = p_conversation_id::text;
$$;

create or replace function public.mute_chat(p_conversation_id uuid, p_muted boolean)
returns void
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  update conversation_members set muted = p_muted
  where conversation_id = p_conversation_id and user_id = app_private.current_user_id()
$$;

-- Delete for everyone (own messages, within a day) — the file goes too.
create or replace function public.delete_message(p_message_id uuid)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v messages%rowtype;
begin
  select * into v from messages where id = p_message_id and sender_id = app_private.current_user_id();
  if not found then raise exception 'message not found' using errcode = 'PT404'; end if;
  if v.created_at < now() - interval '1 day' then
    raise exception 'messages can be deleted for everyone within a day' using errcode = 'PT409';
  end if;
  update messages set deleted_at = now(), body = null where id = v.id;
  update conversations set last_message_at = now() where id = v.conversation_id;
end;
$$;

revoke all on function public.chat_directory(text), public.open_direct_chat(uuid),
  public.create_group_chat(text, uuid[]), public.update_group_chat(uuid, text, uuid[], uuid[]),
  public.leave_chat(uuid),
  public.send_message(uuid, uuid, text, text, uuid, text, bigint, numeric, uuid),
  public.chat_messages(uuid, timestamptz, timestamptz, int), public.my_chats(),
  public.chat_members(uuid), public.mark_chat_read(uuid), public.mute_chat(uuid, boolean),
  public.delete_message(uuid) from public, anonymous;
grant execute on function public.chat_directory(text), public.open_direct_chat(uuid),
  public.create_group_chat(text, uuid[]), public.update_group_chat(uuid, text, uuid[], uuid[]),
  public.leave_chat(uuid),
  public.send_message(uuid, uuid, text, text, uuid, text, bigint, numeric, uuid),
  public.chat_messages(uuid, timestamptz, timestamptz, int), public.my_chats(),
  public.chat_members(uuid), public.mark_chat_read(uuid), public.mute_chat(uuid, boolean),
  public.delete_message(uuid) to authenticated, sidra_app;

select app_private.lock_down_functions();
