import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Eye, EyeOff, MessageSquareReply, Star } from 'lucide-react'
import { useLoad } from '../lib/hooks'
import { db, q, rpc } from '../lib/supabase'
import { date } from '../lib/format'
import { people } from '../lib/people'
import { Avatar, Badge, Button, Card, Empty, ErrorBox, Loading, PageHeader, Select, Stars, Stat, Tabs, useAction } from '../components/ui'

export default function Reviews() {
  const go = useNavigate()
  const { busy, run } = useAction()
  const [tab, setTab] = useState<'all' | 'low' | 'hidden' | 'noreply'>('all')
  const [stars, setStars] = useState('all')
  const data = useLoad(async () => {
    const rows = await q<any[]>(db.from('reviews').select('*').order('created_at', { ascending: false }))
    const b = rows.length ? await q<any[]>(db.from('bookings').select('id, reference, service_name').in('id', rows.map((r) => r.booking_id))) : []
    return { rows, ppl: await people(rows.flatMap((r) => [r.user_id, r.professional_id])), bk: new Map(b.map((x) => [x.id, x])) }
  })
  const list = useMemo(
    () =>
      (data.data?.rows ?? []).filter(
        (r) =>
          (tab === 'all' || (tab === 'low' ? r.rating <= 2 : tab === 'hidden' ? r.status === 'hidden' : !r.reply)) && (stars === 'all' || String(r.rating) === stars),
      ),
    [data.data, tab, stars],
  )
  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const { rows, ppl, bk } = data.data
  const pub = rows.filter((r) => r.status === 'published')
  const avg = pub.length ? pub.reduce((a, r) => a + r.rating, 0) / pub.length : 0

  return (
    <div>
      <PageHeader title="Reviews" subtitle="Customer ratings of professionals. Hidden reviews don’t count towards ratings." />
      <div className="mb-6 grid gap-4 lg:grid-cols-4">
        <Stat label="Average rating" value={avg.toFixed(2)} icon={<Star className="h-5 w-5" />} tone="yellow" hint={`${pub.length} published reviews`} />
        <Card className="lg:col-span-3">
          <div className="space-y-1.5">
            {[5, 4, 3, 2, 1].map((s) => {
              const n = pub.filter((r) => r.rating === s).length
              return (
                <div key={s} className="flex items-center gap-3 text-sm">
                  <span className="w-8 font-semibold">{s} ★</span>
                  <div className="h-2.5 flex-1 overflow-hidden rounded-full bg-ink-100 dark:bg-ink-800">
                    <div className="h-full rounded-full bg-amber-400" style={{ width: `${pub.length ? (n / pub.length) * 100 : 0}%` }} />
                  </div>
                  <span className="w-10 text-right text-ink-500">{n}</span>
                </div>
              )
            })}
          </div>
        </Card>
      </div>
      <div className="mb-4 flex flex-wrap items-center gap-3">
        <Tabs
          value={tab}
          onChange={setTab}
          items={[
            { value: 'all', label: 'All', count: rows.length },
            { value: 'low', label: '1 to 2 stars', count: rows.filter((r) => r.rating <= 2).length },
            { value: 'noreply', label: 'No reply', count: rows.filter((r) => !r.reply).length },
            { value: 'hidden', label: 'Hidden', count: rows.filter((r) => r.status === 'hidden').length },
          ]}
        />
        <Select value={stars} onChange={setStars} options={[{ value: 'all', label: 'Any rating' }, ...[5, 4, 3, 2, 1].map((s) => ({ value: String(s), label: `${s} stars` }))]} />
      </div>
      {list.length === 0 ? (
        <Card>
          <Empty title="No reviews here" />
        </Card>
      ) : (
        <div className="grid gap-4 lg:grid-cols-2">
          {list.map((r) => {
            const c = ppl.get(r.user_id)
            const p = ppl.get(r.professional_id)
            const b = bk.get(r.booking_id)
            return (
              <div key={r.id} className={`card p-5 ${r.status === 'hidden' ? 'opacity-60' : ''}`}>
                <div className="flex items-center gap-3">
                  <Avatar name={c?.full_name} url={c?.avatar_url} />
                  <div className="min-w-0 flex-1">
                    <div className="text-sm font-semibold">{c?.full_name}</div>
                    <div className="text-xs text-ink-500">
                      for{' '}
                      <button className="font-semibold text-brand-600" onClick={() => go(`/pros/${r.professional_id}`)}>
                        {p?.full_name}
                      </button>{' '}
                      · {date(r.created_at)}
                    </div>
                  </div>
                  <Stars value={r.rating} />
                </div>
                <p className="mt-3 text-sm">{r.comment || <span className="text-ink-400">No comment</span>}</p>
                {r.reply && (
                  <div className="mt-3 flex gap-2 rounded-xl bg-ink-50 p-3 text-sm dark:bg-ink-850">
                    <MessageSquareReply className="h-4 w-4 shrink-0 text-ink-400" />
                    {r.reply}
                  </div>
                )}
                <div className="mt-4 flex items-center gap-2">
                  {b && (
                    <button className="text-xs text-ink-500 hover:text-brand-600" onClick={() => go(`/bookings/${b.id}`)}>
                      #{b.reference} · {b.service_name}
                    </button>
                  )}
                  <span className="flex-1" />
                  {r.status === 'hidden' && <Badge>Hidden</Badge>}
                  <Button
                    size="sm"
                    variant="secondary"
                    loading={busy === r.id}
                    icon={r.status === 'hidden' ? <Eye className="h-3.5 w-3.5" /> : <EyeOff className="h-3.5 w-3.5" />}
                    onClick={() => run(r.id, () => rpc('admin_set_review', { p_review: r.id, p_status: r.status === 'hidden' ? 'published' : 'hidden' }), 'Review updated').then(data.reload)}
                  >
                    {r.status === 'hidden' ? 'Publish' : 'Hide'}
                  </Button>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
