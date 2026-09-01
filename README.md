# Absensi

Payroll & HR app for a multi-outlet F&B company — attendance (check-in/out with photo & geotag), staff roster, leave requests, and payroll calculation. Bilingual (Indonesian / English).

Built as a mobile-responsive web app (works in any phone browser, installable as a home-screen shortcut) backed by Supabase.

## Current status

First working slice: **login (username/password) → homepage → check-in/check-out with geotag**, wired to a real Supabase project.

## Setup

1. Install dependencies:
   ```
   npm install
   ```

2. Copy the env template and fill in your Supabase project's URL and public/anon key (find these in Supabase Dashboard → Project Settings → API):
   ```
   cp .env.example .env.local
   ```

3. Run the database schema: open Supabase Dashboard → SQL Editor → New query, paste the contents of `supabase/migrations/0001_init.sql`, and run it. This creates the `profiles` and `attendance_records` tables with Row Level Security policies.

4. Create a test staff account:
   - Supabase Dashboard → Authentication → Users → Add user → enter an email + password.
   - Then in the SQL Editor, set that user's login username and name (replace the email/values):
     ```sql
     update public.profiles
     set username = 'testuser', full_name = 'Test User'
     where email = 'the-email-you-used@example.com';
     ```
   - Now you can sign in on the login screen using `testuser` as the username and the password you set.

5. Run the dev server:
   ```
   npm run dev
   ```

## Project structure

- `src/lib/supabase.js` — Supabase client setup
- `src/context/AuthContext.jsx` — session state, username→email login resolution
- `src/context/LanguageContext.jsx` — ID/EN toggle state, persisted per-user
- `src/i18n/strings.js` — all UI text, keyed by screen — add new keys here as new screens are built
- `src/pages/` — one file per screen
- `src/styles/tokens.css` — NORMI colour palette as CSS variables
- `supabase/migrations/` — SQL schema, run manually in the Supabase SQL Editor (no CLI/migration tooling wired up yet)

## Notes

- Login screen labels the field "Username" per the confirmed design, but Supabase auth underneath is email+password — the `profiles` table maps username → email at login time.
- Default language is Indonesian; toggling persists to the user's `profiles.language` column so it follows them across devices.
- `.env.local` is gitignored — never commit real Supabase keys.
