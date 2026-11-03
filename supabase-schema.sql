-- 20261101_admin_pagination.sql
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


-- 20261101_content_id.sql
begin;
alter table public.shams_content add column if not exists public_id integer generated always as identity unique;
commit;


-- 20261101_profile_integrity.sql
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


-- 20261101_shams_accounts.sql
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


-- 20261102_module_access.sql
begin;
create table if not exists shams_private.module_policy (
 module text primary key check(module in ('collection','quiz','ramadan')),
 mode text not null check(mode in ('free','premium','closed','trial')),
 trial_until timestamptz,
 revision integer not null default 1,
 updated_at timestamptz not null default now(),
 updated_by uuid references auth.users(id) on delete set null,
 check(mode<>'trial' or trial_until is not null)
);
alter table shams_private.module_policy enable row level security;
revoke all on shams_private.module_policy from public,anon,authenticated;
-- The owner is currently testing: one global, server-timed day. Reapplying
-- this migration never restarts an existing trial or overwrites admin choices.
insert into shams_private.module_policy(module,mode,trial_until)
select m,'trial',now()+interval '1 day' from unnest(array['collection','quiz','ramadan']) m
on conflict(module) do nothing;

create or replace function public.shams_module_access() returns jsonb
language sql stable security definer set search_path='' as $$
 select jsonb_build_object('server_time',now(),'lease_seconds',90,'modules',
 coalesce((select jsonb_agg(jsonb_build_object('module',module,'mode',mode,
 'effective_mode',case when mode='trial' and trial_until<=now() then 'premium' else mode end,
 'trial_until',trial_until,'revision',revision,'updated_at',updated_at) order by module)
 from shams_private.module_policy),'[]'::jsonb))
$$;
revoke all on function public.shams_module_access() from public;
grant execute on function public.shams_module_access() to anon,authenticated;

create or replace function public.shams_admin_module(p_module text,p_mode text,p_days integer,p_revision integer) returns jsonb
language plpgsql security definer set search_path='' as $$
declare before_row shams_private.module_policy;after_row shams_private.module_policy;
begin
 if not public.shams_is_admin() then raise exception 'Admin required';end if;
 if p_module not in ('collection','quiz','ramadan') or p_mode not in ('free','premium','closed','trial') or p_module is null or p_mode is null then raise exception 'Invalid module policy';end if;
 if p_mode='trial' and (p_days is null or p_days<1 or p_days>365) then raise exception 'Trial days must be 1..365';end if;
 select * into before_row from shams_private.module_policy where module=p_module for update;
 if not found then raise exception 'Unknown module';end if;
 if p_revision is null or p_revision<>before_row.revision then raise exception 'Policy changed; refresh first';end if;
 update shams_private.module_policy set mode=p_mode,
 trial_until=case when p_mode='trial' then now()+make_interval(days=>p_days) else null end,
 revision=revision+1,updated_at=now(),updated_by=auth.uid()
 where module=p_module returning * into after_row;
 insert into public.shams_admin_audit(actor,action,target,details) values(auth.uid(),'module_policy',p_module,
 jsonb_build_object('before',jsonb_build_object('mode',before_row.mode,'trial_until',before_row.trial_until,'revision',before_row.revision),
 'after',jsonb_build_object('mode',after_row.mode,'trial_until',after_row.trial_until,'revision',after_row.revision)));
 return public.shams_module_access();
end$$;
revoke all on function public.shams_admin_module(text,text,integer,integer) from public,anon;
grant execute on function public.shams_admin_module(text,text,integer,integer) to authenticated;
notify pgrst,'reload schema';
commit;
select public.shams_module_access();


-- 20261103_store_billing.sql
begin;
create table if not exists shams_private.store_subscriptions (
 store text not null check(store in ('google','apple')), identity text not null,
 user_id uuid not null references auth.users(id) on delete cascade,
 product text not null check(product='shams_premium_yearly'), state text not null,
 expires_at timestamptz not null, environment text not null check(environment in ('Production','Sandbox')),
 renewing boolean not null default false, token_cipher text, superseded boolean not null default false, sandbox_allowed boolean not null default false,
 observed_at timestamptz not null, updated_at timestamptz not null default now(),
 primary key(store,identity)
);
alter table shams_private.store_subscriptions enable row level security;
create index if not exists store_user on shams_private.store_subscriptions(user_id);
create table if not exists shams_private.store_events(id text primary key,created_at timestamptz not null default now());
alter table shams_private.store_events enable row level security;
create table if not exists shams_private.store_audit(id bigint generated always as identity primary key,store text not null,identity text not null,user_id uuid not null,state text not null,expires_at timestamptz not null,created_at timestamptz not null default now());
alter table shams_private.store_audit enable row level security;
revoke all on shams_private.store_subscriptions,shams_private.store_events,shams_private.store_audit from public,anon,authenticated;

