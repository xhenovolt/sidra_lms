-- Messaging (0037): staff chats, privacy, files, idempotent sending.
update org_settings set value = 'true' where key = 'messaging_enabled';
update org_settings set value = 'false' where key = 'messaging_learners';
select set_config('m.t3', app_private.create_account('Chat Teacher Three', null, null, 'chat_t3',
  'learner', false, 'staff-pass-1', false)::text, true);
insert into user_roles (user_id, role_key) values (current_setting('m.t3')::uuid, 'teacher');

-- Admin opens a direct chat with a teacher; opening again gives the same chat.
select pg_temp.login_as('admin_1');
set local role authenticated;
select pg_temp.check(exists (select 1 from public.chat_directory() j
                             where j->>'user_id' = '00000000-0000-0000-0000-00000000000b'),
  'teachers are in the chat directory');
select pg_temp.check(not exists (select 1 from public.chat_directory() j
                                 where j->>'user_id' = '00000000-0000-0000-0000-0000000000a1'),
  'learners are not, by default');
select set_config('m.d', public.open_direct_chat('00000000-0000-0000-0000-00000000000b')::text, true);
select pg_temp.check(public.open_direct_chat('00000000-0000-0000-0000-00000000000b')::text = current_setting('m.d'),
  'one direct chat per pair');
select pg_temp.expect_error($q$select public.open_direct_chat('00000000-0000-0000-0000-0000000000a1')$q$,
  'cannot message');

-- Send: text, then the same client id again (a retry) → one message.
select set_config('m.m1', (public.send_message(current_setting('m.d')::uuid,
  '00000000-0000-0000-0000-00000000c001', 'text', 'Assalamu alaikum'))->>'id', true);
select pg_temp.check((public.send_message(current_setting('m.d')::uuid,
  '00000000-0000-0000-0000-00000000c001', 'text', 'Assalamu alaikum'))->>'id' = current_setting('m.m1'),
  'resending the same message does not duplicate it');
select pg_temp.expect_error($q$select public.send_message(current_setting('m.d')::uuid,
  gen_random_uuid(), 'text', '   ')$q$, 'empty message');
reset role;

-- A voice note from the admin's own upload.
insert into media_assets (id, kind, resource_type, delivery, public_id, format, uploaded_by)
values ('00000000-0000-0000-0000-00000000cf01', 'audio', 'video', 'authenticated', 'sidra/chat/voice1', 'm4a',
        '00000000-0000-0000-0000-00000000000a');
select pg_temp.login_as('admin_1');
set local role authenticated;
select public.send_message(current_setting('m.d')::uuid, '00000000-0000-0000-0000-00000000c002',
  'voice', null, '00000000-0000-0000-0000-00000000cf01', 'voice.m4a', 12000, 7.5,
  current_setting('m.m1')::uuid);
reset role;
select pg_temp.check(exists (select 1 from notifications
                             where user_id = '00000000-0000-0000-0000-00000000000b' and kind = 'message'),
  'the other person is notified');

-- The teacher reads the chat and the voice note, replies, marks read.
select pg_temp.login_as('teacher_1');
set local role authenticated;
select pg_temp.check((select (j->>'unread')::int from public.my_chats() j
                      where j->>'id' = current_setting('m.d')) = 2, 'two unread');
select pg_temp.check((select count(*) from public.chat_messages(current_setting('m.d')::uuid)) = 2,
  'teacher sees both messages');
select pg_temp.check((select j->'reply_to'->>'body' from public.chat_messages(current_setting('m.d')::uuid) j
                      where j->>'kind' = 'voice') = 'Assalamu alaikum', 'reply shows what it answers');
select pg_temp.check(app_private.can_read_media('00000000-0000-0000-0000-00000000cf01'),
  'members can open the voice note');
select public.mark_chat_read(current_setting('m.d')::uuid);
select pg_temp.check((select (j->>'unread')::int from public.my_chats() j
                      where j->>'id' = current_setting('m.d')) = 0, 'read');
reset role;

-- Another teacher (not a member) sees nothing: not the chat, not the file.
select pg_temp.login_as('teacher_2');
set local role authenticated;
select pg_temp.check(not exists (select 1 from messages where conversation_id = current_setting('m.d')::uuid),
  'non-members cannot read the messages');
select pg_temp.check(not app_private.can_read_media('00000000-0000-0000-0000-00000000cf01'),
  'non-members cannot open chat files (even staff)');
select pg_temp.expect_error($q$select public.chat_messages(current_setting('m.d')::uuid)$q$, 'chat not found');
select pg_temp.expect_error($q$select public.send_message(current_setting('m.d')::uuid, gen_random_uuid(),
  'text', 'let me in')$q$, 'chat not found');
reset role;

-- Groups: create, add, remove; a removed member loses access.
select pg_temp.login_as('admin_1');
set local role authenticated;
select set_config('m.g', public.create_group_chat('Teachers', array[
  '00000000-0000-0000-0000-00000000000b'::uuid, current_setting('m.t3')::uuid])::text, true);
select pg_temp.check((select count(*) from public.chat_members(current_setting('m.g')::uuid)) = 3,
  'group has three members');
select public.update_group_chat(current_setting('m.g')::uuid, null, null,
  array[current_setting('m.t3')::uuid]);
reset role;
select pg_temp.login_as_id(current_setting('m.t3')::uuid);
set local role authenticated;
select pg_temp.check(not exists (select 1 from public.my_chats() j where j->>'id' = current_setting('m.g')),
  'a removed member no longer sees the group');
reset role;
select pg_temp.login_as('teacher_1');
set local role authenticated;
select pg_temp.expect_error($q$select public.update_group_chat(current_setting('m.g')::uuid, 'Renamed')$q$,
  'only the group''s admins');
-- Delete for everyone: only one's own message.
select pg_temp.expect_error($q$select public.delete_message(current_setting('m.m1')::uuid)$q$, 'not found');
reset role;
select pg_temp.login_as('admin_1');
set local role authenticated;
select public.delete_message(current_setting('m.m1')::uuid);
select pg_temp.check((select (j->>'deleted')::boolean and j->>'body' is null
                      from public.chat_messages(current_setting('m.d')::uuid) j
                      where j->>'id' = current_setting('m.m1')), 'deleted for everyone');
reset role;

-- Learners can't use messaging unless allowed.
select pg_temp.login_as('learner_a');
set local role authenticated;
select pg_temp.expect_error($q$select public.chat_directory()$q$, 'not available');
reset role;
