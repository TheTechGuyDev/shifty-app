import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import {
  ArrowLeft, Bell, CalendarClock, CheckCircle2, CircleDollarSign, EyeOff, MapPin, MessageSquare, Navigation, Trash2, UserCheck, XCircle,
} from 'lucide-react'
import { useAuth } from '../lib/auth'
import { useLoad } from '../lib/hooks'
import { db, q, rpc } from '../lib/supabase'
import { ago, dateTime, money, time, titleCase } from '../lib/format'
import { people } from '../lib/people'
import type { Booking } from '../lib/types'
import {
  Avatar, Badge, Button, Card, ErrorBox, Field, KeyValue, Loading, Modal, Select, Stars, statusTone, useAction, useUi,
} from '../components/ui'
import MapView from '../components/MapView'
import Notes from '../components/Notes'
import Candidates from '../components/Candidates'

const STAGES = ['assigned', 'on_the_way', 'arrived', 'started', 'completed']

export default function BookingDetail() {
  const { id = '' } = useParams()
  const go = useNavigate()
  const { can } = useAuth()
  const { confirm } = useUi()
  const { busy, run } = useAction()
  const [pick, setPick] = useState(false)
  const [resched, setResched] = useState(false)
  const [notify, setNotify] = useState<null | 'customer' | 'pro'>(null)

  const data = useLoad(async () => {
    const b = await q<Booking>(db.from('bookings').select('*').eq('id', id).single())
    const [offers, review, msgs, audit] = await Promise.all([
      q<any[]>(db.from('booking_offers').select('*').eq('booking_id', id).order('created_at')),
      q<any[]>(db.from('reviews').select('*').eq('booking_id', id)),
      can('chat.view') ? q<any[]>(db.from('messages').select('*').eq('booking_id', id).order('created_at')) : Promise.resolve([]),
      can('audit.view') ? q<any[]>(db.from('admin_audit').select('*').eq('entity_id', id).order('created_at')) : Promise.resolve([]),
    ])
    const ppl = await people([b.customer_id, b.professional_id, ...offers.map((o) => o.pro_id), ...audit.map((a) => a.admin_id)])
    return { b, offers, review: review[0], msgs, audit, ppl }
  }, [id])

  // Live updates while the page is open.
  useEffect(() => {
    const ch = db
      .channel('booking-' + id)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'bookings', filter: `id=eq.${id}` }, () => data.reload())
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages', filter: `booking_id=eq.${id}` }, () => data.reload())
      .subscribe()
    return () => {
      db.removeChannel(ch)
    }
  }, [id])

  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const { b, offers, review, msgs, audit, ppl } = data.data
  const c = ppl.get(b.customer_id)
  const p = b.professional_id ? ppl.get(b.professional_id) : null
  const manage = can('bookings.manage')
  const open = b.status === 'pending' || b.status === 'active'
  const stageIdx = Math.max(0, STAGES.indexOf(b.progress ?? 'assigned'))

  const act = (key: string, fn: () => Promise<unknown>, ok: string) => run(key, fn, ok).then((r) => r && data.reload())

  const cancel = async () => {
    const reason = await confirm({ title: 'Cancel this booking?', message: 'The customer and professional are notified.', input: 'Reason (shown to the customer)', inputRequired: true, danger: true, confirm: 'Cancel booking' })
    if (reason) act('cancel', () => rpc('admin_cancel_booking', { p_booking: b.id, p_reason: reason }), 'Booking cancelled')
  }

  const pins = [
    ...(b.lat != null ? [{ lat: b.lat, lng: b.lng!, label: 'A', popup: b.address ?? '' }] : []),
    ...(b.dropoff_lat != null ? [{ lat: b.dropoff_lat, lng: b.dropoff_lng!, label: 'B', color: '#1B1D21', popup: b.dropoff_address ?? '' }] : []),
  ]

  return (
    <div className="space-y-6">
      <button onClick={() => go(-1)} className="inline-flex items-center gap-1.5 text-sm font-semibold text-ink-500 hover:text-ink-900 dark:hover:text-white">
        <ArrowLeft className="h-4 w-4" /> Back
      </button>
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <div className="flex flex-wrap items-center gap-2">
            <h1 className="text-2xl font-bold">{b.service_name}</h1>
            <Badge tone={statusTone(b.status)} dot>
              {titleCase(b.status)}
            </Badge>
            {b.status === 'active' && <Badge tone="blue">{titleCase(b.progress)}</Badge>}
          </div>
          <p className="mt-1 text-sm text-ink-500">
            #{b.reference} · placed {dateTime(b.created_at)} ({ago(b.created_at)})
          </p>
        </div>
        {manage && open && (
          <div className="flex flex-wrap gap-2">
            <Button icon={<UserCheck className="h-4 w-4" />} onClick={() => setPick(true)}>
              {b.professional_id ? 'Reassign' : 'Assign professional'}
            </Button>
            <Button variant="secondary" icon={<CalendarClock className="h-4 w-4" />} onClick={() => setResched(true)}>
              Reschedule
            </Button>
            <Button variant="danger" icon={<XCircle className="h-4 w-4" />} loading={busy === 'cancel'} onClick={cancel}>
              Cancel
            </Button>
          </div>
        )}
      </div>

      {b.reschedule_request && (
        <div className="rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800 dark:border-amber-900 dark:bg-amber-900/20 dark:text-amber-200">
          Professional asked to move this job to <b>{dateTime(b.reschedule_request.at)}</b>
          {b.reschedule_request.note ? `: “${b.reschedule_request.note}”` : ''}. Waiting for the customer.
        </div>
      )}

      <div className="grid gap-6 xl:grid-cols-3">
        <div className="space-y-6 xl:col-span-2">
          {/* Progress */}
          {b.status !== 'cancelled' && (
            <Card title="Job progress">
              <div className="flex items-center">
                {STAGES.map((s, i) => {
                  const done = b.status === 'done' || (b.status === 'active' && i <= stageIdx)
                  return (
                    <div key={s} className="flex flex-1 items-center last:flex-none">
                      <div className="flex flex-col items-center gap-1.5">
                        <span className={`flex h-9 w-9 items-center justify-center rounded-full text-xs font-bold ${done ? 'bg-emerald-500 text-white' : 'bg-ink-100 text-ink-400 dark:bg-ink-800'}`}>
                          {done ? <CheckCircle2 className="h-4 w-4" /> : i + 1}
                        </span>
                        <span className="whitespace-nowrap text-[11px] font-medium text-ink-500">{titleCase(s)}</span>
                      </div>
                      {i < STAGES.length - 1 && <div className={`mx-1 mb-5 h-1 flex-1 rounded ${done && (b.status === 'done' || i < stageIdx) ? 'bg-emerald-500' : 'bg-ink-100 dark:bg-ink-800'}`} />}
                    </div>
                  )
                })}
              </div>
              {manage && b.status === 'active' && (
                <div className="mt-5 flex flex-wrap items-center gap-2 border-t border-ink-100 pt-4 dark:border-ink-800">
                  <span className="text-sm text-ink-500">Update for the professional:</span>
                  {STAGES.slice(stageIdx + 1).map((s) => (
                    <Button
                      key={s}
                      size="sm"
                      variant={s === 'completed' ? 'success' : 'secondary'}
                      loading={busy === s}
                      onClick={async () => {
                        if (s === 'completed' && !(await confirm({ title: 'Mark as completed?', message: 'Commission is calculated and the customer is asked to rate the job.', confirm: 'Complete job' }))) return
                        act(s, () => rpc('admin_set_progress', { p_booking: b.id, p_stage: s }), `Marked ${titleCase(s)}`)
                      }}
                    >
                      {titleCase(s)}
                    </Button>
                  ))}
                </div>
              )}
            </Card>
          )}

          {pins.length > 0 && (
            <Card
              title="Location"
              actions={
                b.lat != null && (
                  <a className="inline-flex items-center gap-1 text-sm font-semibold text-brand-600" target="_blank" rel="noreferrer" href={`https://www.google.com/maps/dir/?api=1&destination=${b.lat},${b.lng}`}>
                    <Navigation className="h-4 w-4" /> Directions
                  </a>
                )
              }
            >
              <MapView pins={pins} height={260} />
              <div className="mt-4 space-y-2 text-sm">
                <div className="flex gap-2">
                  <MapPin className="h-4 w-4 shrink-0 text-brand-500" />
                  {b.address}
                </div>
                {b.dropoff_address && (
                  <div className="flex gap-2">
                    <MapPin className="h-4 w-4 shrink-0" />
                    {b.dropoff_address}
                  </div>
                )}
              </div>
            </Card>
          )}

          <Card title="Order details">
            <KeyValue
              items={[
                ['Scheduled', `${dateTime(b.scheduled_at)}${b.time_slot ? ` · ${b.time_slot}` : ''}`],
                ['Booking type', titleCase(b.kind)],
                ['Payment', `${titleCase(b.payment_method)} · ${titleCase(b.payment_status)}`],
                ['Promo code', b.promo_code ?? 'None'],
                ...Object.entries(b.details ?? {})
                  .filter(([, v]) => v !== null && v !== '' && typeof v !== 'object')
                  .map(([k, v]) => [titleCase(k), String(v)] as [string, string]),
              ]}
            />
            <div className="mt-6 rounded-2xl bg-ink-50 p-4 dark:bg-ink-850">
              {(b.breakdown ?? []).map((l, i) => (
                <div key={i} className="flex justify-between py-1 text-sm">
                  <span>
                    {l.label}
                    {l.note && <span className="text-ink-500"> · {l.note}</span>}
                  </span>
                  <span className="font-medium">{money(l.amount)}</span>
                </div>
              ))}
              <div className="flex justify-between py-1 text-sm">
                <span>Service charge</span>
                <span>{money(b.service_charge)}</span>
              </div>
              {Number(b.discount) > 0 && (
                <div className="flex justify-between py-1 text-sm text-emerald-600">
                  <span>Discount</span>
                  <span>-{money(b.discount)}</span>
                </div>
              )}
              <div className="mt-2 flex justify-between border-t border-ink-200 pt-3 font-bold dark:border-ink-700">
                <span>Total</span>
                <span>{money(b.total_amount)}</span>
              </div>
              {b.status === 'done' && (
                <div className="mt-3 grid grid-cols-2 gap-3 text-sm">
                  <div className="rounded-xl bg-white p-3 dark:bg-ink-900">
                    <div className="text-xs text-ink-500">Commission</div>
                    <div className="font-bold text-emerald-600">{money(b.commission)}</div>
                  </div>
                  <div className="rounded-xl bg-white p-3 dark:bg-ink-900">
                    <div className="text-xs text-ink-500">Professional earned</div>
                    <div className="font-bold">{money(b.pro_earning)}</div>
                  </div>
                </div>
              )}
            </div>
            {can('finance.manage') && (
              <div className="mt-4 flex flex-wrap items-center gap-2">
                <span className="text-sm text-ink-500">Set payment status:</span>
                {['paid', 'unpaid', 'refunded']
                  .filter((s) => s !== b.payment_status)
                  .map((s) => (
                    <Button
                      key={s}
                      size="sm"
                      variant="secondary"
                      icon={<CircleDollarSign className="h-3.5 w-3.5" />}
                      loading={busy === 'pay' + s}
                      onClick={async () => {
                        if (await confirm({ title: `Mark as ${s}?`, confirm: 'Update' })) act('pay' + s, () => rpc('admin_set_payment', { p_booking: b.id, p_status: s }), 'Payment updated')
                      }}
                    >
                      {titleCase(s)}
                    </Button>
                  ))}
              </div>
            )}
          </Card>

          {offers.length > 0 && (
            <Card title="Requests and quotes" subtitle="Professionals this job was sent to" pad={false}>
              <div className="divide-y divide-ink-100 dark:divide-ink-800">
                {offers.map((o) => {
                  const pr = ppl.get(o.pro_id)
                  return (
                    <div key={o.id} className="flex items-center gap-3 px-5 py-3">
                      <Avatar name={pr?.full_name} url={pr?.avatar_url} size={32} />
                      <button className="flex-1 text-left text-sm font-semibold hover:text-brand-600" onClick={() => go(`/pros/${o.pro_id}`)}>
                        {pr?.full_name}
                      </button>
                      {o.quote_amount && <span className="text-sm font-semibold">{money(o.quote_amount)}</span>}
                      <Badge tone={statusTone(o.status)}>{titleCase(o.status)}</Badge>
                      <span className="w-16 text-right text-xs text-ink-400">{ago(o.updated_at ?? o.created_at)}</span>
                    </div>
                  )
                })}
              </div>
            </Card>
          )}

          {((b.before_photos?.length ?? 0) > 0 || (b.after_photos?.length ?? 0) > 0) && (
            <Card title="Job photos">
              {(['before_photos', 'after_photos'] as const).map((k) =>
                (b[k]?.length ?? 0) > 0 ? (
                  <div key={k} className="mb-4">
                    <div className="label">{k === 'before_photos' ? 'Before' : 'After'}</div>
                    <div className="flex flex-wrap gap-2">
                      {b[k]!.map((u) => (
                        <a key={u} href={u} target="_blank" rel="noreferrer">
                          <img src={u} className="h-24 w-24 rounded-xl object-cover" alt="" />
                        </a>
                      ))}
                    </div>
                  </div>
                ) : null,
              )}
            </Card>
          )}

          {can('chat.view') && b.professional_id && <ChatLog msgs={msgs} ppl={ppl} canModerate={can('chat.moderate')} onChange={data.reload} />}
        </div>

        <div className="space-y-6">
          <PersonCard title="Customer" person={c} onOpen={() => go(`/customers/${b.customer_id}`)} onNotify={() => setNotify('customer')} />
          {p ? (
            <PersonCard title="Professional" person={p} onOpen={() => go(`/pros/${b.professional_id}`)} onNotify={() => setNotify('pro')} />
          ) : (
            <Card title="Professional">
              <p className="text-sm text-ink-500">Not assigned yet. {offers.length} professionals were notified.</p>
              {manage && open && (
                <Button className="mt-4 w-full" icon={<UserCheck className="h-4 w-4" />} onClick={() => setPick(true)}>
                  Find a professional
                </Button>
              )}
            </Card>
          )}
          {review && (
            <Card title="Customer review">
              <Stars value={review.rating} />
              {review.comment && <p className="mt-2 text-sm">{review.comment}</p>}
              {review.reply && <p className="mt-2 rounded-xl bg-ink-50 p-3 text-sm dark:bg-ink-850">Reply: {review.reply}</p>}
              <Badge tone={statusTone(review.status)}>{titleCase(review.status)}</Badge>
            </Card>
          )}
          <Notes entity="booking" id={b.id} />
          {audit.length > 0 && (
            <Card title="Admin activity">
              <ol className="space-y-3 border-l-2 border-ink-100 pl-4 dark:border-ink-800">
                {audit.map((a) => (
                  <li key={a.id} className="relative text-sm">
                    <span className="absolute -left-[21px] top-1.5 h-2.5 w-2.5 rounded-full bg-brand-500" />
                    <b>{titleCase(a.action.replace('.', ' '))}</b> by {ppl.get(a.admin_id)?.full_name ?? 'Admin'}
                    <div className="text-xs text-ink-500">{dateTime(a.created_at)}</div>
                  </li>
                ))}
              </ol>
            </Card>
          )}
        </div>
      </div>

      <Candidates bookingId={b.id} open={pick} onClose={() => setPick(false)} onDone={data.reload} />
      <RescheduleModal booking={b} open={resched} onClose={() => setResched(false)} onDone={data.reload} />
      <NotifyModal userId={notify === 'customer' ? b.customer_id : b.professional_id} open={!!notify} onClose={() => setNotify(null)} />
    </div>
  )
}

