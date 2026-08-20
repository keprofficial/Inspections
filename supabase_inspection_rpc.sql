-- Run this in Supabase SQL Editor for the inspection app.
-- It keeps table RLS strict and allows only controlled writes through RPC.

create extension if not exists pgcrypto;

drop function if exists public.start_inspection_public(uuid, text, text);
drop function if exists public.submit_inspection_report_public(uuid, integer, text, jsonb);
drop function if exists public.start_inspection_public(uuid, uuid, text, text);
drop function if exists public.submit_inspection_report_public(uuid, uuid, integer, text, jsonb);
drop function if exists public.start_inspection_public(text, text, text, text);
drop function if exists public.start_inspection_public(text, text, text, text, text, text);
drop function if exists public.submit_inspection_report_public(text, text, integer, text, jsonb);
drop function if exists public.inspection_app_login(jsonb);
drop function if exists public.inspection_app_start(jsonb);
drop function if exists public.inspection_app_submit_report(jsonb);
drop function if exists public.inspection_app_next_code(jsonb);
drop function if exists public.inspection_app_get_critical_issues(jsonb);
drop function if exists public.inspection_app_get_recent_critical_issues(jsonb);

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

drop policy if exists "inspection photos public read" on storage.objects;
create policy "inspection photos public read"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'inspection-photos');

drop policy if exists "inspection photos public upload" on storage.objects;
create policy "inspection photos public upload"
on storage.objects
for insert
to anon, authenticated
with check (bucket_id = 'inspection-photos');

drop policy if exists "inspection photos public update" on storage.objects;
create policy "inspection photos public update"
on storage.objects
for update
to anon, authenticated
using (bucket_id = 'inspection-photos')
with check (bucket_id = 'inspection-photos');

