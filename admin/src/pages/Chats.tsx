import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { EyeOff, MessagesSquare } from 'lucide-react'
import { useAuth } from '../lib/auth'
import { useLoad } from '../lib/hooks'
import { db, q } from '../lib/supabase'
import { ago, dateTime } from '../lib/format'
import { people } from '../lib/people'
import { Avatar, Badge, Button, DataTable, Drawer, ErrorBox, Loading, PageHeader, Stat, Tabs } from '../components/ui'
import { ChatLog } from './BookingDetail'

export default function Chats() {
  const go = useNavigate()
  const { can } = useAuth()
  const [tab, setTab] = useState<'hidden' | 'threads'>('hidden')
  const [open, setOpen] = useState<string | null>(null)
  const data = useLoad(async () => {
    const msgs = await q<any[]>(db.from('messages').select('*').order('created_at', { ascending: false }).limit(3000))
    const ids = [...new Set(msgs.map((m) => m.booking_id))]
    const bookings = ids.length ? await q<any[]>(db.from('bookings').select('id, reference, service_name, customer_id, professional_id').in('id', ids)) : []
    const ppl = await people([...msgs.map((m) => m.sender_id), ...bookings.flatMap((b) => [b.customer_id, b.professional_id])])
    return { msgs, bookings: new Map(bookings.map((b) => [b.id, b])), ppl }
  })

  const threads = useMemo(() => {
    if (!data.data) return []
    const m = new Map<string, any>()
    data.data.msgs.forEach((msg) => {
      const t = m.get(msg.booking_id) ?? { id: msg.booking_id, count: 0, hidden: 0, last: msg.created_at, media: 0 }
      t.count++
      if (msg.is_masked) t.hidden++
      if (msg.kind !== 'text') t.media++
      m.set(msg.booking_id, t)
    })
    return [...m.values()].map((t) => ({ ...t, b: data.data!.bookings.get(t.id) }))
  }, [data.data])

  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const { msgs, ppl, bookings } = data.data
  const hidden = msgs.filter((m) => m.is_masked)
  const offenders = new Map<string, number>()
  hidden.forEach((m) => offenders.set(m.sender_id, (offenders.get(m.sender_id) ?? 0) + 1))
  const openThread = open ? msgs.filter((m) => m.booking_id === open).reverse() : []

  return (
    <div>
      <PageHeader title="Chat Moderation" subtitle="Customer and professional chats. Messages with phone numbers, emails or social handles are hidden automatically." />
      <div className="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-3">
        <Stat label="Conversations" value={threads.length} icon={<MessagesSquare className="h-5 w-5" />} />
        <Stat label="Hidden messages" value={hidden.length} icon={<EyeOff className="h-5 w-5" />} tone="yellow" />
        <Stat label="People with 3+ hidden" value={[...offenders.values()].filter((n) => n >= 3).length} icon={<EyeOff className="h-5 w-5" />} tone="red" hint="Consider a warning or suspension" />
      </div>
      <div className="mb-4">
        <Tabs
          value={tab}
          onChange={setTab}
          items={[
            { value: 'hidden', label: 'Hidden messages', count: hidden.length },
            { value: 'threads', label: 'All conversations', count: threads.length },
          ]}
        />
      </div>
      {tab === 'hidden' ? (
        <DataTable
          rows={hidden}
          exportName="hidden-messages"
          onRow={(m) => setOpen(m.booking_id)}
          search={(m) => `${ppl.get(m.sender_id)?.full_name} ${bookings.get(m.booking_id)?.reference}`}
          columns={[
            {
              key: 'who',
              label: 'Sent by',
              csv: (m) => ppl.get(m.sender_id)?.full_name,
              render: (m) => (
                <div className="flex items-center gap-2">
                  <Avatar name={ppl.get(m.sender_id)?.full_name} url={ppl.get(m.sender_id)?.avatar_url} size={28} />
                  <span className="font-semibold">{ppl.get(m.sender_id)?.full_name}</span>
                  {(offenders.get(m.sender_id) ?? 0) >= 3 && <Badge tone="red">{offenders.get(m.sender_id)}×</Badge>}
                </div>
              ),
            },
            { key: 'role', label: 'Role', csv: (m) => (bookings.get(m.booking_id)?.customer_id === m.sender_id ? 'Customer' : 'Professional'), render: (m) => (bookings.get(m.booking_id)?.customer_id === m.sender_id ? <Badge tone="blue">Customer</Badge> : <Badge tone="orange">Professional</Badge>) },
            { key: 'booking', label: 'Booking', csv: (m) => bookings.get(m.booking_id)?.reference, render: (m) => `#${bookings.get(m.booking_id)?.reference ?? ''} · ${bookings.get(m.booking_id)?.service_name ?? ''}` },
            { key: 'when', label: 'When', sort: (m) => m.created_at, csv: (m) => m.created_at, render: (m) => dateTime(m.created_at) },
          ]}
        />
      ) : (
        <DataTable
          rows={threads}
          onRow={(t) => setOpen(t.id)}
          search={(t) => `${t.b?.reference} ${t.b?.service_name} ${ppl.get(t.b?.customer_id)?.full_name} ${ppl.get(t.b?.professional_id)?.full_name}`}
          columns={[
            { key: 'booking', label: 'Booking', render: (t) => <div><div className="font-semibold">{t.b?.service_name}</div><div className="text-xs text-ink-500">#{t.b?.reference}</div></div> },
            { key: 'cust', label: 'Customer', render: (t) => ppl.get(t.b?.customer_id)?.full_name },
            { key: 'pro', label: 'Professional', render: (t) => ppl.get(t.b?.professional_id)?.full_name },
            { key: 'count', label: 'Messages', sort: (t) => t.count, render: (t) => t.count },
            { key: 'media', label: 'Photos/videos', sort: (t) => t.media, render: (t) => t.media },
            { key: 'hidden', label: 'Hidden', sort: (t) => t.hidden, render: (t) => (t.hidden ? <Badge tone="yellow">{t.hidden}</Badge> : '0') },
            { key: 'last', label: 'Last message', sort: (t) => t.last, render: (t) => ago(t.last) },
          ]}
        />
      )}
      <Drawer
        open={!!open}
        onClose={() => setOpen(null)}
        title={open ? `#${bookings.get(open)?.reference} · ${bookings.get(open)?.service_name}` : ''}
        footer={
          <Button variant="secondary" onClick={() => go(`/bookings/${open}`)}>
            Open booking
          </Button>
        }
      >
        {open && <ChatLog msgs={openThread} ppl={ppl} canModerate={can('chat.moderate')} onChange={data.reload} />}
      </Drawer>
    </div>
  )
}
