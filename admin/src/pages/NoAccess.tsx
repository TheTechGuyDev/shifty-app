import { Lock } from 'lucide-react'
import { useAuth } from '../lib/auth'
import { Button } from '../components/ui'

export default function NoAccess({ page }: { page?: boolean }) {
  const { session, signOut } = useAuth()
  return (
    <div className={page ? 'py-20' : 'flex min-h-full items-center justify-center p-6'}>
      <div className="mx-auto max-w-md text-center">
        <span className="inline-flex h-14 w-14 items-center justify-center rounded-2xl bg-brand-50 text-brand-500 dark:bg-brand-900/30">
          <Lock />
        </span>
        <h1 className="mt-5 text-2xl font-bold">{page ? 'No access to this page' : 'Admin access required'}</h1>
        <p className="mt-2 text-sm text-ink-500">
          {page
            ? 'Your role doesn’t include this section. Ask a Super Admin if you need it.'
            : `${session?.user.email ?? 'This account'} is not on the admin team. Ask a Super Admin to add you.`}
        </p>
        {!page && (
          <Button className="mt-6" variant="secondary" onClick={signOut}>
            Sign out
          </Button>
        )}
      </div>
    </div>
  )
}
