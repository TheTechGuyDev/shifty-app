import { Fragment, useEffect, useState } from 'react'
import { Plus, Save } from 'lucide-react'
import { useLoad } from '../lib/hooks'
import { db, q } from '../lib/supabase'
import { Badge, Button, Card, ErrorBox, Field, Loading, Modal, PageHeader, cx, useAction } from '../components/ui'

export const PERMISSIONS: { key: string; label: string; group: string }[] = [
  { key: 'dashboard.view', label: 'See the overview', group: 'General' },
  { key: 'reports.view', label: 'See analytics', group: 'General' },
  { key: 'bookings.view', label: 'See bookings', group: 'Bookings' },
  { key: 'bookings.manage', label: 'Dispatch, cancel and reschedule', group: 'Bookings' },
  { key: 'users.view', label: 'See customers', group: 'People' },
  { key: 'users.manage', label: 'Suspend and notify accounts', group: 'People' },
  { key: 'pros.view', label: 'See professionals', group: 'People' },
  { key: 'pros.manage', label: 'Edit professionals (level, commission, featured)', group: 'People' },
  { key: 'verification.manage', label: 'Approve applications and documents', group: 'People' },
  { key: 'catalogue.manage', label: 'Edit services and prices', group: 'Catalogue' },
  { key: 'offers.manage', label: 'Edit offers and promo codes', group: 'Catalogue' },
  { key: 'finance.view', label: 'See transactions and payouts', group: 'Finance' },
  { key: 'finance.manage', label: 'Mark payouts and payments', group: 'Finance' },
  { key: 'support.manage', label: 'Answer support chats', group: 'Trust' },
  { key: 'chat.view', label: 'Read customer–pro chats', group: 'Trust' },
  { key: 'chat.moderate', label: 'Remove chat messages', group: 'Trust' },
  { key: 'reviews.manage', label: 'Hide or publish reviews', group: 'Trust' },
  { key: 'broadcast.send', label: 'Send broadcasts', group: 'Trust' },
  { key: 'content.manage', label: 'Edit the Help Center', group: 'System' },
  { key: 'settings.manage', label: 'Change platform settings', group: 'System' },
  { key: 'admins.manage', label: 'Manage the team and roles', group: 'System' },
  { key: 'audit.view', label: 'See the audit log', group: 'System' },
]

export default function Roles() {
  const { busy, run } = useAction()
  const data = useLoad(() => q<any[]>(db.from('admin_roles').select('*').order('created_at')))
  const [draft, setDraft] = useState<Record<string, string[]>>({})
  const [add, setAdd] = useState(false)
  const [name, setName] = useState('')
  useEffect(() => {
    if (data.data) setDraft(Object.fromEntries(data.data.map((r) => [r.key, r.permissions])))
  }, [data.data])
  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const roles = data.data
  const dirty = roles.filter((r) => JSON.stringify([...(draft[r.key] ?? [])].sort()) !== JSON.stringify([...r.permissions].sort()))
  const groups = [...new Set(PERMISSIONS.map((p) => p.group))]

  const toggle = (role: string, perm: string) => {
    const cur = new Set(draft[role] ?? [])
    cur.has(perm) ? cur.delete(perm) : cur.add(perm)
    setDraft({ ...draft, [role]: [...cur] })
  }

  return (
    <div>
      <PageHeader
        title="Roles & Access"
        subtitle="Choose what each role can see and do. Super Admin always has full access."
        actions={
          <>
            <Button variant="secondary" icon={<Plus className="h-4 w-4" />} onClick={() => setAdd(true)}>
              New role
            </Button>
            <Button
              icon={<Save className="h-4 w-4" />}
              disabled={!dirty.length}
              loading={busy === 'save'}
              onClick={() =>
                run('save', async () => {
                  for (const r of dirty) await q(db.from('admin_roles').update({ permissions: draft[r.key] }).eq('key', r.key))
                  data.reload()
                }, 'Roles saved')
              }
            >
              Save {dirty.length ? `(${dirty.length})` : ''}
            </Button>
          </>
        }
      />
      <Card pad={false}>
        <div className="scrollbar-thin overflow-x-auto">
          <table className="w-full">
            <thead className="bg-ink-50/70 dark:bg-ink-850">
              <tr>
                <th className="th sticky left-0 bg-ink-50 dark:bg-ink-850">Permission</th>
                {roles.map((r) => (
                  <th key={r.key} className="th text-center">
                    {r.name}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {groups.map((g) => (
                <Fragment key={g}>
                  <tr>
                    <td colSpan={roles.length + 1} className="bg-ink-50/40 px-4 py-2 text-xs font-bold uppercase tracking-wide text-brand-600 dark:bg-ink-900">
                      {g}
                    </td>
                  </tr>
                  {PERMISSIONS.filter((p) => p.group === g).map((p) => (
                    <tr key={p.key} className="border-t border-ink-100 dark:border-ink-800">
                      <td className="td sticky left-0 bg-white dark:bg-ink-900">
                        <div className="font-medium">{p.label}</div>
                        <div className="text-[11px] text-ink-400">{p.key}</div>
                      </td>
                      {roles.map((r) => {
                        const all = (draft[r.key] ?? []).includes('*')
                        const on = all || (draft[r.key] ?? []).includes(p.key)
                        return (
                          <td key={r.key} className="td text-center">
                            <button
                              disabled={r.key === 'super_admin'}
                              onClick={() => toggle(r.key, p.key)}
                              className={cx(
                                'inline-flex h-6 w-6 items-center justify-center rounded-md border-2 text-xs font-bold transition disabled:cursor-not-allowed',
                                on ? 'border-brand-500 bg-brand-500 text-white' : 'border-ink-200 dark:border-ink-700',
                              )}
                            >
                              {on ? '✓' : ''}
                            </button>
                          </td>
                        )
                      })}
                    </tr>
                  ))}
                </Fragment>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
      <div className="mt-4 flex flex-wrap gap-2">
        {roles.map((r) => (
          <Badge key={r.key} tone={r.is_system ? 'gray' : 'purple'}>
            {r.name}: {r.description || 'Custom role'}
          </Badge>
        ))}
      </div>
      <Modal
        open={add}
        onClose={() => setAdd(false)}
        title="New role"
        footer={
          <Button
            disabled={name.trim().length < 3}
            loading={busy === 'add'}
            onClick={() =>
              run('add', async () => {
                const key = name.toLowerCase().trim().replace(/[^a-z0-9]+/g, '_')
                await q(db.from('admin_roles').insert({ key, name: name.trim(), description: 'Custom role', permissions: ['dashboard.view'] }))
                setAdd(false)
                setName('')
                data.reload()
              }, 'Role created. Tick its permissions and save.')
            }
          >
            Create
          </Button>
        }
      >
        <Field label="Role name" hint="e.g. City Manager, Night Dispatcher">
          <input className="input" value={name} onChange={(e) => setName(e.target.value)} />
        </Field>
      </Modal>
    </div>
  )
}
