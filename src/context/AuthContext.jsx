import { createContext, useContext, useEffect, useState, useCallback } from 'react'
import { supabase } from '../lib/supabase'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [session, setSession] = useState(null)
  const [profile, setProfile] = useState(null)
  const [loading, setLoading] = useState(true)

  const loadProfile = useCallback(async (userId) => {
    if (!userId) {
      setProfile(null)
      return
    }
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single()
    if (!error) setProfile(data)
  }, [])

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      if (session?.user?.id) loadProfile(session.user.id)
      setLoading(false)
    })

    const { data: listener } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session)
      if (session?.user?.id) {
        loadProfile(session.user.id)
      } else {
        setProfile(null)
      }
    })

    return () => listener.subscription.unsubscribe()
  }, [loadProfile])

  /**
   * Login screen collects a "username" per the confirmed design, but
   * Supabase auth is keyed on email. We resolve username -> email first
   * via the `profiles` table (public, username-only lookup), then sign in.
   */
  const signInWithUsername = useCallback(async (username, password) => {
    const { data: profileRow, error: lookupError } = await supabase
      .from('profiles')
      .select('email')
      .eq('username', username.trim().toLowerCase())
      .single()

    if (lookupError || !profileRow?.email) {
      return { error: { message: 'invalid_credentials' } }
    }

    const { data, error } = await supabase.auth.signInWithPassword({
      email: profileRow.email,
      password,
    })

    return { data, error }
  }, [])

  const signOut = useCallback(async () => {
    await supabase.auth.signOut()
  }, [])

  const value = {
    session,
    user: session?.user ?? null,
    profile,
    loading,
    signInWithUsername,
    signOut,
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
