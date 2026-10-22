import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Clock, MapPin, RefreshCw, Send, Timer, UserCheck } from 'lucide-react'
import { useLoad } from '../lib/hooks'
import { db, q } from '../lib/supabase'
import { ago, dateTime, money, titleCase } from '../lib/format'
import { people } from '../lib/people'
import type { Booking } from '../lib/types'
import { Avatar, Badge, Button, Card, Empty, ErrorBox, Loading, PageHeader } from '../components/ui'
import Candidates from '../components/Candidates'

const COLUMNS = [
  { key: 'assigned', label: 'Assigned', color: 'bg-blue-500' },
  { key: 'on_the_way', label: 'On the way', color: 'bg-violet-500' },
  { key: 'arrived', label: 'Arrived', color: 'bg-amber-500' },
  { key: 'started', label: 'Working', color: 'bg-emerald-500' },
]

export default function Dispatch() {
  const go = useNavigate()
  const [pick, setPick] = useState<string | null>(null)
  const [, tick] = useState(0)
  const data = useLoad(async () => {
    const [pending, active] = await Promise.all([
      q<Booking[]>(db.from('bookings').select('*').eq('status', 'pending').order('created_at', { ascending: true })),
      q<Booking[]>(db.from('bookings').select('*').eq('status', 'active').order('scheduled_at', { ascending: true })),
    ])
    const ids = pending.map((p) => p.id)
    const offers = ids.length ? await q<any[]>(db.from('booking_offers').select('booking_id, status').in('booking_id', ids)) : []
    const ppl = await people([...pending, ...active].flatMap((r) => [r.customer_id, r.professional_id]))
    return { pending, active, offers, ppl }
  })

  useEffect(() => {
    const ch = db
      .channel('dispatch')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'bookings' }, () => data.reload())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'booking_offers' }, () => data.reload())
      .subscribe()
    const t = setInterval(() => tick((x) => x + 1), 30_000)
    return () => {
      db.removeChannel(ch)
      clearInterval(t)
    }
  }, [])

  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const { pending, active, offers, ppl } = data.data

  return (
    <div>
      <PageHeader
        title="Live Dispatch"
        subtitle="Bookings waiting for a professional, and jobs in progress. Updates in real time."
        actions={
          <Button variant="secondary" icon={<RefreshCw className="h-4 w-4" />} onClick={data.reload}>
            Refresh
          </Button>
        }
      />

      <Card title={`Waiting for a professional (${pending.length})`} subtitle="Oldest first. Send the request to more pros or assign directly." pad={false}>
        {pending.length === 0 ? (
          <Empty title="Nothing waiting" message="Every booking has a professional." icon={<UserCheck />} />
        ) : (
          <div className="divide-y divide-ink-100 dark:divide-ink-800">
            {pending.map((b) => {
              const mins = (Date.now() - new Date(b.created_at).getTime()) / 60000
              const os = offers.filter((o) => o.booking_id === b.id)
              const c = ppl.get(b.customer_id)
              return (
                <div key={b.id} className="flex flex-wrap items-center gap-4 px-5 py-4">
                  <span className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl ${mins > 30 ? 'bg-red-50 text-red-500 dark:bg-red-900/30' : 'bg-amber-50 text-amber-600 dark:bg-amber-900/30'}`}>
                    <Timer className="h-5 w-5" />
                  </span>
                  <button className="min-w-0 flex-1 text-left" onClick={() => go(`/bookings/${b.id}`)}>
                    <div className="font-semibold">
                      {b.service_name} <span className="font-normal text-ink-400">#{b.reference}</span>
                    </div>
                    <div className="mt-0.5 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-ink-500">
                      <span className="inline-flex items-center gap-1">
                        <Avatar name={c?.full_name} url={c?.avatar_url} size={16} /> {c?.full_name}
                      </span>
                      <span className="inline-flex items-center gap-1">
                        <Clock className="h-3 w-3" /> {dateTime(b.scheduled_at)}
                      </span>
                      <span className="inline-flex max-w-xs items-center gap-1 truncate">
                        <MapPin className="h-3 w-3 shrink-0" /> {b.address}
                      </span>
                    </div>
                  </button>
                  <div className="flex flex-wrap items-center gap-2">
                    <Badge tone={mins > 30 ? 'red' : 'yellow'}>Waiting {ago(b.created_at).replace(' ago', '')}</Badge>
                    <Badge tone="blue">{os.filter((o) => o.status === 'sent').length} notified</Badge>
                    {os.some((o) => o.status === 'quoted') && <Badge tone="purple">{os.filter((o) => o.status === 'quoted').length} quotes</Badge>}
                    {os.length === 0 && <Badge tone="red">No match found</Badge>}
                    <span className="w-24 text-right text-sm font-bold">{Number(b.total_amount) > 0 ? money(b.total_amount) : 'Quote'}</span>
                  </div>
                  <Button size="sm" icon={<Send className="h-3.5 w-3.5" />} onClick={() => setPick(b.id)}>
                    Dispatch
                  </Button>
                </div>
              )
            })}
          </div>
        )}
      </Card>

      <h2 className="mb-3 mt-8 text-lg font-bold">Jobs in progress ({active.length})</h2>
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {COLUMNS.map((col) => {
          const items = active.filter((a) => (a.progress ?? 'assigned') === col.key)
          return (
            <div key={col.key} className="rounded-2xl bg-ink-100/70 p-3 dark:bg-ink-900">
              <div className="mb-3 flex items-center gap-2 px-1">
                <span className={`h-2.5 w-2.5 rounded-full ${col.color}`} />
                <span className="text-sm font-bold">{col.label}</span>
                <span className="ml-auto rounded-full bg-white px-2 text-xs font-bold dark:bg-ink-800">{items.length}</span>
              </div>
              <div className="space-y-2">
                {items.map((b) => {
                  const p = ppl.get(b.professional_id!)
                  const late = b.scheduled_at && new Date(b.scheduled_at).getTime() < Date.now() && col.key === 'assigned'
                  return (
                    <button key={b.id} onClick={() => go(`/bookings/${b.id}`)} className="card w-full p-3 text-left transition hover:-translate-y-0.5 hover:shadow-lg">
                      <div className="flex items-start justify-between gap-2">
                        <div className="text-sm font-semibold">{b.service_name}</div>
                        {late && <Badge tone="red">Late</Badge>}
                      </div>
                      <div className="mt-1 text-xs text-ink-500">{dateTime(b.scheduled_at)}</div>
                      <div className="mt-3 flex items-center gap-2 text-xs">
                        <Avatar name={p?.full_name} url={p?.avatar_url} size={22} />
                        <span className="truncate font-medium">{p?.full_name}</span>
                        <span className="ml-auto font-bold">{money(b.total_amount)}</span>
                      </div>
                    </button>
                  )
                })}
                {items.length === 0 && <p className="py-6 text-center text-xs text-ink-400">No jobs</p>}
              </div>
            </div>
          )
        })}
      </div>
      <p className="mt-3 text-xs text-ink-500">Stage names follow what the professional taps in their app: {COLUMNS.map((c) => titleCase(c.key)).join(' → ')}.</p>

      {pick && <Candidates bookingId={pick} open onClose={() => setPick(null)} onDone={data.reload} />}
    </div>
  )
}
