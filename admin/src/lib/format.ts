const ngn = new Intl.NumberFormat('en-NG', { maximumFractionDigits: 0 })

export const money = (v?: number | string | null) => `₦${ngn.format(Number(v ?? 0))}`
export const compactMoney = (v?: number | string | null) => {
  const n = Number(v ?? 0)
  if (Math.abs(n) >= 1_000_000) return `₦${(n / 1_000_000).toFixed(1).replace(/\.0$/, '')}m`
  if (Math.abs(n) >= 1_000) return `₦${(n / 1_000).toFixed(1).replace(/\.0$/, '')}k`
  return `₦${ngn.format(n)}`
}
export const num = (v?: number | string | null) => ngn.format(Number(v ?? 0))

export const date = (v?: string | null) => (v ? new Date(v).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' }) : '—')
export const dateTime = (v?: string | null) =>
  v ? new Date(v).toLocaleString('en-GB', { day: 'numeric', month: 'short', hour: 'numeric', minute: '2-digit' }) : '—'
export const time = (v?: string | null) => (v ? new Date(v).toLocaleTimeString('en-GB', { hour: 'numeric', minute: '2-digit' }) : '')

export function ago(v?: string | null) {
  if (!v) return '—'
  const s = (Date.now() - new Date(v).getTime()) / 1000
  if (s < 60) return 'just now'
  if (s < 3600) return `${Math.floor(s / 60)}m ago`
  if (s < 86400) return `${Math.floor(s / 3600)}h ago`
  if (s < 86400 * 7) return `${Math.floor(s / 86400)}d ago`
  return date(v)
}

export const initials = (name?: string | null) =>
  (name || '?').trim().split(/\s+/).slice(0, 2).map((w) => w[0]?.toUpperCase() ?? '').join('') || '?'

export const titleCase = (s?: string | null) => (s || '').replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())

/** Downloads rows as a CSV file. */
export function downloadCsv(name: string, rows: Record<string, unknown>[]) {
  if (!rows.length) return
  const cols = Object.keys(rows[0])
  const esc = (v: unknown) => {
    const s = v == null ? '' : typeof v === 'object' ? JSON.stringify(v) : String(v)
    return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s
  }
  const csv = [cols.join(','), ...rows.map((r) => cols.map((c) => esc(r[c])).join(','))].join('\n')
  const a = document.createElement('a')
  a.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }))
  a.download = `${name}-${new Date().toISOString().slice(0, 10)}.csv`
  a.click()
  URL.revokeObjectURL(a.href)
}
