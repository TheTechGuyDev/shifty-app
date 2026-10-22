import { useState } from 'react'
import { Megaphone, Send } from 'lucide-react'
import { useLoad } from '../lib/hooks'
import { db, q, rpc } from '../lib/supabase'
import { dateTime, num, titleCase } from '../lib/format'
import { people } from '../lib/people'
import { Badge, Button, Card, DataTable, Field, PageHeader, Select, useAction, useUi } from '../components/ui'

const AUDIENCES = [
  { value: 'all', label: 'Everyone' },
  { value: 'customers', label: 'Customers only' },
  { value: 'pros', label: 'Approved professionals' },
  { value: 'pros_online', label: 'Professionals online now' },
  { value: 'pros_pending', label: 'Professionals not yet approved' },
]
const TEMPLATES = [
  { title: 'Weekend special 🎉', body: 'Book any cleaning this weekend and get 20% off with code WEEKEND20.', type: 'offer', audience: 'customers' },
  { title: 'High demand right now', body: 'Lots of customers are booking near you. Go online to get more jobs.', type: 'message', audience: 'pros' },
  { title: 'Finish your application', body: 'You’re almost there. Upload a valid ID to get approved and start earning.', type: 'reminder', audience: 'pros_pending' },
  { title: 'Scheduled maintenance', body: 'The app will be briefly unavailable tonight from 1am to 2am.', type: 'message', audience: 'all' },
]

export default function Broadcasts() {
  const { confirm } = useUi()
  const { busy, run } = useAction()
  const [audience, setAudience] = useState('customers')
  const [type, setType] = useState('offer')
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const history = useLoad(async () => {
    const rows = await q<any[]>(db.from('broadcasts').select('*').order('created_at', { ascending: false }))
    const ppl = await people(rows.map((r) => r.sent_by))
    return rows.map((r) => ({ ...r, by: ppl.get(r.sent_by)?.full_name }))
  })

  const send = async () => {
    if (!(await confirm({ title: `Send to ${AUDIENCES.find((a) => a.value === audience)?.label.toLowerCase()}?`, message: 'It appears in their notifications right away. This can’t be undone.', confirm: 'Send now' }))) return
    let n = 0
    const ok = await run('send', async () => {
      n = await rpc<number>('admin_broadcast', { p_audience: audience, p_type: type, p_title: title.trim(), p_body: body.trim() })
    })
    if (ok) {
      setTitle('')
      setBody('')
      history.reload()
      await confirm({ title: 'Broadcast sent', message: `Delivered to ${num(n)} people.`, confirm: 'Done' })
    }
  }

  return (
    <div>
      <PageHeader title="Broadcasts" subtitle="Send an in-app notification to a group of users." />
      <div className="grid gap-6 xl:grid-cols-[1fr_340px]">
        <Card title="New broadcast">
          <div className="mb-5 flex flex-wrap gap-2">
            {TEMPLATES.map((t) => (
              <button
                key={t.title}
                onClick={() => {
                  setTitle(t.title)
                  setBody(t.body)
                  setType(t.type)
                  setAudience(t.audience)
                }}
                className="rounded-full border border-ink-200 px-3 py-1.5 text-xs font-semibold hover:border-brand-400 hover:text-brand-600 dark:border-ink-700"
              >
                {t.title}
              </button>
            ))}
          </div>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Who gets it">
              <Select className="w-full" value={audience} onChange={setAudience} options={AUDIENCES} />
            </Field>
            <Field label="Type">
              <Select
                className="w-full"
                value={type}
                onChange={setType}
                options={[
                  { value: 'offer', label: 'Offer' },
                  { value: 'message', label: 'Announcement' },
                  { value: 'reminder', label: 'Reminder' },
                  { value: 'order', label: 'Order update' },
                ]}
              />
            </Field>
            <div className="sm:col-span-2">
              <Field label={`Title (${title.length}/60)`}>
                <input className="input" maxLength={60} value={title} onChange={(e) => setTitle(e.target.value)} />
              </Field>
            </div>
            <div className="sm:col-span-2">
              <Field label={`Message (${body.length}/300)`}>
                <textarea className="input h-28 py-2" maxLength={300} value={body} onChange={(e) => setBody(e.target.value)} />
              </Field>
            </div>
          </div>
          <div className="mt-5 flex justify-end">
            <Button icon={<Send className="h-4 w-4" />} loading={busy === 'send'} disabled={title.trim().length < 3 || body.trim().length < 5} onClick={send}>
              Send broadcast
            </Button>
          </div>
        </Card>
        <Card title="Preview">
          <div className="mx-auto w-full max-w-[280px] rounded-[2rem] border-8 border-ink-900 bg-ink-100 p-3 dark:border-ink-700 dark:bg-ink-800">
            <div className="mb-3 text-center text-xs font-semibold text-ink-500">Notifications</div>
            <div className="rounded-2xl bg-white p-3 shadow dark:bg-ink-900">
              <div className="flex items-start gap-2.5">
                <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-brand-50 text-brand-500">
                  <Megaphone className="h-4 w-4" />
                </span>
                <div className="min-w-0">
                  <div className="text-sm font-bold">{title || 'Your title'}</div>
                  <div className="mt-0.5 text-xs text-ink-500">{body || 'Your message shows here.'}</div>
                  <div className="mt-1 text-[10px] text-ink-400">Just now</div>
                </div>
              </div>
            </div>
          </div>
        </Card>
      </div>
      <h2 className="mb-3 mt-8 text-lg font-bold">History</h2>
      <DataTable
        rows={history.data ?? []}
        exportName="broadcasts"
        columns={[
          { key: 'when', label: 'Sent', render: (r) => dateTime(r.created_at), csv: (r) => r.created_at },
          { key: 'title', label: 'Title', render: (r) => <div><div className="font-semibold">{r.title}</div><div className="max-w-md truncate text-xs text-ink-500">{r.body}</div></div>, csv: (r) => r.title },
          { key: 'aud', label: 'Audience', render: (r) => <Badge>{AUDIENCES.find((a) => a.value === r.audience)?.label}</Badge>, csv: (r) => r.audience },
          { key: 'type', label: 'Type', render: (r) => titleCase(r.type) },
          { key: 'n', label: 'Recipients', render: (r) => num(r.recipients) },
          { key: 'by', label: 'Sent by', render: (r) => r.by ?? '—' },
        ]}
      />
    </div>
  )
}
