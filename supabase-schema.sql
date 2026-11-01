begin;
create or replace function public.shams_admin_records(p_kind text,p_search text default '',p_offset integer default 0) returns jsonb language plpgsql security definer set search_path='' as $$declare rows jsonb; total bigint; q text:='%'||left(coalesce(p_search,''),100)||'%';off integer:=greatest(0,p_offset);begin
 if not public.shams_is_admin() then raise exception 'Admin required';end if;
 if p_kind='profiles' then
 select count(*) into total from public.shams_profiles where email ilike q or display_name ilike q;
 select coalesce(jsonb_agg(x),'[]') into rows from(select p.*,exists(select 1 from shams_private.admins a where a.user_id=p.id) is_admin from public.shams_profiles p where p.email ilike q or p.display_name ilike q order by p.created_at desc,p.id limit 50 offset off)x;
 elsif p_kind='events' then
 select count(*) into total from public.shams_events e left join public.shams_profiles p on p.id=e.user_id where e.kind ilike q or p.email ilike q;
 select coalesce(jsonb_agg(x),'[]') into rows from(select e.*,p.email from public.shams_events e left join public.shams_profiles p on p.id=e.user_id where e.kind ilike q or p.email ilike q order by e.created_at desc,e.id desc limit 50 offset off)x;
 elsif p_kind='audit' then
 select count(*) into total from public.shams_admin_audit where action ilike q or target ilike q;
 select coalesce(jsonb_agg(x),'[]') into rows from(select * from public.shams_admin_audit where action ilike q or target ilike q order by created_at desc,id desc limit 50 offset off)x;
 else raise exception 'Unknown record type';end if;
 return jsonb_build_object('rows',rows,'total',total,'offset',off);end$$;
revoke all on function public.shams_admin_records(text,text,integer) from public,anon;
grant execute on function public.shams_admin_records(text,text,integer) to authenticated;
commit;

begin;
alter table public.shams_content add column if not exists public_id integer generated always as identity unique;
commit;

begin;
insert into public.shams_profiles(id,email,display_name,created_at,last_sign_in_at) select id,coalesce(email,''),left(coalesce(raw_user_meta_data->>'display_name',''),80),created_at,last_sign_in_at from auth.users on conflict(id) do nothing;
insert into public.shams_events(user_id,kind,created_at) select p.id,'registered',p.created_at from public.shams_profiles p where not exists(select 1 from public.shams_events e where e.user_id=p.id and e.kind='registered');
create or replace function public.shams_claim_admin() returns boolean language plpgsql security definer set search_path='' as $$declare u auth.users;begin
select * into u from auth.users where id=auth.uid();if u.email_confirmed_at is null or not exists(select 1 from shams_private.approved_admins where email=lower(u.email)) or not public.shams_is_active() then return false;end if;
insert into shams_private.admins values(u.id) on conflict do nothing;return public.shams_is_admin();end$$;
create or replace function public.shams_admin_content(p_id uuid,p_kind text,p_payload jsonb,p_published boolean) returns uuid language plpgsql security definer set search_path='' as $$declare result uuid;begin
 if not public.shams_is_admin() then raise exception 'Admin required';end if;
 if p_kind not in ('dua','announcement') or length(coalesce(p_payload->>'title','')) not between 1 and 160 or length(coalesce(p_payload->>'body','')) not between 1 and 12000 then raise exception 'Valid title/body required';end if;
 if p_kind='dua' and p_published and (coalesce(p_payload->>'source','') !~ '^https://' or coalesce(p_payload->>'reviewed','false')<>'true') then raise exception 'Reviewed source required';end if;
 insert into public.shams_content(id,kind,payload,published,updated_by) values(coalesce(p_id,gen_random_uuid()),p_kind,p_payload,p_published,auth.uid()) on conflict(id) do update set kind=excluded.kind,payload=excluded.payload,published=excluded.published,updated_by=excluded.updated_by,updated_at=now() returning id into result;
 insert into public.shams_admin_audit(actor,action,target,details) values(auth.uid(),'content_saved',result::text,jsonb_build_object('kind',p_kind,'published',p_published));return result;end$$;
commit;

