import { useState } from 'react'
import { Copy, Pencil, Plus, Trash2 } from 'lucide-react'
import { useLoad } from '../lib/hooks'
import { db, q } from '../lib/supabase'
import { date, money, titleCase } from '../lib/format'
import { Badge, Button, DataTable, ErrorBox, Field, IconButton, Loading, Modal, PageHeader, Select, Stat, Toggle, useAction, useUi } from '../components/ui'
import { Gift, Percent, Ticket } from 'lucide-react'

type Offer = {
  id?: string
  section: string
  tag: string | null
  title: string
  subtitle: string | null
  code: string | null
  color_start: string | null
  color_end: string | null
  image: string | null
  chip: string | null
  valid_until: string | null
  is_active: boolean
  sort: number
  discount_pct: number
  service_slug: string | null
  category_id?: string | null
}

const blank: Offer = { section: 'latest', tag: 'Offer', title: '', subtitle: '', code: '', color_start: '#FD6B22', color_end: '#FFB37E', image: 'offer_cleaner', chip: '', valid_until: null, is_active: true, sort: 0, discount_pct: 10, service_slug: null }
const IMAGES = ['offer_cleaner', 'offer_cleaner_green', 'offer_painter', 'offer_truck']

export default function Offers() {
  const { confirm } = useUi()
  const { busy, run } = useAction()
  const [edit, setEdit] = useState<Offer | null>(null)
  const data = useLoad(async () => {
    const [offers, used, cats] = await Promise.all([
      q<Offer[]>(db.from('offers').select('*').order('sort')),
      q<any[]>(db.from('bookings').select('promo_code, discount').not('promo_code', 'is', null)),
      q<any[]>(db.from('service_categories').select('slug, name').not('parent_id', 'is', null).order('name')),
    ])
    const usage = new Map<string, { n: number; total: number }>()
    used.forEach((u) => {
      const k = String(u.promo_code).toUpperCase()
      const c = usage.get(k) ?? { n: 0, total: 0 }
      usage.set(k, { n: c.n + 1, total: c.total + Number(u.discount ?? 0) })
    })
    return { offers, usage, cats }
  })

  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const { offers, usage, cats } = data.data
  const totalDiscount = [...usage.values()].reduce((a, b) => a + b.total, 0)

  const save = () =>
    run('save', async () => {
      const { id, category_id, ...row } = edit!
      const clean = { ...row, code: row.code ? row.code.toUpperCase().trim() : null, valid_until: row.valid_until || null, service_slug: row.service_slug || null }
      if (id) await q(db.from('offers').update(clean).eq('id', id))
      else await q(db.from('offers').insert(clean))
      setEdit(null)
      data.reload()
    }, 'Offer saved')

  return (
    <div>
      <PageHeader
        title="Offers & Promos"
        subtitle="Cards on the home and offers screens, and the promo codes customers can apply at checkout."
        actions={
          <Button icon={<Plus className="h-4 w-4" />} onClick={() => setEdit({ ...blank })}>
            New offer
          </Button>
        }
      />
      <div className="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-3">
        <Stat label="Live offers" value={offers.filter((o) => o.is_active && (!o.valid_until || new Date(o.valid_until) > new Date())).length} icon={<Gift className="h-5 w-5" />} />
        <Stat label="Promo codes used" value={[...usage.values()].reduce((a, b) => a + b.n, 0)} icon={<Ticket className="h-5 w-5" />} tone="blue" />
        <Stat label="Discount given" value={money(totalDiscount)} icon={<Percent className="h-5 w-5" />} tone="green" />
      </div>
      <DataTable
        rows={offers}
        exportName="offers"
        search={(o) => `${o.title} ${o.code} ${o.tag}`}
        columns={[
          {
            key: 'card',
            label: 'Offer',
            csv: (o) => o.title,
            render: (o) => (
              <div className="flex items-center gap-3">
                <div className="h-12 w-20 shrink-0 rounded-xl" style={{ background: `linear-gradient(135deg, ${o.color_start}, ${o.color_end})` }} />
                <div>
                  <div className="font-semibold">{o.title}</div>
                  <div className="max-w-xs truncate text-xs text-ink-500">{o.subtitle}</div>
                </div>
              </div>
            ),
          },
          { key: 'section', label: 'Placement', csv: (o) => o.section, render: (o) => <Badge>{titleCase(o.section)}</Badge> },
          {
            key: 'code',
            label: 'Promo code',
            csv: (o) => o.code,
            render: (o) =>
              o.code ? (
                <span className="inline-flex items-center gap-1.5 rounded-lg bg-ink-100 px-2 py-1 font-mono text-xs font-bold dark:bg-ink-800">
                  {o.code}
                  <button onClick={(e) => (e.stopPropagation(), navigator.clipboard.writeText(o.code!))}>
                    <Copy className="h-3 w-3" />
                  </button>
                </span>
              ) : (
                '—'
              ),
          },
          { key: 'pct', label: 'Discount', sort: (o) => o.discount_pct, render: (o) => (o.discount_pct ? `${o.discount_pct}%` : '—') },
          { key: 'svc', label: 'Service', render: (o) => (o.service_slug ? cats.find((c) => c.slug === o.service_slug)?.name ?? o.service_slug : 'Any') },
          { key: 'used', label: 'Used', sort: (o) => usage.get((o.code ?? '').toUpperCase())?.n ?? 0, render: (o) => usage.get((o.code ?? '').toUpperCase())?.n ?? 0 },
          {
            key: 'valid',
            label: 'Valid until',
            csv: (o) => o.valid_until,
            render: (o) => (o.valid_until ? <span className={new Date(o.valid_until) < new Date() ? 'text-red-500' : ''}>{date(o.valid_until)}</span> : 'No end date'),
          },
          {
            key: 'active',
            label: 'Live',
            render: (o) => (
              <span onClick={(e) => e.stopPropagation()}>
                <Toggle checked={o.is_active} onChange={(v) => run(o.id!, async () => (await q(db.from('offers').update({ is_active: v }).eq('id', o.id!)), data.reload()))} />
              </span>
            ),
          },
          {
            key: 'x',
            label: '',
            render: (o) => (
              <div className="flex justify-end gap-1" onClick={(e) => e.stopPropagation()}>
                <IconButton onClick={() => setEdit({ ...o, valid_until: o.valid_until?.slice(0, 10) ?? null })}>
                  <Pencil className="h-4 w-4" />
                </IconButton>
                <IconButton
                  onClick={async () => {
                    if (await confirm({ title: `Delete “${o.title}”?`, danger: true, confirm: 'Delete' })) run(o.id!, async () => (await q(db.from('offers').delete().eq('id', o.id!)), data.reload()), 'Offer deleted')
                  }}
                >
                  <Trash2 className="h-4 w-4 text-red-500" />
                </IconButton>
              </div>
            ),
          },
        ]}
      />

      <Modal
        wide
        open={!!edit}
        onClose={() => setEdit(null)}
        title={edit?.id ? 'Edit offer' : 'New offer'}
        footer={
          <>
            <Button variant="secondary" onClick={() => setEdit(null)}>
              Cancel
            </Button>
            <Button loading={busy === 'save'} disabled={!edit?.title?.trim()} onClick={save}>
              Save
            </Button>
          </>
        }
      >
        {edit && (
          <div className="grid gap-6 md:grid-cols-[1fr_260px]">
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="sm:col-span-2">
                <Field label="Title">
                  <input className="input" value={edit.title} onChange={(e) => setEdit({ ...edit, title: e.target.value })} placeholder="e.g. 40% off deep cleaning" />
                </Field>
              </div>
              <div className="sm:col-span-2">
                <Field label="Subtitle">
                  <input className="input" value={edit.subtitle ?? ''} onChange={(e) => setEdit({ ...edit, subtitle: e.target.value })} />
                </Field>
              </div>
              <Field label="Tag">
                <input className="input" value={edit.tag ?? ''} onChange={(e) => setEdit({ ...edit, tag: e.target.value })} />
              </Field>
              <Field label="Placement">
                <Select
                  className="w-full"
                  value={edit.section}
                  onChange={(v) => setEdit({ ...edit, section: v })}
                  options={[
                    { value: 'latest', label: 'Latest offers' },
                    { value: 'limited', label: 'Limited time' },
                    { value: 'just_for_you', label: 'Just for you' },
                  ]}
                />
              </Field>
              <Field label="Promo code" hint="Leave empty for an info-only card">
                <input className="input font-mono uppercase" value={edit.code ?? ''} onChange={(e) => setEdit({ ...edit, code: e.target.value.toUpperCase() })} />
              </Field>
              <Field label="Discount %" hint="0 to 90">
                <input type="number" min={0} max={90} className="input" value={edit.discount_pct} onChange={(e) => setEdit({ ...edit, discount_pct: Number(e.target.value) })} />
              </Field>
              <Field label="Only for service">
                <Select className="w-full" value={edit.service_slug ?? ''} onChange={(v) => setEdit({ ...edit, service_slug: v || null })} options={[{ value: '', label: 'Any service' }, ...cats.map((c) => ({ value: c.slug, label: c.name }))]} />
              </Field>
              <Field label="Valid until">
                <input type="date" className="input" value={edit.valid_until ?? ''} onChange={(e) => setEdit({ ...edit, valid_until: e.target.value || null })} />
              </Field>
              <Field label="Colour (start)">
                <input type="color" className="h-10 w-full rounded-xl border border-ink-200" value={edit.color_start ?? '#FD6B22'} onChange={(e) => setEdit({ ...edit, color_start: e.target.value })} />
              </Field>
              <Field label="Colour (end)">
                <input type="color" className="h-10 w-full rounded-xl border border-ink-200" value={edit.color_end ?? '#FFB37E'} onChange={(e) => setEdit({ ...edit, color_end: e.target.value })} />
              </Field>
              <Field label="Picture">
                <Select className="w-full" value={edit.image ?? ''} onChange={(v) => setEdit({ ...edit, image: v })} options={IMAGES.map((i) => ({ value: i, label: titleCase(i.replace('offer_', '')) }))} />
              </Field>
              <Field label="Sort order">
                <input type="number" className="input" value={edit.sort} onChange={(e) => setEdit({ ...edit, sort: Number(e.target.value) })} />
              </Field>
            </div>
            <div>
              <div className="label">Preview</div>
              <div className="relative h-40 overflow-hidden rounded-3xl p-4 text-white" style={{ background: `linear-gradient(135deg, ${edit.color_start}, ${edit.color_end})` }}>
                <span className="rounded-full bg-white/25 px-2 py-0.5 text-[11px] font-semibold">{edit.tag || 'Offer'}</span>
                <div className="mt-2 max-w-[60%] text-lg font-bold leading-tight">{edit.title || 'Offer title'}</div>
                <div className="mt-1 max-w-[60%] text-xs opacity-90">{edit.subtitle}</div>
                {edit.image && <img src={`../assets/assets/images/app/${edit.image}.png`} className="absolute -bottom-2 right-0 h-32" alt="" onError={(e) => (e.currentTarget.style.display = 'none')} />}
              </div>
              <label className="mt-4 flex items-center justify-between rounded-xl bg-ink-50 p-3 text-sm font-medium dark:bg-ink-850">
                Live in the app
                <Toggle checked={edit.is_active} onChange={(v) => setEdit({ ...edit, is_active: v })} />
              </label>
            </div>
          </div>
        )}
      </Modal>
    </div>
  )
}
