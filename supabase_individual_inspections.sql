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
  add column if not exists inspection_type text not null default 'individual';

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

notify pgrst, 'reload schema';

select schemaname, tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
  and tablename = 'individual_inspections'
order by policyname;
