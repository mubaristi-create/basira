begin;
alter table shams_private.quiz_bank add column if not exists payload jsonb;
alter table shams_private.quiz_bank add column if not exists legacy boolean not null default true;
alter table shams_private.quiz_rounds add column if not exists answer_keys integer[];
create table if not exists shams_private.quiz_history(user_id uuid not null references auth.users(id) on delete cascade,question_id text not null references shams_private.quiz_bank(id),shown_at timestamptz not null,answered_at timestamptz,selected_id text,primary key(user_id,question_id));
create table if not exists shams_private.quiz_events(user_id uuid not null references auth.users(id) on delete cascade,event_id text not null check(length(event_id)<=250),created_at timestamptz not null default now(),primary key(user_id,event_id));
create table if not exists shams_private.quiz_reports(user_id uuid not null references auth.users(id) on delete cascade,id text not null check(length(id)<=160),question_id text not null references shams_private.quiz_bank(id),language text not null check(language in ('az','tr','ru','en','ar')),note text not null check(length(note) between 1 and 1000),resolved boolean not null default false,created_at timestamptz not null default now(),primary key(user_id,id));
alter table shams_private.quiz_history enable row level security;
alter table shams_private.quiz_events enable row level security;
alter table shams_private.quiz_reports enable row level security;
revoke all on shams_private.quiz_history,shams_private.quiz_events,shams_private.quiz_reports from public,anon,authenticated;
-- Historical ranked rounds are preserved and contribute to the unseen priority.
insert into shams_private.quiz_history(user_id,question_id,shown_at,answered_at)
 select r.user_id,q.id,max(r.started_at),max(r.finished_at) from shams_private.quiz_rounds r cross join lateral unnest(r.questions) q(id) join shams_private.quiz_bank b on b.id=q.id group by r.user_id,q.id
 on conflict(user_id,question_id) do nothing;
create or replace function public.shams_quiz_catalog(p_offset integer default 0) returns jsonb language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(t.payload order by t.id),'[]'::jsonb) from (select id,payload from shams_private.quiz_bank where payload->'active'='true'::jsonb and payload->'reviewed'='true'::jsonb order by id limit 250 offset greatest(0,least(p_offset,5000)))t
$$;
create or replace function public.shams_quiz_sync(p_owner uuid,p_events jsonb default '[]',p_reports jsonb default '[]') returns jsonb language plpgsql security definer set search_path='' as $$
declare e jsonb; q shams_private.quiz_bank; shown timestamptz; answered timestamptz; a text[]:='{}';r text[]:='{}';hist jsonb;
begin
 if not public.shams_is_active() or p_owner is distinct from auth.uid() then raise exception 'Own account required';end if;
 if jsonb_typeof(p_events)<>'array' or jsonb_array_length(p_events)>100 or jsonb_typeof(p_reports)<>'array' or jsonb_array_length(p_reports)>20 then raise exception 'Invalid batch';end if;
 perform pg_advisory_xact_lock(hashtextextended(p_owner::text,208));
 for e in select value from jsonb_array_elements(p_events) loop
  select * into q from shams_private.quiz_bank where id=e->>'question_id';
  if not found or length(e->>'event_id') not between 1 and 250 then raise exception 'Invalid history event';end if;
  if e->>'selected_id' is not null and not (coalesce(q.payload->'option_ids','[]') ? (e->>'selected_id')) then raise exception 'Unknown answer identifier';end if;
  shown:=least(now(),to_timestamp(greatest(0,(e->>'shown_at')::numeric)/1000));
  answered:=case when coalesce((e->>'answered_at')::numeric,0)>0 then least(now(),to_timestamp((e->>'answered_at')::numeric/1000)) end;
  insert into shams_private.quiz_events(user_id,event_id) values(p_owner,e->>'event_id') on conflict do nothing;
  if found then
   insert into shams_private.quiz_history(user_id,question_id,shown_at,answered_at,selected_id) values(p_owner,q.id,shown,answered,e->>'selected_id')
   on conflict(user_id,question_id) do update set shown_at=greatest(shams_private.quiz_history.shown_at,excluded.shown_at),answered_at=greatest(shams_private.quiz_history.answered_at,excluded.answered_at),selected_id=case when excluded.answered_at>=coalesce(shams_private.quiz_history.answered_at,'epoch'::timestamptz) then coalesce(excluded.selected_id,shams_private.quiz_history.selected_id) else shams_private.quiz_history.selected_id end;
  end if;a:=array_append(a,e->>'event_id');
 end loop;
 for e in select value from jsonb_array_elements(p_reports) loop
  if length(e->>'note') not between 1 and 1000 or length(e->>'id') not between 1 and 160 then raise exception 'Invalid report';end if;
  if (select count(*) from shams_private.quiz_reports where user_id=p_owner and created_at>now()-interval '1 hour')>=20 and not exists(select 1 from shams_private.quiz_reports where user_id=p_owner and id=e->>'id') then raise exception 'Report limit';end if;
  insert into shams_private.quiz_reports(user_id,id,question_id,language,note) values(p_owner,e->>'id',e->>'question_id',e->>'language',e->>'note') on conflict do nothing;r:=array_append(r,e->>'id');
 end loop;
 select coalesce(jsonb_object_agg(question_id,jsonb_build_object('shownAt',extract(epoch from shown_at)*1000,'answeredAt',coalesce(extract(epoch from answered_at)*1000,0),'selectedId',selected_id)),'{}') into hist from shams_private.quiz_history where user_id=p_owner;
 return jsonb_build_object('accepted',a,'reported',r,'history',hist);
