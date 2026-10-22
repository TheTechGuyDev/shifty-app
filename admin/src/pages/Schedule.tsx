import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { useLoad } from '../lib/hooks'
import { db, q } from '../lib/supabase'
import { money, time, titleCase } from '../lib/format'
import type { Booking } from '../lib/types'
import { Badge, Button, Card, ErrorBox, IconButton, Loading, PageHeader, cx, statusTone } from '../components/ui'

const key = (d: Date) => `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`

export default function Schedule() {
  const go = useNavigate()
  const [month, setMonth] = useState(() => {
    const d = new Date()
    return new Date(d.getFullYear(), d.getMonth(), 1)
  })
  const [day, setDay] = useState(() => new Date())

  const start = new Date(month.getFullYear(), month.getMonth(), 1)
  const end = new Date(month.getFullYear(), month.getMonth() + 1, 1)
  const data = useLoad(
    () => q<Booking[]>(db.from('bookings').select('*').gte('scheduled_at', start.toISOString()).lt('scheduled_at', end.toISOString()).neq('status', 'cancelled').order('scheduled_at')),
    [month.getTime()],
  )

  const byDay = useMemo(() => {
    const m = new Map<string, Booking[]>()
    data.data?.forEach((b) => {
      const k = key(new Date(b.scheduled_at!))
      m.set(k, [...(m.get(k) ?? []), b])
    })
    return m
  }, [data.data])

  const cells: (Date | null)[] = []
  const lead = (start.getDay() + 6) % 7
  for (let i = 0; i < lead; i++) cells.push(null)
  for (let d = 1; d <= new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate(); d++) cells.push(new Date(month.getFullYear(), month.getMonth(), d))
  const today = key(new Date())
  const list = byDay.get(key(day)) ?? []

  return (
    <div>
      <PageHeader title="Schedule" subtitle="Jobs by the day they are booked for." />
      {data.error && <ErrorBox message={data.error} onRetry={data.reload} />}
      <div className="grid gap-6 xl:grid-cols-3">
        <Card
          className="xl:col-span-2"
          title={month.toLocaleDateString('en-GB', { month: 'long', year: 'numeric' })}
          actions={
            <div className="flex items-center gap-1">
              <IconButton onClick={() => setMonth(new Date(month.getFullYear(), month.getMonth() - 1, 1))}>
                <ChevronLeft className="h-4 w-4" />
              </IconButton>
              <Button
                size="sm"
                variant="secondary"
                onClick={() => {
                  const d = new Date()
                  setMonth(new Date(d.getFullYear(), d.getMonth(), 1))
                  setDay(d)
                }}
              >
                Today
              </Button>
              <IconButton onClick={() => setMonth(new Date(month.getFullYear(), month.getMonth() + 1, 1))}>
                <ChevronRight className="h-4 w-4" />
              </IconButton>
            </div>
          }
        >
          {data.loading && !data.data ? (
            <Loading />
          ) : (
            <div className="grid grid-cols-7 gap-1.5">
              {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) => (
                <div key={d} className="pb-2 text-center text-xs font-semibold uppercase text-ink-400">
                  {d}
                </div>
              ))}
              {cells.map((d, i) => {
                if (!d) return <div key={i} />
                const items = byDay.get(key(d)) ?? []
                const sel = key(d) === key(day)
                return (
                  <button
                    key={i}
                    onClick={() => setDay(d)}
                    className={cx(
                      'flex min-h-[88px] flex-col rounded-xl border p-2 text-left transition',
                      sel ? 'border-brand-500 bg-brand-50 dark:bg-brand-900/20' : 'border-ink-100 hover:border-ink-300 dark:border-ink-800',
                    )}
                  >
                    <span className={cx('text-sm font-semibold', key(d) === today && 'flex h-6 w-6 items-center justify-center rounded-full bg-brand-500 text-white')}>{d.getDate()}</span>
                    <div className="mt-auto space-y-1">
                      {items.slice(0, 2).map((b) => (
                        <div key={b.id} className="hidden truncate rounded-md bg-ink-100 px-1.5 py-0.5 text-[10px] font-medium sm:block dark:bg-ink-800">
                          {time(b.scheduled_at)} {b.service_name}
                        </div>
                      ))}
                      {items.length > 0 && (
                        <div className="text-[11px] font-bold text-brand-600">
                          <span className="sm:hidden">{items.length}</span>
                          <span className="hidden sm:inline">{items.length > 2 ? `+${items.length - 2} more` : ''}</span>
                        </div>
                      )}
                    </div>
                  </button>
                )
              })}
            </div>
          )}
        </Card>
        <Card title={day.toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'long' })} subtitle={`${list.length} jobs`}>
          <div className="space-y-2">
            {list.length === 0 && <p className="py-10 text-center text-sm text-ink-500">No jobs on this day</p>}
            {list.map((b) => (
              <button key={b.id} onClick={() => go(`/bookings/${b.id}`)} className="flex w-full items-center gap-3 rounded-xl border border-ink-100 p-3 text-left hover:border-brand-300 dark:border-ink-800">
                <div className="w-16 text-sm font-bold">{time(b.scheduled_at)}</div>
                <div className="min-w-0 flex-1">
                  <div className="truncate text-sm font-semibold">{b.service_name}</div>
                  <div className="truncate text-xs text-ink-500">{b.address}</div>
                </div>
                <div className="text-right">
                  <Badge tone={statusTone(b.status)}>{titleCase(b.status)}</Badge>
                  <div className="mt-1 text-xs font-semibold">{money(b.total_amount)}</div>
                </div>
              </button>
            ))}
          </div>
        </Card>
      </div>
    </div>
  )
}
