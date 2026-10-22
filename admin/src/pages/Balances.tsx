import { useNavigate } from 'react-router-dom'
import { Banknote, Hourglass, Wallet } from 'lucide-react'
import { useLoad } from '../lib/hooks'
import { rpc } from '../lib/supabase'
import { money } from '../lib/format'
import { Avatar, Badge, DataTable, ErrorBox, Loading, PageHeader, Stat } from '../components/ui'

export default function Balances() {
  const go = useNavigate()
  const data = useLoad(() => rpc<any[]>('admin_pro_balances'))
  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const rows = data.data
  const s = (k: string) => rows.reduce((a, r) => a + Number(r[k] ?? 0), 0)
  return (
    <div>
      <PageHeader title="Professional Balances" subtitle="What each professional has earned, been paid and can still withdraw." />
      <div className="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-3">
        <Stat label="Unpaid balances" value={money(s('balance'))} icon={<Wallet className="h-5 w-5" />} hint="Money you owe professionals" />
        <Stat label="Payouts in progress" value={money(s('pending'))} icon={<Hourglass className="h-5 w-5" />} tone="yellow" />
        <Stat label="Paid out so far" value={money(s('paid_out'))} icon={<Banknote className="h-5 w-5" />} tone="green" />
      </div>
      <DataTable
        rows={rows}
        exportName="pro-balances"
        onRow={(r) => go(`/pros/${r.id}`)}
        search={(r) => `${r.name} ${r.bank_name} ${r.account_number}`}
        columns={[
          { key: 'name', label: 'Professional', sort: (r) => r.name, csv: (r) => r.name, render: (r) => <div className="flex items-center gap-2 font-semibold"><Avatar name={r.name} size={30} />{r.name}</div> },
          { key: 'earned', label: 'Earned', sort: (r) => Number(r.earned), render: (r) => money(r.earned) },
          { key: 'paid', label: 'Paid out', sort: (r) => Number(r.paid_out), render: (r) => money(r.paid_out) },
          { key: 'pending', label: 'In progress', sort: (r) => Number(r.pending), render: (r) => money(r.pending) },
          { key: 'balance', label: 'Available', sort: (r) => Number(r.balance), render: (r) => <b className={Number(r.balance) > 0 ? 'text-emerald-600' : ''}>{money(r.balance)}</b> },
          { key: 'bank', label: 'Bank', csv: (r) => `${r.bank_name ?? ''} ${r.account_number ?? ''}`, render: (r) => (r.bank_name ? `${r.bank_name} · ${r.account_number}` : <Badge tone="yellow">Not added</Badge>) },
        ]}
      />
    </div>
  )
}
