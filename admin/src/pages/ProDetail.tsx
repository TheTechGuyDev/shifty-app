import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, Ban, BadgeCheck, Bell, CheckCircle2, ExternalLink, FileText, Percent, Sparkles, XCircle } from 'lucide-react'
import { useAuth } from '../lib/auth'
import { useLoad } from '../lib/hooks'
import { db, q, rpc } from '../lib/supabase'
import { date, dateTime, money, titleCase } from '../lib/format'
import type { Booking } from '../lib/types'
import {
  Avatar, Badge, Button, Card, DataTable, ErrorBox, Field, KeyValue, Loading, Modal, Select, Stars, Tabs, Toggle, statusTone, useAction, useUi,
} from '../components/ui'
import MapView from '../components/MapView'
import Notes from '../components/Notes'
import { NotifyModal } from './BookingDetail'
import { levelLabel } from './Pros'

const DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

export async function openDocument(path: string) {
  const { data, error } = await db.storage.from('documents').createSignedUrl(path, 300)
  if (error) throw new Error(error.message)
  window.open(data.signedUrl, '_blank')
}

export default function ProDetail() {
  const { id = '' } = useParams()
  const go = useNavigate()
  const { can } = useAuth()
  const { confirm, toast } = useUi()
  const { busy, run } = useAction()
  const [tab, setTab] = useState('overview')
  const [notify, setNotify] = useState(false)
  const [commission, setCommission] = useState(false)

  const data = useLoad(async () => {
    const [pp, p, services, cats, hours, docs, jobs, payouts, reviews, portfolio, team, blocked, settings] = await Promise.all([
      q<any>(db.from('professional_profiles').select('*').eq('user_id', id).maybeSingle()),
      q<any>(db.from('profiles').select('*').eq('id', id).single()),
      q<any[]>(db.from('pro_services').select('*').eq('pro_id', id)),
      q<any[]>(db.from('service_categories').select('id, name')),
      q<any[]>(db.from('availability').select('*').eq('pro_id', id).order('weekday')),
      can('verification.manage') || can('pros.manage') ? q<any[]>(db.from('verification_documents').select('*').eq('pro_id', id).order('created_at')) : Promise.resolve([]),
      q<Booking[]>(db.from('bookings').select('*').eq('professional_id', id).order('created_at', { ascending: false })),
      can('finance.view') ? q<any[]>(db.from('payouts').select('*').eq('pro_id', id).order('created_at', { ascending: false })) : Promise.resolve([]),
      q<any[]>(db.from('reviews').select('*').eq('professional_id', id).order('created_at', { ascending: false })),
      q<any[]>(db.from('portfolio_items').select('*').eq('pro_id', id)),
      q<any[]>(db.from('team_members').select('*').eq('pro_id', id)),
      q<any[]>(db.from('blocked_dates').select('*').eq('pro_id', id).gte('day', new Date().toISOString().slice(0, 10))),
      q<any[]>(db.from('app_settings').select('*').eq('key', 'commission_pct')),
    ])
    if (!pp) throw new Error('This person has not started a professional profile.')
    const catName = new Map(cats.map((c) => [c.id, c.name]))
    return { pp, p, services: services.map((s) => ({ ...s, name: catName.get(s.category_id) ?? 'Service' })), hours, docs, jobs, payouts, reviews, portfolio, team, blocked, defaultPct: Number(settings[0]?.value ?? 10) }
  }, [id])

  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const { pp, p, services, hours, docs, jobs, payouts, reviews, portfolio, team, blocked, defaultPct } = data.data
  const name = pp.business_name || p.full_name
  const done = jobs.filter((j) => j.status === 'done')
  const earned = done.reduce((a, j) => a + Number(j.pro_earning ?? 0), 0)
  const commissionPaid = done.reduce((a, j) => a + Number(j.commission ?? 0), 0)
  const paidOut = payouts.filter((x) => x.status !== 'rejected').reduce((a, x) => a + Number(x.amount), 0)

  const update = (values: Record<string, unknown>, ok: string) => run('u', () => rpc('admin_update_pro', { p_pro: id, p_values: values }), ok).then(data.reload)

  const setStatus = async (status: string) => {
    const needsNote = status === 'rejected'
    const note = await confirm({
      title: status === 'approved' ? `Approve ${name}?` : status === 'rejected' ? `Ask ${name} for changes?` : 'Move back to review?',
      message: status === 'approved' ? 'They can go online and receive jobs straight away.' : 'They are notified in the app.',
      input: needsNote ? 'What needs to change? (sent to the professional)' : undefined,
      inputRequired: needsNote,
      confirm: status === 'approved' ? 'Approve' : status === 'rejected' ? 'Send back' : 'Confirm',
      danger: status === 'rejected',
    })
    if (!note) return
    run('st', () => rpc('admin_set_pro_status', { p_pro: id, p_status: status, p_note: needsNote ? note : null }), 'Status updated').then(data.reload)
  }

  const suspend = async () => {
    if (p.is_suspended) {
      if (await confirm({ title: 'Restore this professional?', confirm: 'Restore' })) run('s', () => rpc('admin_set_suspended', { p_user: id, p_suspended: false }), 'Restored').then(data.reload)
    } else {
      const reason = await confirm({ title: `Suspend ${name}?`, message: 'They go offline and can’t receive jobs or chat.', input: 'Reason (internal)', inputRequired: true, danger: true, confirm: 'Suspend' })
      if (reason) run('s', () => rpc('admin_set_suspended', { p_user: id, p_suspended: true, p_reason: reason }), 'Suspended').then(data.reload)
    }
  }

  const reviewDoc = async (doc: any, status: string) => {
    const note = await confirm({
      title: status === 'approved' ? 'Approve document?' : 'Reject document?',
      input: status === 'rejected' ? 'Reason (sent to the professional)' : undefined,
      inputRequired: status === 'rejected',
      danger: status === 'rejected',
      confirm: status === 'approved' ? 'Approve' : 'Reject',
    })
    if (note) run('d' + doc.id, () => rpc('admin_review_document', { p_doc: doc.id, p_status: status, p_note: status === 'rejected' ? note : null }), 'Document updated').then(data.reload)
  }

  return (
    <div className="space-y-6">
      <button onClick={() => go(-1)} className="inline-flex items-center gap-1.5 text-sm font-semibold text-ink-500 hover:text-ink-900 dark:hover:text-white">
        <ArrowLeft className="h-4 w-4" /> Back
      </button>

      <div className="card overflow-hidden">
        <div className="h-24 bg-gradient-to-r from-brand-500 via-brand-400 to-amber-300" />
        <div className="flex flex-wrap items-end gap-5 px-6 pb-6">
          <div className="-mt-10 rounded-full border-4 border-white dark:border-ink-900">
            <Avatar name={name} url={p.avatar_url} size={84} />
          </div>
          <div className="min-w-0 flex-1 pt-3">
            <div className="flex flex-wrap items-center gap-2">
              <h1 className="text-2xl font-bold">{name}</h1>
              {pp.verification_level >= 2 && <BadgeCheck className="h-5 w-5 text-blue-500" />}
              <Badge tone={p.is_suspended ? 'red' : statusTone(pp.status)} dot>
                {p.is_suspended ? 'Suspended' : pp.status === 'draft' ? 'Incomplete' : titleCase(pp.status)}
              </Badge>
              <Badge tone={pp.is_online ? 'green' : 'gray'}>{pp.is_online ? 'Online' : 'Offline'}</Badge>
              {pp.is_featured && <Badge tone="orange">Featured</Badge>}
            </div>
            <p className="mt-1 text-sm text-ink-500">
              {p.full_name} · {p.email} · {p.phone || 'No phone'} · {titleCase(pp.account_type)}
            </p>
            {pp.status_note && <p className="mt-1 text-sm text-amber-600">Note: {pp.status_note}</p>}
          </div>
          <div className="flex flex-wrap gap-2">
            {can('verification.manage') && pp.status !== 'approved' && (
              <Button variant="success" loading={busy === 'st'} icon={<CheckCircle2 className="h-4 w-4" />} onClick={() => setStatus('approved')}>
                Approve
              </Button>
            )}
            {can('verification.manage') && pp.status !== 'rejected' && (
              <Button variant="secondary" icon={<XCircle className="h-4 w-4" />} onClick={() => setStatus('rejected')}>
                {pp.status === 'approved' ? 'Revoke approval' : 'Request changes'}
              </Button>
            )}
            <Button variant="secondary" icon={<Bell className="h-4 w-4" />} onClick={() => setNotify(true)}>
              Notify
            </Button>
            <Button variant="secondary" icon={<ExternalLink className="h-4 w-4" />} onClick={() => go(`/customers/${id}`)}>
              Account
            </Button>
            {can('users.manage') && (
              <Button variant={p.is_suspended ? 'success' : 'danger'} loading={busy === 's'} icon={<Ban className="h-4 w-4" />} onClick={suspend}>
                {p.is_suspended ? 'Restore' : 'Suspend'}
              </Button>
            )}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4 lg:grid-cols-5">
        {[
          ['Rating', pp.rating_count ? `${Number(pp.rating).toFixed(1)} ★` : 'New'],
          ['Jobs done', pp.jobs_done],
          ['Earned', money(earned)],
          ['Commission paid', money(commissionPaid)],
          ['Balance', money(earned - paidOut)],
        ].map(([k, v]) => (
          <div key={k as string} className="card p-5">
            <div className="text-sm text-ink-500">{k}</div>
            <div className="mt-1 text-xl font-bold">{v}</div>
          </div>
        ))}
      </div>

      <Tabs
        value={tab}
        onChange={setTab}
        items={[
          { value: 'overview', label: 'Overview' },
          { value: 'documents', label: 'Documents', count: docs.length },
          { value: 'jobs', label: 'Jobs', count: jobs.length },
          { value: 'money', label: 'Payouts', count: payouts.length },
          { value: 'reviews', label: 'Reviews', count: reviews.length },
          { value: 'portfolio', label: 'Portfolio', count: portfolio.length },
          { value: 'team', label: 'Team', count: team.length },
        ]}
      />

      <div className="grid gap-6 xl:grid-cols-3">
        <div className="space-y-6 xl:col-span-2">
          {tab === 'overview' && (
            <>
              <Card title="About">
                <p className="whitespace-pre-wrap text-sm">{pp.bio || 'No bio yet.'}</p>
                <div className="mt-5">
                  <KeyValue
                    items={[
                      ['Experience', `${pp.years_experience ?? 0} years`],
                      ['Profile link', pp.slug],
                      ['Base', pp.base_address],
                      ['Travel distance', `${pp.radius_km} km`],
                      ['Joined', date(pp.created_at)],
                      ['Bank', pp.bank_name ? `${pp.bank_name} · ${pp.account_number} · ${pp.account_name}` : 'Not added'],
                    ]}
                  />
                </div>
              </Card>
              <Card title="Services and prices" pad={false}>
                <div className="divide-y divide-ink-100 dark:divide-ink-800">
                  {services.length === 0 && <p className="p-5 text-sm text-ink-500">No services chosen yet.</p>}
                  {services.map((s) => (
                    <div key={s.id} className="flex items-center gap-3 px-5 py-3 text-sm">
                      <span className="flex-1 font-semibold">{s.name}</span>
                      <Badge>{titleCase(s.pricing_type)}</Badge>
                      <span className="w-28 text-right font-semibold">{s.pricing_type === 'quote' ? 'On quote' : money(s.price)}</span>
                      <Badge tone={s.is_active ? 'green' : 'gray'}>{s.is_active ? 'Active' : 'Paused'}</Badge>
                    </div>
                  ))}
                </div>
              </Card>
              {pp.base_lat && (
                <Card title="Service area">
                  <MapView pins={[{ lat: pp.base_lat, lng: pp.base_lng, label: '' }]} circles={[{ lat: pp.base_lat, lng: pp.base_lng, km: pp.radius_km }]} height={280} zoom={10} />
                </Card>
              )}
              <Card title="Working hours">
                <div className="grid grid-cols-2 gap-2 sm:grid-cols-4 lg:grid-cols-7">
                  {DAYS.map((d, i) => {
                    const h = hours.find((x) => x.weekday === i + 1)
                    return (
                      <div key={d} className={`rounded-xl p-3 text-center ${h?.enabled ? 'bg-emerald-50 dark:bg-emerald-900/20' : 'bg-ink-50 dark:bg-ink-850'}`}>
                        <div className="text-xs font-bold">{d}</div>
                        <div className="mt-1 text-[11px] text-ink-500">{h ? (h.enabled ? `${h.start_time.slice(0, 5)}–${h.end_time.slice(0, 5)}` : 'Closed') : 'Not set'}</div>
                      </div>
                    )
                  })}
                </div>
                {blocked.length > 0 && <p className="mt-3 text-xs text-ink-500">Blocked days: {blocked.map((b) => date(b.day)).join(', ')}</p>}
              </Card>
            </>
          )}

          {tab === 'documents' && (
            <Card title="Verification documents" subtitle="Files are private. Links expire after 5 minutes." pad={false}>
              <div className="divide-y divide-ink-100 dark:divide-ink-800">
                {docs.length === 0 && <p className="p-5 text-sm text-ink-500">No documents uploaded.</p>}
                {docs.map((d) => (
                  <div key={d.id} className="flex flex-wrap items-center gap-3 px-5 py-4">
                    <FileText className="h-5 w-5 text-ink-400" />
                    <div className="min-w-0 flex-1">
                      <div className="font-semibold">{d.title || titleCase(d.kind)}</div>
                      <div className="text-xs text-ink-500">
                        {titleCase(d.kind)} · uploaded {dateTime(d.created_at)}
                        {d.note ? ` · ${d.note}` : ''}
                      </div>
                    </div>
                    <Badge tone={statusTone(d.status)}>{titleCase(d.status)}</Badge>
                    <Button size="sm" variant="secondary" onClick={() => openDocument(d.file_path).catch((e) => toast(e.message, 'error'))}>
                      View
                    </Button>
                    {can('verification.manage') && d.status !== 'approved' && (
                      <Button size="sm" variant="success" loading={busy === 'd' + d.id} onClick={() => reviewDoc(d, 'approved')}>
                        Approve
                      </Button>
                    )}
                    {can('verification.manage') && d.status !== 'rejected' && (
                      <Button size="sm" variant="ghost" onClick={() => reviewDoc(d, 'rejected')}>
                        Reject
                      </Button>
                    )}
                  </div>
                ))}
              </div>
            </Card>
          )}

          {tab === 'jobs' && (
            <DataTable<Booking>
              rows={jobs}
              exportName={`jobs-${pp.slug ?? id}`}
              onRow={(r) => go(`/bookings/${r.id}`)}
              search={(r) => `${r.reference} ${r.service_name}`}
              columns={[
                { key: 's', label: 'Job', render: (r) => <b>{r.service_name}</b>, csv: (r) => r.service_name },
                { key: 'r', label: 'Ref', render: (r) => `#${r.reference}`, csv: (r) => r.reference },
                { key: 'd', label: 'Scheduled', sort: (r) => r.scheduled_at ?? '', render: (r) => dateTime(r.scheduled_at) },
                { key: 'a', label: 'Total', sort: (r) => Number(r.total_amount), render: (r) => money(r.total_amount) },
                { key: 'e', label: 'Earned', sort: (r) => Number(r.pro_earning ?? 0), render: (r) => money(r.pro_earning) },
                { key: 'st', label: 'Status', render: (r) => <Badge tone={statusTone(r.status)}>{titleCase(r.status)}</Badge>, csv: (r) => r.status },
              ]}
            />
          )}

          {tab === 'money' && (
            <DataTable
              rows={payouts}
              columns={[
                { key: 'd', label: 'Requested', render: (r) => dateTime(r.created_at) },
                { key: 'a', label: 'Amount', render: (r) => <b>{money(r.amount)}</b> },
                { key: 'b', label: 'Bank', render: (r) => `${r.bank_name ?? ''} ${r.account_number ?? ''}` },
                { key: 's', label: 'Status', render: (r) => <Badge tone={statusTone(r.status)}>{titleCase(r.status)}</Badge> },
              ]}
            />
          )}

          {tab === 'reviews' && (
            <Card title="Reviews">
              <div className="space-y-3">
                {reviews.length === 0 && <p className="text-sm text-ink-500">No reviews yet.</p>}
                {reviews.map((r) => (
                  <div key={r.id} className="rounded-xl border border-ink-100 p-4 dark:border-ink-800">
                    <div className="flex items-center justify-between">
                      <Stars value={r.rating} />
                      <div className="flex items-center gap-2">
                        <Badge tone={statusTone(r.status)}>{titleCase(r.status)}</Badge>
                        <span className="text-xs text-ink-500">{date(r.created_at)}</span>
                      </div>
                    </div>
                    {r.comment && <p className="mt-2 text-sm">{r.comment}</p>}
                    {r.reply && <p className="mt-2 rounded-lg bg-ink-50 p-2 text-sm dark:bg-ink-850">Reply: {r.reply}</p>}
                  </div>
                ))}
              </div>
            </Card>
          )}

          {tab === 'portfolio' && (
            <Card title="Portfolio">
              {portfolio.length === 0 ? (
                <p className="text-sm text-ink-500">No photos yet.</p>
              ) : (
                <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
                  {portfolio.map((i) => (
                    <a key={i.id} href={i.image_url} target="_blank" rel="noreferrer" className="group relative overflow-hidden rounded-2xl">
                      <img src={i.image_url} className="aspect-square w-full object-cover transition group-hover:scale-105" alt="" />
                      {i.caption && <span className="absolute inset-x-0 bottom-0 bg-black/50 p-2 text-xs text-white">{i.caption}</span>}
                    </a>
                  ))}
                </div>
              )}
            </Card>
          )}

          {tab === 'team' && (
            <Card title="Team members">
              {team.length === 0 && <p className="text-sm text-ink-500">No team members.</p>}
              <div className="space-y-2">
                {team.map((m) => (
                  <div key={m.id} className="flex items-center gap-3">
                    <Avatar name={m.name} size={32} />
                    <span className="flex-1 text-sm font-semibold">{m.name}</span>
                    <span className="text-sm text-ink-500">{m.role}</span>
                    <span className="text-sm text-ink-500">{m.phone}</span>
                  </div>
                ))}
              </div>
            </Card>
          )}
        </div>

        <div className="space-y-6">
          {can('pros.manage') && (
            <Card title="Controls">
              <div className="space-y-4">
                <Row label="Online" hint="Force the professional offline or online">
                  <Toggle checked={pp.is_online} disabled={pp.status !== 'approved'} onChange={(v) => update({ is_online: v }, v ? 'Set online' : 'Set offline')} />
                </Row>
                <Row label="Featured" hint="Shown first when jobs are matched">
                  <Toggle checked={pp.is_featured} onChange={(v) => update({ is_featured: v }, v ? 'Featured' : 'No longer featured')} />
                </Row>
                <Field label="Verification level">
                  <Select
                    className="w-full"
                    value={String(pp.verification_level)}
                    onChange={(v) => update({ verification_level: Number(v) }, 'Verification level updated')}
                    options={[1, 2, 3].map((l) => ({ value: String(l), label: `${l} · ${levelLabel(l)}` }))}
                  />
                </Field>
                <Row label={`Commission: ${pp.commission_pct ?? defaultPct}%`} hint={pp.commission_pct == null ? 'Using the platform default' : 'Custom rate for this professional'}>
                  <Button size="sm" variant="secondary" icon={<Percent className="h-3.5 w-3.5" />} onClick={() => setCommission(true)}>
                    Change
                  </Button>
                </Row>
              </div>
            </Card>
          )}
          <Card title="Account">
            <KeyValue
              items={[
                ['Signed up', date(p.created_at)],
                ['Last update', dateTime(pp.updated_at)],
                ['Notifications', `${pp.notify_jobs ? 'Jobs on' : 'Jobs off'} · ${pp.notify_messages ? 'Messages on' : 'Messages off'}`],
                ['Mode', titleCase(p.active_mode)],
              ]}
            />
            {pp.is_featured && (
              <p className="mt-4 flex items-center gap-1.5 text-xs text-brand-600">
                <Sparkles className="h-3.5 w-3.5" /> Featured professionals get requests first.
              </p>
            )}
          </Card>
          <Notes entity="professional" id={id} />
        </div>
      </div>

      <NotifyModal userId={id} open={notify} onClose={() => setNotify(false)} />
      <CommissionModal open={commission} onClose={() => setCommission(false)} current={pp.commission_pct} def={defaultPct} onSave={(v) => update({ commission_pct: v }, 'Commission updated').then(() => setCommission(false))} />
    </div>
  )
}

function Row({ label, hint, children }: { label: string; hint?: string; children: React.ReactNode }) {
  return (
    <div className="flex items-center gap-3">
      <div className="flex-1">
        <div className="text-sm font-semibold">{label}</div>
        {hint && <div className="text-xs text-ink-500">{hint}</div>}
      </div>
      {children}
    </div>
  )
}

function CommissionModal({ open, onClose, current, def, onSave }: { open: boolean; onClose: () => void; current: number | null; def: number; onSave: (v: string) => void }) {
  const [v, setV] = useState(current == null ? '' : String(current))
  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Commission rate"
      footer={
        <>
          <Button variant="secondary" onClick={() => onSave('')}>
            Use default ({def}%)
          </Button>
          <Button disabled={v === '' || Number(v) < 0 || Number(v) > 50} onClick={() => onSave(v)}>
            Save
          </Button>
        </>
      }
    >
      <Field label="Custom commission (%)" hint="Between 0 and 50. Applies to jobs completed from now on.">
        <input type="number" min={0} max={50} step={0.5} className="input" value={v} onChange={(e) => setV(e.target.value)} />
      </Field>
    </Modal>
  )
}
