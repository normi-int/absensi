#!/bin/bash
# Run this from inside your absensi project folder
# (Claude Desktop/project/absensi/absensi — the one with .git in it).
# Adds check-in/out photo capture + compression, and the storage migration.
set -e

mkdir -p supabase/migrations

cat > src/pages/Home.jsx << 'ABSENSI_EOF'
import { useState, useEffect, useCallback, useRef } from 'react'
import { useAuth } from '../context/AuthContext'
import { useLanguage } from '../context/LanguageContext'
import { supabase } from '../lib/supabase'

export default function Home() {
  const { profile, signOut } = useAuth()
  const { lang, setLang, t } = useLanguage()
  const [todayRecord, setTodayRecord] = useState(null)
  const [busy, setBusy] = useState(false)
  const [statusMsg, setStatusMsg] = useState(null)
  const fileInputRef = useRef(null)

  const todayStr = new Date().toISOString().slice(0, 10)

  const loadToday = useCallback(async () => {
    if (!profile?.id) return
    const { data } = await supabase
      .from('attendance_records')
      .select('*')
      .eq('staff_id', profile.id)
      .eq('date', todayStr)
      .maybeSingle()
    setTodayRecord(data ?? null)
  }, [profile?.id, todayStr])

  useEffect(() => {
    loadToday()
  }, [loadToday])

  // Step 1: user taps Check In/Out -> open the camera via the hidden file input.
  function startCheckInOut() {
    setStatusMsg(null)
    fileInputRef.current?.click()
  }

  // Step 2: photo captured -> compress, geotag, upload, write the record.
  async function handlePhotoSelected(e) {
    const file = e.target.files?.[0]
    // allow re-selecting the same file name later
    e.target.value = ''
    if (!file) return

    setBusy(true)
    setStatusMsg(null)

    try {
      const [position, compressedBlob] = await Promise.all([
        getPosition(),
        compressImage(file),
      ])

      const isCheckOut = Boolean(todayRecord)
      const nowIso = new Date().toISOString()
      const photoPath = `${profile.id}/${todayStr}_${isCheckOut ? 'checkout' : 'checkin'}.jpg`

      const { error: uploadError } = await supabase.storage
        .from('attendance-photos')
        .upload(photoPath, compressedBlob, { contentType: 'image/jpeg', upsert: true })
      if (uploadError) throw uploadError

      if (!isCheckOut) {
        const { data, error } = await supabase
          .from('attendance_records')
          .insert({
            staff_id: profile.id,
            date: todayStr,
            check_in_at: nowIso,
            check_in_lat: position.lat,
            check_in_lng: position.lng,
            check_in_photo_url: photoPath,
          })
          .select()
          .single()
        if (error) throw error
        setTodayRecord(data)
        setStatusMsg({ type: 'ok', text: t('home.checkedIn') })
      } else {
        const { data, error } = await supabase
          .from('attendance_records')
          .update({
            check_out_at: nowIso,
            check_out_lat: position.lat,
            check_out_lng: position.lng,
            check_out_photo_url: photoPath,
          })
          .eq('id', todayRecord.id)
          .select()
          .single()
        if (error) throw error
        setTodayRecord(data)
      }
    } catch (err) {
      setStatusMsg({ type: 'error', text: err.message || 'Error' })
    } finally {
      setBusy(false)
    }
  }

  const alreadyCheckedOut = todayRecord?.check_out_at

  return (
    <div style={styles.page}>
      <div style={styles.header}>
        <div>
          <h3 style={styles.greeting}>
            {t('home.greeting')}, {profile?.full_name || '…'} 👋
          </h3>
        </div>
        <div style={styles.headerRight}>
          <div style={styles.langToggleSm}>
            <button
              onClick={() => setLang('id')}
              style={{ ...styles.langBtnSm, ...(lang === 'id' ? styles.langBtnSmActive : {}) }}
            >
              ID
            </button>
            <button
              onClick={() => setLang('en')}
              style={{ ...styles.langBtnSm, ...(lang === 'en' ? styles.langBtnSmActive : {}) }}
            >
              EN
            </button>
          </div>
          <button onClick={signOut} style={styles.signOutBtn}>
            {t('home.signOut')}
          </button>
        </div>
      </div>

      <div style={styles.content}>
        {/* Hero: check-in status */}
        <div style={styles.hero}>
          <div style={styles.heroLabel}>{t('home.todaySchedule')}</div>
          <div style={styles.heroStatus}>
            <span
              style={{
                ...styles.statusDot,
                background: todayRecord ? 'var(--proceed)' : '#D8C4B7',
              }}
            />
            <span style={styles.statusText}>
              {alreadyCheckedOut
                ? t('home.checkedIn')
                : todayRecord
                ? t('home.checkedIn')
                : t('home.notCheckedIn')}
            </span>
          </div>

          {/* Hidden file input: accept="image/*" + capture opens the phone's
              camera directly on mobile browsers; on desktop it falls back to
              a file picker (with a webcam option depending on the browser). */}
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            capture="user"
            style={{ display: 'none' }}
            onChange={handlePhotoSelected}
          />

          {!alreadyCheckedOut && (
            <button onClick={startCheckInOut} disabled={busy} style={styles.checkBtn}>
              {busy
                ? t('home.uploading')
                : todayRecord
                ? t('home.checkOut')
                : t('home.checkIn')}
            </button>
          )}
          {!alreadyCheckedOut && (
            <div style={styles.photoHint}>{t('home.photoHint')}</div>
          )}
          {statusMsg && (
            <div
              style={{
                marginTop: 10,
                fontSize: 12,
                color: statusMsg.type === 'error' ? '#FCA5A5' : '#D8C4B7',
              }}
            >
              {statusMsg.text}
            </div>
          )}
        </div>

        {/* Secondary stats */}
        <div style={styles.statsRow}>
          <div style={styles.statCard}>
            <div style={styles.statNum}>—</div>
            <div style={styles.statLabel}>{t('home.alDaysLeft')}</div>
          </div>
          <div style={styles.statCard}>
            <div style={styles.statNum}>—</div>
            <div style={styles.statLabel}>{t('home.phBanked')}</div>
          </div>
        </div>

        {/* Quick actions */}
        <div style={styles.sectionLabel}>{t('home.quickActions')}</div>
        <div style={styles.quickGrid}>
          <div style={styles.quickTile}>{t('home.ketidakhadiran')}</div>
          <div style={styles.quickTile}>{t('home.kehadiran')}</div>
          <div style={styles.quickTile}>{t('home.lupaAbsen')}</div>
          <div style={styles.quickTile}>{t('home.roster')}</div>
        </div>
      </div>
    </div>
  )
}

