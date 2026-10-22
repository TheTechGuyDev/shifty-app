import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import { createPortal } from 'react-dom'
import { AlertTriangle, ArrowDown, ArrowUp, CheckCircle2, ChevronLeft, ChevronRight, Download, Inbox, Loader2, Search, X, XCircle } from 'lucide-react'
import { downloadCsv, initials } from '../lib/format'

export const cx = (...c: (string | false | null | undefined)[]) => c.filter(Boolean).join(' ')

// ---------- Buttons ----------
type BtnProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger' | 'success' | 'dark'
  size?: 'sm' | 'md'
  loading?: boolean
  icon?: ReactNode
}
export function Button({ variant = 'primary', size = 'md', loading, icon, className, children, disabled, ...rest }: BtnProps) {
  const v = {
    primary: 'bg-brand-500 text-white hover:bg-brand-600 shadow-sm shadow-brand-500/20',
    secondary: 'border border-ink-200 bg-white text-ink-800 hover:bg-ink-50 dark:border-ink-700 dark:bg-ink-850 dark:text-ink-100 dark:hover:bg-ink-800',
    ghost: 'text-ink-600 hover:bg-ink-100 dark:text-ink-300 dark:hover:bg-ink-800',
    danger: 'bg-red-500 text-white hover:bg-red-600',
    success: 'bg-emerald-500 text-white hover:bg-emerald-600',
    dark: 'bg-ink-900 text-white hover:bg-ink-800 dark:bg-white dark:text-ink-900',
  }[variant]
  const s = size === 'sm' ? 'h-8 px-3 text-xs gap-1.5 rounded-lg' : 'h-10 px-4 text-sm gap-2 rounded-xl'
  return (
    <button
      {...rest}
      disabled={disabled || loading}
      className={cx('inline-flex items-center justify-center font-semibold transition active:scale-[.98] disabled:cursor-not-allowed disabled:opacity-50', v, s, className)}
    >
      {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : icon}
      {children}
    </button>
  )
}

export function IconButton({ className, ...rest }: React.ButtonHTMLAttributes<HTMLButtonElement>) {
  return (
    <button
      {...rest}
      className={cx('inline-flex h-9 w-9 items-center justify-center rounded-xl text-ink-500 transition hover:bg-ink-100 hover:text-ink-900 dark:hover:bg-ink-800 dark:hover:text-white', className)}
    />
  )
}

// ---------- Badges ----------
const tones = {
  gray: 'bg-ink-100 text-ink-600 dark:bg-ink-800 dark:text-ink-300',
  orange: 'bg-brand-50 text-brand-600 dark:bg-brand-900/30 dark:text-brand-300',
  green: 'bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300',
  red: 'bg-red-50 text-red-600 dark:bg-red-900/30 dark:text-red-300',
  blue: 'bg-blue-50 text-blue-600 dark:bg-blue-900/30 dark:text-blue-300',
  yellow: 'bg-amber-50 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300',
  purple: 'bg-violet-50 text-violet-600 dark:bg-violet-900/30 dark:text-violet-300',
}
export type Tone = keyof typeof tones
export function Badge({ tone = 'gray', children, dot }: { tone?: Tone; children: ReactNode; dot?: boolean }) {
  return (
    <span className={cx('inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-semibold', tones[tone])}>
      {dot && <span className="h-1.5 w-1.5 rounded-full bg-current" />}
      {children}
    </span>
  )
}

export const statusTone = (s?: string | null): Tone =>
  (({
    pending: 'yellow', active: 'blue', done: 'green', cancelled: 'red', approved: 'green', rejected: 'red', draft: 'gray',
    paid: 'green', unpaid: 'yellow', refunded: 'purple', requested: 'yellow', processing: 'blue', published: 'green', hidden: 'gray',
    open: 'orange', closed: 'gray', sent: 'blue', quoted: 'purple', accepted: 'green', declined: 'red', expired: 'gray',
    urgent: 'red', high: 'orange', normal: 'blue', low: 'gray', suspended: 'red',
  } as Record<string, Tone>)[s ?? ''] ?? 'gray')

