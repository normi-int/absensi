# Absensi

Payroll & HR app for a multi-outlet F&B company — attendance (check-in/out with photo & geotag), staff roster, leave requests, and payroll calculation. Bilingual (Indonesian / English).

Built as a mobile-responsive web app (works in any phone browser, installable as a home-screen shortcut) backed by Supabase.

## Current status

First working slice: **login (email/password) → homepage → check-in/check-out with geotag**, wired to a real Supabase project.

## Setup

1. Install dependencies:
   ```
   npm install
   ```

2. Copy the env template and fill in your Supabase project's URL and public/anon key (find these in Supabase Dashboard → Project Settings → API):
   ```
   cp .env.example .env.local
   ```

3. Run the database schema, in order, in Supabase Dashboard → SQL Editor → New query:
   - `supabase/migrations/0001_init.sql` — creates the `profiles` and `attendance_records` tables with Row Level Security policies.
   - `supabase/migrations/0002_email_login.sql` — removes the `username` column; login is by email directly.

4. Create a test staff account:
   - Supabase Dashboard → Authentication → Users → Add user → enter an email + password (check "Auto Confirm User" if offered).
   - That's it — no extra SQL step needed. Sign in on the login screen with that email and password.

5. Run the dev server:
   ```
   npm run dev
   ```

## Project structure

- `src/lib/supabase.js` — Supabase client setup
- `src/context/AuthContext.jsx` — session state, email/password sign-in
- `src/context/LanguageContext.jsx` — ID/EN toggle state, persisted per-user
- `src/i18n/strings.js` — all UI text, keyed by screen — add new keys here as new screens are built
- `src/pages/` — one file per screen
- `src/styles/tokens.css` — NORMI colour palette as CSS variables
- `supabase/migrations/` — SQL schema, run manually in the Supabase SQL Editor (no CLI/migration tooling wired up yet)

## Notes

- Login is by email + password directly (no separate username).
- Default language is Indonesian; toggling persists to the user's `profiles.language` column so it follows them across devices.
- `.env.local` is gitignored — never commit real Supabase keys.
