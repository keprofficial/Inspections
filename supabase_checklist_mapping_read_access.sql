-- Read access for DB-driven inspection type -> checklist mapping.
-- Run this if the app says checklist mapping/checklist is missing after setup.

alter table public.inspection_app_types enable row level security;
alter table public.inspection_checklist_templates enable row level security;
alter table public.inspection_checklist_items enable row level security;

drop policy if exists "inspection app read inspection types"
on public.inspection_app_types;

create policy "inspection app read inspection types"
on public.inspection_app_types
for select
to anon, authenticated
using (is_active = true);

drop policy if exists "inspection app read checklist templates"
on public.inspection_checklist_templates;

create policy "inspection app read checklist templates"
on public.inspection_checklist_templates
for select
to anon, authenticated
using (is_active = true);

drop policy if exists "inspection app read checklist items"
on public.inspection_checklist_items;

create policy "inspection app read checklist items"
on public.inspection_checklist_items
for select
to anon, authenticated
using (is_active = true);

grant select on public.inspection_app_types to anon, authenticated;
grant select on public.inspection_checklist_templates to anon, authenticated;
grant select on public.inspection_checklist_items to anon, authenticated;

notify pgrst, 'reload schema';

select * from public.inspection_app_types order by inspection_type;

select inspection_kind, count(*) as templates
from public.inspection_checklist_templates
where is_active = true
group by inspection_kind
order by inspection_kind;

select count(*) as checklist_items
from public.inspection_checklist_items
where is_active = true;
