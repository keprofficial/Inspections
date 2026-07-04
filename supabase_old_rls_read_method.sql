-- Restore the old RLS read method for critical inspection issues.
-- Safe to run: this file does not alter table columns or triggers.
-- It only creates SELECT policies needed by other apps using the publishable key.

alter table public.inspections enable row level security;
alter table public.inspection_issues enable row level security;
alter table public.properties enable row level security;
alter table public.services enable row level security;

drop policy if exists "inspection app read inspections" on public.inspections;
create policy "inspection app read inspections"
on public.inspections
for select
to anon, authenticated
using (true);

drop policy if exists "inspection app read critical issues" on public.inspection_issues;
create policy "inspection app read critical issues"
on public.inspection_issues
for select
to anon, authenticated
using (lower(coalesce(severity, '')) = 'critical');

drop policy if exists "inspection app read properties" on public.properties;
create policy "inspection app read properties"
on public.properties
for select
to anon, authenticated
using (true);

drop policy if exists "inspection app read active services" on public.services;
create policy "inspection app read active services"
on public.services
for select
to anon, authenticated
using (coalesce(is_active, true) = true);

-- Optional cleanup: remove the read RPC functions if they were partially created.
drop function if exists public.inspection_app_get_critical_issues(jsonb);
drop function if exists public.inspection_app_get_recent_critical_issues(jsonb);

notify pgrst, 'reload schema';

select schemaname, tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
  and tablename in ('inspections', 'inspection_issues', 'properties', 'services')
  and policyname in (
    'inspection app read inspections',
    'inspection app read critical issues',
    'inspection app read properties',
    'inspection app read active services'
  )
order by tablename, policyname;