function PersonCard({ title, person, onOpen, onNotify }: { title: string; person?: any; onOpen: () => void; onNotify: () => void }) {
  return (
    <Card title={title}>
      <div className="flex items-center gap-3">
        <Avatar name={person?.full_name} url={person?.avatar_url} size={48} />
        <div className="min-w-0 flex-1">
          <button onClick={onOpen} className="truncate text-left font-semibold hover:text-brand-600">
            {person?.full_name}
          </button>
          <div className="truncate text-xs text-ink-500">{person?.email}</div>
          <div className="text-xs text-ink-500">{person?.phone}</div>
        </div>
      </div>
      <div className="mt-4 flex gap-2">
        <Button size="sm" variant="secondary" className="flex-1" onClick={onOpen}>
          View profile
        </Button>
        <Button size="sm" variant="secondary" className="flex-1" icon={<Bell className="h-3.5 w-3.5" />} onClick={onNotify}>
          Notify
        </Button>
      </div>
    </Card>
  )
}

export function ChatLog({ msgs, ppl, canModerate, onChange }: { msgs: any[]; ppl: Map<string, any>; canModerate: boolean; onChange: () => void }) {
  const { confirm } = useUi()
  const { run } = useAction()
  const [urls, setUrls] = useState<Record<string, string>>({})

  useEffect(() => {
    const paths = msgs.filter((m) => m.media_path && !urls[m.media_path]).map((m) => m.media_path)
    if (!paths.length) return
    db.storage
      .from('chat-media')
      .createSignedUrls(paths, 3600)
      .then(({ data }) => {
        const next = { ...urls }
        data?.forEach((d) => d.signedUrl && d.path && (next[d.path] = d.signedUrl))
        setUrls(next)
      })
  }, [msgs])

  return (
    <Card title="Chat between customer and professional" subtitle={`${msgs.length} messages · ${msgs.filter((m) => m.is_masked).length} hidden`}>
      <div className="scrollbar-thin max-h-[480px] space-y-3 overflow-y-auto rounded-2xl bg-ink-50 p-4 dark:bg-ink-850">
        {msgs.length === 0 && <p className="py-6 text-center text-sm text-ink-500">No messages yet</p>}
        {msgs.map((m) => {
          const who = ppl.get(m.sender_id)
          return (
            <div key={m.id} className="group flex gap-2.5">
              <Avatar name={who?.full_name} url={who?.avatar_url} size={28} />
              <div className="min-w-0 flex-1">
                <div className="text-xs text-ink-500">
                  <b className="text-ink-700 dark:text-ink-200">{who?.full_name}</b> · {time(m.created_at)}
                  {m.is_masked && (
                    <span className="ml-2 inline-flex items-center gap-1 text-amber-600">
                      <EyeOff className="h-3 w-3" /> Hidden
                    </span>
                  )}
                </div>
                {m.kind === 'text' && <p className={`mt-0.5 whitespace-pre-wrap text-sm ${m.is_masked ? 'italic text-ink-500' : ''}`}>{m.body}</p>}
                {m.kind === 'image' && urls[m.media_path] && <img src={urls[m.media_path]} className="mt-1 max-h-48 rounded-xl" alt="" />}
                {m.kind === 'video' && urls[m.media_path] && <video src={urls[m.media_path]} controls className="mt-1 max-h-56 rounded-xl" />}
              </div>
              {canModerate && !m.is_masked && (
                <button
                  title="Remove message"
                  className="self-start rounded-lg p-1.5 text-ink-400 opacity-0 transition hover:bg-red-50 hover:text-red-500 group-hover:opacity-100"
                  onClick={async () => {
                    if (await confirm({ title: 'Remove this message?', message: 'It will be replaced with a moderator notice for both sides.', danger: true, confirm: 'Remove' }))
                      run('rm', () => rpc('admin_remove_message', { p_msg: m.id }), 'Message removed').then(onChange)
                  }}
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              )}
            </div>
          )
        })}
      </div>
      <p className="mt-3 flex items-center gap-1.5 text-xs text-ink-500">
        <MessageSquare className="h-3.5 w-3.5" /> Phone numbers, emails and social handles are hidden automatically.
      </p>
    </Card>
  )
}

