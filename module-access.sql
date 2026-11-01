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
