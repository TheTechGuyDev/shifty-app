import { useMemo, useState } from 'react'
import { ArrowDown, ArrowUp, ChevronRight, Pencil, Plus } from 'lucide-react'
import { useLoad } from '../lib/hooks'
import { db, q } from '../lib/supabase'
import { Badge, Button, Card, ErrorBox, Field, IconButton, Loading, Modal, PageHeader, SearchInput, Select, Toggle, cx, useAction } from '../components/ui'

type Cat = {
  id: string
  parent_id: string | null
  name: string
  slug: string
  description: string | null
  icon: string
  color: string
  home_section: string | null
  badge: string | null
  requires_verification: boolean
  sort: number
  home_sort: number | null
  is_active: boolean
}

const blank: Partial<Cat> = { name: '', slug: '', description: '', icon: 'build', color: '#FD6B22', home_section: null, badge: '', requires_verification: false, sort: 0, is_active: true, parent_id: null }
const slugify = (s: string) => s.toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')

export default function Services() {
  const { busy, run } = useAction()
  const [edit, setEdit] = useState<Partial<Cat> | null>(null)
  const [term, setTerm] = useState('')
  const [openGroups, setOpenGroups] = useState<Set<string>>(new Set())
  const data = useLoad(async () => {
    const [cats, counts, offered] = await Promise.all([
      q<Cat[]>(db.from('service_categories').select('*').order('sort')),
      q<any[]>(db.from('bookings').select('category_id')),
      q<any[]>(db.from('pro_services').select('category_id')),
    ])
    const bc = new Map<string, number>()
    counts.forEach((c) => bc.set(c.category_id, (bc.get(c.category_id) ?? 0) + 1))
    const pc = new Map<string, number>()
    offered.forEach((c) => pc.set(c.category_id, (pc.get(c.category_id) ?? 0) + 1))
    return { cats, bc, pc }
  })

  const groups = useMemo(() => (data.data?.cats ?? []).filter((c) => !c.parent_id), [data.data])

  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const { cats, bc, pc } = data.data
  const t = term.toLowerCase()

  const save = () =>
    run(
      'save',
      async () => {
        const v = { ...edit }
        const row = {
          name: v.name!.trim(),
          slug: v.slug || slugify(v.name!),
          description: v.description || null,
          icon: v.icon || 'build',
          color: v.color || '#FD6B22',
          home_section: v.home_section || null,
          badge: v.badge || null,
          requires_verification: !!v.requires_verification,
          sort: Number(v.sort ?? 0),
          home_sort: v.home_sort ?? null,
          is_active: v.is_active ?? true,
          parent_id: v.parent_id || null,
        }
        if (v.id) await q(db.from('service_categories').update(row).eq('id', v.id))
        else await q(db.from('service_categories').insert(row))
        setEdit(null)
        data.reload()
      },
      'Saved',
    )

  const quick = (c: Cat, values: Partial<Cat>) => run(c.id, async () => {
    await q(db.from('service_categories').update(values).eq('id', c.id))
    data.reload()
  })

  const move = (list: Cat[], i: number, dir: -1 | 1) => {
    const a = list[i]
    const b = list[i + dir]
    if (!a || !b) return
    run(a.id, async () => {
      await q(db.from('service_categories').update({ sort: b.sort }).eq('id', a.id))
      await q(db.from('service_categories').update({ sort: a.sort === b.sort ? a.sort + dir : a.sort }).eq('id', b.id))
      data.reload()
    })
  }

  return (
    <div>
      <PageHeader
        title="Services"
        subtitle={`${cats.filter((c) => c.parent_id).length} services in ${groups.length} groups. Changes show in the app right away.`}
        actions={
          <>
            <SearchInput value={term} onChange={setTerm} className="w-60" />
            <Button variant="secondary" icon={<Plus className="h-4 w-4" />} onClick={() => setEdit({ ...blank })}>
              New group
            </Button>
            <Button icon={<Plus className="h-4 w-4" />} onClick={() => setEdit({ ...blank, parent_id: groups[0]?.id })}>
              New service
            </Button>
          </>
        }
      />
      <div className="space-y-3">
        {groups.map((g, gi) => {
          const kids = cats.filter((c) => c.parent_id === g.id && (!t || c.name.toLowerCase().includes(t)))
          if (t && !kids.length && !g.name.toLowerCase().includes(t)) return null
          const open = openGroups.has(g.id) || !!t
          return (
            <Card key={g.id} pad={false}>
              <div className="flex items-center gap-3 px-5 py-4">
                <button
                  className="flex flex-1 items-center gap-3 text-left"
                  onClick={() => {
                    const n = new Set(openGroups)
                    n.has(g.id) ? n.delete(g.id) : n.add(g.id)
                    setOpenGroups(n)
                  }}
                >
                  <ChevronRight className={cx('h-4 w-4 text-ink-400 transition', open && 'rotate-90')} />
                  <span className="h-8 w-8 rounded-lg" style={{ background: g.color }} />
                  <div>
                    <div className="font-bold">{g.name}</div>
                    <div className="text-xs text-ink-500">{cats.filter((c) => c.parent_id === g.id).length} services</div>
                  </div>
                </button>
                {g.home_section && <Badge tone="orange">Home: {g.home_section}</Badge>}
                {!g.is_active && <Badge tone="gray">Hidden</Badge>}
                <IconButton onClick={() => move(groups, gi, -1)} disabled={gi === 0}>
                  <ArrowUp className="h-4 w-4" />
                </IconButton>
                <IconButton onClick={() => move(groups, gi, 1)} disabled={gi === groups.length - 1}>
                  <ArrowDown className="h-4 w-4" />
                </IconButton>
                <Toggle checked={g.is_active} onChange={(v) => quick(g, { is_active: v })} />
                <IconButton onClick={() => setEdit(g)}>
                  <Pencil className="h-4 w-4" />
                </IconButton>
              </div>
              {open && (
                <div className="divide-y divide-ink-100 border-t border-ink-100 dark:divide-ink-800 dark:border-ink-800">
                  {kids.map((c, i) => (
                    <div key={c.id} className="flex flex-wrap items-center gap-3 py-3 pl-14 pr-5">
                      <span className="h-3 w-3 rounded-full" style={{ background: c.color }} />
                      <div className="min-w-0 flex-1">
                        <div className="text-sm font-semibold">{c.name}</div>
                        <div className="text-xs text-ink-500">
                          /{c.slug} · {bc.get(c.id) ?? 0} bookings · {pc.get(c.id) ?? 0} pros offer it
                        </div>
                      </div>
                      {c.badge && <Badge tone="purple">{c.badge}</Badge>}
                      {c.requires_verification && <Badge tone="blue">Needs licence</Badge>}
                      {c.home_section && <Badge tone="orange">Home</Badge>}
                      <IconButton onClick={() => move(kids, i, -1)} disabled={i === 0}>
                        <ArrowUp className="h-4 w-4" />
                      </IconButton>
                      <IconButton onClick={() => move(kids, i, 1)} disabled={i === kids.length - 1}>
                        <ArrowDown className="h-4 w-4" />
                      </IconButton>
                      <Toggle checked={c.is_active} disabled={busy === c.id} onChange={(v) => quick(c, { is_active: v })} />
                      <IconButton onClick={() => setEdit(c)}>
                        <Pencil className="h-4 w-4" />
                      </IconButton>
                    </div>
                  ))}
                  {kids.length === 0 && <p className="py-4 pl-14 text-sm text-ink-500">No services in this group.</p>}
                </div>
              )}
            </Card>
          )
        })}
      </div>

      <Modal
        open={!!edit}
        onClose={() => setEdit(null)}
        title={edit?.id ? `Edit ${edit.name}` : edit?.parent_id ? 'New service' : 'New group'}
        footer={
          <>
            <Button variant="secondary" onClick={() => setEdit(null)}>
              Cancel
            </Button>
            <Button loading={busy === 'save'} disabled={!edit?.name?.trim()} onClick={save}>
              Save
            </Button>
          </>
        }
      >
        {edit && (
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Name">
              <input className="input" value={edit.name ?? ''} onChange={(e) => setEdit({ ...edit, name: e.target.value, slug: edit.id ? edit.slug : slugify(e.target.value) })} />
            </Field>
            <Field label="Slug (link name)" hint="Used by the booking flow. Change with care.">
              <input className="input" value={edit.slug ?? ''} onChange={(e) => setEdit({ ...edit, slug: slugify(e.target.value) })} />
            </Field>
            <Field label="Group">
              <Select
                className="w-full"
                value={edit.parent_id ?? ''}
                onChange={(v) => setEdit({ ...edit, parent_id: v || null })}
                options={[{ value: '', label: 'None (this is a group)' }, ...groups.filter((g) => g.id !== edit.id).map((g) => ({ value: g.id, label: g.name }))]}
              />
            </Field>
            <Field label="Icon name" hint="e.g. cleaning, plumbing, truck, paint, bolt">
              <input className="input" value={edit.icon ?? ''} onChange={(e) => setEdit({ ...edit, icon: e.target.value })} />
            </Field>
            <Field label="Colour">
              <div className="flex gap-2">
                <input type="color" className="h-10 w-12 rounded-lg border border-ink-200" value={edit.color ?? '#FD6B22'} onChange={(e) => setEdit({ ...edit, color: e.target.value })} />
                <input className="input" value={edit.color ?? ''} onChange={(e) => setEdit({ ...edit, color: e.target.value })} />
              </div>
            </Field>
            <Field label="Badge (optional)" hint="e.g. New, Popular">
              <input className="input" value={edit.badge ?? ''} onChange={(e) => setEdit({ ...edit, badge: e.target.value })} />
            </Field>
            <Field label="Show on home screen">
              <Select
                className="w-full"
                value={edit.home_section ?? ''}
                onChange={(v) => setEdit({ ...edit, home_section: v || null })}
                options={[
                  { value: '', label: 'No' },
                  { value: 'hero', label: 'Big cards at the top' },
                  { value: 'other', label: '“Other services” list' },
                ]}
              />
            </Field>
            <Field label="Sort order">
              <input type="number" className="input" value={edit.sort ?? 0} onChange={(e) => setEdit({ ...edit, sort: Number(e.target.value) })} />
            </Field>
            <div className="sm:col-span-2">
              <Field label="Description">
                <textarea className="input h-20 py-2" value={edit.description ?? ''} onChange={(e) => setEdit({ ...edit, description: e.target.value })} />
              </Field>
            </div>
            <label className="flex items-center justify-between gap-3 rounded-xl bg-ink-50 p-3 dark:bg-ink-850">
              <span className="text-sm font-medium">Needs a checked licence</span>
              <Toggle checked={!!edit.requires_verification} onChange={(v) => setEdit({ ...edit, requires_verification: v })} />
            </label>
            <label className="flex items-center justify-between gap-3 rounded-xl bg-ink-50 p-3 dark:bg-ink-850">
              <span className="text-sm font-medium">Visible in the app</span>
              <Toggle checked={edit.is_active ?? true} onChange={(v) => setEdit({ ...edit, is_active: v })} />
            </label>
          </div>
        )}
      </Modal>
    </div>
  )
}