create or replace function public.shams_premium_status() returns jsonb language sql security definer set search_path=public,shams_private as $$
 select jsonb_build_object('premium',coalesce(max(expires_at)>now(),false),'expires_at',max(expires_at),'server_time',now())
 from shams_private.store_subscriptions where user_id=auth.uid() and public.shams_is_active()
 and not superseded and state in ('active','grace','canceled') and expires_at>now()
 and (environment='Production' or sandbox_allowed)
$$;
revoke all on function public.shams_premium_status() from public,anon;
grant execute on function public.shams_premium_status() to authenticated;

-- Only the Edge Function service role may apply an independently verified store result.
create or replace function public.shams_store_apply(p jsonb) returns jsonb language plpgsql security definer set search_path=public,shams_private as $$
declare existing shams_private.store_subscriptions; linked shams_private.store_subscriptions; uid uuid=(p->>'user_id')::uuid; observation timestamptz=(p->>'observed_at')::timestamptz;
begin
 if auth.role()<>'service_role' then raise exception 'Service role required';end if;
 if p->>'product'<>'shams_premium_yearly' or p->>'store' not in ('google','apple') or p->>'state' not in ('active','grace','canceled','pending','hold','paused','expired','revoked') or length(p->>'identity')>300 or length(p->>'identity')<3 or observation>now()+interval '1 minute' then raise exception 'Invalid store result';end if;
 perform pg_advisory_xact_lock(hashtextextended(p->>'store',0));
 if coalesce(p->>'event_id','')<>'' then
  insert into shams_private.store_events(id) values(p->>'event_id') on conflict do nothing;
  if not found then return jsonb_build_object('duplicate',true);end if;
 end if;
 select * into existing from shams_private.store_subscriptions where store=p->>'store' and identity=p->>'identity' for update;
 if found and existing.user_id<>uid then raise exception 'Purchase belongs to another account';end if;
 if existing.observed_at>observation or existing.superseded then return jsonb_build_object('ignored',true);end if;
 if coalesce(p->>'linked_identity','')<>'' then
  select * into linked from shams_private.store_subscriptions where store=p->>'store' and identity=p->>'linked_identity' for update;
  if found and linked.user_id<>uid then raise exception 'Linked purchase belongs to another account';end if;
  update shams_private.store_subscriptions set superseded=true where store=p->>'store' and identity=p->>'linked_identity';
 end if;
 insert into shams_private.store_subscriptions(store,identity,user_id,product,state,expires_at,environment,renewing,token_cipher,observed_at,sandbox_allowed)
 values(p->>'store',p->>'identity',uid,p->>'product',p->>'state',(p->>'expires_at')::timestamptz,p->>'environment',coalesce((p->>'renewing')::boolean,false),p->>'token_cipher',observation,coalesce((p->>'sandbox_allowed')::boolean,false))
 on conflict(store,identity) do update set state=excluded.state,expires_at=excluded.expires_at,environment=excluded.environment,renewing=excluded.renewing,token_cipher=coalesce(excluded.token_cipher,store_subscriptions.token_cipher),sandbox_allowed=excluded.sandbox_allowed,observed_at=excluded.observed_at,updated_at=now();
 insert into shams_private.store_audit(store,identity,user_id,state,expires_at) values(p->>'store',p->>'identity',uid,p->>'state',(p->>'expires_at')::timestamptz);
 return jsonb_build_object('saved',true);
end$$;
revoke all on function public.shams_store_apply(jsonb) from public,anon,authenticated;
grant execute on function public.shams_store_apply(jsonb) to service_role;

create or replace function public.shams_store_lookup(p_store text,p_identity text) returns jsonb language plpgsql security definer set search_path=public,shams_private as $$
begin
 if auth.role()<>'service_role' then raise exception 'Service role required';end if;
 return (select to_jsonb(s) from shams_private.store_subscriptions s where store=p_store and identity=p_identity);
end$$;
revoke all on function public.shams_store_lookup(text,text) from public,anon,authenticated;
grant execute on function public.shams_store_lookup(text,text) to service_role;
create or replace function public.shams_store_reconcile_rows() returns jsonb language plpgsql security definer set search_path=public,shams_private as $$
begin
 if auth.role()<>'service_role' then raise exception 'Service role required';end if;
 return coalesce((select jsonb_agg(to_jsonb(s)) from (select store,identity,user_id,environment,token_cipher from shams_private.store_subscriptions where not superseded order by observed_at limit 100) s),'[]'::jsonb);
end$$;
revoke all on function public.shams_store_reconcile_rows() from public,anon,authenticated;
grant execute on function public.shams_store_reconcile_rows() to service_role;
notify pgrst,'reload schema';
commit;


