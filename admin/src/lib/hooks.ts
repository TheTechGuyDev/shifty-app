import { useCallback, useEffect, useRef, useState } from 'react'

/** Loads data with loading/error state and a reload function. */
export function useLoad<T>(fn: () => Promise<T>, deps: unknown[] = []) {
  const [data, setData] = useState<T | undefined>()
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const seq = useRef(0)
  const reload = useCallback(async () => {
    const id = ++seq.current
    setLoading(true)
    setError(null)
    try {
      const d = await fn()
      if (id === seq.current) setData(d)
    } catch (e) {
      if (id === seq.current) setError(e instanceof Error ? e.message : String(e))
    } finally {
      if (id === seq.current) setLoading(false)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps)
  useEffect(() => {
    reload()
  }, [reload])
  return { data, error, loading, reload, setData }
}

export function useDebounced<T>(value: T, ms = 250) {
  const [v, setV] = useState(value)
  useEffect(() => {
    const t = setTimeout(() => setV(value), ms)
    return () => clearTimeout(t)
  }, [value, ms])
  return v
}

export function useLocal<T>(key: string, initial: T) {
  const [v, setV] = useState<T>(() => {
    try {
      const s = localStorage.getItem(key)
      return s ? (JSON.parse(s) as T) : initial
    } catch {
      return initial
    }
  })
  useEffect(() => {
    try {
      localStorage.setItem(key, JSON.stringify(v))
    } catch {}
  }, [key, v])
  return [v, setV] as const
}
