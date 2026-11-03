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
