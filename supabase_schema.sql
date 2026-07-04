create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null references auth.users(id) on delete cascade,
  full_name text not null,
  mobile_number text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_auth_user_id_key unique (auth_user_id)
);

alter table public.profiles add column if not exists auth_user_id uuid references auth.users(id) on delete cascade;
alter table public.profiles add column if not exists updated_at timestamptz not null default now();
delete from public.profiles where auth_user_id is null;
alter table public.profiles alter column auth_user_id set not null;
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'profiles_auth_user_id_key'
  ) then
    alter table public.profiles add constraint profiles_auth_user_id_key unique (auth_user_id);
  end if;
end;
$$;

create table if not exists public.properties (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  society_name text not null,
  flat_number text not null,
  kepr_id text not null,
  address text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint properties_profile_kepr_key unique (profile_id, kepr_id)
);

alter table public.properties alter column profile_id set not null;
alter table public.properties add column if not exists updated_at timestamptz not null default now();
alter table public.properties add column if not exists type text;
alter table public.properties add column if not exists name text;
alter table public.properties add column if not exists block text;
alter table public.properties add column if not exists property_code text;
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'properties_profile_kepr_key'
  ) then
    alter table public.properties add constraint properties_profile_kepr_key unique (profile_id, kepr_id);
  end if;
end;
$$;

create table if not exists public.inspections (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  title text not null,
  status text not null default 'in_progress',
  progress integer not null default 0 check (progress between 0 and 100),
  submitted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.inspections alter column property_id set not null;
alter table public.inspections add column if not exists progress integer not null default 0;
alter table public.inspections add column if not exists submitted_at timestamptz;
alter table public.inspections add column if not exists updated_at timestamptz not null default now();
alter table public.inspections add column if not exists inspector_name text;
alter table public.inspections add column if not exists conducted_at timestamptz;
alter table public.inspections add column if not exists overall_health_score integer;
alter table public.inspections add column if not exists next_due_at timestamptz;
alter table public.inspections add column if not exists full_report_pdf_url text;
alter table public.inspections add column if not exists summary text;
alter table public.inspections add column if not exists inspection_ref text;

create table if not exists public.inspection_areas (
  id uuid primary key default gen_random_uuid(),
  inspection_id uuid not null references public.inspections(id) on delete cascade,
  template_key text not null,
  name text not null,
  status text not null default 'pending',
  progress integer not null default 0 check (progress between 0 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint inspection_areas_inspection_name_key unique (inspection_id, name)
);

alter table public.inspection_areas alter column inspection_id set not null;
alter table public.inspection_areas add column if not exists updated_at timestamptz not null default now();
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'inspection_areas_inspection_name_key'
  ) then
    alter table public.inspection_areas add constraint inspection_areas_inspection_name_key unique (inspection_id, name);
  end if;
end;
$$;

create table if not exists public.inspection_results (
  id uuid primary key default gen_random_uuid(),
  inspection_area_id uuid not null references public.inspection_areas(id) on delete cascade,
  item_key text not null,
  name text not null,
  category text,
  inspection_type text,
  description text,
  how_to text,
  equipment_needed text,
  severity text check (severity is null or severity in ('low', 'medium', 'high', 'critical')),
  status text not null default 'pending',
  notes text,
  photo_names text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint inspection_results_area_item_key unique (inspection_area_id, item_key)
);

alter table public.inspection_results alter column inspection_area_id set not null;
alter table public.inspection_results add column if not exists photo_names text[] not null default '{}';
alter table public.inspection_results add column if not exists service_code text;
alter table public.inspection_results add column if not exists estimated_cost numeric;
alter table public.inspection_results add column if not exists material_codes text[] not null default '{}';
alter table public.inspection_results add column if not exists updated_at timestamptz not null default now();
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'inspection_results_area_item_key'
  ) then
    alter table public.inspection_results add constraint inspection_results_area_item_key unique (inspection_area_id, item_key);
  end if;
end;
$$;

create table if not exists public.inspection_issues (
  id uuid primary key default gen_random_uuid(),
  inspection_id uuid not null references public.inspections(id) on delete cascade,
  severity text not null,
  category text not null,
  description text not null,
  photo_urls text[],
  status text default 'open',
  linked_service_id uuid,
  linked_booking_id uuid,
  plan_covered boolean default false,
  resident_approval_needed boolean default true,
  resolved_by_user_id uuid,
  resolved_at timestamptz,
  service_code text,
  estimated_cost numeric,
  booking_id uuid,
  is_custom boolean not null default false,
  custom_title text,
  issue_ref text not null,
  material_codes text[] not null default '{}'
);