function getPosition() {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error('Geolocation not supported'))
      return
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => resolve({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
      (err) => reject(new Error(err.message)),
      { enableHighAccuracy: true, timeout: 10000 }
    )
  })
}

/**
 * Resize + compress a captured photo before upload, per the confirmed spec:
 * ~800px wide, ~60% JPEG quality (a 3-5MB phone photo becomes ~80-150KB).
 * The photo only needs to clearly show the person's face for verification,
 * not archival quality — this keeps storage costs and upload time low
 * across 200+ staff x 2 photos/day.
 */
async function compressImage(file, maxWidth = 800, quality = 0.6) {
  const bitmap = await createImageBitmap(file)
  const scale = Math.min(1, maxWidth / bitmap.width)
  const canvas = document.createElement('canvas')
  canvas.width = Math.round(bitmap.width * scale)
  canvas.height = Math.round(bitmap.height * scale)
  const ctx = canvas.getContext('2d')
  ctx.drawImage(bitmap, 0, 0, canvas.width, canvas.height)
  return new Promise((resolve, reject) => {
    canvas.toBlob(
      (blob) => (blob ? resolve(blob) : reject(new Error('compress_failed'))),
      'image/jpeg',
      quality
    )
  })
}

const styles = {
  page: { minHeight: '100vh', background: 'var(--page)' },
  header: {
    padding: '16px 18px 10px',
    background: 'var(--card)',
    borderBottom: '1px solid var(--line)',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  greeting: { margin: 0, fontSize: 16, fontWeight: 700 },
  headerRight: { display: 'flex', alignItems: 'center', gap: 10 },
  langToggleSm: {
    display: 'inline-flex',
    background: 'var(--page)',
    border: '1.2px solid var(--line)',
    borderRadius: 99,
    padding: 2,
  },
  langBtnSm: {
    border: 'none',
    background: 'transparent',
    padding: '3px 9px',
    borderRadius: 99,
    fontSize: 10.5,
    fontWeight: 600,
    color: 'var(--muted)',
    cursor: 'pointer',
    fontFamily: 'inherit',
  },
  langBtnSmActive: { background: 'var(--brown)', color: '#fff' },
  signOutBtn: {
    border: '1.2px solid var(--line)',
    background: 'transparent',
    borderRadius: 8,
    padding: '5px 10px',
    fontSize: 11.5,
    fontWeight: 600,
    color: 'var(--muted)',
    cursor: 'pointer',
    fontFamily: 'inherit',
  },
  content: { padding: 16, maxWidth: 480, margin: '0 auto' },
  hero: {
    background: 'var(--brown)',
    borderRadius: 14,
    padding: 18,
    color: '#fff',
    marginBottom: 16,
  },
  heroLabel: {
    fontSize: 11,
    color: '#D8C4B7',
    textTransform: 'uppercase',
    letterSpacing: '.05em',
    marginBottom: 8,
  },
  heroStatus: { display: 'flex', alignItems: 'center', gap: 6, marginBottom: 16 },
  statusDot: { width: 7, height: 7, borderRadius: '50%' },
  statusText: { fontSize: 13, color: '#E9DCD2' },
  checkBtn: {
    width: '100%',
    fontFamily: 'inherit',
    fontSize: 14,
    fontWeight: 600,
    padding: 13,
    borderRadius: 8,
    border: 'none',
    cursor: 'pointer',
    background: 'var(--add)',
    color: '#fff',
  },
  photoHint: {
    marginTop: 8,
    fontSize: 11,
    color: '#D8C4B7',
    textAlign: 'center',
  },
  statsRow: { display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 16 },
  statCard: {
    background: 'var(--card)',
    border: '1px solid var(--line)',
    borderRadius: 10,
    padding: '12px 14px',
  },
  statNum: { fontSize: 17, fontWeight: 800 },
  statLabel: { fontSize: 11, color: 'var(--muted)' },
  sectionLabel: {
    fontSize: 11,
    fontWeight: 700,
    color: 'var(--muted)',
    textTransform: 'uppercase',
    letterSpacing: '.04em',
    margin: '14px 0 8px',
  },
  quickGrid: { display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 },
  quickTile: {
    background: 'var(--card)',
    border: '1px solid var(--line)',
    borderRadius: 10,
    padding: '14px 8px',
    textAlign: 'center',
    fontSize: 11.5,
    fontWeight: 600,
  },
}
ABSENSI_EOF

cat > src/i18n/strings.js << 'ABSENSI_EOF'
// Central translation table. Every UI string in the app should live here,
// keyed by a short dot-path name, with an `id` (Indonesian, default) and
// `en` (English) value. Add new keys as new screens are built.

export const strings = {
  login: {
    eyebrow: { id: 'MASUK', en: 'SIGN IN' },
    email: { id: 'Email', en: 'Email' },
    password: { id: 'Kata Sandi', en: 'Password' },
    submit: { id: 'Masuk', en: 'Sign In' },
    submitting: { id: 'Sedang masuk…', en: 'Signing in…' },
    forgotPassword: { id: 'Lupa kata sandi', en: 'Forgot my password' },
    errorInvalid: {
      id: 'Email atau kata sandi salah.',
      en: 'Incorrect email or password.',
    },
    errorGeneric: {
      id: 'Terjadi kesalahan. Silakan coba lagi.',
      en: 'Something went wrong. Please try again.',
    },
  },
  home: {
    greeting: { id: 'Hai', en: 'Hi' },
    todaySchedule: { id: "Jadwal Hari Ini", en: "Today's Schedule" },
    notCheckedIn: { id: 'Belum absen masuk', en: 'Not yet checked in' },
    checkedIn: { id: 'Sudah absen masuk', en: 'Checked in' },
    checkIn: { id: 'Absen Masuk', en: 'Check In' },
    checkOut: { id: 'Absen Pulang', en: 'Check Out' },
    uploading: { id: 'Mengunggah foto…', en: 'Uploading photo…' },
    photoHint: {
      id: 'Kamera akan terbuka untuk ambil foto selfie',
      en: 'Your camera will open to take a selfie',
    },
    alDaysLeft: { id: 'Sisa cuti', en: 'AL days left' },
    phBanked: { id: 'PH terkumpul', en: 'PH banked' },
    notifications: { id: 'Notifikasi', en: 'Notifications' },
    quickActions: { id: 'Aksi Cepat', en: 'Quick Actions' },
    ketidakhadiran: { id: 'Ketidakhadiran', en: 'Absence' },
    kehadiran: { id: 'Kehadiran', en: 'Attendance' },
    lupaAbsen: { id: 'Lupa Absen', en: 'Forgot to Clock' },
    roster: { id: 'Roster', en: 'Roster' },
    signOut: { id: 'Keluar', en: 'Sign Out' },
  },
  common: {
    loading: { id: 'Memuat…', en: 'Loading…' },
  },
}

/** Look up a string by dot path, e.g. t('login.submit', lang) */
export function t(path, lang) {
  const parts = path.split('.')
  let node = strings
  for (const p of parts) {
    node = node?.[p]
    if (node === undefined) return path // fallback: show the key itself
  }
  return node[lang] ?? node.id ?? path
}
ABSENSI_EOF

cat > supabase/migrations/0003_backfill_profiles.sql << 'ABSENSI_EOF'
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
ABSENSI_EOF

cat > supabase/migrations/0004_photo_storage.sql << 'ABSENSI_EOF'
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
ABSENSI_EOF

echo "Files updated."
git add -A
git commit -m "Add check-in/out photo capture with client-side compression"
echo ""
echo "Done. Now run: git push"
