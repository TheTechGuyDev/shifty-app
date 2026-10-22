import { BadgeCheck, MapPin, Send, UserCheck } from 'lucide-react'
import { useLoad } from '../lib/hooks'
import { rpc } from '../lib/supabase'
import { Avatar, Badge, Button, Empty, Loading, Modal, Stars, useAction, useUi } from './ui'

/** Pick a professional for a booking: offer the job or assign it directly. */
export default function Candidates({ bookingId, open, onClose, onDone }: { bookingId: string; open: boolean; onClose: () => void; onDone: () => void }) {
  const list = useLoad(() => (open ? rpc<any[]>('admin_candidates', { p_booking: bookingId }) : Promise.resolve([])), [bookingId, open])
  const { busy, run } = useAction()
  const { confirm } = useUi()

  const assign = async (p: any) => {
    if (!(await confirm({ title: `Assign to ${p.name}?`, message: 'The job becomes active right away and both sides are notified.', confirm: 'Assign' }))) return
    if (await run(p.id + 'a', () => rpc('admin_assign_pro', { p_booking: bookingId, p_pro: p.id }), `Assigned to ${p.name}`)) {
      onDone()
      onClose()
    }
  }
  const offer = (p: any) => run(p.id + 'o', () => rpc('admin_offer_booking', { p_booking: bookingId, p_pro: p.id }), `Request sent to ${p.name}`)

  return (
    <Modal open={open} onClose={onClose} title="Choose a professional" wide>
      {list.loading ? (
        <Loading h={200} />
      ) : !list.data?.length ? (
        <Empty title="No approved professionals" message="Approve professionals first, then you can dispatch jobs to them." />
      ) : (
        <div className="space-y-2">
          {list.data.map((p) => (
            <div key={p.id} className="flex flex-wrap items-center gap-3 rounded-2xl border border-ink-100 p-3 dark:border-ink-800">
              <Avatar name={p.name} url={p.avatar} size={42} />
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-1.5 font-semibold">
                  {p.name}
                  {p.level >= 2 && <BadgeCheck className="h-4 w-4 text-blue-500" />}
                </div>
                <div className="flex flex-wrap items-center gap-2 text-xs text-ink-500">
                  <Stars value={Number(p.rating)} /> {p.jobs_done} jobs
                  {p.distance_km != null && (
                    <span className="inline-flex items-center gap-0.5">
                      <MapPin className="h-3 w-3" /> {p.distance_km} km
                    </span>
                  )}
                </div>
              </div>
              <div className="flex flex-wrap gap-1.5">
                {p.offers_service ? <Badge tone="green">Offers this service</Badge> : <Badge>Other service</Badge>}
                <Badge tone={p.is_online ? 'green' : 'gray'} dot>
                  {p.is_online ? 'Online' : 'Offline'}
                </Badge>
              </div>
              <div className="flex gap-2">
                <Button size="sm" variant="secondary" loading={busy === p.id + 'o'} icon={<Send className="h-3.5 w-3.5" />} onClick={() => offer(p)}>
                  Send request
                </Button>
                <Button size="sm" loading={busy === p.id + 'a'} icon={<UserCheck className="h-3.5 w-3.5" />} onClick={() => assign(p)}>
                  Assign
                </Button>
              </div>
            </div>
          ))}
        </div>
      )}
    </Modal>
  )
}