function RescheduleModal({ booking, open, onClose, onDone }: { booking: Booking; open: boolean; onClose: () => void; onDone: () => void }) {
  const [at, setAt] = useState('')
  const [slot, setSlot] = useState(booking.time_slot ?? '')
  const { busy, run } = useAction()
  useEffect(() => {
    if (open && booking.scheduled_at) {
      const d = new Date(booking.scheduled_at)
      setAt(new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16))
    }
  }, [open])
  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Reschedule booking"
      footer={
        <>
          <Button variant="secondary" onClick={onClose}>
            Cancel
          </Button>
          <Button
            disabled={!at}
            loading={busy === 'r'}
            onClick={() =>
              run('r', () => rpc('admin_reschedule', { p_booking: booking.id, p_at: new Date(at).toISOString(), p_slot: slot || null }), 'Booking rescheduled').then((ok) => {
                if (ok) {
                  onDone()
                  onClose()
                }
              })
            }
          >
            Save
          </Button>
        </>
      }
    >
      <div className="space-y-4">
        <Field label="New date and time">
          <input type="datetime-local" className="input" value={at} onChange={(e) => setAt(e.target.value)} />
        </Field>
        <Field label="Time slot label (optional)">
          <input className="input" value={slot} onChange={(e) => setSlot(e.target.value)} placeholder="e.g. 10:00 AM - 12:00 PM" />
        </Field>
        <p className="text-xs text-ink-500">The customer and professional are notified.</p>
      </div>
    </Modal>
  )
}