// ---------- Avatar ----------
export function Avatar({ name, url, size = 36 }: { name?: string | null; url?: string | null; size?: number }) {
  const palette = ['#FD6B22', '#3F8CFF', '#4FBF67', '#8B5CF6', '#F59E0B', '#EC4899', '#14B8A6']
  const color = palette[(name || '?').split('').reduce((a, c) => a + c.charCodeAt(0), 0) % palette.length]
  return url ? (
    <img src={url} alt="" className="shrink-0 rounded-full object-cover" style={{ width: size, height: size }} />
  ) : (
    <span
      className="inline-flex shrink-0 items-center justify-center rounded-full font-bold text-white"
      style={{ width: size, height: size, background: color, fontSize: size * 0.36 }}
    >
      {initials(name)}
    </span>
  )
}

// ---------- Layout bits ----------
export function PageHeader({ title, subtitle, actions }: { title: string; subtitle?: ReactNode; actions?: ReactNode }) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-4">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">{title}</h1>
        {subtitle && <p className="mt-1 text-sm text-ink-500 dark:text-ink-400">{subtitle}</p>}
      </div>
      {actions && <div className="flex flex-wrap items-center gap-2">{actions}</div>}
    </div>
  )
}

export function Card({ title, subtitle, actions, children, className, pad = true }: { title?: ReactNode; subtitle?: ReactNode; actions?: ReactNode; children: ReactNode; className?: string; pad?: boolean }) {
  return (
    <section className={cx('card', className)}>
      {(title || actions) && (
        <div className="flex items-start justify-between gap-3 px-5 pt-5">
          <div>
            {title && <h2 className="text-base font-bold">{title}</h2>}
            {subtitle && <p className="mt-0.5 text-xs text-ink-500 dark:text-ink-400">{subtitle}</p>}
          </div>
          {actions}
        </div>
      )}
      <div className={cx(pad && 'p-5')}>{children}</div>
    </section>
  )
}

export function Stat({ label, value, icon, tone = 'orange', hint, onClick }: { label: string; value: ReactNode; icon: ReactNode; tone?: Tone; hint?: ReactNode; onClick?: () => void }) {
  return (
    <button onClick={onClick} disabled={!onClick} className="card group flex min-w-0 flex-col p-4 text-left sm:p-5 transition enabled:hover:-translate-y-0.5 enabled:hover:shadow-lg disabled:cursor-default">
      <div className="flex items-center gap-3">
        <span className={cx('inline-flex h-10 w-10 items-center justify-center rounded-xl', tones[tone])}>{icon}</span>
        <span className="text-xs font-medium text-ink-500 dark:text-ink-400 sm:text-sm">{label}</span>
      </div>
      <div className="mt-4 truncate text-xl font-bold tracking-tight sm:text-2xl">{value}</div>
      {hint && <div className="mt-1 text-xs text-ink-500 dark:text-ink-400">{hint}</div>}
    </button>
  )
}

export function Spinner({ className }: { className?: string }) {
  return <Loader2 className={cx('h-5 w-5 animate-spin text-brand-500', className)} />
}

export function Loading({ h = 240 }: { h?: number }) {
  return (
    <div className="flex items-center justify-center" style={{ height: h }}>
      <Spinner className="h-7 w-7" />
    </div>
  )
}

export function ErrorBox({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 p-10 text-center">
      <AlertTriangle className="h-8 w-8 text-red-500" />
      <p className="max-w-md text-sm text-ink-600 dark:text-ink-300">{message}</p>
      {onRetry && (
        <Button size="sm" variant="secondary" onClick={onRetry}>
          Try again
        </Button>
      )}
    </div>
  )
}

export function Empty({ title, message, icon, action }: { title: string; message?: string; icon?: ReactNode; action?: ReactNode }) {
  return (
    <div className="flex flex-col items-center justify-center gap-2 px-6 py-14 text-center">
      <span className="mb-2 inline-flex h-14 w-14 items-center justify-center rounded-2xl bg-brand-50 text-brand-500 dark:bg-brand-900/30">{icon ?? <Inbox />}</span>
      <p className="font-semibold">{title}</p>
      {message && <p className="max-w-sm text-sm text-ink-500 dark:text-ink-400">{message}</p>}
      {action && <div className="mt-3">{action}</div>}
    </div>
  )
}

