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
