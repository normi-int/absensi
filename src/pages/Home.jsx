import { useState, useEffect, useCallback } from 'react'
import { useAuth } from '../context/AuthContext'
import { useLanguage } from '../context/LanguageContext'
import { supabase } from '../lib/supabase'

export default function Home() {
  const { profile, signOut } = useAuth()
  const { lang, setLang, t } = useLanguage()
  const [todayRecord, setTodayRecord] = useState(null)
  const [busy, setBusy] = useState(false)
  const [statusMsg, setStatusMsg] = useState(null)

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

  async function handleCheckInOut() {
    setBusy(true)
    setStatusMsg(null)

    try {
      const position = await getPosition()
      const nowIso = new Date().toISOString()

      if (!todayRecord) {
        // Check in
        const { data, error } = await supabase
          .from('attendance_records')
          .insert({
            staff_id: profile.id,
            date: todayStr,
            check_in_at: nowIso,
            check_in_lat: position.lat,
            check_in_lng: position.lng,
          })
          .select()
          .single()
        if (error) throw error
        setTodayRecord(data)
        setStatusMsg({ type: 'ok', text: t('home.checkedIn') })
      } else if (!todayRecord.check_out_at) {
        // Check out
        const { data, error } = await supabase
          .from('attendance_records')
          .update({
            check_out_at: nowIso,
            check_out_lat: position.lat,
            check_out_lng: position.lng,
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
          {!alreadyCheckedOut && (
            <button onClick={handleCheckInOut} disabled={busy} style={styles.checkBtn}>
              {busy ? t('common.loading') : todayRecord ? t('home.checkOut') : t('home.checkIn')}
            </button>
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