export function Tabs<T extends string>({ value, onChange, items }: { value: T; onChange: (v: T) => void; items: { value: T; label: string; count?: number }[] }) {
  return (
    <div className="scrollbar-thin flex gap-1 overflow-x-auto rounded-xl bg-ink-100 p-1 dark:bg-ink-850">
      {items.map((i) => (
        <button
          key={i.value}
          onClick={() => onChange(i.value)}
          className={cx(
            'flex shrink-0 items-center gap-2 rounded-lg px-3.5 py-1.5 text-sm font-semibold transition',
            value === i.value ? 'bg-white text-ink-900 shadow-sm dark:bg-ink-700 dark:text-white' : 'text-ink-500 hover:text-ink-800 dark:hover:text-ink-200',
          )}
        >
          {i.label}
          {i.count != null && (
            <span className={cx('rounded-full px-1.5 text-[11px]', value === i.value ? 'bg-brand-500 text-white' : 'bg-ink-200 dark:bg-ink-700')}>{i.count}</span>
          )}
        </button>
      ))}
    </div>
  )
}

// ---------- Form fields ----------
export function Field({ label, children, hint }: { label: string; children: ReactNode; hint?: ReactNode }) {
  return (
    <label className="block">
      <span className="label">{label}</span>
      {children}
      {hint && <span className="mt-1 block text-xs text-ink-500">{hint}</span>}
    </label>
  )
}

export function Toggle({ checked, onChange, disabled }: { checked: boolean; onChange: (v: boolean) => void; disabled?: boolean }) {
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={() => onChange(!checked)}
      className={cx('relative h-6 w-11 shrink-0 rounded-full transition disabled:opacity-50', checked ? 'bg-brand-500' : 'bg-ink-200 dark:bg-ink-700')}
    >
      <span className={cx('absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-all', checked ? 'left-[22px]' : 'left-0.5')} />
    </button>
  )
}

export function SearchInput({ value, onChange, placeholder = 'Search…', className }: { value: string; onChange: (v: string) => void; placeholder?: string; className?: string }) {
  return (
    <div className={cx('relative', className)}>
      <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-400" />
      <input className="input pl-9" value={value} placeholder={placeholder} onChange={(e) => onChange(e.target.value)} />
    </div>
  )
}

// ---------- Modal / drawer ----------
export function Modal({ open, onClose, title, children, footer, wide }: { open: boolean; onClose: () => void; title: ReactNode; children: ReactNode; footer?: ReactNode; wide?: boolean }) {
  useEffect(() => {
    if (!open) return
    const k = (e: KeyboardEvent) => e.key === 'Escape' && onClose()
    window.addEventListener('keydown', k)
    return () => window.removeEventListener('keydown', k)
  }, [open, onClose])
  if (!open) return null
  return createPortal(
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-ink-950/50 p-0 backdrop-blur-sm sm:items-center sm:p-4" onMouseDown={onClose}>
      <div
        onMouseDown={(e) => e.stopPropagation()}
        className={cx('card max-h-[92vh] w-full overflow-hidden rounded-b-none sm:rounded-2xl', wide ? 'sm:max-w-3xl' : 'sm:max-w-lg')}
      >
        <div className="flex items-center justify-between border-b border-ink-100 px-5 py-4 dark:border-ink-800">
          <h3 className="text-base font-bold">{title}</h3>
          <IconButton onClick={onClose}>
            <X className="h-4 w-4" />
          </IconButton>
        </div>
        <div className="scrollbar-thin max-h-[70vh] overflow-y-auto p-5">{children}</div>
        {footer && <div className="flex justify-end gap-2 border-t border-ink-100 px-5 py-4 dark:border-ink-800">{footer}</div>}
      </div>
    </div>,
    document.body,
  )
}

