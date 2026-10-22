import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useLoad } from '../lib/hooks'
import { db, q } from '../lib/supabase'
import { money } from '../lib/format'
import { Card, ErrorBox, Loading, PageHeader, Toggle } from '../components/ui'
import MapView, { type Pin } from '../components/MapView'

export default function LiveMap() {
  const go = useNavigate()
  const [show, setShow] = useState({ pending: true, active: true, pros: true, area: false })
  const data = useLoad(async () => {
    const [bookings, pros] = await Promise.all([
      q<any[]>(db.from('bookings').select('id, reference, service_name, status, lat, lng, total_amount, address').in('status', ['pending', 'active']).not('lat', 'is', null)),
      q<any[]>(db.from('professional_profiles').select('user_id, business_name, base_lat, base_lng, radius_km, is_online, status').eq('status', 'approved').not('base_lat', 'is', null)),
    ])
    return { bookings, pros }
  })

  const pins = useMemo<Pin[]>(() => {
    if (!data.data) return []
    const out: Pin[] = []
    data.data.bookings.forEach((b) => {
      if ((b.status === 'pending' && show.pending) || (b.status === 'active' && show.active))
        out.push({
          lat: b.lat,
          lng: b.lng,
          color: b.status === 'pending' ? '#F59E0B' : '#3F8CFF',
          label: b.status === 'pending' ? '!' : '',
          popup: `<b>${b.service_name}</b><br/>#${b.reference} · ${money(b.total_amount)}<br/>${b.address ?? ''}`,
          onClick: () => go(`/bookings/${b.id}`),
        })
    })
    if (show.pros)
      data.data.pros.forEach((p) =>
        out.push({ lat: p.base_lat, lng: p.base_lng, color: p.is_online ? '#4FBF67' : '#94A3B8', label: '', popup: `<b>${p.business_name ?? 'Professional'}</b><br/>${p.is_online ? 'Online' : 'Offline'} · ${p.radius_km} km`, onClick: () => go(`/pros/${p.user_id}`) }),
      )
    return out
  }, [data.data, show])

  const circles = useMemo(() => (show.area && data.data ? data.data.pros.map((p) => ({ lat: p.base_lat, lng: p.base_lng, km: p.radius_km })) : []), [data.data, show.area])

  if (data.error) return <ErrorBox message={data.error} onRetry={data.reload} />
  if (!data.data) return <Loading />
  const legend: [keyof typeof show, string, string, number][] = [
    ['pending', 'Waiting bookings', '#F59E0B', data.data.bookings.filter((b) => b.status === 'pending').length],
    ['active', 'Active jobs', '#3F8CFF', data.data.bookings.filter((b) => b.status === 'active').length],
    ['pros', 'Professionals', '#4FBF67', data.data.pros.length],
    ['area', 'Service areas', '#FD6B22', data.data.pros.length],
  ]

  return (
    <div>
      <PageHeader title="Live Map" subtitle="Where demand is and where your professionals are based." />
      <div className="grid gap-6 xl:grid-cols-4">
        <Card className="xl:col-span-3" pad={false}>
          <div className="p-2">
            <MapView pins={pins} circles={circles} height="calc(100vh - 230px)" zoom={11} />
          </div>
        </Card>
        <Card title="Layers">
          <div className="space-y-4">
            {legend.map(([k, label, color, n]) => (
              <div key={k} className="flex items-center gap-3">
                <span className="h-3 w-3 rounded-full" style={{ background: color }} />
                <span className="flex-1 text-sm">
                  {label} <span className="text-ink-400">({n})</span>
                </span>
                <Toggle checked={show[k]} onChange={(v) => setShow({ ...show, [k]: v })} />
              </div>
            ))}
          </div>
          <p className="mt-6 text-xs text-ink-500">Grey pins are professionals who are offline. Tap any pin to open it.</p>
        </Card>
      </div>
    </div>
  )
}
