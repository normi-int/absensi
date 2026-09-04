-- ============================================================
-- Absensi — backfill missing profile rows
-- Run this in Supabase: Dashboard -> SQL Editor -> New query -> paste -> Run
--
-- If a user was created in Authentication -> Users before the
-- handle_new_user trigger existed (or the trigger didn't fire for
-- some other reason), their profiles row is missing, which is why
-- the app shows "profile is null" on Homepage.
--
-- This finds every auth.users row with no matching profiles row and
-- creates one. Safe to run any time — it only inserts what's missing.
-- ============================================================

insert into public.profiles (id, email, full_name)
select
  u.id,
  u.email,
  coalesce(u.raw_user_meta_data->>'full_name', u.email)
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null;

-- Verify: this should now show one row per user in auth.users
select id, email, full_name, role, language from public.profiles;
