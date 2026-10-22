import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react'
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom'
import {
  Activity, BadgeCheck, Bell, BookOpen, CalendarDays, ChartLine, ChevronDown, ClipboardList, Command, CreditCard, FileCheck2, Gift, HandCoins,
  Headphones, HelpCircle, History, LayoutDashboard, ListChecks, LogOut, Map, Megaphone, Menu, MessageSquareWarning, Moon, PanelLeftClose,
  PanelLeftOpen, Receipt, Search, Settings, Share2, ShieldCheck, Star, Sun, Tags, UserCircle2, Users, UsersRound, Wallet, Wrench, X,
} from 'lucide-react'
import { useAuth } from '../lib/auth'
import { db, rpc } from '../lib/supabase'
import { useLocal } from '../lib/hooks'
import { Avatar, cx } from './ui'
import ErrorBoundary from './ErrorBoundary'

export type NavItem = { to: string; label: string; icon: ReactNode; perm: string; badge?: string }
export const NAV: { section: string; items: NavItem[] }[] = [
  {
    section: 'Operations',
    items: [
      { to: '/', label: 'Overview', icon: <LayoutDashboard />, perm: 'dashboard.view' },
      { to: '/dispatch', label: 'Live Dispatch', icon: <Activity />, perm: 'bookings.manage', badge: 'pending' },
      { to: '/bookings', label: 'Bookings', icon: <ClipboardList />, perm: 'bookings.view' },
      { to: '/calendar', label: 'Schedule', icon: <CalendarDays />, perm: 'bookings.view' },
      { to: '/map', label: 'Live Map', icon: <Map />, perm: 'bookings.view' },
    ],
  },
  {
    section: 'People',
    items: [
      { to: '/customers', label: 'Customers', icon: <Users />, perm: 'users.view' },
      { to: '/pros', label: 'Professionals', icon: <Wrench />, perm: 'pros.view' },
      { to: '/applications', label: 'Applications', icon: <ListChecks />, perm: 'verification.manage', badge: 'pros_pending' },
      { to: '/verification', label: 'Verification', icon: <FileCheck2 />, perm: 'verification.manage', badge: 'docs_pending' },
    ],
  },
  {
    section: 'Catalogue',
    items: [
      { to: '/services', label: 'Services', icon: <Tags />, perm: 'catalogue.manage' },
      { to: '/pricing', label: 'Pricing', icon: <Receipt />, perm: 'catalogue.manage' },
      { to: '/offers', label: 'Offers & Promos', icon: <Gift />, perm: 'offers.manage' },
    ],
  },
  {
    section: 'Finance',
    items: [
      { to: '/transactions', label: 'Transactions', icon: <CreditCard />, perm: 'finance.view' },
      { to: '/payouts', label: 'Payouts', icon: <HandCoins />, perm: 'finance.view', badge: 'payouts_pending_count' },
      { to: '/balances', label: 'Pro Balances', icon: <Wallet />, perm: 'finance.view' },
      { to: '/revenue', label: 'Revenue', icon: <ChartLine />, perm: 'finance.view' },
    ],
  },
  {
    section: 'Trust & Support',
    items: [
      { to: '/support', label: 'Support Inbox', icon: <Headphones />, perm: 'support.manage', badge: 'tickets_open' },
      { to: '/chats', label: 'Chat Moderation', icon: <MessageSquareWarning />, perm: 'chat.view' },
      { to: '/reviews', label: 'Reviews', icon: <Star />, perm: 'reviews.manage' },
      { to: '/broadcasts', label: 'Broadcasts', icon: <Megaphone />, perm: 'broadcast.send' },
    ],
  },
  {
    section: 'Insights',
    items: [
      { to: '/analytics', label: 'Analytics', icon: <BadgeCheck />, perm: 'reports.view' },
      { to: '/referrals', label: 'Referrals', icon: <Share2 />, perm: 'users.view' },
    ],
  },
  {
    section: 'System',
    items: [
      { to: '/faqs', label: 'Help Center', icon: <BookOpen />, perm: 'content.manage' },
      { to: '/settings', label: 'Settings', icon: <Settings />, perm: 'settings.manage' },
      { to: '/team', label: 'Admin Team', icon: <UsersRound />, perm: 'admins.manage' },
      { to: '/roles', label: 'Roles & Access', icon: <ShieldCheck />, perm: 'admins.manage' },
      { to: '/audit', label: 'Audit Log', icon: <History />, perm: 'audit.view' },
    ],
  },
]

