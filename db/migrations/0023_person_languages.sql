-- Person profile also returns the languages a person teaches in.
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('public.admin_person_profile(uuid)'::regprocedure);
  if position('''created_at'', v.created_at,' in v_src) = 0 then
    raise exception 'admin_person_profile changed; update 0023';
  end if;
  execute replace(v_src, '''created_at'', v.created_at,',
                  '''created_at'', v.created_at, ''languages'', v.languages,');
end $$;
