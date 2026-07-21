-- Metadata-only Supabase changes for Firebase Storage migration.
-- Files are stored in Firebase Storage. Supabase stores only the returned URLs.

alter table public.inspection_photos
add column if not exists photo_url text;

-- If you previously used the individual inspection table policy that only
-- allowed Supabase Storage URLs, replace it with one that also allows Firebase.
drop policy if exists "inspection app insert individual inspections"
on public.individual_inspections;

create policy "inspection app insert individual inspections"
on public.individual_inspections
for insert
to anon, authenticated
with check (
  length(trim(property_name)) > 0
  and length(trim(property_owner_name)) > 0
  and length(trim(property_owner_mobile)) >= 8
  and (
    report_pdf_url like 'https://egalrsutygdvdmjkvduh.supabase.co/%'
    or report_pdf_url like 'https://firebasestorage.googleapis.com/%'
    or report_pdf_url like 'https://storage.googleapis.com/%'
  )
);

notify pgrst, 'reload schema';

select column_name
from information_schema.columns
where table_schema = 'public'
  and table_name = 'inspection_photos'
  and column_name = 'photo_url';
