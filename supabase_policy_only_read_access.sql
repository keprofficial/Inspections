-- Policy-only read access restore.
-- No ALTER TABLE, no ALTER COLUMN, no function changes, no trigger changes.

select 'POLICY_ONLY_READ_ACCESS_V1' as marker;

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
