begin;
do $$declare a uuid:=gen_random_uuid();b uuid:=gen_random_uuid();begin
 insert into auth.users(id,email,raw_user_meta_data,raw_app_meta_data,aud,role) values(a,'shams-rls-a@example.invalid','{}','{}','authenticated','authenticated'),(b,'shams-rls-b@example.invalid','{}','{}','authenticated','authenticated');
 perform set_config('request.jwt.claims',jsonb_build_object('sub',a::text,'role','authenticated')::text,true);
end$$;
set local role authenticated;
do $$begin
 if (select count(*) from public.shams_profiles)<>1 then raise exception 'FAIL: profile isolation';end if;
 if public.shams_is_admin() then raise exception 'FAIL: unexpected admin';end if;
 begin perform public.shams_admin_overview();raise exception 'FAIL: non-admin access';exception when raise_exception then if sqlerrm<>'Admin required' then raise;end if;end;
 begin update public.shams_profiles set disabled=true where id=auth.uid();raise exception 'FAIL: role escalation';exception when insufficient_privilege then null;end;
 perform public.shams_save_backup('{"version":1,"data":{}}'::jsonb,0);
 if (select count(*) from public.shams_backups)<>1 then raise exception 'FAIL: own backup';end if;
end$$;
reset role;
rollback;
select 'PASS: own profiles/backups only; admin denied; escalation denied; no test users persisted' as result;
