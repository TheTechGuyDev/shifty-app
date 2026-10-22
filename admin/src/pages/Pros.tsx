import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { BadgeCheck, Radio, ShieldCheck, Wrench } from 'lucide-react'
import { useLoad } from '../lib/hooks'
import { rpc } from '../lib/supabase'
import { date, money, num, titleCase } from '../lib/format'
import { Avatar, Badge, DataTable, ErrorBox, Loading, PageHeader, Select, Stars, Stat, Tabs, statusTone } from '../components/ui'

export const levelLabel = (l: number) => (l >= 3 ? 'Qualified' : l >= 2 ? 'ID verified' : 'Basic')

export default function Pros() {
  const go = useNavigate()
  const [tab, setTab] = useState('all')
  const [level, setLevel] = useState('all')
  const data = useLoad(() => rpc<any[]>('admin_pros'))

  const rows = useMemo(
    () =>
      (data.data ?? []).filter(
        (p) =>
          (tab === 'all' || (tab === 'online' ? p.is_online && p.status === 'approved' : tab === 'suspended' ? p.is_suspended : tab === 'featured' ? p.is_featured : p.status === tab)) &&
          (level === 'all' || String(p.level) === level),
      ),
    [data.data, tab, level],
  )

  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const all = data.data
  const n = (f: (p: any) => boolean) => all.filter(f).length

  return (
    <div>
      <PageHeader title="Professionals" subtitle="Artisans and companies offering services on the platform." />
      <div className="mb-6 grid grid-cols-2 gap-4 xl:grid-cols-4">
        <Stat label="Total" value={num(all.length)} icon={<Wrench className="h-5 w-5" />} />
        <Stat label="Approved" value={num(n((p) => p.status === 'approved'))} icon={<BadgeCheck className="h-5 w-5" />} tone="green" />
        <Stat label="Online now" value={num(n((p) => p.is_online && p.status === 'approved'))} icon={<Radio className="h-5 w-5" />} tone="blue" />
        <Stat label="Waiting for review" value={num(n((p) => p.status === 'pending'))} icon={<ShieldCheck className="h-5 w-5" />} tone="yellow" onClick={() => go('/applications')} />
      </div>
      <div className="mb-4">
        <Tabs
          value={tab}
          onChange={setTab}
          items={[
            { value: 'all', label: 'All', count: all.length },
            { value: 'approved', label: 'Approved', count: n((p) => p.status === 'approved') },
            { value: 'online', label: 'Online', count: n((p) => p.is_online && p.status === 'approved') },
            { value: 'pending', label: 'Pending', count: n((p) => p.status === 'pending') },
            { value: 'draft', label: 'Incomplete', count: n((p) => p.status === 'draft') },
            { value: 'rejected', label: 'Rejected', count: n((p) => p.status === 'rejected') },
            { value: 'featured', label: 'Featured', count: n((p) => p.is_featured) },
            { value: 'suspended', label: 'Suspended', count: n((p) => p.is_suspended) },
          ]}
        />
      </div>
      <DataTable
        rows={rows}
        exportName="professionals"
        onRow={(r) => go(`/pros/${r.id}`)}
        search={(r) => `${r.name} ${r.person} ${r.email} ${r.phone} ${r.base_address}`}
        toolbar={
          <Select
            value={level}
            onChange={setLevel}
            options={[
              { value: 'all', label: 'Any verification' },
              { value: '1', label: 'Basic' },
              { value: '2', label: 'ID verified' },
              { value: '3', label: 'Qualified' },
            ]}
          />
        }
        columns={[
          {
            key: 'name',
            label: 'Professional',
            sort: (r) => r.name ?? '',
            csv: (r) => r.name,
            render: (r) => (
              <div className="flex items-center gap-3">
                <div className="relative">
                  <Avatar name={r.name} url={r.avatar} />
                  {r.is_online && r.status === 'approved' && <span className="absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full border-2 border-white bg-emerald-500 dark:border-ink-900" />}
                </div>
                <div>
                  <div className="flex items-center gap-1 font-semibold">
                    {r.name}
                    {r.level >= 2 && <BadgeCheck className="h-4 w-4 text-blue-500" />}
                  </div>
                  <div className="text-xs text-ink-500">
                    {r.person} · {titleCase(r.account_type)}
                  </div>
                </div>
              </div>
            ),
          },
          { key: 'area', label: 'Base', render: (r) => <span className="block max-w-[200px] truncate text-ink-500">{r.base_address ? `${r.base_address} · ${r.radius_km} km` : 'Not set'}</span> },
          { key: 'services', label: 'Services', sort: (r) => r.services, render: (r) => r.services },
          {
            key: 'rating',
            label: 'Rating',
            sort: (r) => Number(r.rating),
            csv: (r) => r.rating,
            render: (r) => (
              <span className="inline-flex items-center gap-1">
                <Stars value={Number(r.rating)} /> <span className="text-xs text-ink-500">({r.rating_count})</span>
              </span>
            ),
          },
          { key: 'jobs', label: 'Jobs', sort: (r) => r.jobs_done, render: (r) => r.jobs_done },
          { key: 'earned', label: 'Earned', sort: (r) => Number(r.earned), render: (r) => money(r.earned) },
          { key: 'level', label: 'Verification', sort: (r) => r.level, csv: (r) => levelLabel(r.level), render: (r) => <Badge tone={r.level >= 3 ? 'green' : r.level >= 2 ? 'blue' : 'gray'}>{levelLabel(r.level)}</Badge> },
          {
            key: 'status',
            label: 'Status',
            sort: (r) => r.status,
            csv: (r) => r.status,
            render: (r) => (
              <div className="flex flex-wrap gap-1">
                <Badge tone={r.is_suspended ? 'red' : statusTone(r.status)} dot>
                  {r.is_suspended ? 'Suspended' : r.status === 'draft' ? 'Incomplete' : titleCase(r.status)}
                </Badge>
                {r.docs_pending > 0 && <Badge tone="yellow">{r.docs_pending} docs</Badge>}
                {r.is_featured && <Badge tone="orange">Featured</Badge>}
              </div>
            ),
          },
          { key: 'joined', label: 'Joined', sort: (r) => r.created_at, csv: (r) => r.created_at, render: (r) => date(r.created_at) },
        ]}
      />
    </div>
  )
}
