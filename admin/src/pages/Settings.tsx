import { useEffect, useState } from 'react'
import { ExternalLink, Save } from 'lucide-react'
import { useLoad } from '../lib/hooks'
import { APP_URL, db, q, rpc } from '../lib/supabase'
import { money } from '../lib/format'
import { Button, Card, ErrorBox, Field, Loading, PageHeader, Toggle, useAction } from '../components/ui'

export default function Settings() {
  const { busy, run } = useAction()
  const data = useLoad(async () => {
    const [settings, charge] = await Promise.all([q<any[]>(db.from('app_settings').select('*')), q<any[]>(db.from('pricing').select('*').eq('key', 'service_charge'))])
    return { s: Object.fromEntries(settings.map((x) => [x.key, x.value])), charge: Number(charge[0]?.amount ?? 0) }
  })
  const [v, setV] = useState({ commission_pct: '10', min_payout: '5000', allow_self_approval: false, service_charge: '500' })
  useEffect(() => {
    if (data.data)
      setV({
        commission_pct: String(data.data.s.commission_pct ?? 10),
        min_payout: String(data.data.s.min_payout ?? 5000),
        allow_self_approval: data.data.s.allow_self_approval === true,
        service_charge: String(data.data.charge),
      })
  }, [data.data])
  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />

  const save = () =>
    run('save', async () => {
      await rpc('admin_set_setting', { p_key: 'commission_pct', p_value: Number(v.commission_pct) })
      await rpc('admin_set_setting', { p_key: 'min_payout', p_value: Number(v.min_payout) })
      await rpc('admin_set_setting', { p_key: 'allow_self_approval', p_value: v.allow_self_approval })
      await q(db.from('pricing').update({ amount: Number(v.service_charge) }).eq('key', 'service_charge'))
      data.reload()
    }, 'Settings saved')

  const example = 20000
  const fee = (example * Number(v.commission_pct || 0)) / 100

  return (
    <div className="max-w-4xl">
      <PageHeader
        title="Settings"
        subtitle="Platform rules that apply across the customer and professional apps."
        actions={
          <Button icon={<Save className="h-4 w-4" />} loading={busy === 'save'} onClick={save}>
            Save changes
          </Button>
        }
      />
      <div className="space-y-6">
        <Card title="Money" subtitle="Applies to jobs completed and payouts requested after you save.">
          <div className="grid gap-5 sm:grid-cols-3">
            <Field label="Commission (%)" hint={`On a ${money(example)} job: you keep ${money(fee)}, the pro gets ${money(example - fee)}`}>
              <input type="number" min={0} max={50} step={0.5} className="input" value={v.commission_pct} onChange={(e) => setV({ ...v, commission_pct: e.target.value })} />
            </Field>
            <Field label="Service charge (₦)" hint="Added to every customer order">
              <input type="number" min={0} className="input" value={v.service_charge} onChange={(e) => setV({ ...v, service_charge: e.target.value })} />
            </Field>
            <Field label="Minimum payout (₦)" hint="Smallest amount a pro can withdraw">
              <input type="number" min={0} className="input" value={v.min_payout} onChange={(e) => setV({ ...v, min_payout: e.target.value })} />
            </Field>
          </div>
          <p className="mt-4 text-xs text-ink-500">Individual professionals can have their own commission rate from their profile page.</p>
        </Card>
        <Card title="Professional approval">
          <div className="flex items-center gap-4">
            <div className="flex-1">
              <div className="font-semibold">Let professionals approve themselves (test mode)</div>
              <p className="text-sm text-ink-500">Shows an “Approve me (test)” button in the professional app. Turn this off before launch so only your team can approve.</p>
            </div>
            <Toggle checked={v.allow_self_approval} onChange={(x) => setV({ ...v, allow_self_approval: x })} />
          </div>
          {v.allow_self_approval && <p className="mt-3 rounded-xl bg-amber-50 p-3 text-sm text-amber-700 dark:bg-amber-900/20 dark:text-amber-300">Test mode is on. Anyone can become an approved professional.</p>}
        </Card>
        <Card title="Links">
          <div className="grid gap-3 sm:grid-cols-2">
            {[
              ['Customer and professional app', APP_URL],
              ['Android test build (APK)', 'https://github.com/TheTechGuyDev/shifty-app/releases/download/android-latest/shifty.apk'],
              ['Database and login settings', 'https://supabase.com/dashboard/project/trgqypwaewtpamaaixll'],
              ['Source code', 'https://github.com/TheTechGuyDev/shifty-app'],
            ].map(([l, u]) => (
              <a key={u} href={u} target="_blank" rel="noreferrer" className="flex items-center justify-between rounded-xl border border-ink-100 p-4 text-sm font-semibold hover:border-brand-400 dark:border-ink-800">
                {l} <ExternalLink className="h-4 w-4 text-ink-400" />
              </a>
            ))}
          </div>
        </Card>
      </div>
    </div>
  )
}
