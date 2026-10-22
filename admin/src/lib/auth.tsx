import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import type { Session } from '@supabase/supabase-js'
import { db, rpc } from './supabase'

export type Me = { id: string; name: string | null; email: string; avatar: string | null; role: string; role_name: string; permissions: string[] }

type Ctx = {
  session: Session | null
  me: Me | null
  ready: boolean
  can: (perm: string) => boolean
  refresh: () => Promise<void>
  signOut: () => Promise<void>
}

const AuthCtx = createContext<Ctx>(null as unknown as Ctx)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [me, setMe] = useState<Me | null>(null)
  const [ready, setReady] = useState(false)

  const load = async (s: Session | null) => {
    setSession(s)
    if (!s) {
      setMe(null)
      setReady(true)
      return
    }
    try {
      setMe(await rpc<Me | null>('admin_me'))
    } catch {
      setMe(null)
    }
    setReady(true)
  }

  useEffect(() => {
    db.auth.getSession().then(({ data }) => load(data.session))
    const { data: sub } = db.auth.onAuthStateChange((event, s) => {
      if (event === 'SIGNED_IN' || event === 'SIGNED_OUT' || event === 'USER_UPDATED') load(s)
      else setSession(s)
    })
    return () => sub.subscription.unsubscribe()
  }, [])

  const can = (perm: string) => !!me && (me.permissions.includes('*') || me.permissions.includes(perm))

  return (
    <AuthCtx.Provider
      value={{
        session,
        me,
        ready,
        can,
        refresh: async () => load((await db.auth.getSession()).data.session),
        signOut: async () => {
          await db.auth.signOut()
        },
      }}
    >
      {children}
    </AuthCtx.Provider>
  )
}

export const useAuth = () => useContext(AuthCtx)
