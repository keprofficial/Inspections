-- Enables full inspection PDF upload and stores the PDF URL on inspections.
-- Safe to run: does not alter inspection_issues or any trigger-dependent columns.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'inspection-photos',
  'inspection-photos',
  true,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

alter table public.inspections
  add column if not exists full_report_pdf_url text;

create or replace function public.inspection_app_submit_report(p_payload jsonb)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inspection_id uuid;
  v_report_pdf_url text;
begin
  v_inspection_id := public.submit_inspection_report_public(
    p_payload ->> 'inspection_id',
    p_payload ->> 'session_token',
    coalesce((p_payload ->> 'overall_health_score')::integer, 0),
    p_payload ->> 'summary',
    coalesce(p_payload -> 'issues', '[]'::jsonb)
  );

  v_report_pdf_url := nullif(p_payload ->> 'report_pdf_url', '');
  if v_report_pdf_url is not null then
    update public.inspections
    set full_report_pdf_url = v_report_pdf_url
    where id = v_inspection_id;
  end if;

  return v_inspection_id::text;
end;
$$;

revoke all on function public.inspection_app_submit_report(jsonb) from public;
grant execute on function public.inspection_app_submit_report(jsonb) to anon, authenticated;

notify pgrst, 'reload schema';

select
  id,
  public,
  allowed_mime_types
from storage.buckets
where id = 'inspection-photos';
