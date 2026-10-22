import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { CheckCircle2, Copy, Loader, XCircle } from 'lucide-react'
import { useAuth } from '../lib/auth'
import { useLoad } from '../lib/hooks'
import { db, q, rpc } from '../lib/supabase'
import { dateTime, money, titleCase } from '../lib/format'
import { people } from '../lib/people'
import { Avatar, Badge, Button, DataTable, ErrorBox, Loading, PageHeader, Tabs, statusTone, useAction, useUi } from '../components/ui'

export default function Payouts() {
  const go = useNavigate()
  const { can } = useAuth()
  const { confirm, toast } = useUi()
  const { busy, run } = useAction()
  const [tab, setTab] = useState<'requested' | 'processing' | 'paid' | 'rejected'>('requested')
  const data = useLoad(async () => {
    const rows = await q<any[]>(db.from('payouts').select('*').order('created_at', { ascending: true }))
    return { rows, ppl: await people(rows.map((r) => r.pro_id)) }
  })
  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const { rows, ppl } = data.data
  const list = rows.filter((r) => r.status === tab)
  const manage = can('finance.manage')

  const set = async (r: any, status: string) => {
    const note =
      status === 'rejected'
        ? await confirm({ title: 'Reject this payout?', message: 'The amount goes back to their balance.', input: 'Reason (sent to the professional)', inputRequired: true, danger: true, confirm: 'Reject' })
        : await confirm({ title: status === 'paid' ? `Mark ${money(r.amount)} as paid?` : 'Mark as processing?', message: status === 'paid' ? 'Only do this after the bank transfer has gone through.' : undefined, confirm: 'Confirm' })
    if (note) run(r.id + status, () => rpc('admin_set_payout', { p_payout: r.id, p_status: status, p_note: status === 'rejected' ? note : null }), 'Payout updated').then(data.reload)
  }

  return (
    <div>
      <PageHeader title="Payouts" subtitle="Professionals’ requests to withdraw their earnings. Send the transfer from your bank, then mark it paid here." />
      <div className="mb-4">
        <Tabs
          value={tab}
          onChange={setTab}
          items={(['requested', 'processing', 'paid', 'rejected'] as const).map((s) => ({ value: s, label: s === 'requested' ? 'New' : titleCase(s), count: rows.filter((r) => r.status === s).length }))}
        />
      </div>
      <div className="mb-4 text-sm text-ink-500">
        Total in this list: <b className="text-ink-900 dark:text-white">{money(list.reduce((a, r) => a + Number(r.amount), 0))}</b>
      </div>
      <DataTable
        rows={list}
        exportName={`payouts-${tab}`}
        search={(r) => `${ppl.get(r.pro_id)?.full_name} ${r.bank_name} ${r.account_number} ${r.account_name}`}
        selectable={manage && (tab === 'requested' || tab === 'processing') ? (r) => r.id : undefined}
        bulk={(ids, clear) => (
          <Button
            size="sm"
            variant="success"
            onClick={async () => {
              if (!(await confirm({ title: `Mark ${ids.length} payouts as paid?`, message: 'Only after the transfers have gone through.', confirm: 'Mark paid' }))) return
              await run('bulk', async () => {
                for (const id of ids) await rpc('admin_set_payout', { p_payout: id, p_status: 'paid' })
              }, 'Payouts marked paid')
              clear()
              data.reload()
            }}
          >
            Mark paid
          </Button>
        )}
        columns={[
          {
            key: 'pro',
            label: 'Professional',
            csv: (r) => ppl.get(r.pro_id)?.full_name,
            render: (r) => (
              <button className="flex items-center gap-2 font-semibold hover:text-brand-600" onClick={() => go(`/pros/${r.pro_id}`)}>
                <Avatar name={ppl.get(r.pro_id)?.full_name} url={ppl.get(r.pro_id)?.avatar_url} size={30} />
                {ppl.get(r.pro_id)?.full_name}
              </button>
            ),
          },
          { key: 'amount', label: 'Amount', sort: (r) => Number(r.amount), render: (r) => <b>{money(r.amount)}</b> },
          {
            key: 'bank',
            label: 'Send to',
            csv: (r) => `${r.bank_name} ${r.account_number} ${r.account_name}`,
            render: (r) => (
              <div>
                <div className="flex items-center gap-1.5 font-mono text-sm">
                  {r.account_number}
                  <button
                    onClick={() => {
                      navigator.clipboard.writeText(r.account_number ?? '')
                      toast('Account number copied')
                    }}
                  >
                    <Copy className="h-3.5 w-3.5 text-ink-400" />
                  </button>
                </div>
                <div className="text-xs text-ink-500">
                  {r.bank_name} · {r.account_name}
                </div>
              </div>
            ),
          },
          { key: 'date', label: 'Requested', sort: (r) => r.created_at, csv: (r) => r.created_at, render: (r) => dateTime(r.created_at) },
          { key: 'status', label: 'Status', csv: (r) => r.status, render: (r) => <Badge tone={statusTone(r.status)}>{titleCase(r.status)}</Badge> },
          {
            key: 'actions',
            label: '',
            render: (r) =>
              manage && (r.status === 'requested' || r.status === 'processing') ? (
                <div className="flex justify-end gap-1.5">
                  {r.status === 'requested' && (
                    <Button size="sm" variant="secondary" icon={<Loader className="h-3.5 w-3.5" />} loading={busy === r.id + 'processing'} onClick={() => set(r, 'processing')}>
                      Processing
                    </Button>
                  )}
                  <Button size="sm" variant="success" icon={<CheckCircle2 className="h-3.5 w-3.5" />} loading={busy === r.id + 'paid'} onClick={() => set(r, 'paid')}>
                    Paid
                  </Button>
                  <Button size="sm" variant="ghost" icon={<XCircle className="h-3.5 w-3.5" />} onClick={() => set(r, 'rejected')}>
                    Reject
                  </Button>
                </div>
              ) : null,
          },
        ]}
      />
    </div>
  )
}
