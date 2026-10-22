export type Booking = {
  id: string
  reference: string
  customer_id: string
  professional_id: string | null
  category_id: string | null
  service_name: string
  service_slug: string | null
  kind: string
  status: 'pending' | 'active' | 'done' | 'cancelled'
  progress: string | null
  scheduled_at: string | null
  time_slot: string | null
  address: string | null
  lat: number | null
  lng: number | null
  dropoff_address: string | null
  dropoff_lat: number | null
  dropoff_lng: number | null
  details: Record<string, any>
  breakdown: { label: string; note?: string; amount: number }[] | null
  subtotal: number | null
  service_charge: number | null
  discount: number | null
  promo_code: string | null
  total_amount: number | null
  payment_method: string
  payment_status: string
  commission: number | null
  pro_earning: number | null
  before_photos: string[] | null
  after_photos: string[] | null
  reschedule_request: { at: string; note?: string } | null
  completed_at: string | null
  created_at: string
  updated_at: string
}

export type Person = { id: string; full_name: string | null; email: string | null; phone: string | null; avatar_url: string | null }

export const BOOKING_COLS =
  'id, reference, customer_id, professional_id, category_id, service_name, service_slug, kind, status, progress, scheduled_at, time_slot, address, lat, lng, dropoff_address, dropoff_lat, dropoff_lng, details, breakdown, subtotal, service_charge, discount, promo_code, total_amount, payment_method, payment_status, commission, pro_earning, before_photos, after_photos, reschedule_request, completed_at, created_at, updated_at'
