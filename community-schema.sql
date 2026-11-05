-- 20261104_admin_identity.sql
-- Email sign-up may be auto-confirmed. Existing admin UUIDs, not email claims,
-- remain the authority; a newly registered matching email must never gain admin.
begin;
do $$begin if not exists(select 1 from shams_private.admins a join public.shams_profiles p on p.id=a.user_id where lower(p.email)='mubaristi@gmail.com' and not p.disabled) then raise exception 'Existing owner admin must be present before disabling email-based promotion';end if;end$$;
create or replace function public.shams_claim_admin() returns boolean language plpgsql security definer set search_path='' as $$begin return public.shams_is_admin();end$$;
create or replace function shams_private.auth_profile() returns trigger language plpgsql security definer set search_path='' as $$begin
 insert into public.shams_profiles(id,email,display_name,last_sign_in_at) values(new.id,coalesce(new.email,''),left(coalesce(new.raw_user_meta_data->>'display_name',''),80),new.last_sign_in_at) on conflict(id) do update set email=excluded.email,last_sign_in_at=excluded.last_sign_in_at;
 if tg_op='INSERT' then insert into public.shams_events(user_id,kind) values(new.id,'registered');
 elsif new.last_sign_in_at is distinct from old.last_sign_in_at then insert into public.shams_events(user_id,kind) values(new.id,'signed_in');end if;
 return new;end$$;
revoke all on function shams_private.auth_profile() from public,anon,authenticated;
commit;


-- 20261104_community.sql
begin;
create table if not exists shams_private.ideas(id uuid primary key default gen_random_uuid(),user_id uuid references auth.users(id) on delete set null,author text not null,title text not null check(length(title) between 3 and 120),body text not null check(length(body) between 5 and 2000),status text not null default 'new' check(status in ('new','planned','developing','soon','completed')),reply text not null default '' check(length(reply)<=2000),hidden boolean not null default false,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create index if not exists ideas_created on shams_private.ideas(created_at desc);
create table if not exists shams_private.leader_members(user_id uuid primary key references auth.users(id) on delete cascade,nickname text not null check(length(nickname) between 2 and 32),visible boolean not null default true);
create table if not exists shams_private.quiz_bank(id text primary key,category text not null,difficulty integer not null check(difficulty between 1 and 4),correct integer not null check(correct between 0 and 3));
create table if not exists shams_private.quiz_rounds(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,questions text[] not null,started_at timestamptz not null default now(),finished_at timestamptz,awarded integer);
create index if not exists quiz_user_started on shams_private.quiz_rounds(user_id,started_at);
create table if not exists shams_private.quiz_credits(user_id uuid references auth.users(id) on delete cascade,question_id text references shams_private.quiz_bank(id),day date not null,points integer not null default 10 check(points=10),primary key(user_id,question_id,day));
alter table shams_private.ideas enable row level security;
alter table shams_private.leader_members enable row level security;
alter table shams_private.quiz_bank enable row level security;
alter table shams_private.quiz_rounds enable row level security;
alter table shams_private.quiz_credits enable row level security;
revoke all on shams_private.ideas,shams_private.leader_members,shams_private.quiz_bank,shams_private.quiz_rounds,shams_private.quiz_credits from public,anon,authenticated;
create or replace function public.shams_ideas_list(p_limit integer default 30,p_admin boolean default false) returns jsonb language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(to_jsonb(t) order by t.created_at desc,t.id),'[]') from (select id,author,title,body,status,reply,hidden,created_at from shams_private.ideas where not hidden or (p_admin and public.shams_is_admin()) order by created_at desc,id limit least(300,greatest(1,coalesce(p_limit,30)))) t
$$;
create or replace function public.shams_idea_post(p_title text,p_body text) returns uuid language plpgsql security definer set search_path='' as $$declare result uuid;name text;begin
 if not public.shams_is_active() then raise exception 'Sign in required';end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,17));
 if (select count(*) from shams_private.ideas where user_id=auth.uid() and created_at>now()-interval '1 hour')>=5 then raise exception 'Please wait before posting again';end if;
 select left(coalesce(nullif(btrim(display_name),''),'SHAMS'),80) into name from public.shams_profiles where id=auth.uid();
 insert into shams_private.ideas(user_id,author,title,body) values(auth.uid(),name,btrim(p_title),btrim(p_body)) returning id into result;return result;end$$;
