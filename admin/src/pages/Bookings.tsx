import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { XCircle } from 'lucide-react'
import { useAuth } from '../lib/auth'
import { useLoad } from '../lib/hooks'
import { db, q, rpc } from '../lib/supabase'
import { dateTime, money, titleCase } from '../lib/format'
import { people } from '../lib/people'
import type { Booking } from '../lib/types'
import { Avatar, Badge, Button, DataTable, ErrorBox, Loading, PageHeader, Select, Tabs, statusTone, useAction, useUi } from '../components/ui'

const STATUSES = ['all', 'pending', 'active', 'done', 'cancelled'] as const

export default function Bookings() {
  const go = useNavigate()
  const { can } = useAuth()
  const { confirm } = useUi()
  const { run } = useAction()
  const [status, setStatus] = useState<(typeof STATUSES)[number]>('all')
  const [service, setService] = useState('all')
  const [pay, setPay] = useState('all')
  const [range, setRange] = useState('all')

  const data = useLoad(async () => {
    const rows = await q<Booking[]>(db.from('bookings').select('*').order('created_at', { ascending: false }).limit(2000))
    return { rows, ppl: await people(rows.flatMap((r) => [r.customer_id, r.professional_id])) }
  })

  const services = useMemo(() => [...new Set((data.data?.rows ?? []).map((r) => r.service_name))].sort(), [data.data])

  const rows = useMemo(() => {
    const since = range === 'all' ? 0 : Date.now() - Number(range) * 864e5
    return (data.data?.rows ?? []).filter(
      (r) =>
        (status === 'all' || r.status === status) &&
        (service === 'all' || r.service_name === service) &&
        (pay === 'all' || r.payment_method === pay || r.payment_status === pay) &&
        new Date(r.created_at).getTime() >= since,
    )
  }, [data.data, status, service, pay, range])

  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const ppl = data.data.ppl
  const count = (s: string) => (s === 'all' ? data.data!.rows.length : data.data!.rows.filter((r) => r.status === s).length)

  return (
    <div>
      <PageHeader title="Bookings" subtitle="Every order placed in the app, with live status and payment." />
      <div className="mb-4">
        <Tabs value={status} onChange={setStatus} items={STATUSES.map((s) => ({ value: s, label: titleCase(s), count: count(s) }))} />
      </div>
      <DataTable<Booking>
        rows={rows}
        exportName="bookings"
        onRow={(r) => go(`/bookings/${r.id}`)}
        search={(r) => `${r.reference} ${r.service_name} ${r.address} ${ppl.get(r.customer_id)?.full_name} ${ppl.get(r.customer_id)?.email} ${r.professional_id ? ppl.get(r.professional_id)?.full_name : ''}`}
        selectable={can('bookings.manage') ? (r) => r.id : undefined}
        bulk={(ids, clear) => (
          <Button
            size="sm"
            variant="danger"
            icon={<XCircle className="h-3.5 w-3.5" />}
            onClick={async () => {
              const reason = await confirm({ title: `Cancel ${ids.length} bookings?`, message: 'Customers and professionals are notified. Done bookings are skipped.', input: 'Reason shown to the customer', inputRequired: true, danger: true, confirm: 'Cancel bookings' })
              if (!reason) return
              await run('bulk', async () => {
                for (const id of ids) await rpc('admin_cancel_booking', { p_booking: id, p_reason: reason }).catch(() => {})
              }, 'Bookings cancelled')
              clear()
              data.reload()
            }}
          >
            Cancel
          </Button>
        )}
        toolbar={
          <>
            <Select value={service} onChange={setService} options={[{ value: 'all', label: 'All services' }, ...services.map((s) => ({ value: s, label: s }))]} />
            <Select
              value={pay}
              onChange={setPay}
              options={[
                { value: 'all', label: 'Any payment' },
                { value: 'cash', label: 'Cash' },
                { value: 'card', label: 'Card' },
                { value: 'paid', label: 'Paid' },
                { value: 'unpaid', label: 'Unpaid' },
                { value: 'refunded', label: 'Refunded' },
              ]}
            />
            <Select
              value={range}
              onChange={setRange}
              options={[
                { value: 'all', label: 'All time' },
                { value: '1', label: 'Today' },
                { value: '7', label: 'Last 7 days' },
                { value: '30', label: 'Last 30 days' },
                { value: '90', label: 'Last 90 days' },
              ]}
            />
          </>
        }
        columns={[
          {
            key: 'ref',
            label: 'Booking',
            sort: (r) => r.created_at,
            csv: (r) => r.reference,
            render: (r) => (
              <div>
                <div className="font-semibold">{r.service_name}</div>
                <div className="text-xs text-ink-500">
                  #{r.reference} · {dateTime(r.created_at)}
                </div>
              </div>
            ),
          },
          {
            key: 'customer',
            label: 'Customer',
            sort: (r) => ppl.get(r.customer_id)?.full_name ?? '',
            csv: (r) => ppl.get(r.customer_id)?.full_name,
            render: (r) => {
              const c = ppl.get(r.customer_id)
              return (
                <div className="flex items-center gap-2">
                  <Avatar name={c?.full_name} url={c?.avatar_url} size={28} />
                  <span>{c?.full_name}</span>
                </div>
              )
            },
          },
          {
            key: 'pro',
            label: 'Professional',
            csv: (r) => (r.professional_id ? ppl.get(r.professional_id)?.full_name : ''),
            render: (r) => (r.professional_id ? ppl.get(r.professional_id)?.full_name : <span className="text-ink-400">Not assigned</span>),
          },
          { key: 'when', label: 'Scheduled', sort: (r) => r.scheduled_at ?? '', csv: (r) => r.scheduled_at, render: (r) => <span className="text-ink-600 dark:text-ink-300">{dateTime(r.scheduled_at)}</span> },
          { key: 'amount', label: 'Amount', sort: (r) => Number(r.total_amount ?? 0), render: (r) => <span className="font-semibold">{money(r.total_amount)}</span> },
          {
            key: 'payment',
            label: 'Payment',
            csv: (r) => `${r.payment_method} ${r.payment_status}`,
            render: (r) => (
              <div className="flex items-center gap-1.5">
                <span className="capitalize text-ink-500">{r.payment_method}</span>
                <Badge tone={statusTone(r.payment_status)}>{titleCase(r.payment_status)}</Badge>
              </div>
            ),
          },
          {
            key: 'status',
            label: 'Status',
            sort: (r) => r.status,
            csv: (r) => r.status,
            render: (r) => (
              <div className="flex flex-col items-start gap-1">
                <Badge tone={statusTone(r.status)} dot>
                  {titleCase(r.status)}
                </Badge>
                {r.status === 'active' && <span className="text-[11px] text-ink-500">{titleCase(r.progress)}</span>}
              </div>
            ),
          },
        ]}
      />
    </div>
  )
}