type Counts = Record<string, number>

export function useTheme() {
  const [dark, setDark] = useState(() => document.documentElement.classList.contains('dark'))
  const toggle = () => {
    const d = !dark
    setDark(d)
    document.documentElement.classList.toggle('dark', d)
    try {
      localStorage.setItem('admin-theme', d ? 'dark' : 'light')
    } catch {}
  }
  return { dark, toggle }
}

export default function Layout() {
  const { me, can, signOut } = useAuth()
  const [collapsed, setCollapsed] = useLocal('admin-collapsed', false)
  const [mobile, setMobile] = useState(false)
  const [counts, setCounts] = useState<Counts>({})
  const [palette, setPalette] = useState(false)
  const loc = useLocation()

  useEffect(() => setMobile(false), [loc.pathname])

  useEffect(() => {
    let alive = true
    const load = () =>
      rpc<Counts>('admin_overview', { p_days: 1 })
        .then((c) => alive && setCounts(c))
        .catch(() => {})
    load()
    const t = setInterval(load, 60_000)
    // Live refresh when bookings, payouts or support change.
    const ch = db
      .channel('admin-counts')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'bookings' }, load)
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'support_messages' }, load)
      .subscribe()
    return () => {
      alive = false
      clearInterval(t)
      db.removeChannel(ch)
    }
  }, [])

  useEffect(() => {
    const k = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault()
        setPalette(true)
      }
    }
    window.addEventListener('keydown', k)
    return () => window.removeEventListener('keydown', k)
  }, [])

  const nav = NAV.map((s) => ({ ...s, items: s.items.filter((i) => can(i.perm)) })).filter((s) => s.items.length)

  const sidebar = (mini: boolean) => (
    <div className="flex h-full flex-col bg-ink-900 text-ink-200">
      <div className={cx('flex h-16 shrink-0 items-center gap-3 px-5', mini && 'justify-center px-0')}>
        <img src="./logo.png" alt="" className="h-9 w-9 rounded-xl" />
        {!mini && (
          <div className="leading-tight">
            <div className="text-[15px] font-bold text-white">Shifty Admin</div>
            <div className="text-[11px] text-ink-400">Control centre</div>
          </div>
        )}
      </div>
      <nav className="scrollbar-thin flex-1 overflow-y-auto px-3 pb-4">
        {nav.map((s) => (
          <div key={s.section} className="mt-4">
            {!mini && <div className="mb-1.5 px-3 text-[11px] font-semibold uppercase tracking-wider text-ink-500">{s.section}</div>}
            {s.items.map((i) => {
              const n = i.badge ? Number(counts[i.badge] ?? 0) : 0
              return (
                <NavLink
                  key={i.to}
                  to={i.to}
                  end={i.to === '/'}
                  title={mini ? i.label : undefined}
                  className={({ isActive }) =>
                    cx(
                      'group relative mb-0.5 flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition [&>svg]:h-[18px] [&>svg]:w-[18px] [&>svg]:shrink-0',
                      mini && 'justify-center',
                      isActive ? 'bg-brand-500 text-white shadow-lg shadow-brand-500/25' : 'text-ink-300 hover:bg-white/5 hover:text-white',
                    )
                  }
                >
                  {i.icon}
                  {!mini && <span className="flex-1 truncate">{i.label}</span>}
                  {n > 0 &&
                    (mini ? (
                      <span className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-brand-400" />
                    ) : (
                      <span className="rounded-full bg-white/10 px-2 text-[11px] font-bold leading-5 text-white">{n}</span>
                    ))}
                </NavLink>
              )
            })}
          </div>
        ))}
      </nav>
      {!mini && (
        <div className="m-3 rounded-2xl bg-gradient-to-br from-brand-500 to-brand-700 p-4 text-white">
          <div className="text-sm font-bold">Need to dispatch?</div>
          <p className="mt-1 text-xs text-white/80">{counts.pending ?? 0} bookings are waiting for a professional.</p>
          <NavLink to="/dispatch" className="mt-3 inline-flex rounded-lg bg-white px-3 py-1.5 text-xs font-bold text-brand-600">
            Open dispatch
          </NavLink>
        </div>
      )}
    </div>
  )

  return (
    <div className="flex h-full">
      <aside className={cx('hidden shrink-0 transition-all duration-300 lg:block', collapsed ? 'w-[76px]' : 'w-[260px]')}>{sidebar(collapsed)}</aside>
      {mobile && (
        <div className="fixed inset-0 z-40 lg:hidden" onClick={() => setMobile(false)}>
          <div className="absolute inset-0 bg-ink-950/60" />
          <div className="relative h-full w-[270px]" onClick={(e) => e.stopPropagation()}>
            {sidebar(false)}
          </div>
        </div>
      )}
      <div className="flex min-w-0 flex-1 flex-col">
        <Header
          counts={counts}
          onMenu={() => setMobile(true)}
          collapsed={collapsed}
          onCollapse={() => setCollapsed(!collapsed)}
          onSearch={() => setPalette(true)}
          name={me?.name ?? me?.email ?? ''}
          role={me?.role_name ?? ''}
          avatar={me?.avatar}
          onSignOut={signOut}
        />
        <main className="scrollbar-thin flex-1 overflow-y-auto">
          <div className="mx-auto max-w-[1440px] p-4 sm:p-6 lg:p-8">
            <ErrorBoundary resetKey={loc.pathname}>
              <Outlet context={{ counts }} />
            </ErrorBoundary>
          </div>
        </main>
      </div>
      {palette && <CommandPalette onClose={() => setPalette(false)} nav={nav.flatMap((s) => s.items)} />}
    </div>
  )
}