end$$;
create or replace function public.shams_quiz_start_v2(p_owner uuid,p_category text,p_level integer,p_language text) returns jsonb language plpgsql security definer set search_path='' as $$
declare qs text[];keys integer[];rid uuid;last_qs text[];
begin
 if not public.shams_is_active() or p_owner is distinct from auth.uid() then raise exception 'Own account required';end if;
 if not exists(select 1 from shams_private.module_policy where module='quiz' and mode<>'closed' and (mode='free' or(mode='trial' and trial_until>now())or coalesce((public.shams_premium_status()->>'premium')::boolean,false))) then raise exception 'Quiz unavailable';end if;
 if not exists(select 1 from shams_private.leader_members where user_id=p_owner and visible) then return null;end if;
 if p_level not between 1 and 3 or p_category not in('all','quran','prophets','history','prayer','ramadan','basics','hadith','general') or p_language not in('az','tr','ru','en','ar') then raise exception 'Invalid quiz settings';end if;
 perform pg_advisory_xact_lock(hashtextextended(p_owner::text,17));
 if(select count(*) from shams_private.quiz_rounds where user_id=p_owner and started_at>=(date_trunc('day',now() at time zone 'UTC') at time zone 'UTC'))>=10 then raise exception 'Daily ranked round limit reached';end if;
 with eligible as(
 select b.id,b.correct,coalesce(b.payload->>'concept_id',b.id) concept,b.payload->>'topic' topic,coalesce((b.payload->>'tier')::integer,least(b.difficulty,3)) tier,h.shown_at,random() tie
 from shams_private.quiz_bank b left join shams_private.quiz_history h on h.user_id=p_owner and h.question_id=b.id
 where b.payload->'active'='true'::jsonb and b.payload->'reviewed'='true'::jsonb and(p_category='all' or b.payload->>'topic'=p_category) and length(b.payload->'question'->>p_language)>0 and not exists(select 1 from jsonb_array_elements(b.payload->'options') o where coalesce(o->>p_language,'')='')
 ),dedup as(select distinct on(concept)* from eligible order by concept,shown_at nulls first,tie),balanced as(
 select *,row_number() over(partition by topic order by shown_at nulls first,abs(tier-p_level),tie) cat_n from dedup
 ),chosen as(select * from balanced order by(shown_at is not null),case when shown_at is null then cat_n else 0 end,shown_at nulls first,abs(tier-p_level),tie limit 10)
 select array_agg(id order by(shown_at is not null),tie),array_agg(correct order by(shown_at is not null),tie) into qs,keys from chosen;
 if coalesce(cardinality(qs),0)<10 then return null;end if;
 select questions into last_qs from shams_private.quiz_rounds where user_id=p_owner order by started_at desc limit 1;
 if qs=last_qs then qs:=qs[2:10]||qs[1:1];keys:=keys[2:10]||keys[1:1];end if;
 insert into shams_private.quiz_rounds(user_id,questions,answer_keys)values(p_owner,qs,keys)returning id into rid;
 return jsonb_build_object('id',rid,'questions',qs);
