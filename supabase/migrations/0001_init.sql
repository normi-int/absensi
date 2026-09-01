-- ============================================================
-- Absensi — initial schema
-- Run this in Supabase: Dashboard -> SQL Editor -> New query -> paste -> Run
-- ============================================================

-- ---------- profiles ----------
-- One row per staff member, linked 1:1 to Supabase's auth.users.
-- `username` is what the login screen collects; auth itself is by email.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  email text not null,
  full_name text not null,
  role text not null default 'staff'
    check (role in ('owner', 'hr', 'om', 'rm', 'staff')),
  outlet text,
  language text not null default 'id' check (language in ('id', 'en')),
  created_at timestamptz not null default now()
);

comment on table public.profiles is
  'Staff directory / auth profile. One row per login-capable user.';

-- ---------- attendance_records ----------
-- One row per staff member per calendar day. Check-in and check-out
-- each carry their own photo + geotag, per the confirmed spec.
create table if not exists public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null references public.profiles(id) on delete cascade,
  date date not null,
  check_in_at timestamptz,
  check_in_lat double precision,
  check_in_lng double precision,
  check_in_photo_url text,
  check_out_at timestamptz,
  check_out_lat double precision,
  check_out_lng double precision,
  check_out_photo_url text,
  created_at timestamptz not null default now(),
  unique (staff_id, date)
);

comment on table public.attendance_records is
  'One row per staff member per day: check-in/out timestamps, geotag, photo.';

-- ============================================================
-- Row Level Security
-- ============================================================

alter table public.profiles enable row level security;
alter table public.attendance_records enable row level security;

-- profiles: a user can read their own profile; HR/OM/Owner can read everyone's.
create policy "profiles_select_own_or_admin"
  on public.profiles for select
  using (
    id = auth.uid()
    or exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role in ('owner', 'hr', 'om')
    )
  );

-- profiles: a user can update only their own row (e.g. language preference).
create policy "profiles_update_own"
  on public.profiles for update
  using (id = auth.uid())
  with check (id = auth.uid());

-- attendance_records: a user can see/insert/update only their own records;
-- HR/OM/Owner can see everyone's (needed for approvals & Keterlambatan later).
create policy "attendance_select_own_or_admin"
  on public.attendance_records for select
  using (
    staff_id = auth.uid()
    or exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role in ('owner', 'hr', 'om')
    )
  );

create policy "attendance_insert_own"
  on public.attendance_records for insert
  with check (staff_id = auth.uid());

create policy "attendance_update_own"
  on public.attendance_records for update
  using (staff_id = auth.uid())
  with check (staff_id = auth.uid());

-- ============================================================
-- Convenience: auto-create a profile row when a new auth user signs up.
-- (Useful later once admin-driven account creation is built; harmless now.)
-- ============================================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, email, full_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', new.email)
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
