import { useMemo, useState } from 'react'
import { Plus, Save } from 'lucide-react'
import { useLoad } from '../lib/hooks'
import { db, q } from '../lib/supabase'
import { money, titleCase } from '../lib/format'
import { Badge, Button, Card, ErrorBox, Field, Loading, Modal, PageHeader, Select, useAction } from '../components/ui'

type Row = { key: string; label: string; amount: number; unit: string }

export default function Pricing() {
  const { busy, run } = useAction()
  const [draft, setDraft] = useState<Record<string, string>>({})
  const [add, setAdd] = useState<Row | null>(null)
  const data = useLoad(() => q<Row[]>(db.from('pricing').select('*').order('key')))

  const groups = useMemo(() => {
    const m = new Map<string, Row[]>()
    data.data?.forEach((r) => {
      const g = r.key.includes('.') ? r.key.split('.')[0] : 'general'
      m.set(g, [...(m.get(g) ?? []), r])
    })
    return [...m.entries()]
  }, [data.data])

  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const changed = Object.keys(draft).filter((k) => String(data.data!.find((r) => r.key === k)?.amount) !== draft[k])

  const saveAll = () =>
    run(
      'save',
      async () => {
        for (const k of changed) await q(db.from('pricing').update({ amount: Number(draft[k]) }).eq('key', k))
        setDraft({})
        data.reload()
      },
      `${changed.length} prices updated`,
    )

  return (
    <div>
      <PageHeader
        title="Pricing"
        subtitle="Base prices the app uses to quote customers before a professional is chosen."
        actions={
          <>
            <Button variant="secondary" icon={<Plus className="h-4 w-4" />} onClick={() => setAdd({ key: '', label: '', amount: 0, unit: 'flat' })}>
              Add price
            </Button>
            <Button icon={<Save className="h-4 w-4" />} disabled={!changed.length} loading={busy === 'save'} onClick={saveAll}>
              Save {changed.length ? `(${changed.length})` : ''}
            </Button>
          </>
        }
      />
      <div className="grid gap-6 lg:grid-cols-2">
        {groups.map(([g, rows]) => (
          <Card key={g} title={titleCase(g)} subtitle={`${rows.length} prices`} pad={false}>
            <div className="divide-y divide-ink-100 dark:divide-ink-800">
              {rows.map((r) => (
                <div key={r.key} className="flex items-center gap-3 px-5 py-3">
                  <div className="min-w-0 flex-1">
                    <div className="text-sm font-semibold">{r.label}</div>
                    <div className="text-xs text-ink-400">{r.key}</div>
                  </div>
                  <Badge>{r.unit}</Badge>
                  <div className="relative w-36">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-sm text-ink-400">₦</span>
                    <input
                      type="number"
                      min={0}
                      className={`input pl-7 text-right font-semibold ${changed.includes(r.key) ? 'border-brand-400 bg-brand-50 dark:bg-brand-900/20' : ''}`}
                      value={draft[r.key] ?? String(r.amount)}
                      onChange={(e) => setDraft({ ...draft, [r.key]: e.target.value })}
                    />
                  </div>
                </div>
              ))}
            </div>
          </Card>
        ))}
      </div>
      <p className="mt-4 text-xs text-ink-500">The service charge row is added to every order. Promo discounts come from Offers & Promos. Current service charge: {money(data.data.find((r) => r.key === 'service_charge')?.amount)}.</p>
      <Modal
        open={!!add}
        onClose={() => setAdd(null)}
        title="Add a price"
        footer={
          <Button
            disabled={!add?.key || !add?.label}
            loading={busy === 'add'}
            onClick={() =>
              run('add', async () => {
                await q(db.from('pricing').insert(add!))
                setAdd(null)
                data.reload()
              }, 'Price added')
            }
          >
            Add
          </Button>
        }
      >
        {add && (
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Key" hint="group.name, e.g. cleaning.5bed">
              <input className="input" value={add.key} onChange={(e) => setAdd({ ...add, key: e.target.value.toLowerCase().replace(/\s/g, '') })} />
            </Field>
            <Field label="Label">
              <input className="input" value={add.label} onChange={(e) => setAdd({ ...add, label: e.target.value })} />
            </Field>
            <Field label="Amount (₦)">
              <input type="number" className="input" value={add.amount} onChange={(e) => setAdd({ ...add, amount: Number(e.target.value) })} />
            </Field>
            <Field label="Unit">
              <Select className="w-full" value={add.unit} onChange={(v) => setAdd({ ...add, unit: v })} options={['flat', 'each', 'hour', 'trip'].map((u) => ({ value: u, label: u }))} />
            </Field>
          </div>
        )}
      </Modal>
    </div>
  )
}
