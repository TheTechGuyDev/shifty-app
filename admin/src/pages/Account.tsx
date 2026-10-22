import { useState } from 'react'
import { useAuth } from '../lib/auth'
import { db, q } from '../lib/supabase'
import { Avatar, Badge, Button, Card, Field, PageHeader, useAction } from '../components/ui'
import { useTheme } from '../components/Layout'
import { Toggle } from '../components/ui'
import { PERMISSIONS } from './Roles'

export default function Account() {
  const { me, refresh } = useAuth()
  const { dark, toggle } = useTheme()
  const { busy, run } = useAction()
  const [name, setName] = useState(me?.name ?? '')
  const [pw, setPw] = useState('')
  const [pw2, setPw2] = useState('')
  const perms = me?.permissions.includes('*') ? PERMISSIONS : PERMISSIONS.filter((p) => me?.permissions.includes(p.key))

  return (
    <div className="max-w-3xl">
      <PageHeader title="My account" />
      <div className="space-y-6">
        <Card>
          <div className="flex items-center gap-4">
            <Avatar name={me?.name} url={me?.avatar} size={64} />
            <div>
              <div className="text-lg font-bold">{me?.name}</div>
              <div className="text-sm text-ink-500">{me?.email}</div>
              <Badge tone="orange">{me?.role_name}</Badge>
            </div>
          </div>
        </Card>
        <Card title="Name">
          <div className="flex gap-3">
            <input className="input" value={name} onChange={(e) => setName(e.target.value)} />
            <Button
              loading={busy === 'name'}
              disabled={name.trim().length < 2}
              onClick={() => run('name', async () => (await q(db.from('profiles').update({ full_name: name.trim() }).eq('id', me!.id)), await refresh()), 'Name updated')}
            >
              Save
            </Button>
          </div>
        </Card>
        <Card title="Change password">
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="New password" hint="At least 8 characters">
              <input type="password" className="input" value={pw} onChange={(e) => setPw(e.target.value)} autoComplete="new-password" />
            </Field>
            <Field label="Repeat password">
              <input type="password" className="input" value={pw2} onChange={(e) => setPw2(e.target.value)} autoComplete="new-password" />
            </Field>
          </div>
          {pw2 && pw !== pw2 && <p className="mt-2 text-sm text-red-500">Passwords don’t match</p>}
          <div className="mt-4 flex justify-end">
            <Button
              loading={busy === 'pw'}
              disabled={pw.length < 8 || pw !== pw2}
              onClick={() =>
                run('pw', async () => {
                  const { error } = await db.auth.updateUser({ password: pw })
                  if (error) throw new Error(error.message)
                  setPw('')
                  setPw2('')
                }, 'Password changed')
              }
            >
              Update password
            </Button>
          </div>
        </Card>
        <Card title="Appearance">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium">Dark mode</span>
            <Toggle checked={dark} onChange={toggle} />
          </div>
        </Card>
        <Card title="What you can do" subtitle={me?.role_name}>
          <div className="flex flex-wrap gap-2">
            {perms.map((p) => (
              <Badge key={p.key} tone="green">
                {p.label}
              </Badge>
            ))}
          </div>
        </Card>
      </div>
    </div>
  )
}
