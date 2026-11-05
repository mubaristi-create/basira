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
