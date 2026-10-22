import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useLoad } from '../lib/hooks'
import { db, q } from '../lib/supabase'
import { dateTime, titleCase } from '../lib/format'
import { people } from '../lib/people'
import { Avatar, Badge, DataTable, ErrorBox, Loading, PageHeader, Select } from '../components/ui'

const LINK: Record<string, string> = { booking: '/bookings/', professional: '/pros/', user: '/customers/' }

export default function Audit() {
  const go = useNavigate()
  const [entity, setEntity] = useState('all')
  const [who, setWho] = useState('all')
  const data = useLoad(async () => {
    const rows = await q<any[]>(db.from('admin_audit').select('*').order('created_at', { ascending: false }).limit(3000))
    return { rows, ppl: await people(rows.map((r) => r.admin_id)) }
  })
  const rows = useMemo(() => (data.data?.rows ?? []).filter((r) => (entity === 'all' || r.entity === entity) && (who === 'all' || r.admin_id === who)), [data.data, entity, who])
  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const { ppl } = data.data
  const admins = [...new Set(data.data.rows.map((r) => r.admin_id))]
  const entities = [...new Set(data.data.rows.map((r) => r.entity))]

  return (
    <div>
      <PageHeader title="Audit Log" subtitle="Every change made from this dashboard, who made it and when." />
      <DataTable
        rows={rows}
        exportName="audit-log"
        pageSize={25}
        onRow={(r) => LINK[r.entity] && go(LINK[r.entity] + r.entity_id)}
        search={(r) => `${r.action} ${r.entity} ${JSON.stringify(r.details)} ${ppl.get(r.admin_id)?.full_name}`}
        toolbar={
          <>
            <Select value={entity} onChange={setEntity} options={[{ value: 'all', label: 'Everything' }, ...entities.map((e) => ({ value: e, label: titleCase(e) }))]} />
            <Select value={who} onChange={setWho} options={[{ value: 'all', label: 'All admins' }, ...admins.map((a) => ({ value: a, label: ppl.get(a)?.full_name ?? 'Admin' }))]} />
          </>
        }
        columns={[
          { key: 'when', label: 'When', csv: (r) => r.created_at, render: (r) => <span className="text-ink-500">{dateTime(r.created_at)}</span> },
          { key: 'who', label: 'Admin', csv: (r) => ppl.get(r.admin_id)?.full_name, render: (r) => <div className="flex items-center gap-2"><Avatar name={ppl.get(r.admin_id)?.full_name} url={ppl.get(r.admin_id)?.avatar_url} size={26} />{ppl.get(r.admin_id)?.full_name}</div> },
          { key: 'action', label: 'Action', csv: (r) => r.action, render: (r) => <span className="font-semibold">{titleCase(r.action.replace('.', ' '))}</span> },
          { key: 'entity', label: 'On', csv: (r) => r.entity, render: (r) => <Badge>{titleCase(r.entity)}</Badge> },
          {
            key: 'details',
            label: 'Details',
            csv: (r) => JSON.stringify(r.details),
            render: (r) => (
              <span className="block max-w-sm truncate text-xs text-ink-500">
                {Object.entries(r.details ?? {})
                  .filter(([, v]) => v !== null && v !== '')
                  .map(([k, v]) => `${titleCase(k)}: ${typeof v === 'object' ? JSON.stringify(v) : v}`)
                  .join(' · ') || '—'}
              </span>
            ),
          },
        ]}
      />
    </div>
  )
}