begin;
create schema if not exists shams_private;
revoke all on schema shams_private from public, anon, authenticated;
create table if not exists shams_private.admins(user_id uuid primary key references auth.users(id) on delete cascade);
create table if not exists shams_private.approved_admins(email text primary key, created_at timestamptz not null default now());
alter table shams_private.admins enable row level security;
alter table shams_private.approved_admins enable row level security;
create table if not exists public.shams_profiles(id uuid primary key references auth.users(id) on delete cascade,email text not null,display_name text not null default '' check(length(display_name)<=80),locale text not null default 'az' check(locale in ('az','tr','ru','en','ar')),disabled boolean not null default false,created_at timestamptz not null default now(),last_sign_in_at timestamptz);
create table if not exists public.shams_events(id bigint generated always as identity primary key,user_id uuid references auth.users(id) on delete set null,kind text not null,details jsonb not null default '{}',created_at timestamptz not null default now());
create index if not exists shams_events_user_date on public.shams_events(user_id,created_at desc);
create table if not exists public.shams_backups(user_id uuid primary key references auth.users(id) on delete cascade,snapshot jsonb not null check(octet_length(snapshot::text)<=1500000),revision integer not null default 1,updated_at timestamptz not null default now());
create table if not exists public.shams_content(id uuid primary key default gen_random_uuid(),kind text not null check(kind in ('dua','announcement')),payload jsonb not null check(octet_length(payload::text)<=30000),published boolean not null default false,updated_by uuid references auth.users(id) on delete set null,updated_at timestamptz not null default now());
create table if not exists public.shams_admin_audit(id bigint generated always as identity primary key,actor uuid references auth.users(id) on delete set null,action text not null,target text,details jsonb not null default '{}',created_at timestamptz not null default now());
create or replace function public.shams_is_admin() returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from shams_private.admins a join public.shams_profiles p on p.id=a.user_id where a.user_id=(select auth.uid()) and not p.disabled)$$;
create or replace function public.shams_is_active() returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from public.shams_profiles where id=(select auth.uid()) and not disabled)$$;
alter table public.shams_profiles enable row level security;
alter table public.shams_events enable row level security;
alter table public.shams_backups enable row level security;
alter table public.shams_content enable row level security;
alter table public.shams_admin_audit enable row level security;
revoke all on public.shams_profiles,public.shams_events,public.shams_backups,public.shams_content,public.shams_admin_audit from anon,authenticated;
grant select on public.shams_profiles,public.shams_events to authenticated;
grant update(display_name,locale) on public.shams_profiles to authenticated;
grant select on public.shams_backups to authenticated;
grant select on public.shams_content to anon,authenticated;
grant select on public.shams_admin_audit to authenticated;
create policy profiles_read on public.shams_profiles for select to authenticated using(id=(select auth.uid()) or (select public.shams_is_admin()));
create policy profiles_edit on public.shams_profiles for update to authenticated using(id=(select auth.uid()) and not disabled) with check(id=(select auth.uid()) and not disabled);
create policy events_read on public.shams_events for select to authenticated using(user_id=(select auth.uid()) or (select public.shams_is_admin()));
create policy backups_owner_only on public.shams_backups for select to authenticated using(user_id=(select auth.uid()) and (select public.shams_is_active()));
create policy content_read on public.shams_content for select to anon,authenticated using(published or (auth.uid() is not null and public.shams_is_admin()));
create policy audit_admin_only on public.shams_admin_audit for select to authenticated using((select public.shams_is_admin()));
create or replace function shams_private.auth_profile() returns trigger language plpgsql security definer set search_path='' as $$begin
 insert into public.shams_profiles(id,email,display_name,last_sign_in_at) values(new.id,coalesce(new.email,''),left(coalesce(new.raw_user_meta_data->>'display_name',''),80),new.last_sign_in_at) on conflict(id) do update set email=excluded.email,last_sign_in_at=excluded.last_sign_in_at;
 if tg_op='INSERT' then insert into public.shams_events(user_id,kind) values(new.id,'registered');
 elsif new.last_sign_in_at is distinct from old.last_sign_in_at then insert into public.shams_events(user_id,kind) values(new.id,'signed_in'); end if;
 if new.email_confirmed_at is not null and exists(select 1 from shams_private.approved_admins where email=lower(new.email)) then insert into shams_private.admins values(new.id) on conflict do nothing; end if;
 return new;end$$;
create trigger shams_auth_profile_insert after insert on auth.users for each row execute function shams_private.auth_profile();
create trigger shams_auth_profile_update after update of last_sign_in_at,email,email_confirmed_at on auth.users for each row execute function shams_private.auth_profile();
create or replace function public.shams_claim_admin() returns boolean language plpgsql security definer set search_path='' as $$declare u auth.users;begin
 select * into u from auth.users where id=auth.uid(); if u.email_confirmed_at is null or not exists(select 1 from shams_private.approved_admins where email=lower(u.email)) then return false;end if;
 insert into shams_private.admins values(u.id) on conflict do nothing;return true;end$$;
create or replace function public.shams_record_event(p_kind text,p_count integer default 0) returns void language plpgsql security definer set search_path='' as $$begin
 if not public.shams_is_active() then raise exception 'Account unavailable';end if;
 if p_kind not in ('signed_out','dua_added','dua_updated','dua_deleted','quiz_completed','shared','backup_saved','backup_restored') or p_count<0 or p_count>1000000 then raise exception 'Invalid activity';end if;
 insert into public.shams_events(user_id,kind,details) values(auth.uid(),p_kind,jsonb_build_object('count',p_count));end$$;
