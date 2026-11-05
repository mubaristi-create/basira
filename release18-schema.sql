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
