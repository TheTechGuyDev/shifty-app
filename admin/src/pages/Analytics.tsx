import { useMemo, useState } from 'react'
import { useLoad } from '../lib/hooks'
import { db, q } from '../lib/supabase'
import { money, num } from '../lib/format'
import { Card, ErrorBox, Loading, PageHeader, Select, Stat, cx } from '../components/ui'
import { Bars, Donut } from '../components/charts'
import { Clock, Repeat, ShoppingBag, TrendingDown, UserCheck, Zap } from 'lucide-react'

const DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

export default function Analytics() {
  const [range, setRange] = useState('90')
  const data = useLoad(async () => {
    const since = new Date(Date.now() - Number(range) * 864e5).toISOString()
    const [bookings, users, offers, pros] = await Promise.all([
      q<any[]>(db.from('bookings').select('id, customer_id, status, service_name, total_amount, created_at, updated_at, scheduled_at, payment_method, address, promo_code, kind').gte('created_at', since)),
      q<any[]>(db.from('profiles').select('id, state, created_at, is_professional')),
      q<any[]>(db.from('booking_offers').select('booking_id, status, created_at, updated_at').gte('created_at', since)),
      q<any[]>(db.from('professional_profiles').select('status')),
    ])
    return { bookings, users, offers, pros }
  }, [range])

  const a = useMemo(() => {
    if (!data.data) return null
    const { bookings, users, offers } = data.data
    const done = bookings.filter((b) => b.status === 'done')
    const customersWhoBooked = new Set(bookings.map((b) => b.customer_id))
    const perCustomer = new Map<string, number>()
    bookings.forEach((b) => perCustomer.set(b.customer_id, (perCustomer.get(b.customer_id) ?? 0) + 1))
    const repeat = [...perCustomer.values()].filter((n) => n > 1).length
    const heat = Array.from({ length: 7 }, () => Array(24).fill(0))
    bookings.forEach((b) => {
      const d = new Date(b.created_at)
      heat[(d.getDay() + 6) % 7][d.getHours()]++
    })
    const max = Math.max(1, ...heat.flat())
    const accepted = offers.filter((o) => o.status === 'accepted')
    const assignMins = accepted.map((o) => (new Date(o.updated_at).getTime() - new Date(o.created_at).getTime()) / 60000).filter((m) => m >= 0)
    const states = new Map<string, number>()
    users.forEach((u) => u.state && states.set(u.state, (states.get(u.state) ?? 0) + 1))
    const lead = bookings.filter((b) => b.scheduled_at).map((b) => (new Date(b.scheduled_at).getTime() - new Date(b.created_at).getTime()) / 864e5)
    return {
      total: bookings.length,
      aov: done.length ? done.reduce((s, b) => s + Number(b.total_amount ?? 0), 0) / done.length : 0,
      cancelRate: bookings.length ? (bookings.filter((b) => b.status === 'cancelled').length / bookings.length) * 100 : 0,
      completion: bookings.length ? (done.length / bookings.length) * 100 : 0,
      funnel: [
        { name: 'Signed up', value: users.length },
        { name: 'Booked once', value: customersWhoBooked.size },
        { name: 'Completed a job', value: new Set(done.map((b) => b.customer_id)).size },
        { name: 'Booked again', value: repeat },
      ],
      repeat,
      heat,
      max,
      assign: assignMins.length ? assignMins.reduce((x, y) => x + y, 0) / assignMins.length : 0,
      acceptRate: offers.length ? (accepted.length / offers.length) * 100 : 0,
      quoteShare: offers.length ? (offers.filter((o) => ['quoted', 'accepted'].includes(o.status)).length / offers.length) * 100 : 0,
      states: [...states.entries()].sort((x, y) => y[1] - x[1]).slice(0, 8).map(([name, value]) => ({ name, value })),
      payment: ['cash', 'card'].map((m) => ({ name: m, value: bookings.filter((b) => b.payment_method === m).length })).filter((x) => x.value),
      promo: bookings.length ? (bookings.filter((b) => b.promo_code).length / bookings.length) * 100 : 0,
      leadDays: lead.length ? lead.reduce((x, y) => x + y, 0) / lead.length : 0,
      kinds: Object.entries(bookings.reduce((m: Record<string, number>, b) => ((m[b.kind] = (m[b.kind] ?? 0) + 1), m), {})).map(([name, value]) => ({ name, value: value as number })),
    }
  }, [data.data])

  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!a) return <Loading />

  return (
    <div className="space-y-6">
      <PageHeader
        title="Analytics"
        subtitle="How customers find, book and come back."
        actions={
          <Select
            value={range}
            onChange={setRange}
            options={[
              { value: '30', label: 'Last 30 days' },
              { value: '90', label: 'Last 90 days' },
              { value: '365', label: 'Last 12 months' },
              { value: '3650', label: 'All time' },
            ]}
          />
        }
      />
      <div className="grid grid-cols-2 gap-4 xl:grid-cols-6">
        <Stat label="Average order" value={money(a.aov)} icon={<ShoppingBag className="h-5 w-5" />} />
        <Stat label="Completion rate" value={`${a.completion.toFixed(0)}%`} icon={<UserCheck className="h-5 w-5" />} tone="green" />
        <Stat label="Cancellation rate" value={`${a.cancelRate.toFixed(0)}%`} icon={<TrendingDown className="h-5 w-5" />} tone="red" />
        <Stat label="Repeat customers" value={num(a.repeat)} icon={<Repeat className="h-5 w-5" />} tone="purple" />
        <Stat label="Avg time to assign" value={`${a.assign.toFixed(0)} min`} icon={<Zap className="h-5 w-5" />} tone="blue" />
        <Stat label="Booked ahead by" value={`${a.leadDays.toFixed(1)} days`} icon={<Clock className="h-5 w-5" />} tone="yellow" />
      </div>
      <div className="grid gap-6 xl:grid-cols-2">
        <Card title="Customer funnel" subtitle="From sign-up to repeat booking">
          <div className="space-y-3">
            {a.funnel.map((f, i) => {
              const pct = a.funnel[0].value ? (f.value / a.funnel[0].value) * 100 : 0
              return (
                <div key={f.name}>
                  <div className="mb-1 flex justify-between text-sm">
                    <span className="font-medium">{f.name}</span>
                    <span>
                      <b>{num(f.value)}</b> <span className="text-ink-400">({pct.toFixed(0)}%)</span>
                    </span>
                  </div>
                  <div className="h-8 overflow-hidden rounded-xl bg-ink-100 dark:bg-ink-800">
                    <div className="h-full rounded-xl bg-gradient-to-r from-brand-500 to-brand-300" style={{ width: `${Math.max(pct, 2)}%`, opacity: 1 - i * 0.15 }} />
                  </div>
                </div>
              )
            })}
          </div>
        </Card>
        <Card title="Dispatch health">
          <div className="grid grid-cols-2 gap-4">
            <div className="rounded-2xl bg-ink-50 p-4 dark:bg-ink-850">
              <div className="text-xs text-ink-500">Requests accepted</div>
              <div className="mt-1 text-2xl font-bold">{a.acceptRate.toFixed(0)}%</div>
            </div>
            <div className="rounded-2xl bg-ink-50 p-4 dark:bg-ink-850">
              <div className="text-xs text-ink-500">Requests with a quote</div>
              <div className="mt-1 text-2xl font-bold">{a.quoteShare.toFixed(0)}%</div>
            </div>
            <div className="rounded-2xl bg-ink-50 p-4 dark:bg-ink-850">
              <div className="text-xs text-ink-500">Bookings using a promo</div>
              <div className="mt-1 text-2xl font-bold">{a.promo.toFixed(0)}%</div>
            </div>
            <div className="rounded-2xl bg-ink-50 p-4 dark:bg-ink-850">
              <div className="text-xs text-ink-500">Approved pros</div>
              <div className="mt-1 text-2xl font-bold">{data.data!.pros.filter((p) => p.status === 'approved').length}</div>
            </div>
          </div>
          <div className="mt-6">
            <Donut data={a.payment} center="bookings" height={160} />
          </div>
        </Card>
      </div>
      <Card title="When people book" subtitle="Bookings created by day and hour (darker = more)">
        <div className="scrollbar-thin overflow-x-auto">
          <div className="min-w-[640px]">
            <div className="ml-10 grid grid-cols-24 text-[10px] text-ink-400" style={{ gridTemplateColumns: 'repeat(24, minmax(0, 1fr))' }}>
              {Array.from({ length: 24 }, (_, h) => (
                <div key={h} className="text-center">
                  {h % 3 === 0 ? `${h}h` : ''}
                </div>
              ))}
            </div>
            {a.heat.map((row, d) => (
              <div key={d} className="mt-1 flex items-center gap-2">
                <span className="w-8 text-xs text-ink-500">{DAYS[d]}</span>
                <div className="grid flex-1 gap-1" style={{ gridTemplateColumns: 'repeat(24, minmax(0, 1fr))' }}>
                  {row.map((v, h) => (
                    <div
                      key={h}
                      title={`${DAYS[d]} ${h}:00 · ${v} bookings`}
                      className={cx('h-6 rounded', v === 0 && 'bg-ink-100 dark:bg-ink-800')}
                      style={v ? { background: `rgba(253,107,34,${0.15 + (v / a.max) * 0.85})` } : undefined}
                    />
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>
      </Card>
      <div className="grid gap-6 xl:grid-cols-2">
        <Card title="Customers by state">{a.states.length ? <Bars data={a.states} x="name" series={[{ key: 'value', name: 'Customers' }]} horizontal height={260} /> : <p className="py-10 text-center text-sm text-ink-500">No data</p>}</Card>
        <Card title="Booking types">
          <Donut data={a.kinds} center="bookings" />
        </Card>
      </div>
    </div>
  )
}
