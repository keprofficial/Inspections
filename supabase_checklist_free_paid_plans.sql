-- KEPR checklist plan mapping.
-- Run after supabase_checklist_rebuild_fresh.sql.
-- This keeps the existing paid/full checklist intact and adds DB-driven
-- filtering for free flat and free society inspections.

begin;

create table if not exists public.inspection_checklist_plans (
  inspection_kind text not null check (inspection_kind in ('flat', 'society')),
  plan_key text not null check (plan_key in ('free', 'paid')),
  display_name text not null,
  description text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (inspection_kind, plan_key)
);

create table if not exists public.inspection_checklist_plan_items (
  inspection_kind text not null check (inspection_kind in ('flat', 'society')),
  plan_key text not null check (plan_key in ('free')),
  item_id text not null references public.inspection_checklist_items(id) on delete cascade,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (inspection_kind, plan_key, item_id),
  foreign key (inspection_kind, plan_key)
    references public.inspection_checklist_plans(inspection_kind, plan_key)
    on delete cascade
);

create index if not exists inspection_checklist_plan_items_lookup_idx
on public.inspection_checklist_plan_items(inspection_kind, plan_key, sort_order);

alter table public.inspection_checklist_plans enable row level security;
alter table public.inspection_checklist_plan_items enable row level security;

drop policy if exists "inspection app read checklist plans" on public.inspection_checklist_plans;
drop policy if exists "inspection app read checklist plan items" on public.inspection_checklist_plan_items;

create policy "inspection app read checklist plans"
on public.inspection_checklist_plans
for select
to anon, authenticated
using (is_active = true);

create policy "inspection app read checklist plan items"
on public.inspection_checklist_plan_items
for select
to anon, authenticated
using (is_active = true);

grant select on public.inspection_checklist_plans to anon, authenticated;
grant select on public.inspection_checklist_plan_items to anon, authenticated;

insert into public.inspection_checklist_plans (
  inspection_kind,
  plan_key,
  display_name,
  description,
  is_active
) values
  ('flat', 'free', 'Free Flat Inspection', '50 mandatory basic flat checks for free inspection.', true),
  ('flat', 'paid', 'Paid Flat Inspection', 'Full flat checklist.', true),
  ('society', 'free', 'Free Society Inspection', '50 mandatory basic society checks for free inspection.', true),
  ('society', 'paid', 'Paid Society Inspection', 'Full society checklist.', true)
on conflict (inspection_kind, plan_key) do update
set
  display_name = excluded.display_name,
  description = excluded.description,
  is_active = excluded.is_active,
  updated_at = now();

delete from public.inspection_checklist_plan_items
where (inspection_kind = 'flat' and plan_key = 'free')
   or (inspection_kind = 'society' and plan_key = 'free');

