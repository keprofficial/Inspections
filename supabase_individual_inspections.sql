-- Individual / stranger property inspection storage.
-- Safe to run multiple times. This creates one separate table and RLS policies
-- for inspection-app inserts/reads. It does not alter existing inspection tables.

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

drop policy if exists "inspection app insert individual inspections"
on public.individual_inspections;

create policy "inspection app insert individual inspections"
on public.individual_inspections
for insert
to anon, authenticated
with check (
  length(trim(property_name)) > 0
  and length(trim(property_owner_name)) > 0
  and length(trim(property_owner_mobile)) >= 8
  and report_pdf_url like 'https://egalrsutygdvdmjkvduh.supabase.co/storage/v1/object/public/%'
);

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
    inspection_ref,
    inspection_code,
    inspection_type,
    inspector_id,
    inspector_name,
    inspector_mobile,
    property_name,
    property_owner_name,
    property_owner_mobile,
    report_pdf_url,
    total_checks,
    completed_checks,
    critical_issue_count,
    checklist,
    critical_issues,
    submitted_at
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

revoke all on function public.inspection_app_submit_individual_inspection(jsonb)
from public;
grant execute on function public.inspection_app_submit_individual_inspection(jsonb)
to anon, authenticated;

notify pgrst, 'reload schema';

select schemaname, tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
  and tablename = 'individual_inspections'
order by policyname;
