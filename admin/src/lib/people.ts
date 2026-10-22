import { db } from './supabase'
import type { Person } from './types'

const cache = new Map<string, Person>()

/** Loads names/avatars for a set of user ids (cached). */
export async function people(ids: (string | null | undefined)[]): Promise<Map<string, Person>> {
  const need = [...new Set(ids.filter((x): x is string => !!x && !cache.has(x)))]
  for (let i = 0; i < need.length; i += 150) {
    const { data } = await db.from('profiles').select('id, full_name, email, phone, avatar_url').in('id', need.slice(i, i + 150))
    data?.forEach((p) => cache.set(p.id, p as Person))
  }
  const pros = need.length ? await db.from('professional_profiles').select('user_id, business_name').in('user_id', need) : { data: [] as any[] }
  pros.data?.forEach((p: any) => {
    const c = cache.get(p.user_id)
    if (c && p.business_name) cache.set(p.user_id, { ...c, full_name: p.business_name })
  })
  return new Map(ids.filter((x): x is string => !!x).map((id) => [id, cache.get(id) ?? { id, full_name: 'Unknown', email: null, phone: null, avatar_url: null }]))
}
