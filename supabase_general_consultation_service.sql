-- Adds the General consultation service used by the Inspection app fallback.
-- Safe to re-run. No inspection/report rows are modified.

begin;

insert into public.service_categories (
  name,
  subtitle,
  icon_name,
  color_hex,
  starting_price,
  sort_order,
  is_active
)
select
  'General',
  'Minor repairs & maintenance',
  'tool',
  '#1A5FA8',
  150,
  8,
  true
where not exists (
  select 1 from public.service_categories where lower(name) = 'general'
);

insert into public.services (
  service_code,
  category_id,
  category,
  name,
  description,
  base_price,
  duration_label,
  duration_minutes,
  rating,
  review_count,
  icon_name,
  credits_applicable,
  is_active,
  sort_order,
  subcategory_name
)
select
  'KS999',
  c.id,
  'General',
  'Consultation Visit',
  'General inspection consultation for issues that do not match an existing service catalog item.',
  150,
  '30 mins',
  30,
  4.8,
  0,
  'support_agent',
  false,
  true,
  999,
  'General'
from public.service_categories c
where lower(c.name) = 'general'
on conflict (service_code) do update
set
  category_id = excluded.category_id,
  category = excluded.category,
  name = excluded.name,
  description = excluded.description,
  base_price = excluded.base_price,
  duration_label = excluded.duration_label,
  duration_minutes = excluded.duration_minutes,
  icon_name = excluded.icon_name,
  is_active = true,
  subcategory_name = excluded.subcategory_name;

commit;
