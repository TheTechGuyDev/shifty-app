import { useMemo, useState } from 'react'
import { Pencil, Plus, Trash2 } from 'lucide-react'
import { useLoad } from '../lib/hooks'
import { db, q } from '../lib/supabase'
import { Badge, Button, Card, Empty, ErrorBox, Field, IconButton, Loading, Modal, PageHeader, SearchInput, useAction, useUi } from '../components/ui'

type Faq = { id?: string; category: string; question: string; answer: string; sort: number }

export default function Faqs() {
  const { confirm } = useUi()
  const { busy, run } = useAction()
  const [edit, setEdit] = useState<Faq | null>(null)
  const [term, setTerm] = useState('')
  const data = useLoad(() => q<Faq[]>(db.from('faqs').select('*').order('category').order('sort')))
  const cats = useMemo(() => [...new Set((data.data ?? []).map((f) => f.category))], [data.data])
  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const t = term.toLowerCase()

  return (
    <div>
      <PageHeader
        title="Help Center"
        subtitle="Questions and answers shown on the FAQ screen of the app."
        actions={
          <>
            <SearchInput value={term} onChange={setTerm} className="w-60" />
            <Button icon={<Plus className="h-4 w-4" />} onClick={() => setEdit({ category: cats[0] ?? 'General', question: '', answer: '', sort: 0 })}>
              New question
            </Button>
          </>
        }
      />
      {cats.length === 0 && (
        <Card>
          <Empty title="No questions yet" />
        </Card>
      )}
      <div className="space-y-6">
        {cats.map((c) => {
          const items = data.data!.filter((f) => f.category === c && (!t || `${f.question} ${f.answer}`.toLowerCase().includes(t)))
          if (!items.length) return null
          return (
            <Card key={c} title={c} subtitle={`${items.length} questions`} pad={false}>
              <div className="divide-y divide-ink-100 dark:divide-ink-800">
                {items.map((f) => (
                  <div key={f.id} className="flex gap-3 px-5 py-4">
                    <div className="min-w-0 flex-1">
                      <div className="font-semibold">{f.question}</div>
                      <p className="mt-1 text-sm text-ink-600 dark:text-ink-300">{f.answer}</p>
                    </div>
                    <Badge>#{f.sort}</Badge>
                    <IconButton onClick={() => setEdit(f)}>
                      <Pencil className="h-4 w-4" />
                    </IconButton>
                    <IconButton
                      onClick={async () => {
                        if (await confirm({ title: 'Delete this question?', danger: true, confirm: 'Delete' })) run(f.id!, async () => (await q(db.from('faqs').delete().eq('id', f.id!)), data.reload()), 'Deleted')
                      }}
                    >
                      <Trash2 className="h-4 w-4 text-red-500" />
                    </IconButton>
                  </div>
                ))}
              </div>
            </Card>
          )
        })}
      </div>
      <Modal
        open={!!edit}
        onClose={() => setEdit(null)}
        title={edit?.id ? 'Edit question' : 'New question'}
        footer={
          <Button
            loading={busy === 'save'}
            disabled={!edit?.question.trim() || !edit?.answer.trim() || !edit?.category.trim()}
            onClick={() =>
              run('save', async () => {
                const { id, ...row } = edit!
                if (id) await q(db.from('faqs').update(row).eq('id', id))
                else await q(db.from('faqs').insert(row))
                setEdit(null)
                data.reload()
              }, 'Saved')
            }
          >
            Save
          </Button>
        }
      >
        {edit && (
          <div className="space-y-4">
            <Field label="Category" hint="Pick an existing one or type a new one">
              <input className="input" list="faq-cats" value={edit.category} onChange={(e) => setEdit({ ...edit, category: e.target.value })} />
              <datalist id="faq-cats">
                {cats.map((c) => (
                  <option key={c} value={c} />
                ))}
              </datalist>
            </Field>
            <Field label="Question">
              <input className="input" value={edit.question} onChange={(e) => setEdit({ ...edit, question: e.target.value })} />
            </Field>
            <Field label="Answer">
              <textarea className="input h-32 py-2" value={edit.answer} onChange={(e) => setEdit({ ...edit, answer: e.target.value })} />
            </Field>
            <Field label="Order">
              <input type="number" className="input" value={edit.sort} onChange={(e) => setEdit({ ...edit, sort: Number(e.target.value) })} />
            </Field>
          </div>
        )}
      </Modal>
    </div>
  )
}