export function Drawer({ open, onClose, title, children, footer }: { open: boolean; onClose: () => void; title: ReactNode; children: ReactNode; footer?: ReactNode }) {
  useEffect(() => {
    if (!open) return
    const k = (e: KeyboardEvent) => e.key === 'Escape' && onClose()
    window.addEventListener('keydown', k)
    return () => window.removeEventListener('keydown', k)
  }, [open, onClose])
  if (!open) return null
  return createPortal(
    <div className="fixed inset-0 z-50 flex justify-end bg-ink-950/40 backdrop-blur-sm" onMouseDown={onClose}>
      <div onMouseDown={(e) => e.stopPropagation()} className="flex h-full w-full max-w-xl flex-col bg-white shadow-2xl dark:bg-ink-900">
        <div className="flex items-center justify-between border-b border-ink-100 px-6 py-4 dark:border-ink-800">
          <h3 className="text-lg font-bold">{title}</h3>
          <IconButton onClick={onClose}>
            <X className="h-4 w-4" />
          </IconButton>
        </div>
        <div className="scrollbar-thin flex-1 overflow-y-auto p-6">{children}</div>
        {footer && <div className="flex flex-wrap justify-end gap-2 border-t border-ink-100 px-6 py-4 dark:border-ink-800">{footer}</div>}
      </div>
    </div>,
    document.body,
  )
}

// ---------- Toasts and confirm ----------
type Toast = { id: number; kind: 'ok' | 'error'; text: string }
type UiCtx = {
  toast: (text: string, kind?: 'ok' | 'error') => void
  confirm: (o: { title: string; message?: string; confirm?: string; danger?: boolean; input?: string; inputRequired?: boolean }) => Promise<string | false>
}
const Ui = createContext<UiCtx>(null as unknown as UiCtx)
export const useUi = () => useContext(Ui)

export function UiProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([])
  const [dlg, setDlg] = useState<null | (Parameters<UiCtx['confirm']>[0] & { resolve: (v: string | false) => void })>(null)
  const [text, setText] = useState('')

  const toast = useCallback((t: string, kind: 'ok' | 'error' = 'ok') => {
    const id = Date.now() + Math.random()
    setToasts((x) => [...x, { id, kind, text: t }])
    setTimeout(() => setToasts((x) => x.filter((y) => y.id !== id)), 4200)
  }, [])

  const confirm = useCallback<UiCtx['confirm']>((o) => {
    setText('')
    return new Promise((resolve) => setDlg({ ...o, resolve }))
  }, [])

  const close = (v: string | false) => {
    dlg?.resolve(v)
    setDlg(null)
  }

  return (
    <Ui.Provider value={{ toast, confirm }}>
      {children}
      {createPortal(
        <div className="pointer-events-none fixed bottom-4 right-4 z-[60] flex w-[calc(100%-2rem)] max-w-sm flex-col gap-2">
          {toasts.map((t) => (
            <div key={t.id} className="card pointer-events-auto flex items-start gap-3 p-4 shadow-xl">
              {t.kind === 'ok' ? <CheckCircle2 className="h-5 w-5 shrink-0 text-emerald-500" /> : <XCircle className="h-5 w-5 shrink-0 text-red-500" />}
              <p className="text-sm">{t.text}</p>
            </div>
          ))}
        </div>,
        document.body,
      )}
      <Modal
        open={!!dlg}
        onClose={() => close(false)}
        title={dlg?.title}
        footer={
          <>
            <Button variant="secondary" onClick={() => close(false)}>
              Cancel
            </Button>
            <Button variant={dlg?.danger ? 'danger' : 'primary'} disabled={!!dlg?.inputRequired && text.trim().length < 2} onClick={() => close(text.trim() || 'yes')}>
              {dlg?.confirm ?? 'Confirm'}
            </Button>
          </>
        }
      >
        {dlg?.message && <p className="text-sm text-ink-600 dark:text-ink-300">{dlg.message}</p>}
        {dlg?.input != null && (
          <textarea autoFocus className="input mt-4 h-24 py-2" placeholder={dlg.input} value={text} onChange={(e) => setText(e.target.value)} />
        )}
      </Modal>
    </Ui.Provider>
  )
}

