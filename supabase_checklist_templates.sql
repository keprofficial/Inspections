-- Dynamic inspection checklist templates for the KEPR inspection app.
-- Safe to run multiple times. This creates DB-driven checklist tables and
-- read policies for the publishable key. It does not remove old data.

create table if not exists public.inspection_checklist_templates (
  template_key text primary key,
  name text not null,
  icon_name text not null default 'home_work',
  sort_order integer not null default 0,
  is_default boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.inspection_checklist_items (
  id text primary key,
  template_key text not null references public.inspection_checklist_templates(template_key) on delete cascade,
  sort_order integer not null default 0,
  name text not null,
  category text not null default 'General',
  inspection_type text not null default '',
  description text not null default '',
  how_to text not null default '',
  equipment_needed text not null default '',
  severity text not null default 'medium',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists inspection_checklist_items_template_sort_idx
on public.inspection_checklist_items(template_key, sort_order);

alter table public.inspection_checklist_templates enable row level security;
alter table public.inspection_checklist_items enable row level security;

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

notify pgrst, 'reload schema';

select schemaname, tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
  and tablename in (
    'inspection_checklist_templates',
    'inspection_checklist_items'
  )
order by tablename, policyname;