end$$;
-- Keep the old client on its bundled legacy bank; it cannot render newly imported IDs.
create or replace function public.shams_quiz_start(p_category text,p_level integer) returns jsonb language plpgsql security definer set search_path='' as $$declare qs text[];rid uuid;begin
 if not public.shams_is_active()then raise exception 'Sign in required';end if;
 if not exists(select 1 from shams_private.module_policy where module='quiz' and mode<>'closed' and(mode='free'or(mode='trial'and trial_until>now())or coalesce((public.shams_premium_status()->>'premium')::boolean,false)))then raise exception 'Quiz unavailable';end if;
 if not exists(select 1 from shams_private.leader_members where user_id=auth.uid()and visible)then return null;end if;
 if p_level not between 1 and 4 or p_category not in('all','quran','prophets','history','prayer','ramadan','culture','names','general')then raise exception 'Invalid quiz settings';end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,17));
 if(select count(*)from shams_private.quiz_rounds where user_id=auth.uid()and started_at>=(date_trunc('day',now()at time zone'UTC')at time zone'UTC'))>=10 then raise exception 'Daily ranked round limit reached';end if;
 select array_agg(t.id order by random())into qs from(select id from shams_private.quiz_bank where legacy and payload->'active'='true'::jsonb and payload->'reviewed'='true'::jsonb and(p_category='all'or category=p_category)order by abs(difficulty-p_level),random()limit 10)t;
 if cardinality(qs)<>10 then return null;end if;
 insert into shams_private.quiz_rounds(user_id,questions,answer_keys)values(auth.uid(),qs,array(select b.correct from unnest(qs)with ordinality x(id,n)join shams_private.quiz_bank b on b.id=x.id order by x.n))returning id into rid;return jsonb_build_object('id',rid,'questions',qs);
end$$;
create or replace function public.shams_quiz_finish(p_round uuid,p_answers integer[])returns jsonb language plpgsql security definer set search_path='' as $$
declare r shams_private.quiz_rounds;credit integer:=0;n integer;expected integer;d date:=(now()at time zone'UTC')::date;begin
 if not public.shams_is_active()then raise exception 'Sign in required';end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,17));select * into r from shams_private.quiz_rounds where id=p_round and user_id=auth.uid()for update;
 if not found then raise exception 'Round not found';end if;if r.finished_at is not null then return jsonb_build_object('awarded',r.awarded,'replayed',true);end if;
 if p_answers is null or r.started_at<now()-interval'24 hours'or cardinality(p_answers)<>cardinality(r.questions)or array_lower(p_answers,1)<>1 or exists(select 1 from unnest(p_answers)a where a is null or a not between 0 and 3)then raise exception 'Invalid or expired round';end if;
 for n in 1..cardinality(r.questions)loop
  select coalesce(r.answer_keys[n],b.correct)into expected from shams_private.quiz_bank b where b.id=r.questions[n];
  if expected=p_answers[n]then insert into shams_private.quiz_credits(user_id,question_id,day)values(auth.uid(),r.questions[n],d)on conflict do nothing;if found then credit:=credit+10;end if;end if;
 end loop;
 update shams_private.quiz_rounds set finished_at=now(),awarded=credit where id=p_round;
 insert into public.shams_events(user_id,kind,details)values(auth.uid(),'ranked_quiz_completed',jsonb_build_object('points',credit));return jsonb_build_object('awarded',credit,'replayed',false);