create or replace function public.shams_save_backup(p_snapshot jsonb,p_revision integer) returns integer language plpgsql security definer set search_path='' as $$declare current_revision integer;begin
 if not public.shams_is_active() then raise exception 'Account unavailable';end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,0));
 select revision into current_revision from public.shams_backups where user_id=auth.uid();
 if coalesce(current_revision,0)<>p_revision then raise exception 'Backup changed. Reload before replacing.';end if;
 insert into public.shams_backups(user_id,snapshot,revision) values(auth.uid(),p_snapshot,coalesce(current_revision,0)+1) on conflict(user_id) do update set snapshot=excluded.snapshot,revision=excluded.revision,updated_at=now();
 perform public.shams_record_event('backup_saved',0);return coalesce(current_revision,0)+1;end$$;
create or replace function public.shams_admin_overview() returns jsonb language plpgsql security definer set search_path='' as $$begin
 if not public.shams_is_admin() then raise exception 'Admin required';end if;
 return jsonb_build_object('profiles',coalesce((select jsonb_agg(x order by x.created_at desc) from (select p.*,exists(select 1 from shams_private.admins a where a.user_id=p.id) is_admin from public.shams_profiles p order by created_at desc limit 500)x),'[]'::jsonb),'events',coalesce((select jsonb_agg(x order by x.created_at desc) from (select * from public.shams_events order by created_at desc limit 200)x),'[]'::jsonb),'content',coalesce((select jsonb_agg(x order by x.updated_at desc) from public.shams_content x),'[]'::jsonb),'audit',coalesce((select jsonb_agg(x order by x.created_at desc) from (select * from public.shams_admin_audit order by created_at desc limit 100)x),'[]'::jsonb),'total_users',(select count(*) from public.shams_profiles),'disabled_users',(select count(*) from public.shams_profiles where disabled));end$$;
create or replace function public.shams_admin_user(p_id uuid,p_disabled boolean) returns void language plpgsql security definer set search_path='' as $$begin
 if not public.shams_is_admin() or p_id=auth.uid() then raise exception 'Admin required; cannot disable yourself';end if;
 update public.shams_profiles set disabled=p_disabled where id=p_id; if not found then raise exception 'User not found';end if;
 insert into public.shams_admin_audit(actor,action,target,details) values(auth.uid(),'user_status',p_id::text,jsonb_build_object('disabled',p_disabled));end$$;
create or replace function public.shams_admin_content(p_id uuid,p_kind text,p_payload jsonb,p_published boolean) returns uuid language plpgsql security definer set search_path='' as $$declare result uuid;begin
 if not public.shams_is_admin() then raise exception 'Admin required';end if;
 if p_kind not in ('dua','announcement') or length(coalesce(p_payload->>'title','')) not between 1 and 160 or length(coalesce(p_payload->>'body','')) not between 1 and 12000 then raise exception 'Valid title/body required';end if;
 if p_kind='dua' and p_published and (coalesce(p_payload->>'source','') !~ '^https://' or p_payload->>'reviewed'<>'true') then raise exception 'Reviewed source required';end if;
 insert into public.shams_content(id,kind,payload,published,updated_by) values(coalesce(p_id,gen_random_uuid()),p_kind,p_payload,p_published,auth.uid()) on conflict(id) do update set kind=excluded.kind,payload=excluded.payload,published=excluded.published,updated_by=excluded.updated_by,updated_at=now() returning id into result;
 insert into public.shams_admin_audit(actor,action,target,details) values(auth.uid(),'content_saved',result::text,jsonb_build_object('kind',p_kind,'published',p_published));return result;end$$;
revoke all on function public.shams_is_admin(),public.shams_is_active(),public.shams_claim_admin(),public.shams_record_event(text,integer),public.shams_save_backup(jsonb,integer),public.shams_admin_overview(),public.shams_admin_user(uuid,boolean),public.shams_admin_content(uuid,text,jsonb,boolean) from public,anon;
grant execute on function public.shams_is_admin(),public.shams_is_active(),public.shams_claim_admin(),public.shams_record_event(text,integer),public.shams_save_backup(jsonb,integer),public.shams_admin_overview(),public.shams_admin_user(uuid,boolean),public.shams_admin_content(uuid,text,jsonb,boolean) to authenticated;
-- anon content policy needs this boolean helper; it returns false without an auth.uid().
grant execute on function public.shams_is_admin() to anon;
revoke all on function shams_private.auth_profile() from public,anon,authenticated;
commit;