create or replace function public.shams_idea_admin(p_id uuid,p_reply text,p_status text,p_hidden boolean) returns void language plpgsql security definer set search_path='' as $$begin
 if not public.shams_is_admin() then raise exception 'Admin required';end if;
 update shams_private.ideas set reply=coalesce(p_reply,''),status=p_status,hidden=p_hidden,updated_at=now() where id=p_id;
 if not found then raise exception 'Not found';end if;
 insert into public.shams_admin_audit(actor,action,target,details) values(auth.uid(),'idea_updated',p_id::text,jsonb_build_object('status',p_status,'hidden',p_hidden));end$$;
create or replace function public.shams_leader_join(p_nickname text,p_visible boolean) returns void language plpgsql security definer set search_path='' as $$begin
 if not public.shams_is_active() then raise exception 'Sign in required';end if;
 insert into shams_private.leader_members values(auth.uid(),btrim(p_nickname),p_visible) on conflict(user_id) do update set nickname=excluded.nickname,visible=excluded.visible;end$$;
create or replace function public.shams_leaderboard() returns jsonb language sql stable security definer set search_path='' as $$
 with scores as (select user_id,sum(points)::integer points from shams_private.quiz_credits group by user_id),ranked as (select m.user_id,m.nickname,m.visible,coalesce(s.points,0) points,row_number() over(order by coalesce(s.points,0) desc,m.user_id) rank from shams_private.leader_members m join public.shams_profiles p on p.id=m.user_id left join scores s on s.user_id=m.user_id where m.visible and not p.disabled and coalesce(s.points,0)>0)
 select jsonb_build_object('rows',coalesce((select jsonb_agg(to_jsonb(t) order by t.rank) from (select * from ranked order by rank limit 100) t),'[]'),'me',(select jsonb_build_object('nickname',m.nickname,'visible',m.visible,'points',coalesce(s.points,0),'rank',r.rank) from shams_private.leader_members m left join scores s on s.user_id=m.user_id left join ranked r on r.user_id=m.user_id where m.user_id=auth.uid()))
$$;
create or replace function public.shams_quiz_start(p_category text,p_level integer) returns jsonb language plpgsql security definer set search_path='' as $$declare qs text[];rid uuid;begin
 if not public.shams_is_active() then raise exception 'Sign in required';end if;
 if not exists(select 1 from shams_private.module_policy where module='quiz' and mode<>'closed' and (mode='free' or (mode='trial' and trial_until>now()) or coalesce((public.shams_premium_status()->>'premium')::boolean,false))) then raise exception 'Quiz unavailable';end if;
 if not exists(select 1 from shams_private.leader_members where user_id=auth.uid() and visible) then return null;end if;
 if p_level not between 1 and 4 or p_category not in ('all','quran','prophets','history','prayer','ramadan','culture','names','general') then raise exception 'Invalid quiz settings';end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,17));
 if (select count(*) from shams_private.quiz_rounds where user_id=auth.uid() and started_at>=date_trunc('day',now() at time zone 'UTC') at time zone 'UTC')>=10 then raise exception 'Daily ranked round limit reached';end if;
 select array_agg(t.id order by random()) into qs from (select id from shams_private.quiz_bank where p_category='all' or category=p_category order by abs(difficulty-p_level),random() limit 10) t;
 if array_length(qs,1)<>10 then raise exception 'Not enough questions';end if;
 insert into shams_private.quiz_rounds(user_id,questions) values(auth.uid(),qs) returning id into rid;
 return jsonb_build_object('id',rid,'questions',qs);end$$;
