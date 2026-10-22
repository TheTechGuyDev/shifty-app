import { useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { Gift, Share2, Users } from 'lucide-react'
import { useLoad } from '../lib/hooks'
import { db, q } from '../lib/supabase'
import { date, num } from '../lib/format'
import { Avatar, DataTable, ErrorBox, Loading, PageHeader, Stat } from '../components/ui'

export default function Referrals() {
  const go = useNavigate()
  const data = useLoad(async () => {
    const [users, bookings] = await Promise.all([
      q<any[]>(db.from('profiles').select('id, full_name, email, avatar_url, referral_code, referred_by, created_at')),
      q<any[]>(db.from('bookings').select('customer_id, status')),
    ])
    return { users, bookings }
  })
  const rows = useMemo(() => {
    if (!data.data) return []
    const { users, bookings } = data.data
    const booked = new Set(bookings.filter((b) => b.status === 'done').map((b) => b.customer_id))
    return users
      .filter((u) => u.referral_code)
      .map((u) => {
        const invited = users.filter((x) => x.referred_by && x.referred_by.toUpperCase() === u.referral_code.toUpperCase())
        return { ...u, invited: invited.length, converted: invited.filter((x) => booked.has(x.id)).length, lastInvite: invited.map((x) => x.created_at).sort().pop() }
      })
      .filter((u) => u.invited > 0)
      .sort((a, b) => b.invited - a.invited)
  }, [data.data])
  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const referred = data.data.users.filter((u) => u.referred_by).length

  return (
    <div>
      <PageHeader title="Referrals" subtitle="Who is bringing new customers in with their invite code." />
      <div className="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-3">
        <Stat label="Signed up with a code" value={num(referred)} icon={<Users className="h-5 w-5" />} />
        <Stat label="Active referrers" value={num(rows.length)} icon={<Share2 className="h-5 w-5" />} tone="blue" />
        <Stat label="Referred and completed a job" value={num(rows.reduce((a, r) => a + r.converted, 0))} icon={<Gift className="h-5 w-5" />} tone="green" />
      </div>
      <DataTable
        rows={rows}
        exportName="referrals"
        onRow={(r) => go(`/customers/${r.id}`)}
        search={(r) => `${r.full_name} ${r.email} ${r.referral_code}`}
        columns={[
          { key: 'n', label: 'Referrer', csv: (r) => r.full_name, render: (r) => <div className="flex items-center gap-2"><Avatar name={r.full_name} url={r.avatar_url} size={30} /><div><div className="font-semibold">{r.full_name}</div><div className="text-xs text-ink-500">{r.email}</div></div></div> },
          { key: 'code', label: 'Code', render: (r) => <span className="font-mono font-bold">{r.referral_code}</span> },
          { key: 'inv', label: 'Signed up', sort: (r) => r.invited, render: (r) => r.invited },
          { key: 'conv', label: 'Completed a job', sort: (r) => r.converted, render: (r) => r.converted },
          { key: 'last', label: 'Last sign-up', render: (r) => date(r.lastInvite) },
        ]}
      />
    </div>
  )
}
