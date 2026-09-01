import { createContext, useContext, useEffect, useState, useCallback } from 'react'
import { t as translate } from '../i18n/strings'
import { supabase } from '../lib/supabase'
import { useAuth } from './AuthContext'

const LanguageContext = createContext(null)
const LOCAL_KEY = 'absensi_lang'

export function LanguageProvider({ children }) {
  const { profile, user } = useAuth()
  const [lang, setLangState] = useState(() => {
    try {
      return localStorage.getItem(LOCAL_KEY) || 'id'
    } catch {
      return 'id'
    }
  })

  // Once the logged-in user's profile loads, prefer their saved account-level
  // language preference over whatever was in local storage.
  useEffect(() => {
    if (profile?.language && (profile.language === 'id' || profile.language === 'en')) {
      setLangState(profile.language)
      try {
        localStorage.setItem(LOCAL_KEY, profile.language)
      } catch {
        /* ignore */
      }
    }
  }, [profile?.language])

  const setLang = useCallback(
    async (next) => {
      setLangState(next)
      try {
        localStorage.setItem(LOCAL_KEY, next)
      } catch {
        /* ignore */
      }
      // Persist per-user if logged in, so it syncs across devices.
      if (user?.id) {
        await supabase.from('profiles').update({ language: next }).eq('id', user.id)
      }
    },
    [user?.id]
  )

  const t = useCallback((path) => translate(path, lang), [lang])

  return (
    <LanguageContext.Provider value={{ lang, setLang, t }}>
      {children}
    </LanguageContext.Provider>
  )
}

export function useLanguage() {
  const ctx = useContext(LanguageContext)
  if (!ctx) throw new Error('useLanguage must be used within LanguageProvider')
  return ctx
}