create or replace function public.shams_quiz_finish(p_round uuid,p_answers integer[]) returns jsonb language plpgsql security definer set search_path='' as $$declare r shams_private.quiz_rounds;credit integer:=0;n integer;d date:=(now() at time zone 'UTC')::date;begin
 if not public.shams_is_active() then raise exception 'Sign in required';end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,17));
 select * into r from shams_private.quiz_rounds where id=p_round and user_id=auth.uid() for update;
 if not found then raise exception 'Round not found';end if;
 if r.finished_at is not null then return jsonb_build_object('awarded',r.awarded,'replayed',true);end if;
 if p_answers is null or r.started_at<now()-interval '24 hours' or cardinality(p_answers)<>10 or array_lower(p_answers,1)<>1 or exists(select 1 from unnest(p_answers) a where a is null or a not between 0 and 3) then raise exception 'Invalid or expired round';end if;
 for n in 1..10 loop
  if exists(select 1 from shams_private.quiz_bank where id=r.questions[n] and correct=p_answers[n]) then
   insert into shams_private.quiz_credits(user_id,question_id,day) values(auth.uid(),r.questions[n],d) on conflict do nothing;
   if found then credit:=credit+10;end if;
  end if;
 end loop;
 update shams_private.quiz_rounds set finished_at=now(),awarded=credit where id=p_round;
 insert into public.shams_events(user_id,kind,details) values(auth.uid(),'ranked_quiz_completed',jsonb_build_object('points',credit));
 return jsonb_build_object('awarded',credit,'replayed',false);end$$;
revoke all on function public.shams_ideas_list(integer,boolean),public.shams_idea_post(text,text),public.shams_idea_admin(uuid,text,text,boolean),public.shams_leader_join(text,boolean),public.shams_leaderboard(),public.shams_quiz_start(text,integer),public.shams_quiz_finish(uuid,integer[]) from public,anon,authenticated;
grant execute on function public.shams_ideas_list(integer,boolean),public.shams_leaderboard() to anon,authenticated;
grant execute on function public.shams_idea_post(text,text),public.shams_idea_admin(uuid,text,text,boolean),public.shams_leader_join(text,boolean),public.shams_quiz_start(text,integer),public.shams_quiz_finish(uuid,integer[]) to authenticated;
commit;


-- 20261104_quiz_bank.sql
begin;
insert into shams_private.quiz_bank(id,category,difficulty,correct) values
('quran-01','quran',1,0),
('quran-02','quran',1,3),
('quran-03','quran',1,2),
('quran-04','quran',1,1),
('quran-05','quran',1,0),
('quran-06','quran',1,3),
('quran-07','quran',1,2),
('quran-08','quran',1,1),
('quran-09','quran',3,0),
('quran-10','quran',4,3),
('prophets-01','prophets',1,2),
('prophets-02','prophets',1,1),
('prophets-03','prophets',1,0),
('prophets-04','prophets',1,3),
('prophets-05','prophets',1,2),
('prophets-06','prophets',1,1),
('prophets-07','prophets',1,0),
('prophets-08','prophets',1,3),
('prophets-09','prophets',3,2),
('prophets-10','prophets',4,1),
('history-01','history',1,0),
('history-02','history',2,3),
('history-03','history',1,2),
('history-04','history',2,1),
('history-05','history',1,0),
('history-06','history',2,3),
('history-07','history',1,2),
('history-08','history',3,1),
('history-09','history',3,0),
('history-10','history',4,3),
('prayer-01','prayer',1,2),
('prayer-02','prayer',1,1),
('prayer-03','prayer',2,0),
('prayer-04','prayer',1,3),
('prayer-05','prayer',2,2),
('prayer-06','prayer',1,1),
('prayer-07','prayer',2,0),
('prayer-08','prayer',1,3),
('prayer-09','prayer',3,2),
('prayer-10','prayer',4,1),
('ramadan-01','ramadan',1,0),
('ramadan-02','ramadan',1,3),
('ramadan-03','ramadan',2,2),
('ramadan-04','ramadan',1,1),
('ramadan-05','ramadan',2,0),
('ramadan-06','ramadan',2,3),
('ramadan-07','ramadan',3,2),
('ramadan-08','ramadan',1,1),
('ramadan-09','ramadan',3,0),
('ramadan-10','ramadan',4,3),
('culture-01','culture',1,2),
('culture-02','culture',1,1),
('culture-03','culture',2,0),
('culture-04','culture',1,3),
('culture-05','culture',1,2),
('culture-06','culture',2,1),
('culture-07','culture',2,0),
('culture-08','culture',1,3),
('culture-09','culture',3,2),
('culture-10','culture',4,1),
('names-01','names',1,0),
('names-02','names',1,3),
('names-03','names',1,2),
('names-04','names',1,1),
('names-05','names',3,0),
('names-06','names',1,3),
('names-07','names',1,2),
('names-08','names',3,1),
('names-09','names',3,0),
('names-10','names',4,3),
('general-01','general',1,2),
('general-02','general',2,1),
('general-03','general',1,0),
('general-04','general',2,3),
('general-05','general',1,2),
('general-06','general',1,1),
('general-07','general',2,0),
('general-08','general',1,3),
('general-09','general',3,2),
('general-10','general',4,1)
on conflict(id) do update set category=excluded.category,difficulty=excluded.difficulty,correct=excluded.correct;
commit;


