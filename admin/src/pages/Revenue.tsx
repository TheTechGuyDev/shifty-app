import { useState } from 'react'
import { useLoad } from '../lib/hooks'
import { rpc } from '../lib/supabase'
import { money, num } from '../lib/format'
import { Card, DataTable, ErrorBox, Loading, PageHeader, Select, Stat } from '../components/ui'
import { AreaTrend, Bars } from '../components/charts'
import { CircleDollarSign, Landmark, Percent, Receipt } from 'lucide-react'

export default function Revenue() {
  const [months, setMonths] = useState('12')
  const data = useLoad(() => rpc<any[]>('admin_monthly_finance', { p_months: Number(months) }), [months])
  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const rows = data.data.map((r) => ({ ...r, revenue: Number(r.commission) + Number(r.fees) }))
  const s = (k: string) => rows.reduce((a, r) => a + Number(r[k] ?? 0), 0)
  const takeRate = s('gmv') ? ((s('revenue') / s('gmv')) * 100).toFixed(1) : '0'

  return (
    <div className="space-y-6">
      <PageHeader
        title="Revenue"
        subtitle="Platform income from commission and service charges, month by month."
        actions={
          <Select
            value={months}
            onChange={setMonths}
            options={[
              { value: '6', label: 'Last 6 months' },
              { value: '12', label: 'Last 12 months' },
              { value: '24', label: 'Last 24 months' },
            ]}
          />
        }
      />
      <div className="grid grid-cols-2 gap-4 xl:grid-cols-4">
        <Stat label="Completed job value" value={money(s('gmv'))} icon={<CircleDollarSign className="h-5 w-5" />} hint={`${num(s('jobs'))} jobs`} />
        <Stat label="Platform revenue" value={money(s('revenue'))} icon={<Landmark className="h-5 w-5" />} tone="green" hint="Commission + service charges" />
        <Stat label="Take rate" value={`${takeRate}%`} icon={<Percent className="h-5 w-5" />} tone="blue" hint="Revenue ÷ job value" />
        <Stat label="Paid to professionals" value={money(s('payouts'))} icon={<Receipt className="h-5 w-5" />} tone="purple" />
      </div>
      <div className="grid gap-6 xl:grid-cols-2">
        <Card title="Revenue by month">
          <Bars data={rows} x="month" series={[{ key: 'commission', name: 'Commission' }, { key: 'fees', name: 'Service charges', color: '#3F8CFF' }]} money />
        </Card>
        <Card title="Job value and payouts">
          <AreaTrend data={rows} x="month" series={[{ key: 'gmv', name: 'Job value' }, { key: 'payouts', name: 'Payouts', color: '#8B5CF6' }]} money />
        </Card>
      </div>
      <DataTable
        rows={[...rows].reverse()}
        exportName="monthly-revenue"
        pageSize={24}
        columns={[
          { key: 'month', label: 'Month' },
          { key: 'jobs', label: 'Jobs', render: (r) => num(r.jobs) },
          { key: 'gmv', label: 'Job value', render: (r) => money(r.gmv) },
          { key: 'commission', label: 'Commission', render: (r) => money(r.commission) },
          { key: 'fees', label: 'Service charges', render: (r) => money(r.fees) },
          { key: 'revenue', label: 'Revenue', render: (r) => <b>{money(r.revenue)}</b> },
          { key: 'payouts', label: 'Payouts', render: (r) => money(r.payouts) },
        ]}
      />
    </div>
  )
}
