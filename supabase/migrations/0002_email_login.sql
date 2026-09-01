-- ============================================================
-- Absensi — switch login to email directly (drop username)
-- Run this in Supabase: Dashboard -> SQL Editor -> New query -> paste -> Run
-- Safe to run even if 0001_init.sql was already applied.
-- ============================================================

-- Username is no longer used for login; email is used directly.
-- Drop the column (and its uniqueness constraint) if present.
alter table public.profiles drop column if exists username;

-- Update the new-user trigger to no longer reference username.
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', new.email)
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;
