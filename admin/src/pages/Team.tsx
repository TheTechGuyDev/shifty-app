import { useState } from 'react'
import { UserPlus } from 'lucide-react'
import { useAuth } from '../lib/auth'
import { useLoad } from '../lib/hooks'
import { db, q, rpc } from '../lib/supabase'
import { ago, date } from '../lib/format'
import { Avatar, Badge, Button, DataTable, ErrorBox, Field, Loading, Modal, PageHeader, Select, useAction, useUi } from '../components/ui'

export default function Team() {
  const { me, refresh } = useAuth()
  const { confirm, toast } = useUi()
  const { busy, run } = useAction()
  const [add, setAdd] = useState(false)
  const [email, setEmail] = useState('')
  const [role, setRole] = useState('support')
  const data = useLoad(async () => {
    const [admins, roles, audit] = await Promise.all([
      q<any[]>(db.from('profiles').select('id, full_name, email, avatar_url, admin_role, created_at').not('admin_role', 'is', null)),
      q<any[]>(db.from('admin_roles').select('*').order('name')),
      q<any[]>(db.from('admin_audit').select('admin_id, created_at').order('created_at', { ascending: false }).limit(500)).catch(() => []),
    ])
    const last = new Map<string, string>()
    audit.forEach((a) => !last.has(a.admin_id) && last.set(a.admin_id, a.created_at))
    return { admins, roles, last }
  })
  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const { admins, roles, last } = data.data
  const roleName = (k: string) => roles.find((r) => r.key === k)?.name ?? k

  const invite = () =>
    run('add', async () => {
      const u = await rpc<any>('admin_find_user', { p_email: email })
      if (!u) throw new Error('No account with that email. Ask them to sign up in the app first, then add them here.')
      await rpc('admin_set_role', { p_user: u.id, p_role: role })
      setAdd(false)
      setEmail('')
      data.reload()
      toast(`${u.name ?? u.email} is now ${roleName(role)}`)
    })

  return (
    <div>
      <PageHeader
        title="Admin Team"
        subtitle="People who can sign in to this dashboard, and what they can do."
        actions={
          <Button icon={<UserPlus className="h-4 w-4" />} onClick={() => setAdd(true)}>
            Add team member
          </Button>
        }
      />
      <DataTable
        rows={admins}
        columns={[
          {
            key: 'n',
            label: 'Member',
            render: (r) => (
              <div className="flex items-center gap-3">
                <Avatar name={r.full_name} url={r.avatar_url} />
                <div>
                  <div className="font-semibold">
                    {r.full_name} {r.id === me?.id && <Badge tone="orange">You</Badge>}
                  </div>
                  <div className="text-xs text-ink-500">{r.email}</div>
                </div>
              </div>
            ),
          },
          {
            key: 'role',
            label: 'Role',
            render: (r) => (
              <Select
                value={r.admin_role}
                onChange={(v) =>
                  run(r.id, () => rpc('admin_set_role', { p_user: r.id, p_role: v }), 'Role updated').then(() => {
                    data.reload()
                    if (r.id === me?.id) refresh()
                  })
                }
                options={roles.map((x) => ({ value: x.key, label: x.name }))}
              />
            ),
          },
          { key: 'active', label: 'Last admin action', render: (r) => ago(last.get(r.id)) },
          { key: 'since', label: 'Account created', render: (r) => date(r.created_at) },
          {
            key: 'x',
            label: '',
            render: (r) => (
              <Button
                size="sm"
                variant="ghost"
                loading={busy === 'rm' + r.id}
                onClick={async () => {
                  if (await confirm({ title: `Remove ${r.full_name} from the team?`, message: 'Their app account stays. They just lose dashboard access.', danger: true, confirm: 'Remove' }))
                    run('rm' + r.id, () => rpc('admin_set_role', { p_user: r.id, p_role: null }), 'Removed').then(data.reload)
                }}
              >
                Remove
              </Button>
            ),
          },
        ]}
      />
      <Modal
        open={add}
        onClose={() => setAdd(false)}
        title="Add team member"
        footer={
          <Button loading={busy === 'add'} disabled={!email.includes('@')} onClick={invite}>
            Add
          </Button>
        }
      >
        <div className="space-y-4">
          <Field label="Email" hint="They must already have an account in the app.">
            <input className="input" type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
          </Field>
          <Field label="Role">
            <Select className="w-full" value={role} onChange={setRole} options={roles.map((x) => ({ value: x.key, label: x.name }))} />
          </Field>
          <p className="rounded-xl bg-ink-50 p-3 text-xs text-ink-600 dark:bg-ink-850 dark:text-ink-300">{roles.find((r) => r.key === role)?.description}</p>
        </div>
      </Modal>
    </div>
  )
}