alter table public.inspection_issues add column if not exists photo_urls text[];
alter table public.inspection_issues add column if not exists linked_service_id uuid;
alter table public.inspection_issues add column if not exists linked_booking_id uuid;
alter table public.inspection_issues add column if not exists plan_covered boolean default false;
alter table public.inspection_issues add column if not exists resident_approval_needed boolean default true;
alter table public.inspection_issues add column if not exists resolved_by_user_id uuid;
alter table public.inspection_issues add column if not exists resolved_at timestamptz;
alter table public.inspection_issues add column if not exists service_code text;
alter table public.inspection_issues add column if not exists estimated_cost numeric;
alter table public.inspection_issues add column if not exists booking_id uuid;
alter table public.inspection_issues add column if not exists is_custom boolean not null default false;
alter table public.inspection_issues add column if not exists custom_title text;
alter table public.inspection_issues add column if not exists issue_ref text not null default gen_random_uuid()::text;
alter table public.inspection_issues add column if not exists material_codes text[] not null default '{}';

create table if not exists public.inspection_photos (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid references auth.users(id) on delete set null,
  property_id uuid references public.properties(id) on delete set null,
  inspection_id uuid references public.inspections(id) on delete set null,
  kepr_id text,
  society_name text,
  flat_number text,
  area_name text,
  item_key text not null,
  file_name text not null,
  mime_type text not null default 'image/jpeg',
  byte_size integer not null default 0,
  image_base64 text not null,
  created_at timestamptz not null default now()
);

alter table public.inspection_photos add column if not exists auth_user_id uuid references auth.users(id) on delete set null;
alter table public.inspection_photos add column if not exists property_id uuid references public.properties(id) on delete set null;
alter table public.inspection_photos add column if not exists inspection_id uuid references public.inspections(id) on delete set null;
alter table public.inspection_photos add column if not exists kepr_id text;
alter table public.inspection_photos add column if not exists society_name text;
alter table public.inspection_photos add column if not exists flat_number text;
alter table public.inspection_photos add column if not exists area_name text;
alter table public.inspection_photos add column if not exists byte_size integer not null default 0;
alter table public.inspection_photos add column if not exists image_base64 text;
alter table public.inspection_photos alter column image_base64 set not null;

create table if not exists public.inspection_reports (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  inspection_id uuid not null references public.inspections(id) on delete cascade,
  total_items integer not null default 0,
  completed_items integer not null default 0,
  pending_items integer not null default 0,
  progress integer not null default 0 check (progress between 0 and 100),
  created_at timestamptz not null default now(),
  constraint inspection_reports_inspection_key unique (inspection_id)
);

alter table public.inspection_reports alter column property_id set not null;
alter table public.inspection_reports alter column inspection_id set not null;
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'inspection_reports_inspection_key'
  ) then
    alter table public.inspection_reports add constraint inspection_reports_inspection_key unique (inspection_id);
  end if;
end;
$$;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists touch_profiles_updated_at on public.profiles;
create trigger touch_profiles_updated_at
before update on public.profiles
for each row execute function public.touch_updated_at();

drop trigger if exists touch_properties_updated_at on public.properties;
create trigger touch_properties_updated_at
before update on public.properties
for each row execute function public.touch_updated_at();

drop trigger if exists touch_inspections_updated_at on public.inspections;
create trigger touch_inspections_updated_at
before update on public.inspections
for each row execute function public.touch_updated_at();

drop trigger if exists touch_inspection_areas_updated_at on public.inspection_areas;
create trigger touch_inspection_areas_updated_at
before update on public.inspection_areas
for each row execute function public.touch_updated_at();

drop trigger if exists touch_inspection_results_updated_at on public.inspection_results;
create trigger touch_inspection_results_updated_at
before update on public.inspection_results
for each row execute function public.touch_updated_at();

alter table public.profiles enable row level security;
alter table public.properties enable row level security;
alter table public.inspections enable row level security;
alter table public.inspection_areas enable row level security;
alter table public.inspection_results enable row level security;
alter table public.inspection_issues enable row level security;
alter table public.inspection_photos enable row level security;
alter table public.inspection_reports enable row level security;

drop policy if exists "dev read profiles" on public.profiles;
drop policy if exists "dev insert profiles" on public.profiles;
drop policy if exists "dev read properties" on public.properties;
drop policy if exists "dev insert properties" on public.properties;
drop policy if exists "dev read inspections" on public.inspections;
drop policy if exists "dev insert inspections" on public.inspections;
drop policy if exists "dev update inspections" on public.inspections;
drop policy if exists "dev read inspection areas" on public.inspection_areas;
drop policy if exists "dev insert inspection areas" on public.inspection_areas;
drop policy if exists "dev read inspection results" on public.inspection_results;
drop policy if exists "dev insert inspection results" on public.inspection_results;
drop policy if exists "dev read inspection issues" on public.inspection_issues;
drop policy if exists "dev insert inspection issues" on public.inspection_issues;
drop policy if exists "dev insert inspection photos" on public.inspection_photos;
drop policy if exists "dev read inspection reports" on public.inspection_reports;
drop policy if exists "dev insert inspection reports" on public.inspection_reports;

drop policy if exists "profiles owner read" on public.profiles;
create policy "profiles owner read" on public.profiles
for select using (auth.uid() = auth_user_id);

drop policy if exists "profiles owner insert" on public.profiles;
create policy "profiles owner insert" on public.profiles
for insert with check (auth.uid() = auth_user_id);

