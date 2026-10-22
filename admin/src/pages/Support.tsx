import { useEffect, useMemo, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, Send, User, Zap } from 'lucide-react'
import { useLoad } from '../lib/hooks'
import { db, q, rpc } from '../lib/supabase'
import { ago, time, titleCase } from '../lib/format'
import { Avatar, Badge, Button, Empty, ErrorBox, Loading, PageHeader, SearchInput, Select, Tabs, cx, statusTone, useAction } from '../components/ui'

const QUICK = [
  'Hi, thanks for reaching out. I’m looking into this now.',
  'Sorry about this. I’ve escalated it to our operations team and will update you shortly.',
  'Could you share your booking reference so I can check?',
  'Your refund has been processed. It may take 3 to 5 working days to reflect.',
  'This has been resolved. Is there anything else I can help with?',
]

export default function Support() {
  const go = useNavigate()
  const [tab, setTab] = useState<'open' | 'pending' | 'closed' | 'all'>('open')
  const [term, setTerm] = useState('')
  const [sel, setSel] = useState<string | null>(null)
  const inbox = useLoad(() => rpc<any[]>('admin_support_inbox'))

  useEffect(() => {
    const ch = db
      .channel('support-inbox')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'support_messages' }, () => inbox.reload())
      .subscribe()
    return () => {
      db.removeChannel(ch)
    }
  }, [])

  const list = useMemo(
    () =>
      (inbox.data ?? []).filter(
        (t) => (tab === 'all' || t.status === tab) && (!term || `${t.name} ${t.email} ${t.last_body}`.toLowerCase().includes(term.toLowerCase())),
      ),
    [inbox.data, tab, term],
  )

  if (inbox.error) return <ErrorBox message={inbox.error} onRetry={inbox.reload} />
  if (!inbox.data) return <Loading />
  const current = inbox.data.find((t) => t.user_id === sel)

  return (
    <div>
      <PageHeader title="Support Inbox" subtitle="Conversations from the in-app Help chat. Replies appear in the customer’s app instantly." />
      <div className="card grid h-[calc(100vh-220px)] min-h-[520px] overflow-hidden lg:grid-cols-[360px_1fr]">
        <div className={cx('flex min-h-0 flex-col border-r border-ink-100 dark:border-ink-800', sel && 'hidden lg:flex')}>
          <div className="space-y-3 border-b border-ink-100 p-4 dark:border-ink-800">
            <SearchInput value={term} onChange={setTerm} />
            <Tabs
              value={tab}
              onChange={setTab}
              items={(['open', 'pending', 'closed', 'all'] as const).map((s) => ({ value: s, label: s === 'pending' ? 'Replied' : titleCase(s), count: s === 'all' ? inbox.data!.length : inbox.data!.filter((t) => t.status === s).length }))}
            />
          </div>
          <div className="scrollbar-thin flex-1 overflow-y-auto">
            {list.length === 0 && <Empty title="No conversations" />}
            {list.map((t) => (
              <button
                key={t.user_id}
                onClick={() => setSel(t.user_id)}
                className={cx('flex w-full gap-3 border-b border-ink-100 px-4 py-3 text-left transition dark:border-ink-800', sel === t.user_id ? 'bg-brand-50 dark:bg-ink-850' : 'hover:bg-ink-50 dark:hover:bg-ink-850')}
              >
                <Avatar name={t.name} url={t.avatar} size={40} />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <span className="truncate text-sm font-semibold">{t.name || t.email}</span>
                    <span className="ml-auto shrink-0 text-[11px] text-ink-400">{ago(t.last_at)}</span>
                  </div>
                  <p className={cx('truncate text-xs', t.last_sender === 'user' ? 'font-semibold text-ink-700 dark:text-ink-200' : 'text-ink-500')}>
                    {t.last_sender === 'agent' && 'You: '}
                    {t.last_body}
                  </p>
                  <div className="mt-1 flex gap-1">
                    <Badge tone={statusTone(t.status)}>{t.status === 'pending' ? 'Replied' : titleCase(t.status)}</Badge>
                    {t.priority !== 'normal' && <Badge tone={statusTone(t.priority)}>{titleCase(t.priority)}</Badge>}
                  </div>
                </div>
              </button>
            ))}
          </div>
        </div>
        <div className={cx('min-h-0', !sel && 'hidden lg:block')}>
          {current ? (
            <Thread key={current.user_id} t={current} onBack={() => setSel(null)} onChange={inbox.reload} onProfile={() => go(`/customers/${current.user_id}`)} />
          ) : (
            <div className="flex h-full items-center justify-center">
              <Empty title="Choose a conversation" message="Pick a customer on the left to read and reply." />
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

function Thread({ t, onBack, onChange, onProfile }: { t: any; onBack: () => void; onChange: () => void; onProfile: () => void }) {
  const [text, setText] = useState('')
  const [quick, setQuick] = useState(false)
  const { busy, run } = useAction()
  const end = useRef<HTMLDivElement>(null)
  const msgs = useLoad(() => q<any[]>(db.from('support_messages').select('*').eq('user_id', t.user_id).order('created_at')), [t.user_id])

  useEffect(() => {
    const ch = db
      .channel('support-' + t.user_id)
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'support_messages', filter: `user_id=eq.${t.user_id}` }, () => msgs.reload())
      .subscribe()
    return () => {
      db.removeChannel(ch)
    }
  }, [t.user_id])
  useEffect(() => end.current?.scrollIntoView({ behavior: 'smooth' }), [msgs.data])

  const send = () =>
    run('send', async () => {
      await rpc('admin_support_reply', { p_user: t.user_id, p_body: text.trim() })
      setText('')
      msgs.reload()
      onChange()
    })

  const update = (status?: string, priority?: string) =>
    run('upd', () => rpc('admin_support_update', { p_user: t.user_id, p_status: status ?? null, p_priority: priority ?? null, p_assign: null }), 'Updated').then(onChange)

  return (
    <div className="flex h-full flex-col">
      <div className="flex flex-wrap items-center gap-3 border-b border-ink-100 px-4 py-3 dark:border-ink-800">
        <button className="lg:hidden" onClick={onBack}>
          <ArrowLeft className="h-5 w-5" />
        </button>
        <Avatar name={t.name} url={t.avatar} />
        <div className="min-w-0 flex-1">
          <div className="truncate font-semibold">{t.name}</div>
          <div className="truncate text-xs text-ink-500">{t.email}</div>
        </div>
        <Select value={t.priority} onChange={(v) => update(undefined, v)} options={['low', 'normal', 'high', 'urgent'].map((p) => ({ value: p, label: `${titleCase(p)} priority` }))} />
        <Select
          value={t.status}
          onChange={(v) => update(v)}
          options={[
            { value: 'open', label: 'Open' },
            { value: 'pending', label: 'Replied' },
            { value: 'closed', label: 'Closed' },
          ]}
        />
        <Button size="sm" variant="secondary" icon={<User className="h-3.5 w-3.5" />} onClick={onProfile}>
          Profile
        </Button>
      </div>
      <div className="scrollbar-thin flex-1 space-y-3 overflow-y-auto bg-ink-50 p-4 dark:bg-ink-950">
        {(msgs.data ?? []).map((m) => (
          <div key={m.id} className={cx('flex', m.sender === 'agent' ? 'justify-end' : 'justify-start')}>
            <div className={cx('max-w-[75%] rounded-2xl px-4 py-2.5 text-sm', m.sender === 'agent' ? 'rounded-br-md bg-brand-500 text-white' : 'rounded-bl-md bg-white shadow-sm dark:bg-ink-850')}>
              {m.sender === 'agent' && m.agent_name && <div className="mb-0.5 text-[11px] font-semibold opacity-80">{m.agent_name}</div>}
              <p className="whitespace-pre-wrap">{m.body}</p>
              <div className={cx('mt-1 text-right text-[10px]', m.sender === 'agent' ? 'text-white/70' : 'text-ink-400')}>{time(m.created_at)}</div>
            </div>
          </div>
        ))}
        <div ref={end} />
      </div>
      <div className="border-t border-ink-100 p-3 dark:border-ink-800">
        {quick && (
          <div className="mb-2 flex flex-wrap gap-1.5">
            {QUICK.map((qk) => (
              <button
                key={qk}
                onClick={() => {
                  setText(qk)
                  setQuick(false)
                }}
                className="rounded-full border border-ink-200 px-3 py-1 text-left text-xs hover:border-brand-400 dark:border-ink-700"
              >
                {qk}
              </button>
            ))}
          </div>
        )}
        <div className="flex items-end gap-2">
          <button title="Quick replies" onClick={() => setQuick(!quick)} className="rounded-xl p-2.5 text-ink-500 hover:bg-ink-100 dark:hover:bg-ink-800">
            <Zap className="h-5 w-5" />
          </button>
          <textarea
            className="input min-h-[44px] flex-1 resize-none py-2.5"
            rows={1}
            placeholder="Write a reply…"
            value={text}
            onChange={(e) => setText(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && !e.shiftKey && text.trim()) {
                e.preventDefault()
                send()
              }
            }}
          />
          <Button loading={busy === 'send'} disabled={!text.trim()} onClick={send} icon={<Send className="h-4 w-4" />}>
            Send
          </Button>
        </div>
      </div>
    </div>
  )
}
