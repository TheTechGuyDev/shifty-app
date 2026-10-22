import { createClient } from '@supabase/supabase-js'

export const SUPABASE_URL = 'https://trgqypwaewtpamaaixll.supabase.co'
export const SUPABASE_KEY = 'sb_publishable_k4ZflmSCyOLodE0xIhlUng_aVblZjB2'
export const APP_NAME = 'Shifty'
export const APP_URL = 'https://thetechguydev.github.io/shifty-app/'

export const db = createClient(SUPABASE_URL, SUPABASE_KEY, {
  auth: { persistSession: true, storageKey: 'shifty-admin-auth' },
})

/** Calls an RPC and throws a readable error. */
export async function rpc<T = unknown>(fn: string, params?: Record<string, unknown>): Promise<T> {
  const { data, error } = await db.rpc(fn, params)
  if (error) throw new Error(error.message)
  return data as T
}

/** Runs a query builder and throws on error. */
export async function q<T = any>(p: PromiseLike<{ data: T | null; error: { message: string } | null }>): Promise<T> {
  const { data, error } = await p
  if (error) throw new Error(error.message)
  return data as T
}
