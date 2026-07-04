-- Safe read-only RPC setup for other apps.
-- This file does not alter any table columns, so it will not disturb triggers.

drop function if exists public.inspection_app_get_critical_issues(jsonb);
drop function if exists public.inspection_app_get_recent_critical_issues(jsonb);

create or replace function public.inspection_app_get_critical_issues(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inspection_id uuid;
  v_session_token uuid;
begin
  if nullif(trim(coalesce(p_payload ->> 'inspection_id', '')), '') is null then
    raise exception 'inspection_id is required';
  end if;

  if nullif(trim(coalesce(p_payload ->> 'session_token', '')), '') is null then
    raise exception 'session_token is required';
  end if;

  v_inspection_id := (p_payload ->> 'inspection_id')::uuid;
  v_session_token := (p_payload ->> 'session_token')::uuid;

  if not exists (
    select 1
    from public.inspection_app_sessions s
    join public.inspection_app_users u on u.id = s.inspector_id
    where s.token = v_session_token
      and s.revoked_at is null
      and s.expires_at > now()
      and u.is_active = true
  ) then
    raise exception 'Invalid or expired inspector session';
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'inspection_id', i.id,
          'inspection_ref', i.inspection_ref,
          'inspection_summary', i.summary,
          'overall_health_score', i.overall_health_score,
          'conducted_at', i.conducted_at,
          'inspector_name', i.inspector_name,
          'property_id', p.id,
          'society_name', coalesce(p.society_name, p.name),
          'block', p.block,
          'flat_number', coalesce(p.flat_number, p.name),
          'property_code', coalesce(p.property_code, p.kepr_id),
          'address', p.address,
          'issue_id', ii.id,
          'issue_ref', ii.issue_ref,
          'severity', ii.severity,
          'category', ii.category,
          'description', ii.description,
          'status', ii.status,
          'service_code', ii.service_code,
          'service_name', svc.name,
          'photo_urls', coalesce(ii.photo_urls, array[]::text[]),
          'material_codes', coalesce(ii.material_codes, array[]::text[]),
          'resident_approval_needed', ii.resident_approval_needed,
          'plan_covered', ii.plan_covered
        )
        order by ii.issue_ref, ii.service_code
      )
      from public.inspection_issues ii
      join public.inspections i on i.id = ii.inspection_id
      join public.properties p on p.id = i.property_id
      left join public.services svc on svc.service_code = ii.service_code
      where ii.inspection_id = v_inspection_id
        and lower(coalesce(ii.severity, '')) = 'critical'
    ),
    '[]'::jsonb
  );
end;
$$;

create or replace function public.inspection_app_get_recent_critical_issues(p_payload jsonb default '{}'::jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_property_id uuid;
  v_service_code text;
  v_status text;
  v_limit integer;
  v_session_token uuid;
begin
  if nullif(trim(coalesce(p_payload ->> 'session_token', '')), '') is null then
    raise exception 'session_token is required';
  end if;

  v_session_token := (p_payload ->> 'session_token')::uuid;

  if not exists (
    select 1
    from public.inspection_app_sessions s
    join public.inspection_app_users u on u.id = s.inspector_id
    where s.token = v_session_token
      and s.revoked_at is null
      and s.expires_at > now()
      and u.is_active = true
  ) then
    raise exception 'Invalid or expired inspector session';
  end if;

  if nullif(trim(coalesce(p_payload ->> 'property_id', '')), '') is not null then
    v_property_id := (p_payload ->> 'property_id')::uuid;
  end if;

  v_service_code := nullif(trim(coalesce(p_payload ->> 'service_code', '')), '');
  v_status := nullif(trim(coalesce(p_payload ->> 'status', '')), '');
  v_limit := least(greatest(coalesce((p_payload ->> 'limit')::integer, 50), 1), 200);

  return coalesce(
    (
      select jsonb_agg(row_data order by sort_conducted_at desc nulls last, sort_issue_ref)
      from (
        select
          i.conducted_at as sort_conducted_at,
          ii.issue_ref as sort_issue_ref,
          jsonb_build_object(
            'inspection_id', i.id,
            'inspection_ref', i.inspection_ref,
            'inspection_summary', i.summary,
            'overall_health_score', i.overall_health_score,
            'conducted_at', i.conducted_at,
            'inspector_name', i.inspector_name,
            'property_id', p.id,
            'society_name', coalesce(p.society_name, p.name),
            'block', p.block,
            'flat_number', coalesce(p.flat_number, p.name),
            'property_code', coalesce(p.property_code, p.kepr_id),
            'address', p.address,
            'issue_id', ii.id,
            'issue_ref', ii.issue_ref,
            'severity', ii.severity,
            'category', ii.category,
            'description', ii.description,
            'status', ii.status,
            'service_code', ii.service_code,
            'service_name', svc.name,
            'photo_urls', coalesce(ii.photo_urls, array[]::text[]),
            'material_codes', coalesce(ii.material_codes, array[]::text[]),
            'resident_approval_needed', ii.resident_approval_needed,
            'plan_covered', ii.plan_covered
          ) as row_data
        from public.inspection_issues ii
        join public.inspections i on i.id = ii.inspection_id
        join public.properties p on p.id = i.property_id
        left join public.services svc on svc.service_code = ii.service_code
        where lower(coalesce(ii.severity, '')) = 'critical'
          and (v_property_id is null or i.property_id = v_property_id)
          and (v_service_code is null or ii.service_code = v_service_code)
          and (v_status is null or ii.status = v_status)
        order by i.conducted_at desc nulls last, ii.issue_ref
        limit v_limit
      ) rows
    ),
    '[]'::jsonb
  );
end;
$$;

revoke all on function public.inspection_app_get_critical_issues(jsonb) from public;
revoke all on function public.inspection_app_get_recent_critical_issues(jsonb) from public;

grant execute on function public.inspection_app_get_critical_issues(jsonb) to anon, authenticated;
grant execute on function public.inspection_app_get_recent_critical_issues(jsonb) to anon, authenticated;

notify pgrst, 'reload schema';

select proname, pg_get_function_identity_arguments(oid) as arguments
from pg_proc
where pronamespace = 'public'::regnamespace
and proname in (
  'inspection_app_get_critical_issues',
  'inspection_app_get_recent_critical_issues'
)
order by proname;