create table if not exists public.inspection_app_users (
  id uuid primary key default extensions.gen_random_uuid(),
  display_name text not null,
  mobile_number text not null unique,
  password_hash text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.inspection_app_sessions (
  token uuid primary key default extensions.gen_random_uuid(),
  inspector_id uuid not null references public.inspection_app_users(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '12 hours',
  revoked_at timestamptz
);

alter table public.inspection_app_users enable row level security;
alter table public.inspection_app_sessions enable row level security;

drop policy if exists "inspection app users no direct access" on public.inspection_app_users;
create policy "inspection app users no direct access"
on public.inspection_app_users
for all
to anon, authenticated
using (false)
with check (false);

drop policy if exists "inspection app sessions no direct access" on public.inspection_app_sessions;
create policy "inspection app sessions no direct access"
on public.inspection_app_sessions
for all
to anon, authenticated
using (false)
with check (false);

alter table public.services enable row level security;

drop policy if exists "inspection app read active services" on public.services;
create policy "inspection app read active services"
on public.services
for select
to anon, authenticated
using (is_active = true);

alter table public.inspections
  add column if not exists overall_health_score integer,
  add column if not exists summary text,
  add column if not exists full_report_pdf_url text,
  add column if not exists inspection_type text not null default 'flat',
  add column if not exists inspection_code text;

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

create table if not exists public.inspection_code_counters (
  inspection_type text primary key references public.inspection_app_types(inspection_type),
  next_value bigint not null default 1,
  updated_at timestamptz not null default now()
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

insert into public.inspection_app_users (
  display_name,
  mobile_number,
  password_hash,
  is_active
)
values
  ('Demo Inspector', '9876543210', extensions.crypt('Demo@123', extensions.gen_salt('bf')), true),
  ('Asha Inspector', '9876543211', extensions.crypt('Demo@123', extensions.gen_salt('bf')), true),
  ('Ravi Inspector', '9876543212', extensions.crypt('Demo@123', extensions.gen_salt('bf')), true),
  ('Neha Inspector', '9876543213', extensions.crypt('Demo@123', extensions.gen_salt('bf')), true),
  ('Kiran Inspector', '9876543214', extensions.crypt('Demo@123', extensions.gen_salt('bf')), true)
on conflict (mobile_number) do update
set
  display_name = excluded.display_name,
  password_hash = excluded.password_hash,
  is_active = excluded.is_active,
  updated_at = now();

create or replace function public.authenticate_inspection_user(
  p_mobile_number text,
  p_password text
)
returns table (
  inspector_id uuid,
  display_name text,
  mobile_number text,
  session_token uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user public.inspection_app_users%rowtype;
  v_token uuid;
  v_mobile_number text;
begin
  v_mobile_number := regexp_replace(coalesce(p_mobile_number, ''), '[^0-9]', '', 'g');
  if v_mobile_number ~ '^91[0-9]{10}$' then
    v_mobile_number := right(v_mobile_number, 10);
  end if;

  select u.*
  into v_user
  from public.inspection_app_users as u
  where u.mobile_number = v_mobile_number
    and u.is_active = true
    and u.password_hash = extensions.crypt(coalesce(p_password, ''), u.password_hash)
  limit 1;

  if v_user.id is null then
    raise exception 'Invalid mobile number or password';
  end if;

  insert into public.inspection_app_sessions (inspector_id)
  values (v_user.id)
  returning token into v_token;

  return query
  select
    v_user.id as inspector_id,
    v_user.display_name,
    v_user.mobile_number,
    v_token as session_token;
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
  v_property_type text;
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

  select p.type
  into v_property_type
  from public.properties p
  where p.id = v_property_id;

  if v_property_type is null then
    raise exception 'property_id % does not exist', v_property_id;
  end if;

  if v_inspection_type = 'society' and v_property_type <> 'society' then
    raise exception 'Society inspection must target a society property, not %',
      v_property_type;
  end if;

  if v_inspection_type = 'flat' and v_property_type <> 'flat' then
    raise exception 'Flat inspection must target a flat property, not %',
      v_property_type;
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
    coalesce(
      v_inspection_code,
      'INSP-' || replace(extensions.gen_random_uuid()::text, '-', '')
    ),
    v_inspection_type,
    v_inspection_code,
    v_now + interval '6 months'
  )
  returning id into v_inspection_id;

  return v_inspection_id;
end;
$$;

create or replace function public.submit_inspection_report_public(
  p_inspection_id text,
  p_session_token text,
  p_overall_health_score integer,
  p_summary text,
  p_issues jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inspection_id uuid;
  v_session_token uuid;
begin
  if nullif(trim(coalesce(p_inspection_id, '')), '') is null then
    raise exception 'inspection_id is required';
  end if;

  if nullif(trim(coalesce(p_session_token, '')), '') is null then
    raise exception 'session_token is required';
  end if;

  v_inspection_id := p_inspection_id::uuid;
  v_session_token := p_session_token::uuid;

  if not exists (
    select 1
    from public.inspection_app_sessions s
    join public.inspection_app_users u on u.id = s.inspector_id
    where s.token = v_session_token
      and s.revoked_at is null
      and s.expires_at > now()
      and u.is_active = true
  ) then
    raise exception 'Invalid or expired inspector session';
  end if;

  if not exists (
    select 1
    from public.inspections
    where id = v_inspection_id
  ) then
    raise exception 'inspection_id % does not exist', v_inspection_id;
  end if;

  update public.inspections
  set
    overall_health_score = p_overall_health_score,
    summary = coalesce(p_summary, summary)
  where id = v_inspection_id;

  delete from public.inspection_issues
  where inspection_id = v_inspection_id;

  insert into public.inspection_issues (
    inspection_id,
    severity,
    category,
    description,
    photo_urls,
    status,
    linked_service_id,
    plan_covered,
    resident_approval_needed,
    service_code,
    estimated_cost,
    is_custom,
    custom_title,
    issue_ref,
    material_codes
  )
  select
    v_inspection_id,
    coalesce(nullif(issue.severity, ''), 'critical'),
    issue.category,
    coalesce(issue.description, ''),
    coalesce(issue.photo_urls, array[]::text[]),
    coalesce(nullif(issue.status, ''), 'open'),
    issue.linked_service_id,
    coalesce(issue.plan_covered, false),
    coalesce(issue.resident_approval_needed, true),
    issue.service_code,
    issue.estimated_cost,
    coalesce(issue.is_custom, false),
    issue.custom_title,
    coalesce(
      nullif(issue.issue_ref, ''),
      'ISS-' || replace(extensions.gen_random_uuid()::text, '-', '')
    ),
    coalesce(issue.material_codes, array[]::text[])
  from jsonb_to_recordset(coalesce(p_issues, '[]'::jsonb)) as issue(
    severity text,
    category text,
    description text,
    photo_urls text[],
    status text,
    linked_service_id uuid,
    plan_covered boolean,
    resident_approval_needed boolean,
    service_code text,
    estimated_cost numeric,
    is_custom boolean,
    custom_title text,
    issue_ref text,
    material_codes text[]
  );

  return v_inspection_id;
end;
$$;

revoke all on function public.authenticate_inspection_user(text, text) from public;
revoke all on function public.start_inspection_public(text, text, text, text, text, text) from public;
revoke all on function public.submit_inspection_report_public(text, text, integer, text, jsonb) from public;

grant execute on function public.authenticate_inspection_user(text, text) to anon, authenticated;
grant execute on function public.start_inspection_public(text, text, text, text, text, text) to anon, authenticated;
grant execute on function public.submit_inspection_report_public(text, text, integer, text, jsonb) to anon, authenticated;

create or replace function public.inspection_app_login(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_login record;
begin
  select *
  into v_login
  from public.authenticate_inspection_user(
    p_payload ->> 'mobile_number',
    p_payload ->> 'password'
  )
  limit 1;

  return jsonb_build_object(
    'inspector_id', v_login.inspector_id,
    'display_name', v_login.display_name,
    'mobile_number', v_login.mobile_number,
    'session_token', v_login.session_token
  );
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

create or replace function public.inspection_app_submit_report(p_payload jsonb)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inspection_id uuid;
  v_report_pdf_url text;
begin
  v_inspection_id := public.submit_inspection_report_public(
    p_payload ->> 'inspection_id',
    p_payload ->> 'session_token',
    coalesce((p_payload ->> 'overall_health_score')::integer, 0),
    p_payload ->> 'summary',
    coalesce(p_payload -> 'issues', '[]'::jsonb)
  );

  v_report_pdf_url := nullif(p_payload ->> 'report_pdf_url', '');
  if v_report_pdf_url is not null then
    update public.inspections
    set full_report_pdf_url = v_report_pdf_url
    where id = v_inspection_id;
  end if;

  return v_inspection_id::text;
end;
$$;

create or replace function public.inspection_app_get_critical_issues(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inspection_id uuid;
  v_session_token uuid;
begin
  if nullif(trim(coalesce(p_payload ->> 'inspection_id', '')), '') is null then
    raise exception 'inspection_id is required';
  end if;

  if nullif(trim(coalesce(p_payload ->> 'session_token', '')), '') is null then
    raise exception 'session_token is required';
  end if;

  v_inspection_id := (p_payload ->> 'inspection_id')::uuid;
  v_session_token := (p_payload ->> 'session_token')::uuid;

  if not exists (
    select 1
    from public.inspection_app_sessions s
    join public.inspection_app_users u on u.id = s.inspector_id
    where s.token = v_session_token
      and s.revoked_at is null
      and s.expires_at > now()
      and u.is_active = true
  ) then
    raise exception 'Invalid or expired inspector session';
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'inspection_id', i.id,
          'inspection_ref', i.inspection_ref,
          'inspection_type', i.inspection_type,
          'inspection_code', coalesce(i.inspection_code, i.inspection_ref),
          'inspection_summary', i.summary,
          'report_pdf_url', i.full_report_pdf_url,
          'overall_health_score', i.overall_health_score,
          'conducted_at', i.conducted_at,
          'inspector_name', i.inspector_name,
          'property_id', p.id,
          'society_name', coalesce(p.society_name, p.name),
          'block', p.block,
          'flat_number', coalesce(p.flat_number, p.name),
          'property_code', coalesce(p.property_code, p.kepr_id),
          'address', p.address,
          'issue_id', ii.id,
          'issue_ref', ii.issue_ref,
          'severity', ii.severity,
          'category', ii.category,
          'description', ii.description,
          'status', ii.status,
          'service_code', ii.service_code,
          'service_name', s.name,
          'photo_urls', coalesce(ii.photo_urls, array[]::text[]),
          'material_codes', coalesce(ii.material_codes, array[]::text[]),
          'resident_approval_needed', ii.resident_approval_needed,
          'plan_covered', ii.plan_covered
        )
        order by ii.issue_ref, ii.service_code
      )
      from public.inspection_issues ii
      join public.inspections i on i.id = ii.inspection_id
      join public.properties p on p.id = i.property_id
      left join public.services s on s.service_code = ii.service_code
      where ii.inspection_id = v_inspection_id
        and lower(coalesce(ii.severity, '')) = 'critical'
    ),
    '[]'::jsonb
  );
end;
$$;

create or replace function public.inspection_app_get_recent_critical_issues(p_payload jsonb default '{}'::jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_property_id uuid;
  v_service_code text;
  v_status text;
  v_limit integer;
  v_session_token uuid;
begin
  if nullif(trim(coalesce(p_payload ->> 'session_token', '')), '') is null then
    raise exception 'session_token is required';
  end if;

  v_session_token := (p_payload ->> 'session_token')::uuid;

  if not exists (
    select 1
    from public.inspection_app_sessions s
    join public.inspection_app_users u on u.id = s.inspector_id
    where s.token = v_session_token
      and s.revoked_at is null
      and s.expires_at > now()
      and u.is_active = true
  ) then
    raise exception 'Invalid or expired inspector session';
  end if;

  if nullif(trim(coalesce(p_payload ->> 'property_id', '')), '') is not null then
    v_property_id := (p_payload ->> 'property_id')::uuid;
  end if;

  v_service_code := nullif(trim(coalesce(p_payload ->> 'service_code', '')), '');
  v_status := nullif(trim(coalesce(p_payload ->> 'status', '')), '');
  v_limit := least(greatest(coalesce((p_payload ->> 'limit')::integer, 50), 1), 200);

  return coalesce(
    (
      select jsonb_agg(row_data order by sort_conducted_at desc nulls last, sort_issue_ref)
      from (
        select
          i.conducted_at as sort_conducted_at,
          ii.issue_ref as sort_issue_ref,
          jsonb_build_object(
            'inspection_id', i.id,
            'inspection_ref', i.inspection_ref,
            'inspection_type', i.inspection_type,
            'inspection_code', coalesce(i.inspection_code, i.inspection_ref),
            'inspection_summary', i.summary,
            'report_pdf_url', i.full_report_pdf_url,
            'overall_health_score', i.overall_health_score,
            'conducted_at', i.conducted_at,
            'inspector_name', i.inspector_name,
            'property_id', p.id,
            'society_name', coalesce(p.society_name, p.name),
            'block', p.block,
            'flat_number', coalesce(p.flat_number, p.name),
            'property_code', coalesce(p.property_code, p.kepr_id),
            'address', p.address,
            'issue_id', ii.id,
            'issue_ref', ii.issue_ref,
            'severity', ii.severity,
            'category', ii.category,
            'description', ii.description,
            'status', ii.status,
            'service_code', ii.service_code,
            'service_name', s.name,
            'photo_urls', coalesce(ii.photo_urls, array[]::text[]),
            'material_codes', coalesce(ii.material_codes, array[]::text[]),
            'resident_approval_needed', ii.resident_approval_needed,
            'plan_covered', ii.plan_covered
          ) as row_data
        from public.inspection_issues ii
        join public.inspections i on i.id = ii.inspection_id
        join public.properties p on p.id = i.property_id
        left join public.services s on s.service_code = ii.service_code
        where lower(coalesce(ii.severity, '')) = 'critical'
          and (v_property_id is null or i.property_id = v_property_id)
          and (v_service_code is null or ii.service_code = v_service_code)
          and (v_status is null or ii.status = v_status)
        order by i.conducted_at desc nulls last, ii.issue_ref
        limit v_limit
      ) rows
    ),
    '[]'::jsonb
  );
end;
$$;

-- Individual Home inspections do not belong to a saved flat/property row.
-- Keep their completed checklist and PDF in a dedicated report table.
create table if not exists public.individual_inspections (
  id uuid primary key default gen_random_uuid(),
  inspection_ref text not null unique,
  inspection_code text,
  inspection_type text not null default 'individual',
  inspector_id text,
  inspector_name text,
  inspector_mobile text,
  property_name text not null,
  property_owner_name text not null,
  property_owner_mobile text not null,
  report_pdf_url text not null,
  total_checks integer not null default 0,
  completed_checks integer not null default 0,
  critical_issue_count integer not null default 0,
  checklist jsonb not null default '[]'::jsonb,
  critical_issues jsonb not null default '[]'::jsonb,
  submitted_at timestamptz not null default now()
);

alter table public.individual_inspections
  add column if not exists inspection_code text,
  add column if not exists inspection_type text not null default 'individual',
  add column if not exists inspector_id text,
  add column if not exists inspector_name text,
  add column if not exists inspector_mobile text,
  add column if not exists total_checks integer not null default 0,
  add column if not exists completed_checks integer not null default 0,
  add column if not exists critical_issue_count integer not null default 0,
  add column if not exists checklist jsonb not null default '[]'::jsonb,
  add column if not exists critical_issues jsonb not null default '[]'::jsonb,
  add column if not exists submitted_at timestamptz not null default now();

create unique index if not exists individual_inspections_inspection_code_uidx
on public.individual_inspections(inspection_code)
where inspection_code is not null;

alter table public.individual_inspections enable row level security;

drop policy if exists "inspection app read individual inspections"
on public.individual_inspections;
create policy "inspection app read individual inspections"
on public.individual_inspections
for select
to anon, authenticated
using (true);

create or replace function public.inspection_app_submit_individual_inspection(
  p_payload jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session_token uuid;
  v_inspector public.inspection_app_users%rowtype;
  v_report_id uuid;
  v_inspection_ref text;
  v_report_url text;
begin
  v_inspection_ref := nullif(trim(coalesce(p_payload ->> 'inspection_ref', '')), '');
  v_report_url := nullif(trim(coalesce(p_payload ->> 'report_pdf_url', '')), '');

  if v_inspection_ref is null then
    raise exception 'inspection_ref is required';
  end if;
  if nullif(trim(coalesce(p_payload ->> 'session_token', '')), '') is null then
    raise exception 'session_token is required';
  end if;
  if nullif(trim(coalesce(p_payload ->> 'property_name', '')), '') is null then
    raise exception 'property_name is required';
  end if;
  if nullif(trim(coalesce(p_payload ->> 'property_owner_name', '')), '') is null then
    raise exception 'property_owner_name is required';
  end if;
  if length(regexp_replace(coalesce(p_payload ->> 'property_owner_mobile', ''), '[^0-9]', '', 'g')) < 8 then
    raise exception 'A valid property_owner_mobile is required';
  end if;
  if v_report_url is null
     or v_report_url not like 'https://egalrsutygdvdmjkvduh.supabase.co/storage/v1/object/public/%' then
    raise exception 'A valid public report_pdf_url is required';
  end if;

  v_session_token := (p_payload ->> 'session_token')::uuid;
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

  insert into public.individual_inspections (
    inspection_ref, inspection_code, inspection_type, inspector_id,
    inspector_name, inspector_mobile, property_name, property_owner_name,
    property_owner_mobile, report_pdf_url, total_checks, completed_checks,
    critical_issue_count, checklist, critical_issues, submitted_at
  ) values (
    v_inspection_ref,
    nullif(trim(coalesce(p_payload ->> 'inspection_code', '')), ''),
    'individual',
    v_inspector.id::text,
    v_inspector.display_name,
    v_inspector.mobile_number,
    trim(p_payload ->> 'property_name'),
    trim(p_payload ->> 'property_owner_name'),
    trim(p_payload ->> 'property_owner_mobile'),
    v_report_url,
    greatest(coalesce((p_payload ->> 'total_checks')::integer, 0), 0),
    greatest(coalesce((p_payload ->> 'completed_checks')::integer, 0), 0),
    greatest(coalesce((p_payload ->> 'critical_issue_count')::integer, 0), 0),
    coalesce(p_payload -> 'checklist', '[]'::jsonb),
    coalesce(p_payload -> 'critical_issues', '[]'::jsonb),
    now()
  )
  on conflict (inspection_ref) do update
  set
    inspection_code = excluded.inspection_code,
    inspector_id = excluded.inspector_id,
    inspector_name = excluded.inspector_name,
    inspector_mobile = excluded.inspector_mobile,
    property_name = excluded.property_name,
    property_owner_name = excluded.property_owner_name,
    property_owner_mobile = excluded.property_owner_mobile,
    report_pdf_url = excluded.report_pdf_url,
    total_checks = excluded.total_checks,
    completed_checks = excluded.completed_checks,
    critical_issue_count = excluded.critical_issue_count,
    checklist = excluded.checklist,
    critical_issues = excluded.critical_issues,
    submitted_at = now()
  returning id into v_report_id;

  return v_report_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Society checklist template icon names
-- Ensures every society area template has a recognised icon_name so the
-- inspection app renders a proper coloured gradient icon instead of the
-- generic fallback.  Uses ILIKE so it is safe to re-run at any time.
-- ---------------------------------------------------------------------------

alter table public.inspection_checklist_templates
  add column if not exists icon_name text;

update public.inspection_checklist_templates
set icon_name = 'lobby'
where inspection_kind = 'society'
  and (name ilike '%lobby%' or name ilike '%entrance%' or name ilike '%reception%');

update public.inspection_checklist_templates
set icon_name = 'local_parking'
where inspection_kind = 'society'
  and (name ilike '%parking%' or name ilike '%car park%' or name ilike '%vehicle%');

update public.inspection_checklist_templates
set icon_name = 'garden'
where inspection_kind = 'society'
  and (name ilike '%garden%' or name ilike '%landscape%' or name ilike '%lawn%'
       or name ilike '%outdoor%' or name ilike '%exterior%' or name ilike '%park%');

update public.inspection_checklist_templates
set icon_name = 'pool'
where inspection_kind = 'society'
  and (name ilike '%pool%' or name ilike '%swimming%');

update public.inspection_checklist_templates
set icon_name = 'fitness_center'
where inspection_kind = 'society'
  and (name ilike '%gym%' or name ilike '%fitness%' or name ilike '%gymnasium%'
       or name ilike '%sport%');

update public.inspection_checklist_templates
set icon_name = 'clubhouse'
where inspection_kind = 'society'
  and (name ilike '%clubhouse%' or name ilike '%club house%'
       or name ilike '%community hall%' or name ilike '%banquet%'
       or name ilike '%event hall%' or name ilike '%meeting room%'
       or name ilike '%conference%');

update public.inspection_checklist_templates
set icon_name = 'security'
where inspection_kind = 'society'
  and (name ilike '%security%' or name ilike '%guard%' or name ilike '%cctv%'
       or name ilike '%surveillance%' or name ilike '%watch%');

update public.inspection_checklist_templates
set icon_name = 'fire_extinguisher'
where inspection_kind = 'society'
  and (name ilike '%fire%');

update public.inspection_checklist_templates
set icon_name = 'electrical_services'
where inspection_kind = 'society'
  and (name ilike '%electrical%' or name ilike '%electric room%'
       or name ilike '%dg room%' or name ilike '%generator%'
       or name ilike '%power room%' or name ilike '%transformer%'
       or name ilike '%wiring%');

update public.inspection_checklist_templates
set icon_name = 'pump_room'
where inspection_kind = 'society'
  and (name ilike '%pump%' or name ilike '%sump%' or name ilike '%water tank%'
       or name ilike '%overhead tank%' or name ilike '%plumbing%'
       or name ilike '%water supply%' or name ilike '%drainage%');

update public.inspection_checklist_templates
set icon_name = 'staircase'
where inspection_kind = 'society'
  and (name ilike '%stair%');

update public.inspection_checklist_templates
set icon_name = 'elevator'
where inspection_kind = 'society'
  and (name ilike '%elevator%' or name ilike '%lift%');

update public.inspection_checklist_templates
set icon_name = 'rooftop'
where inspection_kind = 'society'
  and (name ilike '%terrace%' or name ilike '%rooftop%' or name ilike '%roof%'
       or name ilike '%ceiling%');

update public.inspection_checklist_templates
set icon_name = 'society_office'
where inspection_kind = 'society'
  and (name ilike '%office%' or name ilike '%admin%' or name ilike '%management%'
       or name ilike '%secretary%');

update public.inspection_checklist_templates
set icon_name = 'corridor'
where inspection_kind = 'society'
  and (name ilike '%corridor%' or name ilike '%passage%' or name ilike '%walkway%'
       or name ilike '%pathway%');

update public.inspection_checklist_templates
set icon_name = 'apartment'
where inspection_kind = 'society'
  and (name ilike '%building%' or name ilike '%block%' or name ilike '%tower%'
       or name ilike '%structure%' or name ilike '%facade%' or name ilike '%external%');

-- Fall back for any remaining society templates that still have no icon_name
update public.inspection_checklist_templates
set icon_name = 'apartment'
where inspection_kind = 'society'
  and (icon_name is null or icon_name = '');

-- ---------------------------------------------------------------------------

revoke all on function public.inspection_app_login(jsonb) from public;
revoke all on function public.inspection_app_start(jsonb) from public;
revoke all on function public.inspection_app_submit_report(jsonb) from public;
revoke all on function public.inspection_app_next_code(jsonb) from public;
revoke all on function public.inspection_app_get_critical_issues(jsonb) from public;
revoke all on function public.inspection_app_get_recent_critical_issues(jsonb) from public;
revoke all on function public.inspection_app_submit_individual_inspection(jsonb) from public;

grant execute on function public.inspection_app_login(jsonb) to anon, authenticated;
grant execute on function public.inspection_app_start(jsonb) to anon, authenticated;
grant execute on function public.inspection_app_submit_report(jsonb) to anon, authenticated;
grant execute on function public.inspection_app_next_code(jsonb) to anon, authenticated;
grant execute on function public.inspection_app_get_critical_issues(jsonb) to anon, authenticated;
grant execute on function public.inspection_app_get_recent_critical_issues(jsonb) to anon, authenticated;
grant execute on function public.inspection_app_submit_individual_inspection(jsonb) to anon, authenticated;

notify pgrst, 'reload schema';

select proname, pg_get_function_identity_arguments(oid) as arguments
from pg_proc
where pronamespace = 'public'::regnamespace
and proname in (
  'inspection_app_login',
  'inspection_app_start',
  'inspection_app_submit_report',
  'inspection_app_next_code',
  'inspection_app_get_critical_issues',
  'inspection_app_get_recent_critical_issues'
  ,'inspection_app_submit_individual_inspection'
)
order by proname;
