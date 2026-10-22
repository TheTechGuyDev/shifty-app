import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { CheckCircle2, Eye, XCircle } from 'lucide-react'
import { useLoad } from '../lib/hooks'
import { db, q, rpc } from '../lib/supabase'
import { dateTime, titleCase } from '../lib/format'
import { people } from '../lib/people'
import { Avatar, Badge, Button, DataTable, ErrorBox, Loading, PageHeader, Tabs, statusTone, useAction, useUi } from '../components/ui'
import { openDocument } from './ProDetail'

export default function Verification() {
  const go = useNavigate()
  const { confirm, toast } = useUi()
  const { busy, run } = useAction()
  const [tab, setTab] = useState<'pending' | 'approved' | 'rejected'>('pending')
  const data = useLoad(async () => {
    const docs = await q<any[]>(db.from('verification_documents').select('*').order('created_at', { ascending: true }))
    return { docs, ppl: await people(docs.map((d) => d.pro_id)) }
  })
  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const { docs, ppl } = data.data

  const decide = async (d: any, status: string) => {
    const note = await confirm({
      title: status === 'approved' ? 'Approve this document?' : 'Reject this document?',
      message: status === 'approved' ? 'ID documents raise the pro to “ID verified”, certificates to “Qualified”.' : undefined,
      input: status === 'rejected' ? 'Reason (sent to the professional)' : undefined,
      inputRequired: status === 'rejected',
      danger: status === 'rejected',
      confirm: status === 'approved' ? 'Approve' : 'Reject',
    })
    if (note) run(d.id, () => rpc('admin_review_document', { p_doc: d.id, p_status: status, p_note: status === 'rejected' ? note : null }), 'Document updated').then(data.reload)
  }

  return (
    <div>
      <PageHeader title="Verification" subtitle="IDs, CAC certificates and trade licences uploaded by professionals." />
      <div className="mb-4">
        <Tabs value={tab} onChange={setTab} items={(['pending', 'approved', 'rejected'] as const).map((s) => ({ value: s, label: titleCase(s), count: docs.filter((d) => d.status === s).length }))} />
      </div>
      <DataTable
        rows={docs.filter((d) => d.status === tab)}
        search={(d) => `${d.title} ${d.kind} ${ppl.get(d.pro_id)?.full_name}`}
        exportName="documents"
        columns={[
          {
            key: 'pro',
            label: 'Professional',
            csv: (d) => ppl.get(d.pro_id)?.full_name,
            render: (d) => {
              const p = ppl.get(d.pro_id)
              return (
                <button onClick={() => go(`/pros/${d.pro_id}`)} className="flex items-center gap-2 font-semibold hover:text-brand-600">
                  <Avatar name={p?.full_name} url={p?.avatar_url} size={30} /> {p?.full_name}
                </button>
              )
            },
          },
          { key: 'title', label: 'Document', csv: (d) => d.title, render: (d) => <div><div className="font-medium">{d.title || titleCase(d.kind)}</div><div className="text-xs text-ink-500">{titleCase(d.kind)}</div></div> },
          { key: 'type', label: 'Type', csv: (d) => (['certificate', 'license'].includes(d.kind) ? 'Qualification' : 'Identity'), render: (d) => <Badge tone={['certificate', 'license'].includes(d.kind) ? 'purple' : 'blue'}>{['certificate', 'license'].includes(d.kind) ? 'Qualification' : 'Identity'}</Badge> },
          { key: 'date', label: 'Uploaded', sort: (d) => d.created_at, csv: (d) => d.created_at, render: (d) => dateTime(d.created_at) },
          { key: 'status', label: 'Status', csv: (d) => d.status, render: (d) => <div><Badge tone={statusTone(d.status)}>{titleCase(d.status)}</Badge>{d.note && <div className="mt-1 max-w-[200px] truncate text-xs text-ink-500">{d.note}</div>}</div> },
          {
            key: 'actions',
            label: '',
            render: (d) => (
              <div className="flex justify-end gap-1.5">
                <Button size="sm" variant="secondary" icon={<Eye className="h-3.5 w-3.5" />} onClick={() => openDocument(d.file_path).catch((e) => toast(e.message, 'error'))}>
                  View
                </Button>
                {d.status !== 'approved' && (
                  <Button size="sm" variant="success" icon={<CheckCircle2 className="h-3.5 w-3.5" />} loading={busy === d.id} onClick={() => decide(d, 'approved')}>
                    Approve
                  </Button>
                )}
                {d.status !== 'rejected' && (
                  <Button size="sm" variant="ghost" icon={<XCircle className="h-3.5 w-3.5" />} onClick={() => decide(d, 'rejected')}>
                    Reject
                  </Button>
                )}
              </div>
            ),
          },
        ]}
      />
    </div>
  )
}