-- 20261104_release18.sql
begin;
alter table shams_private.ideas add column if not exists client_id uuid;
create unique index if not exists ideas_client_once on shams_private.ideas(user_id,client_id) where client_id is not null;
create table if not exists shams_private.idea_terms(user_id uuid primary key references auth.users(id) on delete cascade,version text not null,accepted_at timestamptz not null default now());
create table if not exists shams_private.idea_blocks(user_id uuid references auth.users(id) on delete cascade,blocked_id uuid references auth.users(id) on delete cascade,created_at timestamptz not null default now(),primary key(user_id,blocked_id),check(user_id<>blocked_id));
create table if not exists shams_private.idea_reports(id uuid primary key default gen_random_uuid(),post_id uuid not null references shams_private.ideas(id) on delete cascade,reporter uuid not null references auth.users(id) on delete cascade,reason text not null check(reason in ('spam','abuse','private','other')),note text not null default '' check(length(note)<=500),resolved boolean not null default false,created_at timestamptz not null default now(),unique(post_id,reporter,reason));
alter table shams_private.idea_reports alter column post_id drop not null;
alter table shams_private.idea_reports add column if not exists subject_user uuid references auth.users(id) on delete cascade;
create unique index if not exists profile_report_once on shams_private.idea_reports(reporter,subject_user,reason) where post_id is null;
alter table shams_private.idea_terms enable row level security;
alter table shams_private.idea_blocks enable row level security;
alter table shams_private.idea_reports enable row level security;
revoke all on shams_private.idea_terms,shams_private.idea_blocks,shams_private.idea_reports from public,anon,authenticated;
create or replace function public.shams_idea_send(p_title text,p_body text,p_request uuid,p_terms text) returns uuid language plpgsql security definer set search_path='' as $$declare result uuid;previous shams_private.ideas;name text;begin
 if not public.shams_is_active() then raise exception 'Sign in required';end if;
 if p_terms is distinct from '2026-11-04' then raise exception 'Posting rules must be accepted';end if;
 if p_request is null or p_title is null or p_body is null or length(btrim(p_title)) not between 3 and 120 or length(btrim(p_body)) not between 5 and 2000 then raise exception 'Invalid post';end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,17));
 select * into previous from shams_private.ideas where user_id=auth.uid() and client_id=p_request;
 if found then if previous.title<>btrim(p_title) or previous.body<>btrim(p_body) then raise exception 'Request already used';end if;return previous.id;end if;
 if (select count(*) from shams_private.ideas where user_id=auth.uid() and created_at>now()-interval '1 hour')>=5 then raise exception 'Please wait before posting again';end if;
 select left(coalesce(nullif(btrim(display_name),''),'SHAMS'),80) into name from public.shams_profiles where id=auth.uid();
 insert into shams_private.idea_terms values(auth.uid(),p_terms,now()) on conflict(user_id) do update set version=excluded.version,accepted_at=excluded.accepted_at;
 insert into shams_private.ideas(user_id,author,title,body,client_id) values(auth.uid(),name,btrim(p_title),btrim(p_body),p_request) returning id into result;return result;end$$;
