-- Run this file once in the Supabase SQL Editor.
-- It allows the inspector dashboard to read submitted reports across devices
-- while preserving Row Level Security on the underlying tables.

drop function if exists public.inspection_app_get_submitted_reports(jsonb);

create or replace function public.inspection_app_get_submitted_reports(
  p_payload jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session_token uuid;
  v_inspector_id uuid;
  v_inspector_name text;
  v_inspector_mobile text;
  v_limit integer;
begin
  if nullif(trim(coalesce(p_payload ->> 'session_token', '')), '') is null then
    raise exception 'session_token is required';
  end if;

  v_session_token := (p_payload ->> 'session_token')::uuid;
  v_limit := least(
    greatest(coalesce((p_payload ->> 'limit')::integer, 100), 1),
    200
  );

  select u.id, u.display_name, u.mobile_number
  into v_inspector_id, v_inspector_name, v_inspector_mobile
  from public.inspection_app_sessions s
  join public.inspection_app_users u on u.id = s.inspector_id
  where s.token = v_session_token
    and s.revoked_at is null
    and s.expires_at > now()
    and u.is_active = true
  limit 1;

  if v_inspector_id is null then
    raise exception 'Invalid or expired inspector session';
  end if;

  return coalesce(
    (
      select jsonb_agg(
        to_jsonb(report_row)
        order by report_row.submitted_at desc
      )
      from (
        select *
        from (
          select
            i.id::text as inspection_id,
            coalesce(i.inspection_type, 'flat') as inspection_type,
            i.property_id::text as property_id,
            coalesce(
              society.name,
              parent.name,
              p.name,
              i.inspection_ref,
              'Property Inspection'
            ) as society_name,
            coalesce(
              p.name,
              i.inspection_ref,
              '-'
            ) as flat_number,
            coalesce(
              i.inspection_code,
              p.property_code
            ) as property_code,
            i.full_report_pdf_url as report_url,
            coalesce(i.conducted_at, now()) as submitted_at
          from public.inspections i
          left join public.properties p on p.id = i.property_id
          left join public.properties parent on parent.id = p.parent_property_id
          left join public.properties society on society.id = parent.parent_property_id
          where nullif(i.full_report_pdf_url, '') is not null
            and lower(trim(coalesce(i.inspector_name, ''))) =
                lower(trim(v_inspector_name))

          union all

          select
            coalesce(ii.inspection_ref, ii.id::text) as inspection_id,
            coalesce(ii.inspection_type, 'individual') as inspection_type,
            ii.inspection_ref as property_id,
            coalesce(
              ii.property_name,
              'Individual Inspection'
            ) as society_name,
            'Owner: ' || coalesce(ii.property_owner_name, '-') as flat_number,
            coalesce(
              ii.inspection_code,
              ii.property_owner_mobile
            ) as property_code,
            ii.report_pdf_url as report_url,
            ii.submitted_at
          from public.individual_inspections ii
          where nullif(ii.report_pdf_url, '') is not null
            and (
              ii.inspector_id = v_inspector_id::text
              or regexp_replace(
                   coalesce(ii.inspector_mobile, ''),
                   '\D',
                   '',
                   'g'
                 ) = regexp_replace(
                   coalesce(v_inspector_mobile, ''),
                   '\D',
                   '',
                   'g'
                 )
              or lower(trim(coalesce(ii.inspector_name, ''))) =
                 lower(trim(v_inspector_name))
            )
        ) combined
        order by submitted_at desc
        limit v_limit
      ) report_row
    ),
    '[]'::jsonb
  );
end;
$$;

revoke all
on function public.inspection_app_get_submitted_reports(jsonb)
from public;

grant execute
on function public.inspection_app_get_submitted_reports(jsonb)
to anon, authenticated;

notify pgrst, 'reload schema';

select
  proname,
  pg_get_function_identity_arguments(oid) as arguments
from pg_proc
where pronamespace = 'public'::regnamespace
  and proname = 'inspection_app_get_submitted_reports';
