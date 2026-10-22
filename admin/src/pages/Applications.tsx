import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { CheckCircle2, FileText, MapPin, XCircle } from 'lucide-react'
import { useLoad } from '../lib/hooks'
import { db, q, rpc } from '../lib/supabase'
import { ago, titleCase } from '../lib/format'
import { people } from '../lib/people'
import { Avatar, Badge, Button, Card, Empty, ErrorBox, Loading, PageHeader, Tabs, statusTone, useAction, useUi } from '../components/ui'
import { openDocument } from './ProDetail'

export default function Applications() {
  const go = useNavigate()
  const { confirm, toast } = useUi()
  const { busy, run } = useAction()
  const [tab, setTab] = useState<'pending' | 'draft' | 'rejected'>('pending')
  const data = useLoad(async () => {
    const pros = await q<any[]>(db.from('professional_profiles').select('*').in('status', ['pending', 'draft', 'rejected']).order('updated_at', { ascending: true }))
    const ids = pros.map((p) => p.user_id)
    const [docs, services, cats] = await Promise.all([
      ids.length ? q<any[]>(db.from('verification_documents').select('*').in('pro_id', ids)) : Promise.resolve([]),
      ids.length ? q<any[]>(db.from('pro_services').select('pro_id, category_id').in('pro_id', ids)) : Promise.resolve([]),
      q<any[]>(db.from('service_categories').select('id, name')),
    ])
    const ppl = await people(ids)
    const cat = new Map(cats.map((c) => [c.id, c.name]))
    return pros.map((p) => ({
      ...p,
      person: ppl.get(p.user_id),
      docs: docs.filter((d) => d.pro_id === p.user_id),
      services: services.filter((s) => s.pro_id === p.user_id).map((s) => cat.get(s.category_id)),
    }))
  })

  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const list = data.data.filter((p) => p.status === tab)

  const decide = async (p: any, status: 'approved' | 'rejected') => {
    const note = await confirm({
      title: status === 'approved' ? `Approve ${p.business_name || p.person?.full_name}?` : 'Send back for changes?',
      message: status === 'approved' ? 'Their pending documents stay pending until you review them.' : undefined,
      input: status === 'rejected' ? 'What should they fix?' : undefined,
      inputRequired: status === 'rejected',
      confirm: status === 'approved' ? 'Approve' : 'Send back',
      danger: status === 'rejected',
    })
    if (note) run(p.user_id, () => rpc('admin_set_pro_status', { p_pro: p.user_id, p_status: status, p_note: status === 'rejected' ? note : null }), status === 'approved' ? 'Approved' : 'Sent back').then(data.reload)
  }

  return (
    <div>
      <PageHeader title="Applications" subtitle="Professionals waiting to be approved. Oldest first." />
      <div className="mb-5">
        <Tabs
          value={tab}
          onChange={setTab}
          items={[
            { value: 'pending', label: 'Submitted', count: data.data.filter((p) => p.status === 'pending').length },
            { value: 'draft', label: 'Still filling in', count: data.data.filter((p) => p.status === 'draft').length },
            { value: 'rejected', label: 'Sent back', count: data.data.filter((p) => p.status === 'rejected').length },
          ]}
        />
      </div>
      {list.length === 0 ? (
        <Card>
          <Empty title="No applications here" message={tab === 'pending' ? 'New submissions will show up here.' : undefined} icon={<CheckCircle2 />} />
        </Card>
      ) : (
        <div className="grid gap-4 lg:grid-cols-2">
          {list.map((p) => {
            const name = p.business_name || p.person?.full_name
            const hasId = p.docs.some((d: any) => !['certificate', 'license'].includes(d.kind))
            return (
              <div key={p.user_id} className="card p-5">
                <div className="flex items-start gap-3">
                  <Avatar name={name} url={p.person?.avatar_url} size={48} />
                  <div className="min-w-0 flex-1">
                    <button onClick={() => go(`/pros/${p.user_id}`)} className="text-left font-bold hover:text-brand-600">
                      {name}
                    </button>
                    <div className="text-xs text-ink-500">
                      {p.person?.full_name} · {titleCase(p.account_type)} · {p.years_experience ?? 0} yrs · updated {ago(p.updated_at)}
                    </div>
                  </div>
                  <Badge tone={statusTone(p.status)}>{p.status === 'draft' ? 'Incomplete' : titleCase(p.status)}</Badge>
                </div>
                {p.bio && <p className="mt-3 line-clamp-3 text-sm text-ink-600 dark:text-ink-300">{p.bio}</p>}
                <div className="mt-3 flex flex-wrap gap-1.5">
                  {p.services.slice(0, 6).map((s: string) => (
                    <Badge key={s}>{s}</Badge>
                  ))}
                  {p.services.length === 0 && <span className="text-xs text-ink-400">No services yet</span>}
                </div>
                {p.base_address && (
                  <p className="mt-3 flex items-center gap-1 text-xs text-ink-500">
                    <MapPin className="h-3.5 w-3.5" /> {p.base_address} · {p.radius_km} km
                  </p>
                )}
                <div className="mt-4 space-y-1.5 rounded-xl bg-ink-50 p-3 dark:bg-ink-850">
                  {p.docs.length === 0 && <p className="text-xs text-red-500">No documents uploaded</p>}
                  {p.docs.map((d: any) => (
                    <div key={d.id} className="flex items-center gap-2 text-sm">
                      <FileText className="h-4 w-4 text-ink-400" />
                      <button className="flex-1 truncate text-left hover:text-brand-600" onClick={() => openDocument(d.file_path).catch((e) => toast(e.message, 'error'))}>
                        {d.title || titleCase(d.kind)}
                      </button>
                      <Badge tone={statusTone(d.status)}>{titleCase(d.status)}</Badge>
                    </div>
                  ))}
                </div>
                <div className="mt-4 flex flex-wrap gap-2">
                  <Button size="sm" variant="success" icon={<CheckCircle2 className="h-3.5 w-3.5" />} loading={busy === p.user_id} disabled={!hasId || !p.services.length} onClick={() => decide(p, 'approved')}>
                    Approve
                  </Button>
                  <Button size="sm" variant="secondary" icon={<XCircle className="h-3.5 w-3.5" />} onClick={() => decide(p, 'rejected')}>
                    Request changes
                  </Button>
                  <Button size="sm" variant="ghost" onClick={() => go(`/pros/${p.user_id}`)}>
                    Full profile
                  </Button>
                </div>
                {(!hasId || !p.services.length) && <p className="mt-2 text-xs text-ink-500">Approval needs an ID document and at least one service.</p>}
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
