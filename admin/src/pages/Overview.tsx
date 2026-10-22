import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  AlertTriangle, ArrowRight, Banknote, CalendarCheck, CircleDollarSign, ClipboardList, FileCheck2, Headphones, Percent, Plus, Radio, ShieldAlert, Star, UserPlus, Wrench,
} from 'lucide-react'
import { useAuth } from '../lib/auth'
import { useLoad } from '../lib/hooks'
import { db, rpc } from '../lib/supabase'
import { compactMoney, date, dateTime, money, num, titleCase } from '../lib/format'
import { people } from '../lib/people'
import type { Booking } from '../lib/types'
import { Avatar, Badge, Button, Card, ErrorBox, Loading, Select, Stat, Stars, statusTone } from '../components/ui'
import { AreaTrend, Bars, Donut } from '../components/charts'

export default function Overview() {
  const [days, setDays] = useState('30')
  const { me, can } = useAuth()
  const go = useNavigate()
  const ov = useLoad(() => rpc<any>('admin_overview', { p_days: Number(days) }), [days])
  const recent = useLoad(async () => {
    if (!can('bookings.view')) return { rows: [] as Booking[], ppl: new Map() }
    const { data } = await db.from('bookings').select('*').order('created_at', { ascending: false }).limit(8)
    const rows = (data ?? []) as Booking[]
    return { rows, ppl: await people(rows.flatMap((r) => [r.customer_id, r.professional_id])) }
  })

  if (ov.error) return <ErrorBox message={ov.error} onRetry={ov.reload} />
  const d = ov.data
  const series = (d?.series ?? []).map((s: any) => ({ ...s, label: new Date(s.day).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' }) }))
  const hour = new Date().getHours()

  const attention = d
    ? [
        { n: d.unassigned_old, label: 'Bookings waiting 30+ minutes for a professional', to: '/dispatch', icon: <AlertTriangle />, tone: 'text-red-500 bg-red-50 dark:bg-red-900/30' },
        { n: d.pros_pending, label: 'Professional applications to review', to: '/applications', icon: <UserPlus />, tone: 'text-brand-500 bg-brand-50 dark:bg-brand-900/30' },
        { n: d.docs_pending, label: 'Documents waiting for verification', to: '/verification', icon: <FileCheck2 />, tone: 'text-blue-500 bg-blue-50 dark:bg-blue-900/30' },
        { n: d.payouts_pending_count, label: `Payout requests (${compactMoney(d.payouts_pending)})`, to: '/payouts', icon: <Banknote />, tone: 'text-emerald-600 bg-emerald-50 dark:bg-emerald-900/30' },
        { n: d.tickets_open, label: 'Open support conversations', to: '/support', icon: <Headphones />, tone: 'text-violet-500 bg-violet-50 dark:bg-violet-900/30' },
        { n: d.masked_messages, label: 'Chat messages hidden for contact sharing', to: '/chats', icon: <ShieldAlert />, tone: 'text-amber-600 bg-amber-50 dark:bg-amber-900/30' },
      ]
    : []

  return (
    <div className="space-y-6">
      {/* Welcome banner */}
      <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-ink-900 via-ink-900 to-ink-800 p-6 text-white sm:p-8">
        <div className="absolute -right-20 -top-24 h-72 w-72 rounded-full bg-brand-500/40 blur-3xl" />
        <div className="absolute bottom-0 right-40 h-40 w-40 rounded-full bg-brand-400/20 blur-2xl" />
        <div className="relative flex flex-wrap items-end justify-between gap-6">
          <div>
            <p className="text-sm text-ink-300">{new Date().toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'long' })}</p>
            <h1 className="mt-1 text-3xl font-bold">
              {hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening'}, {(me?.name ?? '').split(' ')[0] || 'there'}
            </h1>
            <p className="mt-2 text-ink-300">
              {d ? (
                <>
                  {num(d.bookings_today)} bookings today · {num(d.pros_online)} professionals online · {num(d.pending)} waiting for dispatch
                </>
              ) : (
                'Loading today’s numbers…'
              )}
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <Select
              className="border-white/10 bg-white/10 text-white dark:bg-white/10 [&>option]:text-ink-900"
              value={days}
              onChange={setDays}
              options={[
                { value: '7', label: 'Last 7 days' },
                { value: '30', label: 'Last 30 days' },
                { value: '90', label: 'Last 90 days' },
                { value: '365', label: 'Last 12 months' },
              ]}
            />
            {can('bookings.manage') && (
              <Button icon={<Radio className="h-4 w-4" />} onClick={() => go('/dispatch')}>
                Live dispatch
              </Button>
            )}
            {can('broadcast.send') && (
              <Button variant="secondary" className="border-white/10 bg-white/10 text-white hover:bg-white/20 dark:bg-white/10" icon={<Plus className="h-4 w-4" />} onClick={() => go('/broadcasts')}>
                Broadcast
              </Button>
            )}
          </div>
        </div>
      </div>

      {!d ? (
        <Loading />
      ) : (
        <>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <Stat label="Completed job value" value={compactMoney(d.gmv)} icon={<CircleDollarSign className="h-5 w-5" />} hint={`${num(d.done)} jobs completed`} onClick={() => go('/transactions')} />
            <Stat label="Commission earned" value={compactMoney(d.commission)} icon={<Percent className="h-5 w-5" />} tone="green" hint={`+ ${compactMoney(d.service_fees)} service fees`} onClick={() => go('/revenue')} />
            <Stat label="Bookings" value={num(d.bookings)} icon={<ClipboardList className="h-5 w-5" />} tone="blue" hint={`${num(d.active)} active · ${num(d.cancelled)} cancelled`} onClick={() => go('/bookings')} />
            <Stat label="New sign-ups" value={num(d.new_customers)} icon={<UserPlus className="h-5 w-5" />} tone="purple" hint={`${num(d.customers)} customers in total`} onClick={() => go('/customers')} />
            <Stat label="Approved professionals" value={num(d.pros_approved)} icon={<Wrench className="h-5 w-5" />} tone="orange" hint={`${num(d.pros_online)} online now`} onClick={() => go('/pros')} />
            <Stat label="Waiting for dispatch" value={num(d.pending)} icon={<CalendarCheck className="h-5 w-5" />} tone="yellow" hint={`${num(d.unassigned_old)} waiting 30+ min`} onClick={() => go('/dispatch')} />
            <Stat label="Payouts to process" value={compactMoney(d.payouts_pending)} icon={<Banknote className="h-5 w-5" />} tone="green" hint={`${num(d.payouts_pending_count)} requests`} onClick={() => go('/payouts')} />
            <Stat label="Average rating" value={Number(d.avg_rating).toFixed(1)} icon={<Star className="h-5 w-5" />} tone="yellow" hint={`${num(d.reviews)} new reviews`} onClick={() => go('/reviews')} />
          </div>

          <div className="grid gap-6 xl:grid-cols-3">
            <Card className="xl:col-span-2" title="Bookings and completed value" subtitle={`Daily, last ${days} days`}>
              <AreaTrend
                data={series}
                x="label"
                series={[
                  { key: 'gmv', name: 'Completed value' },
                  { key: 'commission', name: 'Commission', color: '#4FBF67' },
                ]}
                money
              />
            </Card>
            <Card title="Bookings by status" subtitle={`Created in the last ${days} days`}>
              <Donut data={Object.entries(d.by_status ?? {}).map(([k, v]) => ({ name: k, value: Number(v) }))} center="bookings" />
            </Card>
          </div>

          <div className="grid gap-6 xl:grid-cols-3">
            <Card title="Top services" subtitle="By number of bookings">
              {d.by_service.length ? <Bars data={d.by_service} x="name" series={[{ key: 'n', name: 'Bookings' }]} horizontal height={260} /> : <p className="py-10 text-center text-sm text-ink-500">No bookings yet</p>}
            </Card>
            <Card title="Daily activity" subtitle="New bookings and sign-ups">
              <Bars
                data={series.slice(-14)}
                x="label"
                series={[
                  { key: 'bookings', name: 'Bookings' },
                  { key: 'signups', name: 'Sign-ups', color: '#3F8CFF' },
                ]}
                height={260}
              />
            </Card>
            <Card title="Needs attention" subtitle="Tap to open">
              <div className="space-y-2">
                {attention.filter((a) => Number(a.n) > 0).length === 0 && <p className="py-10 text-center text-sm text-ink-500">All clear. Nothing is waiting.</p>}
                {attention
                  .filter((a) => Number(a.n) > 0)
                  .map((a) => (
                    <button key={a.to} onClick={() => go(a.to)} className="flex w-full items-center gap-3 rounded-xl p-2.5 text-left transition hover:bg-ink-50 dark:hover:bg-ink-800">
                      <span className={`inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-xl [&>svg]:h-5 [&>svg]:w-5 ${a.tone}`}>{a.icon}</span>
                      <span className="flex-1 text-sm">{a.label}</span>
                      <span className="text-lg font-bold">{a.n}</span>
                    </button>
                  ))}
              </div>
            </Card>
          </div>

          <div className="grid gap-6 xl:grid-cols-3">
            <Card
              className="xl:col-span-2"
              pad={false}
              title="Recent bookings"
              actions={
                <Button variant="ghost" size="sm" onClick={() => go('/bookings')}>
                  View all <ArrowRight className="h-3.5 w-3.5" />
                </Button>
              }
            >
              <div className="scrollbar-thin mt-3 overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-ink-50/70 dark:bg-ink-850">
                    <tr>
                      <th className="th">Booking</th>
                      <th className="th">Customer</th>
                      <th className="th">Professional</th>
                      <th className="th">Amount</th>
                      <th className="th">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-ink-100 dark:divide-ink-800">
                    {(recent.data?.rows ?? []).map((b) => {
                      const c = recent.data!.ppl.get(b.customer_id)
                      const p = b.professional_id ? recent.data!.ppl.get(b.professional_id) : null
                      return (
                        <tr key={b.id} className="cursor-pointer hover:bg-brand-50/40 dark:hover:bg-ink-850" onClick={() => go(`/bookings/${b.id}`)}>
                          <td className="td">
                            <div className="font-semibold">{b.service_name}</div>
                            <div className="text-xs text-ink-500">
                              #{b.reference} · {dateTime(b.created_at)}
                            </div>
                          </td>
                          <td className="td">
                            <div className="flex items-center gap-2">
                              <Avatar name={c?.full_name} url={c?.avatar_url} size={28} />
                              {c?.full_name}
                            </div>
                          </td>
                          <td className="td text-ink-500">{p?.full_name ?? 'Not assigned'}</td>
                          <td className="td font-semibold">{money(b.total_amount)}</td>
                          <td className="td">
                            <Badge tone={statusTone(b.status)} dot>
                              {titleCase(b.status)}
                            </Badge>
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
                {recent.data && !recent.data.rows.length && <p className="p-10 text-center text-sm text-ink-500">No bookings yet</p>}
              </div>
            </Card>
            <Card title="Top professionals" subtitle={`Earnings, last ${days} days`}>
              <div className="space-y-3">
                {d.top_pros.length === 0 && <p className="py-10 text-center text-sm text-ink-500">No approved professionals yet</p>}
                {d.top_pros.map((p: any, i: number) => (
                  <button key={p.id} onClick={() => go(`/pros/${p.id}`)} className="flex w-full items-center gap-3 rounded-xl p-1.5 text-left hover:bg-ink-50 dark:hover:bg-ink-800">
                    <span className="w-5 text-center text-sm font-bold text-ink-400">{i + 1}</span>
                    <Avatar name={p.name} url={p.avatar} />
                    <div className="min-w-0 flex-1">
                      <div className="truncate text-sm font-semibold">{p.name}</div>
                      <div className="flex items-center gap-1 text-xs text-ink-500">
                        <Stars value={Number(p.rating)} /> {p.jobs_done} jobs
                      </div>
                    </div>
                    <span className="text-sm font-bold">{compactMoney(p.earned)}</span>
                  </button>
                ))}
              </div>
              <div className="mt-5 rounded-2xl bg-ink-50 p-4 text-sm dark:bg-ink-850">
                <div className="flex justify-between">
                  <span className="text-ink-500">Payment split</span>
                </div>
                <div className="mt-2 flex gap-4">
                  {Object.entries(d.by_payment ?? {}).map(([k, v]) => (
                    <div key={k}>
                      <div className="text-lg font-bold">{num(v as number)}</div>
                      <div className="text-xs capitalize text-ink-500">{k}</div>
                    </div>
                  ))}
                  {!Object.keys(d.by_payment ?? {}).length && <span className="text-ink-500">No data</span>}
                </div>
              </div>
              <p className="mt-4 text-xs text-ink-400">All-time completed value: {money(d.gmv_all)} · since {date(new Date(Date.now() - Number(days) * 864e5).toISOString())}</p>
            </Card>
          </div>
        </>
      )}
    </div>
  )
}
