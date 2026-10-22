import { useState } from 'react'
import { StickyNote } from 'lucide-react'
import { useAuth } from '../lib/auth'
import { useLoad } from '../lib/hooks'
import { db, q } from '../lib/supabase'
import { ago } from '../lib/format'
import { people } from '../lib/people'
import { Avatar, Button, Card, useAction } from './ui'

/** Private notes the team leaves on a booking, customer or professional. */
export default function Notes({ entity, id }: { entity: string; id: string }) {
  const { me } = useAuth()
  const [text, setText] = useState('')
  const { busy, run } = useAction()
  const notes = useLoad(async () => {
    const rows = await q<any[]>(db.from('admin_notes').select('*').eq('entity', entity).eq('entity_id', id).order('created_at', { ascending: false }))
    const ppl = await people(rows.map((r) => r.admin_id))
    return rows.map((r) => ({ ...r, who: ppl.get(r.admin_id) }))
  }, [entity, id])

  const add = () =>
    run('add', async () => {
      await q(db.from('admin_notes').insert({ entity, entity_id: id, body: text.trim(), admin_id: me!.id }))
      setText('')
      notes.reload()
    })

  return (
    <Card title="Team notes" subtitle="Only visible to admins">
      <textarea className="input h-20 py-2" placeholder="Add a note for the team…" value={text} onChange={(e) => setText(e.target.value)} />
      <div className="mt-2 flex justify-end">
        <Button size="sm" disabled={text.trim().length < 2} loading={busy === 'add'} onClick={add} icon={<StickyNote className="h-3.5 w-3.5" />}>
          Add note
        </Button>
      </div>
      <div className="mt-4 space-y-3">
        {(notes.data ?? []).map((n) => (
          <div key={n.id} className="flex gap-3">
            <Avatar name={n.who?.full_name} url={n.who?.avatar_url} size={30} />
            <div className="flex-1 rounded-xl bg-ink-50 px-3 py-2 dark:bg-ink-850">
              <div className="text-xs text-ink-500">
                <span className="font-semibold text-ink-700 dark:text-ink-200">{n.who?.full_name ?? 'Admin'}</span> · {ago(n.created_at)}
              </div>
              <p className="mt-0.5 whitespace-pre-wrap text-sm">{n.body}</p>
            </div>
          </div>
        ))}
        {notes.data?.length === 0 && <p className="text-center text-xs text-ink-400">No notes yet</p>}
      </div>
    </Card>
  )
}