-- Earlier APKs do not contain the required consent UI. Read access remains.
create or replace function public.shams_idea_post(p_title text,p_body text) returns uuid language plpgsql security definer set search_path='' as $$begin raise exception 'Update SHAMS to accept posting rules';end$$;
create or replace function public.shams_ideas_list(p_limit integer default 30,p_admin boolean default false) returns jsonb language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(to_jsonb(t) order by t.created_at desc,t.id),'[]') from (select i.id,i.user_id author_id,i.author,i.title,i.body,i.status,i.reply,i.hidden,i.created_at from shams_private.ideas i where ((p_admin and public.shams_is_admin()) or (not i.hidden and not exists(select 1 from shams_private.idea_blocks b where b.user_id=auth.uid() and b.blocked_id=i.user_id))) order by i.created_at desc,i.id limit least(300,greatest(1,coalesce(p_limit,30)))) t
$$;
create or replace function public.shams_idea_report(p_id uuid,p_reason text,p_note text) returns void language plpgsql security definer set search_path='' as $$begin
 if not public.shams_is_active() then raise exception 'Sign in required';end if;
 if not exists(select 1 from shams_private.ideas where id=p_id and user_id is distinct from auth.uid()) then raise exception 'Post not found';end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,18));
 if (select count(*) from shams_private.idea_reports where reporter=auth.uid() and created_at>now()-interval '1 hour')>=10 then raise exception 'Report limit reached';end if;
 insert into shams_private.idea_reports(post_id,reporter,reason,note) values(p_id,auth.uid(),p_reason,coalesce(p_note,'')) on conflict(post_id,reporter,reason) do nothing;end$$;
create or replace function public.shams_idea_block(p_id uuid) returns void language plpgsql security definer set search_path='' as $$declare other_user uuid;begin
 if not public.shams_is_active() then raise exception 'Sign in required';end if;
 select user_id into other_user from shams_private.ideas where id=p_id;
 if other_user is null or other_user=auth.uid() then raise exception 'Invalid author';end if;
 insert into shams_private.idea_blocks(user_id,blocked_id) values(auth.uid(),other_user) on conflict do nothing;end$$;
create or replace function public.shams_idea_blocks() returns jsonb language sql stable security definer set search_path='' as $$select coalesce(jsonb_agg(jsonb_build_object('id',p.id,'name',coalesce(nullif(p.display_name,''),'SHAMS'))),'[]') from shams_private.idea_blocks b join public.shams_profiles p on p.id=b.blocked_id where b.user_id=auth.uid()$$;
create or replace function public.shams_idea_unblock(p_user uuid) returns void language plpgsql security definer set search_path='' as $$begin delete from shams_private.idea_blocks where user_id=auth.uid() and blocked_id=p_user;end$$;
create or replace function public.shams_idea_reports() returns jsonb language plpgsql security definer set search_path='' as $$begin
 if not public.shams_is_admin() then raise exception 'Admin required';end if;
 return (select coalesce(jsonb_agg(to_jsonb(t) order by t.created_at desc),'[]') from (select r.id,r.post_id,coalesce(r.subject_user,i.user_id) user_id,r.reason,r.note,r.created_at,coalesce(i.title,m.nickname,p.display_name,'SHAMS') title,coalesce(i.body,'Profile report') body from shams_private.idea_reports r left join shams_private.ideas i on i.id=r.post_id left join shams_private.leader_members m on m.user_id=r.subject_user left join public.shams_profiles p on p.id=r.subject_user where not r.resolved order by r.created_at desc limit 100) t);end$$;