insert into public.inspection_checklist_plan_items (
  inspection_kind,
  plan_key,
  item_id,
  sort_order,
  is_active
) values
  ('flat', 'free', 'main-entrance-door-1', 1, true),
  ('flat', 'free', 'main-entrance-door-2', 2, true),
  ('flat', 'free', 'main-entrance-door-3', 3, true),
  ('flat', 'free', 'main-entrance-door-4', 4, true),
  ('flat', 'free', 'living-room-9', 5, true),
  ('flat', 'free', 'living-room-11', 6, true),
  ('flat', 'free', 'living-room-12', 7, true),
  ('flat', 'free', 'living-room-13', 8, true),
  ('flat', 'free', 'living-room-15', 9, true),
  ('flat', 'free', 'living-room-17', 10, true),
  ('flat', 'free', 'living-room-22', 11, true),
  ('flat', 'free', 'living-room-23', 12, true),
  ('flat', 'free', 'living-room-24', 13, true),
  ('flat', 'free', 'living-room-25', 14, true),
  ('flat', 'free', 'master-bedroom-37', 15, true),
  ('flat', 'free', 'master-bedroom-38', 16, true),
  ('flat', 'free', 'master-bedroom-40', 17, true),
  ('flat', 'free', 'master-bedroom-41', 18, true),
  ('flat', 'free', 'master-bedroom-42', 19, true),
  ('flat', 'free', 'master-bedroom-45', 20, true),
  ('flat', 'free', 'master-bedroom-48', 21, true),
  ('flat', 'free', 'master-bedroom-49', 22, true),
  ('flat', 'free', 'bedroom-2-54', 23, true),
  ('flat', 'free', 'bedroom-2-56', 24, true),
  ('flat', 'free', 'bedroom-2-58', 25, true),
  ('flat', 'free', 'bedroom-2-60', 26, true),
  ('flat', 'free', 'bedroom-2-61', 27, true),
  ('flat', 'free', 'master-bathroom-63', 28, true),
  ('flat', 'free', 'master-bathroom-68', 29, true),
  ('flat', 'free', 'master-bathroom-69', 30, true),
  ('flat', 'free', 'master-bathroom-75', 31, true),
  ('flat', 'free', 'master-bathroom-76', 32, true),
  ('flat', 'free', 'master-bathroom-77', 33, true),
  ('flat', 'free', 'master-bathroom-78', 34, true),
  ('flat', 'free', 'master-bathroom-80', 35, true),
  ('flat', 'free', 'master-bathroom-82', 36, true),
  ('flat', 'free', 'master-bathroom-83', 37, true),
  ('flat', 'free', 'master-bathroom-84', 38, true),
  ('flat', 'free', 'master-bathroom-87', 39, true),
  ('flat', 'free', 'kitchen-100', 40, true),
  ('flat', 'free', 'kitchen-110', 41, true),
  ('flat', 'free', 'kitchen-111', 42, true),
  ('flat', 'free', 'kitchen-113', 43, true),
  ('flat', 'free', 'kitchen-115', 44, true),
  ('flat', 'free', 'kitchen-116', 45, true),
  ('flat', 'free', 'kitchen-117', 46, true),
  ('flat', 'free', 'kitchen-125', 47, true),
  ('flat', 'free', 'kitchen-128', 48, true),
  ('flat', 'free', 'electrical-panel-mcb-room-149', 49, true),
  ('flat', 'free', 'water-tank-overhead-162', 50, true),

  ('society', 'free', 'society-main-gate-perimeter-003', 1, true),
  ('society', 'free', 'society-main-gate-perimeter-004', 2, true),
  ('society', 'free', 'society-main-gate-perimeter-005', 3, true),
  ('society', 'free', 'society-main-gate-perimeter-006', 4, true),
  ('society', 'free', 'society-main-gate-perimeter-007', 5, true),
  ('society', 'free', 'society-main-gate-perimeter-009', 6, true),
  ('society', 'free', 'society-main-gate-perimeter-010', 7, true),
  ('society', 'free', 'society-main-gate-perimeter-011', 8, true),
  ('society', 'free', 'society-security-cabin-guard-post-013', 9, true),
  ('society', 'free', 'society-security-cabin-guard-post-014', 10, true),
  ('society', 'free', 'society-security-cabin-guard-post-015', 11, true),
  ('society', 'free', 'society-security-cabin-guard-post-016', 12, true),
  ('society', 'free', 'society-security-cabin-guard-post-017', 13, true),
  ('society', 'free', 'society-main-lobby-entrance-025', 14, true),
  ('society', 'free', 'society-main-lobby-entrance-026', 15, true),
  ('society', 'free', 'society-lift-cabin-031', 16, true),
  ('society', 'free', 'society-lift-cabin-033', 17, true),
  ('society', 'free', 'society-lift-cabin-034', 18, true),
  ('society', 'free', 'society-lift-cabin-035', 19, true),
  ('society', 'free', 'society-lift-cabin-036', 20, true),
  ('society', 'free', 'society-lift-cabin-037', 21, true),
  ('society', 'free', 'society-lift-machine-room-041', 22, true),
  ('society', 'free', 'society-lift-machine-room-042', 23, true),
  ('society', 'free', 'society-lift-pit-043', 24, true),
  ('society', 'free', 'society-staircase-floor-corridors-046', 25, true),
  ('society', 'free', 'society-staircase-floor-corridors-047', 26, true),
  ('society', 'free', 'society-staircase-floor-corridors-050', 27, true),
  ('society', 'free', 'society-staircase-floor-corridors-051', 28, true),
  ('society', 'free', 'society-staircase-floor-corridors-054', 29, true),
  ('society', 'free', 'society-staircase-floor-corridors-055', 30, true),
  ('society', 'free', 'society-staircase-floor-corridors-056', 31, true),
  ('society', 'free', 'society-staircase-floor-corridors-059', 32, true),
  ('society', 'free', 'society-staircase-floor-corridors-060', 33, true),
  ('society', 'free', 'society-staircase-floor-corridors-062', 34, true),
  ('society', 'free', 'society-staircase-floor-corridors-063', 35, true),
  ('society', 'free', 'society-terrace-rooftop-065', 36, true),
  ('society', 'free', 'society-terrace-rooftop-067', 37, true),
  ('society', 'free', 'society-terrace-rooftop-068', 38, true),
  ('society', 'free', 'society-terrace-rooftop-071', 39, true),
  ('society', 'free', 'society-terrace-rooftop-073', 40, true),
  ('society', 'free', 'society-parking-078', 41, true),
  ('society', 'free', 'society-parking-079', 42, true),
  ('society', 'free', 'society-parking-080', 43, true),
  ('society', 'free', 'society-parking-082', 44, true),
  ('society', 'free', 'society-parking-083', 45, true),
  ('society', 'free', 'society-parking-087', 46, true),
  ('society', 'free', 'society-parking-088', 47, true),
  ('society', 'free', 'society-pump-room-095', 48, true),
  ('society', 'free', 'society-pump-room-096', 49, true),
  ('society', 'free', 'society-pump-room-098', 50, true)
on conflict (inspection_kind, plan_key, item_id) do update
set
  sort_order = excluded.sort_order,
  is_active = true,
  updated_at = now();

select
  inspection_kind,
  plan_key,
  count(*) as active_items
from public.inspection_checklist_plan_items
where is_active = true
group by inspection_kind, plan_key
order by inspection_kind, plan_key;

commit;