function Header(p: {
  counts: Counts
  onMenu: () => void
  collapsed: boolean
  onCollapse: () => void
  onSearch: () => void
  name: string
  role: string
  avatar?: string | null
  onSignOut: () => void
}) {
  const { dark, toggle } = useTheme()
  const [bell, setBell] = useState(false)
  const [menu, setMenu] = useState(false)
  const nav = useNavigate()
  const c = p.counts
  const alerts = [
    { n: c.pros_pending, text: 'professional applications to review', to: '/applications' },
    { n: c.docs_pending, text: 'documents waiting for verification', to: '/verification' },
    { n: c.unassigned_old, text: 'bookings unassigned for 30+ minutes', to: '/dispatch' },
    { n: c.payouts_pending_count, text: 'payout requests to process', to: '/payouts' },
    { n: c.tickets_open, text: 'open support conversations', to: '/support' },
  ].filter((a) => Number(a.n) > 0)
  const hour = new Date().getHours()

  return (
    <header className="sticky top-0 z-30 flex h-16 shrink-0 items-center gap-3 border-b border-ink-100 bg-white/85 px-4 backdrop-blur dark:border-ink-800 dark:bg-ink-950/85 sm:px-6">
      <button className="rounded-xl p-2 hover:bg-ink-100 dark:hover:bg-ink-800 lg:hidden" onClick={p.onMenu}>
        <Menu className="h-5 w-5" />
      </button>
      <button className="hidden rounded-xl p-2 text-ink-500 hover:bg-ink-100 dark:hover:bg-ink-800 lg:block" onClick={p.onCollapse}>
        {p.collapsed ? <PanelLeftOpen className="h-5 w-5" /> : <PanelLeftClose className="h-5 w-5" />}
      </button>
      <button
        onClick={p.onSearch}
        className="flex h-10 min-w-0 flex-1 items-center gap-2 md:max-w-md rounded-xl border border-ink-200 bg-ink-50 px-3 text-sm text-ink-400 transition hover:border-ink-300 dark:border-ink-800 dark:bg-ink-900"
      >
        <Search className="h-4 w-4" />
        <span className="flex-1 truncate text-left"><span className="sm:hidden">Search</span><span className="hidden sm:inline">Search bookings, people, pages…</span></span>
        <kbd className="hidden items-center gap-0.5 rounded-md border border-ink-200 px-1.5 py-0.5 text-[10px] font-semibold dark:border-ink-700 sm:flex">
          <Command className="h-3 w-3" />K
        </kbd>
      </button>
      <div className="hidden flex-1 xl:block">
        <span className="text-sm text-ink-500">{hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening'}, </span>
        <span className="text-sm font-semibold">{p.name.split(' ')[0]}</span>
      </div>
      <div className="ml-auto flex shrink-0 items-center gap-0.5 sm:gap-1">
        <button className="hidden rounded-xl p-2.5 text-ink-500 hover:bg-ink-100 dark:hover:bg-ink-800 sm:block" onClick={toggle} title="Toggle theme">
          {dark ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
        </button>
        <div className="relative">
          <button className="relative rounded-xl p-2.5 text-ink-500 hover:bg-ink-100 dark:hover:bg-ink-800" onClick={() => setBell(!bell)}>
            <Bell className="h-5 w-5" />
            {alerts.length > 0 && <span className="absolute right-2 top-2 h-2 w-2 rounded-full bg-brand-500 ring-2 ring-white dark:ring-ink-950" />}
          </button>
          {bell && (
            <>
              <div className="fixed inset-0 z-10" onClick={() => setBell(false)} />
              <div className="card absolute right-0 z-20 mt-2 w-80 overflow-hidden shadow-xl">
                <div className="border-b border-ink-100 px-4 py-3 text-sm font-bold dark:border-ink-800">Needs attention</div>
                {alerts.length === 0 && <p className="p-6 text-center text-sm text-ink-500">All clear. Nothing waiting.</p>}
                {alerts.map((a) => (
                  <button
                    key={a.to}
                    onClick={() => {
                      setBell(false)
                      nav(a.to)
                    }}
                    className="flex w-full items-center gap-3 px-4 py-3 text-left text-sm hover:bg-ink-50 dark:hover:bg-ink-800"
                  >
                    <span className="flex h-8 min-w-8 items-center justify-center rounded-lg bg-brand-50 px-2 text-xs font-bold text-brand-600 dark:bg-brand-900/30">{a.n}</span>
                    {a.text}
                  </button>
                ))}
              </div>
            </>
          )}
        </div>
        <div className="relative">
          <button className="flex items-center gap-2.5 rounded-xl py-1.5 pl-1.5 pr-2 hover:bg-ink-100 dark:hover:bg-ink-800" onClick={() => setMenu(!menu)}>
            <Avatar name={p.name} url={p.avatar} size={34} />
            <div className="hidden text-left leading-tight sm:block">
              <div className="max-w-[140px] truncate text-sm font-semibold">{p.name}</div>
              <div className="text-[11px] text-ink-500">{p.role}</div>
            </div>
            <ChevronDown className="hidden h-4 w-4 text-ink-400 sm:block" />
          </button>
          {menu && (
            <>
              <div className="fixed inset-0 z-10" onClick={() => setMenu(false)} />
              <div className="card absolute right-0 z-20 mt-2 w-56 overflow-hidden p-1.5 shadow-xl">
                <MenuBtn icon={<UserCircle2 />} label="My account" onClick={() => (setMenu(false), nav('/account'))} />
                <MenuBtn icon={<HelpCircle />} label="Open customer app" onClick={() => window.open('../', '_blank')} />
                <MenuBtn icon={<LogOut />} label="Sign out" danger onClick={p.onSignOut} />
              </div>
            </>
          )}
        </div>
      </div>
    </header>
  )
}

function MenuBtn({ icon, label, onClick, danger }: { icon: ReactNode; label: string; onClick: () => void; danger?: boolean }) {
  return (
    <button
      onClick={onClick}
      className={cx(
        'flex w-full items-center gap-2.5 rounded-lg px-3 py-2 text-sm font-medium hover:bg-ink-50 dark:hover:bg-ink-800 [&>svg]:h-4 [&>svg]:w-4',
        danger && 'text-red-500',
      )}
    >
      {icon}
      {label}
    </button>
  )
}

type Hit = { kind: string; label: string; sub?: string; to: string }

function CommandPalette({ onClose, nav }: { onClose: () => void; nav: NavItem[] }) {
  const [term, setTerm] = useState('')
  const [hits, setHits] = useState<Hit[]>([])
  const [idx, setIdx] = useState(0)
  const go = useNavigate()
  const { can } = useAuth()
  const input = useRef<HTMLInputElement>(null)

  useEffect(() => input.current?.focus(), [])

  const pages: Hit[] = useMemo(
    () => [...nav.map((n) => ({ kind: 'Page', label: n.label, to: n.to })), { kind: 'Page', label: 'My account', to: '/account' }],
    [nav],
  )

  useEffect(() => {
    const t = term.trim()
    const pageHits = pages.filter((p) => !t || p.label.toLowerCase().includes(t.toLowerCase()))
    if (t.length < 2) {
      setHits(pageHits)
      setIdx(0)
      return
    }
    let alive = true
    const timer = setTimeout(async () => {
      const like = `%${t.replace(/[%_,()]/g, '')}%`
      const out: Hit[] = [...pageHits]
      try {
        if (can('bookings.view')) {
          const { data } = await db.from('bookings').select('id, reference, service_name, status').or(`reference.ilike.${like},service_name.ilike.${like},address.ilike.${like}`).limit(6)
          data?.forEach((b) => out.push({ kind: 'Booking', label: `#${b.reference} · ${b.service_name}`, sub: b.status, to: `/bookings/${b.id}` }))
        }
        if (can('users.view')) {
          const { data } = await db.from('profiles').select('id, full_name, email, is_professional').or(`full_name.ilike.${like},email.ilike.${like},phone.ilike.${like}`).limit(6)
          data?.forEach((u) =>
            out.push({ kind: u.is_professional ? 'Professional' : 'Customer', label: u.full_name || u.email, sub: u.email, to: u.is_professional ? `/pros/${u.id}` : `/customers/${u.id}` }),
          )
        }
      } catch {}
      if (alive) {
        setHits(out)
        setIdx(0)
      }
    }, 220)
    return () => {
      alive = false
      clearTimeout(timer)
    }
  }, [term, pages, can])

  const pick = (h?: Hit) => {
    if (!h) return
    go(h.to)
    onClose()
  }

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center bg-ink-950/50 p-4 pt-[12vh] backdrop-blur-sm" onMouseDown={onClose}>
      <div className="card w-full max-w-xl overflow-hidden shadow-2xl" onMouseDown={(e) => e.stopPropagation()}>
        <div className="flex items-center gap-3 border-b border-ink-100 px-4 dark:border-ink-800">
          <Search className="h-5 w-5 text-ink-400" />
          <input
            ref={input}
            className="h-14 flex-1 bg-transparent text-base outline-none"
            placeholder="Type a booking reference, name, email or page…"
            value={term}
            onChange={(e) => setTerm(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'ArrowDown') setIdx((i) => Math.min(i + 1, hits.length - 1))
              if (e.key === 'ArrowUp') setIdx((i) => Math.max(i - 1, 0))
              if (e.key === 'Enter') pick(hits[idx])
              if (e.key === 'Escape') onClose()
            }}
          />
          <button onClick={onClose}>
            <X className="h-4 w-4 text-ink-400" />
          </button>
        </div>
        <div className="scrollbar-thin max-h-[50vh] overflow-y-auto p-2">
          {hits.length === 0 && <p className="p-6 text-center text-sm text-ink-500">No results</p>}
          {hits.map((h, i) => (
            <button
              key={h.kind + h.to + h.label}
              onMouseEnter={() => setIdx(i)}
              onClick={() => pick(h)}
              className={cx('flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left', i === idx && 'bg-brand-50 dark:bg-ink-800')}
            >
              <span className="w-24 shrink-0 text-[11px] font-semibold uppercase tracking-wide text-ink-400">{h.kind}</span>
              <span className="flex-1 truncate text-sm font-medium">{h.label}</span>
              {h.sub && <span className="truncate text-xs text-ink-400">{h.sub}</span>}
            </button>
          ))}
        </div>
      </div>
    </div>
  )
}
