-- ============================================================
-- Absensi — check-in/out photo storage
-- Run this in Supabase: Dashboard -> SQL Editor -> New query -> paste -> Run
--
-- Creates a private storage bucket for attendance photos, and RLS
-- policies so each staff member can only upload/read their own
-- photos (path convention: {staff_id}/{date}_{checkin|checkout}.jpg).
-- Admin roles (owner/hr/om) can read everyone's, for future approval
-- / audit screens.
-- ============================================================

-- Private bucket: photos are not publicly accessible by URL, only via
-- signed URLs generated on demand (or direct download by an authorized user).
insert into storage.buckets (id, name, public)
values ('attendance-photos', 'attendance-photos', false)
on conflict (id) do nothing;

-- A staff member can upload into their own folder only.
-- Path convention: storage path = "{auth.uid()}/filename.jpg"
create policy "attendance_photos_insert_own"
  on storage.objects for insert
  with check (
    bucket_id = 'attendance-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- A staff member can overwrite/update their own photos (upsert on retry).
create policy "attendance_photos_update_own"
  on storage.objects for update
  using (
    bucket_id = 'attendance-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- A staff member can read their own photos; HR/OM/Owner can read everyone's.
create policy "attendance_photos_select_own_or_admin"
  on storage.objects for select
  using (
    bucket_id = 'attendance-photos'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or exists (
        select 1 from public.profiles p
        where p.id = auth.uid() and p.role in ('owner', 'hr', 'om')
      )
    )
  );