end$$;
create or replace function public.shams_quiz_import(p_questions jsonb)returns integer language plpgsql security definer set search_path='' as $$
declare q jsonb;l text;other shams_private.quiz_bank;n integer:=0;begin
 if not public.shams_is_admin()then raise exception 'Admin required';end if;
 if jsonb_typeof(p_questions)<>'array'or jsonb_array_length(p_questions)not between 1 and 5000 then raise exception '1-5000 questions required';end if;
 perform pg_advisory_xact_lock(2082026);
 for q in select value from jsonb_array_elements(p_questions)loop
  if jsonb_typeof(q)is distinct from'object'or jsonb_typeof(q->'options')is distinct from'array'or jsonb_typeof(q->'option_ids')is distinct from'array'or jsonb_typeof(q->'active')is distinct from'boolean'or jsonb_typeof(q->'reviewed')is distinct from'boolean'or q->>'id'is null or q->>'topic'is null or q->>'difficulty'is null or q->>'tier'is null then raise exception 'Required fields missing';end if;
  if not(q->>'id'~'^[-a-zA-Z0-9_]{1,100}$')or q->>'topic'not in('quran','prophets','history','prayer','ramadan','basics','hadith','general')or(q->>'difficulty')::integer not between 1 and 4 or(q->>'tier')::integer not between 1 and 3 then raise exception 'Invalid metadata';end if;
  if jsonb_array_length(q->'options')<>4 or jsonb_array_length(q->'option_ids')<>4 or(select count(distinct value)from jsonb_array_elements_text(q->'option_ids'))<>4 or(q->>'correct')::integer not between 0 and 3 or(q->'option_ids'->>((q->>'correct')::integer))is distinct from(q->>'correct_option_id')then raise exception 'Invalid answer key';end if;
  if length(coalesce(q->>'source_reference',''))=0 or coalesce(q->>'source_url','')!~'^https://[^[:space:]]+$'then raise exception 'Source required';end if;
  foreach l in array array['az','tr','ru','en','ar']loop
   if length(coalesce(q->'question'->>l,''))=0 or length(coalesce(q->'explanation'->>l,''))=0 or exists(select 1 from jsonb_array_elements(q->'options')o where length(coalesce(o->>l,''))=0)or(select count(distinct lower(btrim(o->>l)))from jsonb_array_elements(q->'options')o)<>4 then raise exception 'Incomplete/duplicate translation';end if;
   if q->'active'='true'::jsonb and q->'translation_review'->>l is distinct from'true'then raise exception 'Language approval required';end if;
   if exists(select 1 from shams_private.quiz_bank b where b.id<>q->>'id'and lower(btrim(b.payload->'question'->>l))=lower(btrim(q->'question'->>l)))then raise exception 'Duplicate question text';end if;
  end loop;
  if q->'active'='true'::jsonb and(q->'reviewed'is distinct from'true'::jsonb or q->>'review_status'is distinct from'approved'or q->'review'->'source_checked'is distinct from'true'::jsonb or length(coalesce(q->'review'->>'reviewer',''))<2 or coalesce(q->'review'->>'date','')!~'^\d{4}-\d{2}-\d{2}'or(q->'controversial'='true'::jsonb and length(coalesce(q->'review'->>'resolution',''))=0))then raise exception 'Independent editorial approval required';end if;
  if exists(select 1 from shams_private.quiz_bank b where b.id<>q->>'id'and b.payload->>'source_reference'=q->>'source_reference'and lower(b.payload->'options'->b.correct->>'en')=lower(q->'options'->((q->>'correct')::integer)->>'en'))then raise exception 'Same source/answer needs editorial comparison';end if;
  if exists(select 1 from shams_private.quiz_bank b where b.id=q->>'id'and b.payload is not null and b.payload->'option_ids'is distinct from q->'option_ids')then raise exception 'Option identifiers are immutable; create a new question ID';end if;
  if exists(select 1 from shams_private.quiz_bank b where b.id<>q->>'id'and coalesce(b.payload->>'concept_id',b.id)=coalesce(q->>'concept_id',q->>'id'))then raise exception 'Duplicate concept';end if;
  if exists(select 1 from jsonb_array_elements_text(q->'option_ids')i where i!~'^[-a-zA-Z0-9_:]{1,140}$')then raise exception 'Invalid option identifiers';end if;
  insert into shams_private.quiz_bank(id,category,difficulty,correct,payload,legacy)values(q->>'id',q->>'topic',(q->>'difficulty')::integer,(q->>'correct')::integer,q,false)
  on conflict(id)do update set category=excluded.category,difficulty=excluded.difficulty,correct=excluded.correct,payload=excluded.payload;
  n:=n+1;
 end loop;
 if(select count(*)from shams_private.quiz_bank)>5000 then raise exception 'Catalog capacity: 5000';end if;
 insert into public.shams_admin_audit(actor,action,target,details)values(auth.uid(),'quiz_import','quiz_bank',jsonb_build_object('count',n));return n;
end$$;
create or replace function public.shams_quiz_reports()returns jsonb language plpgsql stable security definer set search_path='' as $$begin
 if not public.shams_is_admin()then raise exception 'Admin required';end if;return(select coalesce(jsonb_agg(to_jsonb(t)),'[]')from(select id,user_id,question_id,language,note,created_at from shams_private.quiz_reports where not resolved order by created_at desc limit 200)t);end$$;
create or replace function public.shams_quiz_report_resolve(p_id text)returns void language plpgsql security definer set search_path='' as $$begin
 if not public.shams_is_admin()then raise exception 'Admin required';end if;update shams_private.quiz_reports set resolved=true where id=p_id;insert into public.shams_admin_audit(actor,action,target)values(auth.uid(),'quiz_report_resolved',p_id);end$$;
revoke all on function public.shams_quiz_catalog(integer),public.shams_quiz_sync(uuid,jsonb,jsonb),public.shams_quiz_start_v2(uuid,text,integer,text),public.shams_quiz_import(jsonb),public.shams_quiz_reports(),public.shams_quiz_report_resolve(text)from public,anon,authenticated;
grant execute on function public.shams_quiz_catalog(integer)to anon,authenticated;
grant execute on function public.shams_quiz_sync(uuid,jsonb,jsonb),public.shams_quiz_start_v2(uuid,text,integer,text),public.shams_quiz_import(jsonb),public.shams_quiz_reports(),public.shams_quiz_report_resolve(text)to authenticated;
-- Catalog payload seed is appended by prepare-quiz.cjs before COMMIT.
commit;
