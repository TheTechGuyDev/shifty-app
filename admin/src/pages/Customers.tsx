import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useLoad } from '../lib/hooks'
import { rpc } from '../lib/supabase'
import { date, money, num } from '../lib/format'
import { Avatar, Badge, DataTable, ErrorBox, Loading, PageHeader, Stat, Tabs } from '../components/ui'
import { Repeat, UserCheck, UserPlus, Users } from 'lucide-react'

export default function Customers() {
  const go = useNavigate()
  const [tab, setTab] = useState<'all' | 'booked' | 'never' | 'suspended' | 'pros'>('all')
  const data = useLoad(() => rpc<any[]>('admin_customers'))

  const rows = useMemo(() => {
    const r = data.data ?? []
    return r.filter((c) =>
      tab === 'all' ? true : tab === 'booked' ? c.bookings > 0 : tab === 'never' ? c.bookings === 0 : tab === 'suspended' ? c.is_suspended : c.is_professional,
    )
  }, [data.data, tab])

  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const all = data.data
  const month = all.filter((c) => Date.now() - new Date(c.created_at).getTime() < 30 * 864e5).length
  const repeat = all.filter((c) => c.bookings > 1).length

  return (
    <div>
      <PageHeader title="Customers" subtitle="Everyone who has signed up to the app." />
      <div className="mb-6 grid grid-cols-2 gap-4 xl:grid-cols-4">
        <Stat label="Total accounts" value={num(all.length)} icon={<Users className="h-5 w-5" />} />
        <Stat label="New in 30 days" value={num(month)} icon={<UserPlus className="h-5 w-5" />} tone="blue" />
        <Stat label="Have booked" value={num(all.filter((c) => c.bookings > 0).length)} icon={<UserCheck className="h-5 w-5" />} tone="green" />
        <Stat label="Repeat customers" value={num(repeat)} icon={<Repeat className="h-5 w-5" />} tone="purple" />
      </div>
      <div className="mb-4">
        <Tabs
          value={tab}
          onChange={setTab}
          items={[
            { value: 'all', label: 'All', count: all.length },
            { value: 'booked', label: 'Have booked', count: all.filter((c) => c.bookings > 0).length },
            { value: 'never', label: 'Never booked', count: all.filter((c) => c.bookings === 0).length },
            { value: 'pros', label: 'Also professionals', count: all.filter((c) => c.is_professional).length },
            { value: 'suspended', label: 'Suspended', count: all.filter((c) => c.is_suspended).length },
          ]}
        />
      </div>
      <DataTable
        rows={rows}
        exportName="customers"
        onRow={(r) => go(`/customers/${r.id}`)}
        search={(r) => `${r.name} ${r.email} ${r.phone} ${r.state} ${r.referral_code}`}
        columns={[
          {
            key: 'name',
            label: 'Customer',
            sort: (r) => r.name ?? '',
            csv: (r) => r.name,
            render: (r) => (
              <div className="flex items-center gap-3">
                <Avatar name={r.name} url={r.avatar} />
                <div>
                  <div className="font-semibold">{r.name || 'No name'}</div>
                  <div className="text-xs text-ink-500">{r.email}</div>
                </div>
              </div>
            ),
          },
          { key: 'phone', label: 'Phone', render: (r) => r.phone || '—' },
          { key: 'state', label: 'State', sort: (r) => r.state ?? '', render: (r) => r.state || '—' },
          { key: 'bookings', label: 'Bookings', sort: (r) => r.bookings, render: (r) => <b>{r.bookings}</b> },
          { key: 'spent', label: 'Spent', sort: (r) => Number(r.spent), render: (r) => money(r.spent) },
          { key: 'last', label: 'Last booking', sort: (r) => r.last_booking ?? '', csv: (r) => r.last_booking, render: (r) => date(r.last_booking) },
          { key: 'joined', label: 'Joined', sort: (r) => r.created_at, csv: (r) => r.created_at, render: (r) => date(r.created_at) },
          {
            key: 'status',
            label: 'Status',
            csv: (r) => (r.is_suspended ? 'suspended' : 'active'),
            render: (r) => (
              <div className="flex gap-1">
                {r.is_suspended ? <Badge tone="red">Suspended</Badge> : <Badge tone="green">Active</Badge>}
                {r.is_professional && <Badge tone="orange">Pro</Badge>}
              </div>
            ),
          },
        ]}
      />
    </div>
  )
}
