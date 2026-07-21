-- Optional backend draft persistence for the KEPR Inspection app.
-- Run once in Supabase SQL Editor after the main inspection RPC setup.
-- This does not alter existing inspection/report tables.

create table if not exists public.inspection_drafts (
  inspection_id uuid primary key,
  inspector_id text,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.inspection_drafts enable row level security;

drop policy if exists "inspection app draft read" on public.inspection_drafts;
drop policy if exists "inspection app draft write" on public.inspection_drafts;
-- No public table policy is created. The app reads/writes drafts only through
-- the security-definer RPC functions below, keeping direct table access closed.

create or replace function public.inspection_app_save_draft(p_payload jsonb)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inspection_id uuid;
  v_session_token uuid;
  v_inspector_id text;
begin
  v_inspection_id := nullif(p_payload->>'inspection_id', '')::uuid;
  v_session_token := nullif(p_payload->>'session_token', '')::uuid;
  v_inspector_id := nullif(p_payload->>'inspector_id', '');

  if v_inspection_id is null then
    raise exception 'inspection_id is required';
  end if;

  if v_session_token is null then
    raise exception 'session_token is required';
  end if;

  select s.inspector_id::text
  into v_inspector_id
  from public.inspection_app_sessions s
  join public.inspection_app_users u on u.id = s.inspector_id
  where s.token = v_session_token
    and s.expires_at > now()
    and coalesce(u.is_active, true) = true;

  if v_inspector_id is null then
    raise exception 'invalid inspection session';
  end if;

  insert into public.inspection_drafts (
    inspection_id,
    inspector_id,
    payload,
    updated_at
  ) values (
    v_inspection_id,
    v_inspector_id,
    jsonb_build_object('areas', coalesce(p_payload->'areas', '[]'::jsonb)),
    now()
  )
  on conflict (inspection_id) do update
  set inspector_id = excluded.inspector_id,
      payload = excluded.payload,
      updated_at = now();

  return true;
end;
$$;

create or replace function public.inspection_app_load_draft(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inspection_id uuid;
  v_session_token uuid;
  v_inspector_id text;
  v_payload jsonb;
begin
  v_inspection_id := nullif(p_payload->>'inspection_id', '')::uuid;
  v_session_token := nullif(p_payload->>'session_token', '')::uuid;

  if v_inspection_id is null then
    return null;
  end if;

  if v_session_token is null then
    raise exception 'session_token is required';
  end if;

  select s.inspector_id::text
  into v_inspector_id
  from public.inspection_app_sessions s
  join public.inspection_app_users u on u.id = s.inspector_id
  where s.token = v_session_token
    and s.expires_at > now()
    and coalesce(u.is_active, true) = true;

  if v_inspector_id is null then
    raise exception 'invalid inspection session';
  end if;

  select d.payload
  into v_payload
  from public.inspection_drafts d
  where d.inspection_id = v_inspection_id
    and d.inspector_id = v_inspector_id;

  return v_payload;
end;
$$;
