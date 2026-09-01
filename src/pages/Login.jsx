import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { useLanguage } from '../context/LanguageContext'

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState(null)
  const [submitting, setSubmitting] = useState(false)

  const { signInWithEmail } = useAuth()
  const { lang, setLang, t } = useLanguage()
  const navigate = useNavigate()

  async function handleSubmit(e) {
    e.preventDefault()
    setError(null)
    setSubmitting(true)

    const { error } = await signInWithEmail(email, password)

    setSubmitting(false)

    if (error) {
      setError(
        error.message === 'invalid_credentials'
          ? t('login.errorInvalid')
          : t('login.errorGeneric')
      )
      return
    }

    navigate('/', { replace: true })
  }

  return (
    <div style={styles.page}>
      <div style={styles.langToggle}>
        <button
          type="button"
          onClick={() => setLang('id')}
          style={{ ...styles.langBtn, ...(lang === 'id' ? styles.langBtnActive : styles.langBtnInactive) }}
        >
          ID
        </button>
        <button
          type="button"
          onClick={() => setLang('en')}
          style={{ ...styles.langBtn, ...(lang === 'en' ? styles.langBtnActive : styles.langBtnInactive) }}
        >
          EN
        </button>
      </div>

      <form onSubmit={handleSubmit} style={styles.card}>
        <div style={styles.eyebrow}>{t('login.eyebrow')}</div>

        <label style={styles.label} htmlFor="email">
          {t('login.email')}
        </label>
        <input
          id="email"
          type="email"
          autoComplete="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          style={styles.input}
          required
        />

        <label style={styles.label} htmlFor="password">
          {t('login.password')}
        </label>
        <input
          id="password"
          type="password"
          autoComplete="current-password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          style={{ ...styles.input, marginBottom: 20 }}
          required
        />

        {error && <div style={styles.error}>{error}</div>}

        <button type="submit" disabled={submitting} style={styles.submitBtn}>
          {submitting ? t('login.submitting') : t('login.submit')}
        </button>

        <div style={styles.forgotRow}>
          <a href="#" style={styles.forgotLink}>
            {t('login.forgotPassword')}
          </a>
        </div>
      </form>
    </div>
  )
}

const styles = {
  page: {
    minHeight: '100vh',
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    padding: '24px 20px',
    background: 'var(--page)',
  },
  langToggle: {
    display: 'inline-flex',
    background: '#fff',
    border: '1.4px solid var(--line)',
    borderRadius: 99,
    padding: 3,
    gap: 2,
    marginBottom: 22,
    alignSelf: 'flex-end',
    maxWidth: 380,
    width: '100%',
    justifyContent: 'flex-end',
  },
  langBtn: {
    border: 'none',
    cursor: 'pointer',
    padding: '5px 12px',
    borderRadius: 99,
    fontSize: 11.5,
    fontFamily: 'inherit',
  },
  langBtnActive: {
    background: 'var(--brown)',
    color: '#fff',
    fontWeight: 700,
  },
  langBtnInactive: {
    background: 'transparent',
    color: 'var(--muted)',
    fontWeight: 600,
  },
  card: {
    width: '100%',
    maxWidth: 380,
    background: 'var(--card)',
    border: '1px solid var(--line)',
    borderRadius: 14,
    padding: '26px 24px',
    boxShadow: '0 8px 30px rgba(20, 15, 10, 0.06)',
  },
  eyebrow: {
    fontSize: 11.5,
    fontWeight: 800,
    letterSpacing: '.06em',
    color: 'var(--muted)',
    marginBottom: 18,
  },
  label: {
    display: 'block',
    fontSize: 11.5,
    fontWeight: 600,
    color: 'var(--muted)',
    marginBottom: 5,
    textTransform: 'uppercase',
    letterSpacing: '.03em',
  },
  input: {
    width: '100%',
    fontFamily: 'inherit',
    fontSize: 13.5,
    padding: '10px 12px',
    borderRadius: 8,
    border: '1.4px solid var(--line)',
    background: '#fff',
    color: 'var(--ink)',
    marginBottom: 14,
  },
  submitBtn: {
    width: '100%',
    fontFamily: 'inherit',
    fontSize: 14,
    fontWeight: 600,
    padding: 13,
    borderRadius: 8,
    border: 'none',
    cursor: 'pointer',
    background: 'var(--proceed)',
    color: '#fff',
  },
  forgotRow: {
    textAlign: 'center',
    marginTop: 18,
    fontSize: 12,
  },
  forgotLink: {
    color: 'var(--accent)',
    textDecoration: 'none',
    fontWeight: 600,
  },
  error: {
    background: '#FCE9E9',
    color: '#9B0A0A',
    borderRadius: 8,
    padding: '8px 12px',
    fontSize: 12.5,
    marginBottom: 14,
  },
}
