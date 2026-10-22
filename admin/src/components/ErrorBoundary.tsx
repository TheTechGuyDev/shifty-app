import { Component, type ReactNode } from 'react'
import { AlertTriangle } from 'lucide-react'

/** Keeps one broken page from blanking the whole dashboard. */
export default class ErrorBoundary extends Component<{ children: ReactNode; resetKey: string }, { error: Error | null }> {
  state = { error: null as Error | null }
  static getDerivedStateFromError(error: Error) {
    return { error }
  }
  componentDidUpdate(prev: { resetKey: string }) {
    if (prev.resetKey !== this.props.resetKey && this.state.error) this.setState({ error: null })
  }
  render() {
    if (!this.state.error) return this.props.children
    return (
      <div className="flex flex-col items-center justify-center gap-3 py-24 text-center">
        <AlertTriangle className="h-10 w-10 text-red-500" />
        <h2 className="text-lg font-bold">This page couldn’t load</h2>
        <p className="max-w-md text-sm text-ink-500">{this.state.error.message}</p>
        <button className="mt-2 rounded-xl bg-brand-500 px-4 py-2 text-sm font-semibold text-white" onClick={() => this.setState({ error: null })}>
          Try again
        </button>
      </div>
    )
  }
}
