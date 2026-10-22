import { Area, AreaChart, Bar, BarChart, CartesianGrid, Cell, Legend, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { compactMoney, num } from '../lib/format'

export const COLORS = ['#FD6B22', '#3F8CFF', '#4FBF67', '#8B5CF6', '#FDB921', '#EC4899', '#14B8A6', '#94A3B8']

const axis = { stroke: 'currentColor', tick: { fontSize: 11, fill: 'currentColor' }, tickLine: false, axisLine: false }

function Tip({ active, payload, label, money }: any) {
  if (!active || !payload?.length) return null
  return (
    <div className="rounded-xl border border-ink-100 bg-white px-3 py-2 text-xs shadow-lg dark:border-ink-700 dark:bg-ink-850">
      {label != null && <div className="mb-1 font-semibold">{label}</div>}
      {payload.map((p: any) => (
        <div key={p.dataKey ?? p.name} className="flex items-center gap-2">
          <span className="h-2 w-2 rounded-full" style={{ background: p.color ?? p.payload?.fill }} />
          <span className="text-ink-500">{p.name}:</span>
          <span className="font-semibold">{money?.includes?.(p.dataKey) || money === true ? compactMoney(p.value) : num(p.value)}</span>
        </div>
      ))}
    </div>
  )
}

export function AreaTrend({ data, x, series, money, height = 280 }: { data: any[]; x: string; series: { key: string; name: string; color?: string }[]; money?: string[] | boolean; height?: number }) {
  return (
    <div className="text-ink-400" style={{ height }}>
      <ResponsiveContainer>
        <AreaChart data={data} margin={{ top: 10, right: 8, left: -12, bottom: 0 }}>
          <defs>
            {series.map((s, i) => (
              <linearGradient key={s.key} id={`g-${s.key}`} x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor={s.color ?? COLORS[i]} stopOpacity={0.28} />
                <stop offset="100%" stopColor={s.color ?? COLORS[i]} stopOpacity={0} />
              </linearGradient>
            ))}
          </defs>
          <CartesianGrid strokeDasharray="3 3" stroke="currentColor" strokeOpacity={0.15} vertical={false} />
          <XAxis dataKey={x} {...axis} minTickGap={24} />
          <YAxis {...axis} tickFormatter={(v) => (money ? compactMoney(v) : num(v))} width={56} />
          <Tooltip content={<Tip money={money} />} />
          {series.map((s, i) => (
            <Area key={s.key} type="monotone" dataKey={s.key} name={s.name} stroke={s.color ?? COLORS[i]} strokeWidth={2.5} fill={`url(#g-${s.key})`} />
          ))}
        </AreaChart>
      </ResponsiveContainer>
    </div>
  )
}

export function Bars({ data, x, series, money, height = 280, horizontal }: { data: any[]; x: string; series: { key: string; name: string; color?: string }[]; money?: string[] | boolean; height?: number; horizontal?: boolean }) {
  return (
    <div className="text-ink-400" style={{ height }}>
      <ResponsiveContainer>
        <BarChart data={data} layout={horizontal ? 'vertical' : 'horizontal'} margin={{ top: 10, right: 8, left: horizontal ? 8 : -12, bottom: 0 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="currentColor" strokeOpacity={0.15} vertical={!!horizontal} horizontal={!horizontal} />
          {horizontal ? (
            <>
              <XAxis type="number" {...axis} tickFormatter={(v) => (money ? compactMoney(v) : num(v))} />
              <YAxis type="category" dataKey={x} {...axis} width={120} />
            </>
          ) : (
            <>
              <XAxis dataKey={x} {...axis} minTickGap={12} />
              <YAxis {...axis} tickFormatter={(v) => (money ? compactMoney(v) : num(v))} width={56} />
            </>
          )}
          <Tooltip content={<Tip money={money} />} cursor={{ fill: 'currentColor', fillOpacity: 0.06 }} />
          {series.length > 1 && <Legend wrapperStyle={{ fontSize: 12 }} />}
          {series.map((s, i) => (
            <Bar key={s.key} dataKey={s.key} name={s.name} fill={s.color ?? COLORS[i]} radius={horizontal ? [0, 6, 6, 0] : [6, 6, 0, 0]} maxBarSize={36} />
          ))}
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}

export function Donut({ data, height = 220, center, money }: { data: { name: string; value: number }[]; height?: number; center?: string; money?: boolean }) {
  const total = data.reduce((a, b) => a + b.value, 0)
  return (
    <div className="flex flex-col items-center gap-4 sm:flex-row xl:flex-col 2xl:flex-row">
      <div className="relative shrink-0" style={{ width: height, height }}>
        <ResponsiveContainer>
          <PieChart>
            <Pie data={data.length ? data : [{ name: 'None', value: 1 }]} dataKey="value" nameKey="name" innerRadius="68%" outerRadius="100%" paddingAngle={data.length > 1 ? 3 : 0} stroke="none">
              {(data.length ? data : [{ name: 'None', value: 1 }]).map((_, i) => (
                <Cell key={i} fill={data.length ? COLORS[i % COLORS.length] : '#E5E7EB'} />
              ))}
            </Pie>
            {data.length > 0 && <Tooltip content={<Tip money={money} />} />}
          </PieChart>
        </ResponsiveContainer>
        <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
          <div className="text-2xl font-bold">{money ? compactMoney(total) : num(total)}</div>
          <div className="text-xs text-ink-500">{center}</div>
        </div>
      </div>
      <ul className="w-full min-w-0 space-y-2">
        {data.map((d, i) => (
          <li key={d.name} className="flex items-center gap-2 text-sm">
            <span className="h-2.5 w-2.5 rounded-full" style={{ background: COLORS[i % COLORS.length] }} />
            <span className="flex-1 truncate capitalize text-ink-600 dark:text-ink-300">{d.name}</span>
            <span className="font-semibold">{money ? compactMoney(d.value) : num(d.value)}</span>
          </li>
        ))}
      </ul>
    </div>
  )
}