/** Wraps an async action with toasts. */
export function useAction() {
  const { toast } = useUi()
  const [busy, setBusy] = useState<string | null>(null)
  const run = async (key: string, fn: () => Promise<unknown>, ok?: string) => {
    setBusy(key)
    try {
      await fn()
      if (ok) toast(ok)
      return true
    } catch (e) {
      toast(e instanceof Error ? e.message : String(e), 'error')
      return false
    } finally {
      setBusy(null)
    }
  }
  return { busy, run }
}

// ---------- Data table ----------
export type Column<T> = {
  key: string
  label: string
  render?: (row: T) => ReactNode
  sort?: (row: T) => string | number
  className?: string
  csv?: (row: T) => unknown
}

export function DataTable<T extends Record<string, any>>({
  rows,
  columns,
  onRow,
  search,
  pageSize = 15,
  exportName,
  toolbar,
  empty,
  selectable,
  bulk,
}: {
  rows: T[]
  columns: Column<T>[]
  onRow?: (row: T) => void
  search?: (row: T) => string
  pageSize?: number
  exportName?: string
  toolbar?: ReactNode
  empty?: ReactNode
  selectable?: (row: T) => string
  bulk?: (ids: string[], clear: () => void) => ReactNode
}) {
  const [term, setTerm] = useState('')
  const [page, setPage] = useState(0)
  const [sortKey, setSortKey] = useState<string | null>(null)
  const [asc, setAsc] = useState(false)
  const [sel, setSel] = useState<Set<string>>(new Set())

  const filtered = useMemo(() => {
    let r = rows
    if (term && search) {
      const t = term.toLowerCase()
      r = r.filter((x) => search(x).toLowerCase().includes(t))
    }
    const col = columns.find((c) => c.key === sortKey)
    if (col?.sort) {
      const f = col.sort
      r = [...r].sort((a, b) => {
        const x = f(a)
        const y = f(b)
        return (x > y ? 1 : x < y ? -1 : 0) * (asc ? 1 : -1)
      })
    }
    return r
  }, [rows, term, search, sortKey, asc, columns])

  useEffect(() => setPage(0), [term, rows.length])
  const pages = Math.max(1, Math.ceil(filtered.length / pageSize))
  const view = filtered.slice(page * pageSize, page * pageSize + pageSize)

  const doExport = () =>
    downloadCsv(
      exportName || 'export',
      filtered.map((r) => Object.fromEntries(columns.map((c) => [c.label, c.csv ? c.csv(r) : c.sort ? c.sort(r) : (r as any)[c.key]]))),
    )

  return (
    <div className="card overflow-hidden">
      {(search || exportName || toolbar) && (
        <div className="flex flex-wrap items-center gap-2 border-b border-ink-100 p-4 dark:border-ink-800">
          {search && <SearchInput value={term} onChange={setTerm} className="w-full sm:w-72" />}
          <div className="flex flex-1 flex-wrap items-center gap-2">{toolbar}</div>
          {selectable && bulk && sel.size > 0 && (
            <div className="flex items-center gap-2 rounded-xl bg-brand-50 px-3 py-1.5 dark:bg-brand-900/30">
              <span className="text-xs font-semibold text-brand-700 dark:text-brand-200">{sel.size} selected</span>
              {bulk([...sel], () => setSel(new Set()))}
            </div>
          )}
          {exportName && (
            <Button variant="secondary" size="sm" icon={<Download className="h-3.5 w-3.5" />} onClick={doExport} disabled={!filtered.length}>
              Export CSV
            </Button>
          )}
        </div>
      )}
      <div className="scrollbar-thin overflow-x-auto">
        <table className="w-full">
          <thead className="bg-ink-50/70 dark:bg-ink-850">
            <tr>
              {selectable && (
                <th className="w-10 px-4">
                  <input
                    type="checkbox"
                    className="accent-brand-500"
                    checked={view.length > 0 && view.every((r) => sel.has(selectable(r)))}
                    onChange={(e) => {
                      const n = new Set(sel)
                      view.forEach((r) => (e.target.checked ? n.add(selectable(r)) : n.delete(selectable(r))))
                      setSel(n)
                    }}
                  />
                </th>
              )}
              {columns.map((c) => (
                <th
                  key={c.key}
                  className={cx('th', c.sort && 'cursor-pointer select-none hover:text-ink-800 dark:hover:text-ink-200', c.className)}
                  onClick={() => {
                    if (!c.sort) return
                    if (sortKey === c.key) setAsc(!asc)
                    else {
                      setSortKey(c.key)
                      setAsc(false)
                    }
                  }}
                >
                  <span className="inline-flex items-center gap-1">
                    {c.label}
                    {sortKey === c.key && (asc ? <ArrowUp className="h-3 w-3" /> : <ArrowDown className="h-3 w-3" />)}
                  </span>
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-ink-100 dark:divide-ink-800">
            {view.map((r, i) => (
              <tr
                key={(r.id as string) ?? i}
                onClick={() => onRow?.(r)}
                className={cx('transition', onRow && 'cursor-pointer hover:bg-brand-50/40 dark:hover:bg-ink-850')}
              >
                {selectable && (
                  <td className="px-4" onClick={(e) => e.stopPropagation()}>
                    <input
                      type="checkbox"
                      className="accent-brand-500"
                      checked={sel.has(selectable(r))}
                      onChange={(e) => {
                        const n = new Set(sel)
                        e.target.checked ? n.add(selectable(r)) : n.delete(selectable(r))
                        setSel(n)
                      }}
                    />
                  </td>
                )}
                {columns.map((c) => (
                  <td key={c.key} className={cx('td', c.className)}>
                    {c.render ? c.render(r) : String(r[c.key] ?? '—')}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {!filtered.length && (empty ?? <Empty title="Nothing here yet" message={term ? 'No results match your search.' : undefined} />)}
      {filtered.length > pageSize && (
        <div className="flex items-center justify-between border-t border-ink-100 px-4 py-3 text-sm dark:border-ink-800">
          <span className="text-ink-500">
            {page * pageSize + 1}–{Math.min(filtered.length, (page + 1) * pageSize)} of {filtered.length}
          </span>
          <div className="flex items-center gap-1">
            <IconButton disabled={page === 0} onClick={() => setPage(page - 1)}>
              <ChevronLeft className="h-4 w-4" />
            </IconButton>
            <span className="px-2 text-xs font-semibold">
              {page + 1} / {pages}
            </span>
            <IconButton disabled={page >= pages - 1} onClick={() => setPage(page + 1)}>
              <ChevronRight className="h-4 w-4" />
            </IconButton>
          </div>
        </div>
      )}
    </div>
  )
}

export function Select({ value, onChange, options, className }: { value: string; onChange: (v: string) => void; options: { value: string; label: string }[]; className?: string }) {
  return (
    <select className={cx('input w-auto pr-8', className)} value={value} onChange={(e) => onChange(e.target.value)}>
      {options.map((o) => (
        <option key={o.value} value={o.value}>
          {o.label}
        </option>
      ))}
    </select>
  )
}

export function KeyValue({ items }: { items: [string, ReactNode][] }) {
  return (
    <dl className="grid grid-cols-1 gap-x-6 gap-y-3 sm:grid-cols-2">
      {items.map(([k, v]) => (
        <div key={k}>
          <dt className="text-xs font-semibold uppercase tracking-wide text-ink-400">{k}</dt>
          <dd className="mt-0.5 break-words text-sm">{v ?? '—'}</dd>
        </div>
      ))}
    </dl>
  )
}

export function Stars({ value }: { value: number }) {
  return (
    <span className="inline-flex text-amber-400">
      {[1, 2, 3, 4, 5].map((i) => (
        <span key={i} className={i <= Math.round(value) ? '' : 'text-ink-200 dark:text-ink-700'}>
          ★
        </span>
      ))}
    </span>
  )
}
