begin;
do $$declare a uuid:=gen_random_uuid();u uuid:=gen_random_uuid();begin
 insert into auth.users(id,email,raw_user_meta_data,raw_app_meta_data,aud,role) values(a,'shams-policy-admin@example.invalid','{}','{}','authenticated','authenticated'),(u,'shams-policy-user@example.invalid','{}','{}','authenticated','authenticated');
 insert into shams_private.admins values(a);
 perform set_config('shams.test.admin',a::text,true);perform set_config('shams.test.user',u::text,true);
end$$;
set local role anon;
do $$begin
 if jsonb_array_length(public.shams_module_access()->'modules')<>3 then raise exception 'FAIL public policies';end if;
 begin perform public.shams_admin_module('quiz','free',1,1);raise exception 'FAIL anon write';exception when insufficient_privilege then null;end;
end$$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('shams.test.user'),'role','authenticated')::text,true);
set local role authenticated;
do $$begin
 begin perform public.shams_admin_module('quiz','free',1,1);raise exception 'FAIL normal user write';exception when raise_exception then if sqlerrm<>'Admin required' then raise;end if;end;
end$$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('shams.test.admin'),'role','authenticated')::text,true);
set local role authenticated;
do $$declare r integer;payload jsonb;begin
 select (x->>'revision')::integer into r from jsonb_array_elements(public.shams_module_access()->'modules') x where x->>'module'='quiz';
 perform public.shams_admin_module('quiz','free',1,r);
 begin perform public.shams_admin_module('quiz','closed',1,r);raise exception 'FAIL stale revision';exception when raise_exception then if sqlerrm<>'Policy changed; refresh first' then raise;end if;end;
 perform public.shams_admin_module('quiz','trial',2,r+1);
 begin perform public.shams_admin_module('quiz','trial',0,r+2);raise exception 'FAIL zero days';exception when raise_exception then if sqlerrm<>'Trial days must be 1..365' then raise;end if;end;
 if not exists(select 1 from public.shams_admin_audit where action='module_policy' and target='quiz') then raise exception 'FAIL audit';end if;
end$$;
reset role;
update shams_private.module_policy set mode='trial',trial_until=now()-interval '1 second' where module='quiz';
do $$begin if not exists(select 1 from jsonb_array_elements(public.shams_module_access()->'modules') x where x->>'module'='quiz' and x->>'effective_mode'='premium') then raise exception 'FAIL trial expiry';end if;end$$;
rollback;
select 'PASS: public read; no anonymous/ordinary-user writes; admin audited updates; revision guard; server trial expiry; rollback' result;
