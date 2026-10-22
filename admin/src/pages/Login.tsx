import { useState } from 'react'
import { ArrowRight, Eye, EyeOff, ShieldCheck } from 'lucide-react'
import { db } from '../lib/supabase'
import { Button, useUi } from '../components/ui'

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [show, setShow] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [mode, setMode] = useState<'login' | 'reset'>('login')
  const { toast } = useUi()

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    setBusy(true)
    setError(null)
    if (mode === 'reset') {
      const { error } = await db.auth.resetPasswordForEmail(email.trim(), { redirectTo: window.location.origin + window.location.pathname + '#/account' })
      setBusy(false)
      if (error) setError(error.message)
      else {
        toast('If that email has an account, a reset link is on its way.')
        setMode('login')
      }
      return
    }
    const { error } = await db.auth.signInWithPassword({ email: email.trim(), password })
    setBusy(false)
    if (error) setError(error.message === 'Invalid login credentials' ? 'Incorrect email or password.' : error.message)
  }

  return (
    <div className="grid min-h-full lg:grid-cols-2">
      <div className="relative hidden overflow-hidden bg-ink-900 p-12 text-white lg:flex lg:flex-col">
        <div className="absolute -right-32 -top-32 h-96 w-96 rounded-full bg-brand-500/30 blur-3xl" />
        <div className="absolute -bottom-40 -left-20 h-[28rem] w-[28rem] rounded-full bg-brand-600/20 blur-3xl" />
        <div className="relative flex items-center gap-3">
          <img src="./logo.png" className="h-11 w-11 rounded-2xl" alt="" />
          <span className="text-xl font-bold">Shifty Admin</span>
        </div>
        <div className="relative mt-auto max-w-md">
          <h1 className="text-4xl font-bold leading-tight">Run the whole marketplace from one place.</h1>
          <p className="mt-4 text-ink-300">Dispatch jobs, verify professionals, settle payouts, moderate chats and answer customers, live.</p>
          <div className="mt-10 grid grid-cols-3 gap-3">
            {[
              ['Bookings', 'Live dispatch'],
              ['Professionals', 'Verification'],
              ['Finance', 'Payouts'],
            ].map(([a, b]) => (
              <div key={a} className="rounded-2xl border border-white/10 bg-white/5 p-4">
                <div className="text-sm font-semibold">{a}</div>
                <div className="text-xs text-ink-400">{b}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
      <div className="flex items-center justify-center p-6">
        <form onSubmit={submit} className="w-full max-w-sm">
          <div className="mb-8 flex items-center gap-3 lg:hidden">
            <img src="./logo.png" className="h-10 w-10 rounded-xl" alt="" />
            <span className="text-lg font-bold">Shifty Admin</span>
          </div>
          <span className="inline-flex h-12 w-12 items-center justify-center rounded-2xl bg-brand-50 text-brand-500 dark:bg-brand-900/30">
            <ShieldCheck />
          </span>
          <h2 className="mt-5 text-2xl font-bold">{mode === 'login' ? 'Sign in' : 'Reset password'}</h2>
          <p className="mt-1 text-sm text-ink-500">{mode === 'login' ? 'For Shifty team members only.' : 'We’ll email you a link to set a new password.'}</p>
          <label className="label mt-8">Email</label>
          <input className="input h-12" type="email" autoComplete="username" required value={email} onChange={(e) => setEmail(e.target.value)} />
          {mode === 'login' && (
            <>
              <label className="label mt-5">Password</label>
              <div className="relative">
                <input
                  className="input h-12 pr-11"
                  type={show ? 'text' : 'password'}
                  autoComplete="current-password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                />
                <button type="button" onClick={() => setShow(!show)} className="absolute right-3 top-1/2 -translate-y-1/2 text-ink-400">
                  {show ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </>
          )}
          {error && <p className="mt-4 rounded-xl bg-red-50 px-3 py-2 text-sm text-red-600 dark:bg-red-900/30 dark:text-red-300">{error}</p>}
          <Button className="mt-6 h-12 w-full" loading={busy} icon={!busy && <ArrowRight className="h-4 w-4" />}>
            {mode === 'login' ? 'Sign in' : 'Send reset link'}
          </Button>
          <button type="button" className="mt-4 w-full text-center text-sm font-semibold text-brand-600" onClick={() => setMode(mode === 'login' ? 'reset' : 'login')}>
            {mode === 'login' ? 'Forgot password?' : 'Back to sign in'}
          </button>
        </form>
      </div>
    </div>
  )
}
