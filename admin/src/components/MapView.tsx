import { useEffect, useRef } from 'react'
import L from 'leaflet'

export type Pin = { lat: number; lng: number; color?: string; label?: string; popup?: string; onClick?: () => void }

/** OpenStreetMap with coloured pins. Fits all pins in view. */
export default function MapView({ pins, height = 320, zoom = 12, circles }: { pins: Pin[]; height?: number | string; zoom?: number; circles?: { lat: number; lng: number; km: number }[] }) {
  const el = useRef<HTMLDivElement>(null)
  const map = useRef<L.Map | null>(null)
  const layer = useRef<L.LayerGroup | null>(null)

  useEffect(() => {
    if (!el.current || map.current) return
    map.current = L.map(el.current, { zoomControl: true, attributionControl: true }).setView([6.5244, 3.3792], zoom)
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19, attribution: '© OpenStreetMap' }).addTo(map.current)
    layer.current = L.layerGroup().addTo(map.current)
    setTimeout(() => map.current?.invalidateSize(), 200)
    return () => {
      map.current?.remove()
      map.current = null
    }
  }, [zoom])

  useEffect(() => {
    const m = map.current
    const g = layer.current
    if (!m || !g) return
    g.clearLayers()
    const pts: L.LatLngExpression[] = []
    circles?.forEach((c) => {
      L.circle([c.lat, c.lng], { radius: c.km * 1000, color: '#FD6B22', weight: 1.5, fillOpacity: 0.08 }).addTo(g)
    })
    pins.forEach((p) => {
      const icon = L.divIcon({
        className: '',
        iconSize: [30, 30],
        iconAnchor: [15, 30],
        html: `<div style="width:30px;height:30px;border-radius:50% 50% 50% 0;transform:rotate(-45deg);background:${p.color ?? '#FD6B22'};border:3px solid #fff;box-shadow:0 4px 10px rgba(0,0,0,.25);display:flex;align-items:center;justify-content:center"><span style="transform:rotate(45deg);color:#fff;font:700 11px 'DM Sans',sans-serif">${p.label ?? ''}</span></div>`,
      })
      const mk = L.marker([p.lat, p.lng], { icon }).addTo(g)
      if (p.popup) mk.bindPopup(p.popup)
      if (p.onClick) mk.on('click', p.onClick)
      pts.push([p.lat, p.lng])
    })
    if (pts.length === 1) m.setView(pts[0], 14)
    else if (pts.length > 1) m.fitBounds(L.latLngBounds(pts), { padding: [40, 40], maxZoom: 15 })
  }, [pins, circles])

  return <div ref={el} style={{ height }} className="z-0 w-full overflow-hidden rounded-2xl" />
}
