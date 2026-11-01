begin;
do $$declare a uuid:=gen_random_uuid();b uuid:=gen_random_uuid();begin
 insert into auth.users(id,email,raw_user_meta_data,raw_app_meta_data,aud,role) values(a,'shams-admin-test@example.invalid','{}','{}','authenticated','authenticated'),(b,'shams-private-test@example.invalid','{}','{}','authenticated','authenticated');
 insert into shams_private.admins values(a);
 insert into public.shams_backups(user_id,snapshot) values(b,'{"version":1,"data":{"private":"test-only"}}');
 perform set_config('request.jwt.claims',jsonb_build_object('sub',a::text,'role','authenticated')::text,true);
end$$;
set local role authenticated;
do $$begin
 if not public.shams_is_admin() then raise exception 'FAIL: admin not recognized';end if;
 if (select count(*) from public.shams_backups)<>0 then raise exception 'FAIL: admin can read another private backup';end if;
 if not (public.shams_admin_overview() ? 'profiles') then raise exception 'FAIL: admin overview';end if;
 if not (public.shams_admin_records('profiles','',0) ? 'rows') then raise exception 'FAIL: paginated users';end if;
 perform public.shams_admin_content(null,'announcement','{"title":"Test only","body":"Rolled back"}',false);
 begin perform public.shams_admin_content(null,'dua','{"title":"Test only","body":"Rolled back","source":"https://example.invalid"}',true);raise exception 'FAIL: unreviewed content published';exception when raise_exception then if sqlerrm<>'Reviewed source required' then raise;end if;end;
 begin perform public.shams_admin_user(auth.uid(),true);raise exception 'FAIL: self disable';exception when raise_exception then if sqlerrm<>'Admin required; cannot disable yourself' then raise;end if;end;
end$$;
reset role;
rollback;
select 'PASS: admin records and CMS; private backups hidden; review gate; no fixtures persisted' as result;