-- 20261103_store_refunds.sql
begin;
alter table shams_private.store_subscriptions add column if not exists latest_order text;
create table if not exists shams_private.store_voided_orders(store text not null,identity text not null,order_id text not null,created_at timestamptz not null default now(),primary key(store,identity,order_id));
alter table shams_private.store_voided_orders enable row level security;
revoke all on shams_private.store_voided_orders from public,anon,authenticated;
create or replace function public.shams_store_apply(p jsonb) returns jsonb language plpgsql security definer set search_path=public,shams_private as $$
declare existing shams_private.store_subscriptions; linked shams_private.store_subscriptions; uid uuid=(p->>'user_id')::uuid; observation timestamptz=(p->>'observed_at')::timestamptz;
begin
 if auth.role()<>'service_role' then raise exception 'Service role required';end if;
 if p->>'product'<>'shams_premium_yearly' or p->>'store' not in ('google','apple') or p->>'state' not in ('active','grace','canceled','pending','hold','paused','expired','revoked') or length(p->>'identity')>300 or length(p->>'identity')<3 or observation>now()+interval '1 minute' then raise exception 'Invalid store result';end if;
 perform pg_advisory_xact_lock(hashtextextended(p->>'store',0));
 if coalesce(p->>'event_id','')<>'' then
  insert into shams_private.store_events(id) values(p->>'event_id') on conflict do nothing;
  if not found then return jsonb_build_object('duplicate',true);end if;
 end if;
 if exists(select 1 from shams_private.store_voided_orders where store=p->>'store' and identity=p->>'identity' and order_id=p->>'latest_order') then p=p||jsonb_build_object('state','revoked');end if;
 select * into existing from shams_private.store_subscriptions where store=p->>'store' and identity=p->>'identity' for update;
 if found and existing.user_id<>uid then raise exception 'Purchase belongs to another account';end if;
 if existing.observed_at>observation or existing.superseded then return jsonb_build_object('ignored',true);end if;
 if coalesce(p->>'linked_identity','')<>'' then
  select * into linked from shams_private.store_subscriptions where store=p->>'store' and identity=p->>'linked_identity' for update;
  if found and linked.user_id<>uid then raise exception 'Linked purchase belongs to another account';end if;
  update shams_private.store_subscriptions set superseded=true where store=p->>'store' and identity=p->>'linked_identity';
 end if;
 insert into shams_private.store_subscriptions(store,identity,user_id,product,state,expires_at,environment,renewing,token_cipher,observed_at,sandbox_allowed,latest_order)
 values(p->>'store',p->>'identity',uid,p->>'product',p->>'state',(p->>'expires_at')::timestamptz,p->>'environment',coalesce((p->>'renewing')::boolean,false),p->>'token_cipher',observation,coalesce((p->>'sandbox_allowed')::boolean,false),p->>'latest_order')
 on conflict(store,identity) do update set state=excluded.state,expires_at=excluded.expires_at,environment=excluded.environment,renewing=excluded.renewing,token_cipher=coalesce(excluded.token_cipher,store_subscriptions.token_cipher),sandbox_allowed=excluded.sandbox_allowed,latest_order=excluded.latest_order,observed_at=excluded.observed_at,updated_at=now();
 insert into shams_private.store_audit(store,identity,user_id,state,expires_at) values(p->>'store',p->>'identity',uid,p->>'state',(p->>'expires_at')::timestamptz);
 return jsonb_build_object('saved',true);
end$$;
revoke all on function public.shams_store_apply(jsonb) from public,anon,authenticated;
grant execute on function public.shams_store_apply(jsonb) to service_role;
create or replace function public.shams_store_void(p_store text,p_identity text,p_order text) returns void language plpgsql security definer set search_path=public,shams_private as $$
begin
 if auth.role()<>'service_role' then raise exception 'Service role required';end if;
 if p_store<>'google' or p_order is null or length(p_order)<3 or length(p_order)>200 then raise exception 'Invalid voided order';end if;
 perform pg_advisory_xact_lock(hashtextextended(p_store,0));
 insert into shams_private.store_voided_orders(store,identity,order_id) values(p_store,p_identity,p_order) on conflict do nothing;
 if not found then return;end if;
 update shams_private.store_subscriptions set state='revoked',updated_at=now() where store=p_store and identity=p_identity and latest_order=p_order;
 if found then insert into shams_private.store_audit(store,identity,user_id,state,expires_at) select store,identity,user_id,state,expires_at from shams_private.store_subscriptions where store=p_store and identity=p_identity;end if;
end$$;
revoke all on function public.shams_store_void(text,text,text) from public,anon,authenticated;
grant execute on function public.shams_store_void(text,text,text) to service_role;
notify pgrst,'reload schema';
commit;
