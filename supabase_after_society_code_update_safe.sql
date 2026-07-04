-- SAFE UPDATE AFTER SOCIETY + DB-GENERATED INSPECTION CODES
-- Run this BEFORE supabase_checklist_rebuild_fresh.sql.
-- This file does not alter inspection_issues.status or any trigger-dependent column.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'inspection-photos',
  'inspection-photos',
  true,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

alter table public.inspections
  add column if not exists inspection_type text not null default 'flat',
  add column if not exists inspection_code text,
  add column if not exists full_report_pdf_url text;

create table if not exists public.inspection_app_types (
  inspection_type text primary key,
  display_name text not null,
  code_prefix text not null,
  checklist_kind text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (inspection_type in ('flat', 'individual', 'society')),
  check (checklist_kind in ('flat', 'society'))
);

insert into public.inspection_app_types (
  inspection_type,
  display_name,
  code_prefix,
  checklist_kind,
  is_active
)
values
  ('flat', 'Flat Inspection', 'INF', 'flat', true),
  ('individual', 'Individual Home Inspection', 'INP', 'flat', true),
  ('society', 'Society Inspection', 'INS', 'society', true)
on conflict (inspection_type) do update
set
  display_name = excluded.display_name,
  code_prefix = excluded.code_prefix,
  checklist_kind = excluded.checklist_kind,
  is_active = excluded.is_active,
  updated_at = now();

create table if not exists public.inspection_code_counters (
  inspection_type text primary key references public.inspection_app_types(inspection_type),
  next_value bigint not null default 1,
  updated_at timestamptz not null default now()
);

insert into public.inspection_code_counters (inspection_type, next_value)
values
  ('flat', 1),
  ('individual', 1),
  ('society', 1)
on conflict (inspection_type) do nothing;

create or replace function public.generate_inspection_code_public(
  p_inspection_type text
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inspection_type text;
  v_prefix text;
  v_value bigint;
begin
  v_inspection_type := lower(nullif(trim(coalesce(p_inspection_type, 'flat')), ''));

  select code_prefix
  into v_prefix
  from public.inspection_app_types
  where inspection_type = v_inspection_type
    and is_active = true;

  if v_prefix is null then
    raise exception 'Invalid inspection_type %', p_inspection_type;
  end if;

  insert into public.inspection_code_counters (inspection_type, next_value)
  values (v_inspection_type, 1)
  on conflict (inspection_type) do nothing;

  update public.inspection_code_counters
  set
    next_value = next_value + 1,
    updated_at = now()
  where inspection_type = v_inspection_type
  returning next_value - 1 into v_value;

  return v_prefix || lpad(v_value::text, 3, '0');
end;
$$;

create or replace function public.start_inspection_public(
  p_property_id text,
  p_session_token text,
  p_inspector_name text,
  p_summary text,
  p_inspection_code text default null,
  p_inspection_type text default 'flat'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inspection_id uuid;
  v_now timestamptz := now();
  v_inspector public.inspection_app_users%rowtype;
  v_property_id uuid;
  v_session_token uuid;
  v_inspection_type text;
  v_inspection_code text;
begin
  if nullif(trim(coalesce(p_property_id, '')), '') is null then
    raise exception 'property_id is required';
  end if;

  if nullif(trim(coalesce(p_session_token, '')), '') is null then
    raise exception 'session_token is required';
  end if;

  v_property_id := p_property_id::uuid;
  v_session_token := p_session_token::uuid;
  v_inspection_type := lower(nullif(trim(coalesce(p_inspection_type, 'flat')), ''));

  if v_inspection_type not in ('flat', 'individual', 'society') then
    raise exception 'Invalid inspection_type %', p_inspection_type;
  end if;

  v_inspection_code := coalesce(
    nullif(trim(coalesce(p_inspection_code, '')), ''),
    public.generate_inspection_code_public(v_inspection_type)
  );

  select u.*
  into v_inspector
  from public.inspection_app_sessions s
  join public.inspection_app_users u on u.id = s.inspector_id
  where s.token = v_session_token
    and s.revoked_at is null
    and s.expires_at > now()
    and u.is_active = true
  limit 1;

  if v_inspector.id is null then
    raise exception 'Invalid or expired inspector session';
  end if;

  if not exists (
    select 1
    from public.properties
    where id = v_property_id
  ) then
    raise exception 'property_id % does not exist', v_property_id;
  end if;

  insert into public.inspections (
    property_id,
    inspector_name,
    conducted_at,
    summary,
    inspection_ref,
    inspection_type,
    inspection_code,
    next_due_at
  )
  values (
    v_property_id,
    coalesce(nullif(trim(p_inspector_name), ''), v_inspector.display_name),
    v_now,
    coalesce(p_summary, ''),
    v_inspection_code,
    v_inspection_type,
    v_inspection_code,
    v_now + interval '6 months'
  )
  returning id into v_inspection_id;

  return v_inspection_id;
end;
$$;

create or replace function public.inspection_app_start(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inspection_id uuid;
begin
  v_inspection_id := public.start_inspection_public(
    p_payload ->> 'property_id',
    p_payload ->> 'session_token',
    p_payload ->> 'inspector_name',
    p_payload ->> 'summary',
    p_payload ->> 'inspection_code',
    p_payload ->> 'inspection_type'
  );

  return (
    select jsonb_build_object(
      'inspection_id', i.id,
      'inspection_code', coalesce(i.inspection_code, i.inspection_ref),
      'inspection_type', i.inspection_type
    )
    from public.inspections i
    where i.id = v_inspection_id
  );
end;
$$;

create or replace function public.inspection_app_next_code(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_type text;
begin
  v_type := lower(nullif(trim(coalesce(p_payload ->> 'inspection_type', 'flat')), ''));
  v_code := public.generate_inspection_code_public(v_type);
  return jsonb_build_object(
    'inspection_type', v_type,
    'inspection_code', v_code
  );
end;
$$;

grant execute on function public.generate_inspection_code_public(text) to anon, authenticated;
grant execute on function public.start_inspection_public(text, text, text, text, text, text) to anon, authenticated;
grant execute on function public.inspection_app_start(jsonb) to anon, authenticated;
grant execute on function public.inspection_app_next_code(jsonb) to anon, authenticated;

notify pgrst, 'reload schema';

select * from public.inspection_app_types order by inspection_type;
