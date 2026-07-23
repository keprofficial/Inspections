-- Keeps society and flat inspection records strictly separated.
-- Run after supabase_inspection_rpc.sql. Safe to run repeatedly.

create or replace function public.enforce_inspection_property_scope()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_property_type text;
begin
  select p.type into v_property_type
  from public.properties p
  where p.id = new.property_id;

  if v_property_type is null then
    raise exception 'Inspection property % does not exist', new.property_id;
  end if;

  if new.inspection_type = 'society' and v_property_type <> 'society' then
    raise exception 'Society inspection must target a society property, not %',
      v_property_type;
  end if;

  if new.inspection_type = 'flat' and v_property_type <> 'flat' then
    raise exception 'Flat inspection must target a flat property, not %',
      v_property_type;
  end if;

  return new;
end;
$$;

drop trigger if exists enforce_inspection_property_scope
on public.inspections;

create trigger enforce_inspection_property_scope
before insert or update of property_id, inspection_type
on public.inspections
for each row
execute function public.enforce_inspection_property_scope();

-- Audit only: expected result is zero rows.
select
  i.id,
  i.inspection_ref,
  i.inspection_type,
  i.property_id,
  p.type as property_type,
  p.name as property_name
from public.inspections i
join public.properties p on p.id = i.property_id
where (i.inspection_type = 'society' and p.type <> 'society')
   or (i.inspection_type = 'flat' and p.type <> 'flat');