drop policy if exists "profiles owner update" on public.profiles;
create policy "profiles owner update" on public.profiles
for update using (auth.uid() = auth_user_id)
with check (auth.uid() = auth_user_id);

drop policy if exists "properties owner read" on public.properties;
create policy "properties owner read" on public.properties
for select using (
  exists (
    select 1 from public.profiles p
    where p.id = properties.profile_id and p.auth_user_id = auth.uid()
  )
);

drop policy if exists "properties owner write" on public.properties;
create policy "properties owner write" on public.properties
for all using (
  exists (
    select 1 from public.profiles p
    where p.id = properties.profile_id and p.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.profiles p
    where p.id = properties.profile_id and p.auth_user_id = auth.uid()
  )
);

drop policy if exists "inspections owner all" on public.inspections;
create policy "inspections owner all" on public.inspections
for all using (
  exists (
    select 1
    from public.properties pr
    join public.profiles p on p.id = pr.profile_id
    where pr.id = inspections.property_id and p.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.properties pr
    join public.profiles p on p.id = pr.profile_id
    where pr.id = inspections.property_id and p.auth_user_id = auth.uid()
  )
);

drop policy if exists "inspection areas owner all" on public.inspection_areas;
create policy "inspection areas owner all" on public.inspection_areas
for all using (
  exists (
    select 1
    from public.inspections i
    join public.properties pr on pr.id = i.property_id
    join public.profiles p on p.id = pr.profile_id
    where i.id = inspection_areas.inspection_id and p.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.inspections i
    join public.properties pr on pr.id = i.property_id
    join public.profiles p on p.id = pr.profile_id
    where i.id = inspection_areas.inspection_id and p.auth_user_id = auth.uid()
  )
);

drop policy if exists "inspection results owner all" on public.inspection_results;
create policy "inspection results owner all" on public.inspection_results
for all using (
  exists (
    select 1
    from public.inspection_areas ia
    join public.inspections i on i.id = ia.inspection_id
    join public.properties pr on pr.id = i.property_id
    join public.profiles p on p.id = pr.profile_id
    where ia.id = inspection_results.inspection_area_id and p.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.inspection_areas ia
    join public.inspections i on i.id = ia.inspection_id
    join public.properties pr on pr.id = i.property_id
    join public.profiles p on p.id = pr.profile_id
    where ia.id = inspection_results.inspection_area_id and p.auth_user_id = auth.uid()
  )
);

drop policy if exists "inspection issues owner all" on public.inspection_issues;
create policy "inspection issues owner all" on public.inspection_issues
for all using (
  exists (
    select 1
    from public.inspections i
    join public.properties pr on pr.id = i.property_id
    join public.profiles p on p.id = pr.profile_id
    where i.id = inspection_issues.inspection_id and p.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.inspections i
    join public.properties pr on pr.id = i.property_id
    join public.profiles p on p.id = pr.profile_id
    where i.id = inspection_issues.inspection_id and p.auth_user_id = auth.uid()
  )
);

drop policy if exists "dev insert inspection issues" on public.inspection_issues;
create policy "dev insert inspection issues" on public.inspection_issues
for insert to anon
with check (true);

drop policy if exists "inspection photos owner read" on public.inspection_photos;
create policy "inspection photos owner read" on public.inspection_photos
for select using (
  auth.uid() = auth_user_id
  or exists (
    select 1
    from public.inspections i
    join public.properties pr on pr.id = i.property_id
    join public.profiles p on p.id = pr.profile_id
    where i.id = inspection_photos.inspection_id and p.auth_user_id = auth.uid()
  )
);

drop policy if exists "inspection photos owner insert" on public.inspection_photos;
create policy "inspection photos owner insert" on public.inspection_photos
for insert with check (
  auth.uid() is null
  or auth.uid() = auth_user_id
  or exists (
    select 1
    from public.inspections i
    join public.properties pr on pr.id = i.property_id
    join public.profiles p on p.id = pr.profile_id
    where i.id = inspection_photos.inspection_id and p.auth_user_id = auth.uid()
  )
);

drop policy if exists "inspection photos owner delete" on public.inspection_photos;
create policy "inspection photos owner delete" on public.inspection_photos
for delete using (
  auth.uid() = auth_user_id
  or exists (
    select 1
    from public.inspections i
    join public.properties pr on pr.id = i.property_id
    join public.profiles p on p.id = pr.profile_id
    where i.id = inspection_photos.inspection_id and p.auth_user_id = auth.uid()
  )
);

drop policy if exists "dev insert inspection photos" on public.inspection_photos;
create policy "dev insert inspection photos" on public.inspection_photos
for insert to anon
with check (auth_user_id is null);

drop policy if exists "inspection reports owner all" on public.inspection_reports;
create policy "inspection reports owner all" on public.inspection_reports
for all using (
  exists (
    select 1
    from public.properties pr
    join public.profiles p on p.id = pr.profile_id
    where pr.id = inspection_reports.property_id and p.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.properties pr
    join public.profiles p on p.id = pr.profile_id
    where pr.id = inspection_reports.property_id and p.auth_user_id = auth.uid()
  )
);