export function NotifyModal({ userId, open, onClose }: { userId?: string | null; open: boolean; onClose: () => void }) {
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [type, setType] = useState('message')
  const { busy, run } = useAction()
  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Send in-app notification"
      footer={
        <>
          <Button variant="secondary" onClick={onClose}>
            Cancel
          </Button>
          <Button
            disabled={title.trim().length < 2 || body.trim().length < 2}
            loading={busy === 'n'}
            onClick={() =>
              run('n', () => rpc('admin_notify_user', { p_user: userId, p_title: title.trim(), p_body: body.trim(), p_type: type }), 'Notification sent').then((ok) => {
                if (ok) {
                  setTitle('')
                  setBody('')
                  onClose()
                }
              })
            }
          >
            Send
          </Button>
        </>
      }
    >
      <div className="space-y-4">
        <Field label="Type">
          <Select
            className="w-full"
            value={type}
            onChange={setType}
            options={[
              { value: 'message', label: 'Message' },
              { value: 'order', label: 'Order update' },
              { value: 'reminder', label: 'Reminder' },
              { value: 'offer', label: 'Offer' },
            ]}
          />
        </Field>
        <Field label="Title">
          <input className="input" value={title} onChange={(e) => setTitle(e.target.value)} maxLength={80} />
        </Field>
        <Field label="Message">
          <textarea className="input h-28 py-2" value={body} onChange={(e) => setBody(e.target.value)} maxLength={500} />
        </Field>
      </div>
    </Modal>
  )
}