create or replace function public.shams_user_report(p_user uuid,p_reason text,p_note text) returns void language plpgsql security definer set search_path='' as $$begin
 if not public.shams_is_active() then raise exception 'Sign in required';end if;
 if p_user=auth.uid() or not exists(select 1 from shams_private.leader_members where user_id=p_user and visible) then raise exception 'Public profile not found';end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,18));
 if (select count(*) from shams_private.idea_reports where reporter=auth.uid() and created_at>now()-interval '1 hour')>=10 then raise exception 'Report limit reached';end if;
 insert into shams_private.idea_reports(subject_user,reporter,reason,note) values(p_user,auth.uid(),p_reason,coalesce(p_note,'')) on conflict do nothing;end$$;
create or replace function public.shams_user_block(p_user uuid) returns void language plpgsql security definer set search_path='' as $$begin
 if not public.shams_is_active() then raise exception 'Sign in required';end if;
 if p_user=auth.uid() or not exists(select 1 from public.shams_profiles where id=p_user) then raise exception 'Invalid author';end if;
 insert into shams_private.idea_blocks(user_id,blocked_id) values(auth.uid(),p_user) on conflict do nothing;end$$;
create or replace function public.shams_leaderboard() returns jsonb language sql stable security definer set search_path='' as $$
 with scores as (select user_id,sum(points)::integer points from shams_private.quiz_credits group by user_id),ranked as (select m.user_id,m.nickname,m.visible,coalesce(s.points,0) points,row_number() over(order by coalesce(s.points,0) desc,m.user_id) rank from shams_private.leader_members m join public.shams_profiles p on p.id=m.user_id left join scores s on s.user_id=m.user_id where m.visible and not p.disabled and coalesce(s.points,0)>0)
 select jsonb_build_object('rows',coalesce((select jsonb_agg(to_jsonb(t) order by t.rank) from (select * from ranked r where not exists(select 1 from shams_private.idea_blocks b where b.user_id=auth.uid() and b.blocked_id=r.user_id) order by rank limit 100) t),'[]'),'me',(select jsonb_build_object('nickname',m.nickname,'visible',m.visible,'points',coalesce(s.points,0),'rank',r.rank) from shams_private.leader_members m left join scores s on s.user_id=m.user_id left join ranked r on r.user_id=m.user_id where m.user_id=auth.uid()))
$$;
create or replace function public.shams_idea_report_resolve(p_id uuid) returns void language plpgsql security definer set search_path='' as $$begin
 if not public.shams_is_admin() then raise exception 'Admin required';end if;
 update shams_private.idea_reports set resolved=true where id=p_id;
 insert into public.shams_admin_audit(actor,action,target) values(auth.uid(),'idea_report_reviewed',p_id::text);end$$;
create or replace function public.shams_delete_user_posts(p_user uuid) returns void language plpgsql security definer set search_path='' as $$begin
 if exists(select 1 from shams_private.admins where user_id=p_user) then raise exception 'Transfer the administrator role before deleting this account';end if;
 delete from shams_private.ideas where user_id=p_user;
end$$;
revoke all on function public.shams_idea_send(text,text,uuid,text),public.shams_idea_report(uuid,text,text),public.shams_idea_block(uuid),public.shams_idea_blocks(),public.shams_idea_unblock(uuid),public.shams_idea_reports(),public.shams_idea_report_resolve(uuid),public.shams_delete_user_posts(uuid) from public,anon,authenticated;
grant execute on function public.shams_idea_send(text,text,uuid,text),public.shams_idea_report(uuid,text,text),public.shams_idea_block(uuid),public.shams_idea_blocks(),public.shams_idea_unblock(uuid),public.shams_idea_reports(),public.shams_idea_report_resolve(uuid) to authenticated;
grant execute on function public.shams_delete_user_posts(uuid) to service_role;
revoke all on function public.shams_user_report(uuid,text,text),public.shams_user_block(uuid) from public,anon;
grant execute on function public.shams_user_report(uuid,text,text),public.shams_user_block(uuid) to authenticated;
notify pgrst,'reload schema';
commit;
