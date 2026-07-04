-- Updates only the start-inspection RPC so next_due_at is 6 months after conducted_at.
-- Safe to run: does not touch inspection_issues, triggers, or RLS policies.

create or replace function public.start_inspection_public(
  p_property_id text,
  p_session_token text,
  p_inspector_name text,
  p_summary text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inspection_id uuid;
  v_now timestamptz := now();
  v_inspector public.inspection_app_users%rowtype;
  v_property_id uuid;
  v_session_token uuid;
begin
  if nullif(trim(coalesce(p_property_id, '')), '') is null then
    raise exception 'property_id is required';
  end if;

  if nullif(trim(coalesce(p_session_token, '')), '') is null then
    raise exception 'session_token is required';
  end if;

  v_property_id := p_property_id::uuid;
  v_session_token := p_session_token::uuid;

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

  if not exists (
    select 1
    from public.properties
    where id = v_property_id
  ) then
    raise exception 'property_id % does not exist', v_property_id;
  end if;

  insert into public.inspections (
    property_id,
    inspector_name,
    conducted_at,
    summary,
    inspection_ref,
    next_due_at
  )
  values (
    v_property_id,
    coalesce(nullif(trim(p_inspector_name), ''), v_inspector.display_name),
    v_now,
    coalesce(p_summary, ''),
    'INSP-' || replace(extensions.gen_random_uuid()::text, '-', ''),
    v_now + interval '6 months'
  )
  returning id into v_inspection_id;

  return v_inspection_id;
end;
$$;

notify pgrst, 'reload schema';

select proname, pg_get_function_identity_arguments(oid) as arguments
from pg_proc
where pronamespace = 'public'::regnamespace
and proname = 'start_inspection_public';
