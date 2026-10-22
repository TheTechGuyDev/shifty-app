import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, Ban, Bell, CheckCircle2, Wrench } from 'lucide-react'
import { useAuth } from '../lib/auth'
import { useLoad } from '../lib/hooks'
import { db, q, rpc } from '../lib/supabase'
import { date, dateTime, money, titleCase } from '../lib/format'
import type { Booking } from '../lib/types'
import { Avatar, Badge, Button, Card, DataTable, ErrorBox, KeyValue, Loading, Stars, statusTone, useAction, useUi } from '../components/ui'
import Notes from '../components/Notes'
import { NotifyModal } from './BookingDetail'

export default function CustomerDetail() {
  const { id = '' } = useParams()
  const go = useNavigate()
  const { can } = useAuth()
  const { confirm } = useUi()
  const { busy, run } = useAction()
  const [notify, setNotify] = useState(false)

  const data = useLoad(async () => {
    const [p, bookings, addresses, reviews, pro, referred, support] = await Promise.all([
      q<any>(db.from('profiles').select('*').eq('id', id).single()),
      q<Booking[]>(db.from('bookings').select('*').eq('customer_id', id).order('created_at', { ascending: false })),
      can('users.view') ? q<any[]>(db.from('addresses').select('*').eq('user_id', id)) : Promise.resolve([]),
      q<any[]>(db.from('reviews').select('*').eq('user_id', id).order('created_at', { ascending: false })),
      q<any>(db.from('professional_profiles').select('user_id, status').eq('user_id', id).maybeSingle()),
      Promise.resolve([] as any[]),
      can('support.manage') ? q<any[]>(db.from('support_messages').select('id').eq('user_id', id)) : Promise.resolve([]),
    ])
    const refs = p.referral_code ? await q<any[]>(db.from('profiles').select('id, full_name, created_at').eq('referred_by', p.referral_code)) : referred
    return { p, bookings, addresses, reviews, pro, refs, support }
  }, [id])

  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const { p, bookings, addresses, reviews, pro, refs, support } = data.data
  const spent = bookings.filter((b) => b.status === 'done').reduce((a, b) => a + Number(b.total_amount ?? 0), 0)

  const suspend = async () => {
    if (p.is_suspended) {
      if (await confirm({ title: 'Restore this account?', confirm: 'Restore' })) run('s', () => rpc('admin_set_suspended', { p_user: id, p_suspended: false }), 'Account restored').then(data.reload)
    } else {
      const reason = await confirm({ title: 'Suspend this account?', message: 'They won’t be able to book or chat until restored.', input: 'Reason (internal)', inputRequired: true, danger: true, confirm: 'Suspend' })
      if (reason) run('s', () => rpc('admin_set_suspended', { p_user: id, p_suspended: true, p_reason: reason }), 'Account suspended').then(data.reload)
    }
  }

  return (
    <div className="space-y-6">
      <button onClick={() => go(-1)} className="inline-flex items-center gap-1.5 text-sm font-semibold text-ink-500 hover:text-ink-900 dark:hover:text-white">
        <ArrowLeft className="h-4 w-4" /> Back
      </button>
      <div className="card flex flex-wrap items-center gap-5 p-6">
        <Avatar name={p.full_name} url={p.avatar_url} size={72} />
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <h1 className="text-2xl font-bold">{p.full_name || 'No name'}</h1>
            {p.is_suspended ? <Badge tone="red">Suspended</Badge> : <Badge tone="green">Active</Badge>}
            {pro && <Badge tone="orange">Professional · {titleCase(pro.status)}</Badge>}
            {p.admin_role && <Badge tone="purple">Admin</Badge>}
          </div>
          <p className="mt-1 text-sm text-ink-500">
            {p.email} · {p.phone || 'No phone'} · joined {date(p.created_at)}
          </p>
          {p.is_suspended && p.suspended_reason && <p className="mt-1 text-sm text-red-500">Reason: {p.suspended_reason}</p>}
        </div>
        <div className="flex flex-wrap gap-2">
          {pro && (
            <Button variant="secondary" icon={<Wrench className="h-4 w-4" />} onClick={() => go(`/pros/${id}`)}>
              Professional profile
            </Button>
          )}
          <Button variant="secondary" icon={<Bell className="h-4 w-4" />} onClick={() => setNotify(true)}>
            Notify
          </Button>
          {can('users.manage') && (
            <Button variant={p.is_suspended ? 'success' : 'danger'} loading={busy === 's'} icon={p.is_suspended ? <CheckCircle2 className="h-4 w-4" /> : <Ban className="h-4 w-4" />} onClick={suspend}>
              {p.is_suspended ? 'Restore' : 'Suspend'}
            </Button>
          )}
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        {[
          ['Bookings', bookings.length],
          ['Completed', bookings.filter((b) => b.status === 'done').length],
          ['Total spent', money(spent)],
          ['Cancelled', bookings.filter((b) => b.status === 'cancelled').length],
        ].map(([k, v]) => (
          <div key={k} className="card p-5">
            <div className="text-sm text-ink-500">{k}</div>
            <div className="mt-1 text-2xl font-bold">{v}</div>
          </div>
        ))}
      </div>

      <div className="grid gap-6 xl:grid-cols-3">
        <div className="space-y-6 xl:col-span-2">
          <div>
            <h2 className="mb-3 text-lg font-bold">Bookings</h2>
            <DataTable<Booking>
              rows={bookings}
              pageSize={8}
              onRow={(r) => go(`/bookings/${r.id}`)}
              columns={[
                { key: 's', label: 'Service', render: (r) => <b>{r.service_name}</b> },
                { key: 'r', label: 'Ref', render: (r) => `#${r.reference}` },
                { key: 'd', label: 'Date', render: (r) => dateTime(r.scheduled_at) },
                { key: 'a', label: 'Amount', render: (r) => money(r.total_amount) },
                { key: 'st', label: 'Status', render: (r) => <Badge tone={statusTone(r.status)}>{titleCase(r.status)}</Badge> },
              ]}
            />
          </div>
          {reviews.length > 0 && (
            <Card title="Reviews written">
              <div className="space-y-3">
                {reviews.map((r) => (
                  <div key={r.id} className="rounded-xl bg-ink-50 p-3 dark:bg-ink-850">
                    <div className="flex items-center justify-between">
                      <Stars value={r.rating} />
                      <span className="text-xs text-ink-500">{date(r.created_at)}</span>
                    </div>
                    {r.comment && <p className="mt-1 text-sm">{r.comment}</p>}
                  </div>
                ))}
              </div>
            </Card>
          )}
        </div>
        <div className="space-y-6">
          <Card title="Profile">
            <KeyValue
              items={[
                ['Address', p.address],
                ['State', p.state],
                ['Zip code', p.zip_code],
                ['Referral code', p.referral_code],
                ['Referred by', p.referred_by],
                ['Push notifications', p.push_enabled ? 'On' : 'Off'],
                ['Support messages', String(support.length)],
                ['People referred', String(refs.length)],
              ]}
            />
          </Card>
          {addresses.length > 0 && (
            <Card title="Saved locations">
              <div className="space-y-2">
                {addresses.map((a) => (
                  <div key={a.id} className="text-sm">
                    <Badge>{titleCase(a.label)}</Badge> <span className="ml-1">{a.address}</span>
                  </div>
                ))}
              </div>
            </Card>
          )}
          <Notes entity="user" id={id} />
        </div>
      </div>
      <NotifyModal userId={id} open={notify} onClose={() => setNotify(false)} />
    </div>
  )
}
