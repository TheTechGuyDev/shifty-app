import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Banknote, CircleDollarSign, Percent, Receipt } from 'lucide-react'
import { useLoad } from '../lib/hooks'
import { db, q } from '../lib/supabase'
import { dateTime, money, titleCase } from '../lib/format'
import { people } from '../lib/people'
import type { Booking } from '../lib/types'
import { Badge, DataTable, ErrorBox, Loading, PageHeader, Select, Stat, statusTone } from '../components/ui'

export default function Transactions() {
  const go = useNavigate()
  const [range, setRange] = useState('30')
  const [method, setMethod] = useState('all')
  const data = useLoad(async () => {
    const rows = await q<Booking[]>(db.from('bookings').select('*').eq('status', 'done').order('completed_at', { ascending: false }).limit(5000))
    return { rows, ppl: await people(rows.flatMap((r) => [r.customer_id, r.professional_id])) }
  })
  const rows = useMemo(() => {
    const since = range === 'all' ? 0 : Date.now() - Number(range) * 864e5
    return (data.data?.rows ?? []).filter((r) => new Date(r.completed_at ?? r.created_at).getTime() >= since && (method === 'all' || r.payment_method === method))
  }, [data.data, range, method])

  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const ppl = data.data.ppl
  const sum = (f: (r: Booking) => number) => rows.reduce((a, r) => a + f(r), 0)

  return (
    <div>
      <PageHeader title="Transactions" subtitle="Completed jobs with what the customer paid, the commission and what the professional earned." />
      <div className="mb-6 grid grid-cols-2 gap-4 xl:grid-cols-4">
        <Stat label="Customers paid" value={money(sum((r) => Number(r.total_amount ?? 0)))} icon={<CircleDollarSign className="h-5 w-5" />} hint={`${rows.length} jobs`} />
        <Stat label="Commission" value={money(sum((r) => Number(r.commission ?? 0)))} icon={<Percent className="h-5 w-5" />} tone="green" />
        <Stat label="Service charges" value={money(sum((r) => Number(r.service_charge ?? 0)))} icon={<Receipt className="h-5 w-5" />} tone="blue" />
        <Stat label="Owed to professionals" value={money(sum((r) => Number(r.pro_earning ?? 0)))} icon={<Banknote className="h-5 w-5" />} tone="purple" />
      </div>
      <DataTable<Booking>
        rows={rows}
        exportName="transactions"
        onRow={(r) => go(`/bookings/${r.id}`)}
        search={(r) => `${r.reference} ${r.service_name} ${ppl.get(r.customer_id)?.full_name} ${r.professional_id ? ppl.get(r.professional_id)?.full_name : ''}`}
        toolbar={
          <>
            <Select
              value={range}
              onChange={setRange}
              options={[
                { value: '7', label: 'Last 7 days' },
                { value: '30', label: 'Last 30 days' },
                { value: '90', label: 'Last 90 days' },
                { value: '365', label: 'Last 12 months' },
                { value: 'all', label: 'All time' },
              ]}
            />
            <Select value={method} onChange={setMethod} options={[{ value: 'all', label: 'Cash and card' }, { value: 'cash', label: 'Cash' }, { value: 'card', label: 'Card' }]} />
          </>
        }
        columns={[
          { key: 'date', label: 'Completed', sort: (r) => r.completed_at ?? '', csv: (r) => r.completed_at, render: (r) => dateTime(r.completed_at) },
          { key: 'ref', label: 'Job', csv: (r) => `${r.reference} ${r.service_name}`, render: (r) => <div><div className="font-semibold">{r.service_name}</div><div className="text-xs text-ink-500">#{r.reference}</div></div> },
          { key: 'cust', label: 'Customer', csv: (r) => ppl.get(r.customer_id)?.full_name, render: (r) => ppl.get(r.customer_id)?.full_name },
          { key: 'pro', label: 'Professional', csv: (r) => (r.professional_id ? ppl.get(r.professional_id)?.full_name : ''), render: (r) => (r.professional_id ? ppl.get(r.professional_id)?.full_name : '—') },
          { key: 'method', label: 'Method', csv: (r) => r.payment_method, render: (r) => <span className="capitalize">{r.payment_method}</span> },
          { key: 'total', label: 'Total', sort: (r) => Number(r.total_amount ?? 0), render: (r) => <b>{money(r.total_amount)}</b> },
          { key: 'comm', label: 'Commission', sort: (r) => Number(r.commission ?? 0), render: (r) => <span className="text-emerald-600">{money(r.commission)}</span> },
          { key: 'earn', label: 'Pro earned', sort: (r) => Number(r.pro_earning ?? 0), render: (r) => money(r.pro_earning) },
          { key: 'paid', label: 'Payment', csv: (r) => r.payment_status, render: (r) => <Badge tone={statusTone(r.payment_status)}>{titleCase(r.payment_status)}</Badge> },
        ]}
      />
    </div>
  )
}
