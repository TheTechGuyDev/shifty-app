import { lazy, Suspense, type ReactNode } from 'react'
import { HashRouter, Navigate, Route, Routes } from 'react-router-dom'
import { AuthProvider, useAuth } from './lib/auth'
import { Loading, UiProvider } from './components/ui'
import Layout from './components/Layout'
import Login from './pages/Login'
import NoAccess from './pages/NoAccess'

const Overview = lazy(() => import('./pages/Overview'))
const Dispatch = lazy(() => import('./pages/Dispatch'))
const Bookings = lazy(() => import('./pages/Bookings'))
const BookingDetail = lazy(() => import('./pages/BookingDetail'))
const Schedule = lazy(() => import('./pages/Schedule'))
const LiveMap = lazy(() => import('./pages/LiveMap'))
const Customers = lazy(() => import('./pages/Customers'))
const CustomerDetail = lazy(() => import('./pages/CustomerDetail'))
const Pros = lazy(() => import('./pages/Pros'))
const ProDetail = lazy(() => import('./pages/ProDetail'))
const Applications = lazy(() => import('./pages/Applications'))
const Verification = lazy(() => import('./pages/Verification'))
const Services = lazy(() => import('./pages/Services'))
const Pricing = lazy(() => import('./pages/Pricing'))
const Offers = lazy(() => import('./pages/Offers'))
const Transactions = lazy(() => import('./pages/Transactions'))
const Payouts = lazy(() => import('./pages/Payouts'))
const Balances = lazy(() => import('./pages/Balances'))
const Revenue = lazy(() => import('./pages/Revenue'))
const Support = lazy(() => import('./pages/Support'))
const Chats = lazy(() => import('./pages/Chats'))
const Reviews = lazy(() => import('./pages/Reviews'))
const Broadcasts = lazy(() => import('./pages/Broadcasts'))
const Analytics = lazy(() => import('./pages/Analytics'))
const Referrals = lazy(() => import('./pages/Referrals'))
const Faqs = lazy(() => import('./pages/Faqs'))
const SettingsPage = lazy(() => import('./pages/Settings'))
const Team = lazy(() => import('./pages/Team'))
const Roles = lazy(() => import('./pages/Roles'))
const Audit = lazy(() => import('./pages/Audit'))
const Account = lazy(() => import('./pages/Account'))

function Guard({ perm, children }: { perm: string; children: ReactNode }) {
  const { can } = useAuth()
  return can(perm) ? <>{children}</> : <NoAccess page />
}

function Shell() {
  const { session, me, ready } = useAuth()
  if (!ready) return <Loading h={400} />
  if (!session) return <Login />
  if (!me) return <NoAccess />
  const r = (path: string, perm: string, el: ReactNode) => (
    <Route path={path} element={<Guard perm={perm}><Suspense fallback={<Loading />}>{el}</Suspense></Guard>} />
  )
  return (
    <Routes>
      <Route element={<Layout />}>
        {r('/', 'dashboard.view', <Overview />)}
        {r('/dispatch', 'bookings.manage', <Dispatch />)}
        {r('/bookings', 'bookings.view', <Bookings />)}
        {r('/bookings/:id', 'bookings.view', <BookingDetail />)}
        {r('/calendar', 'bookings.view', <Schedule />)}
        {r('/map', 'bookings.view', <LiveMap />)}
        {r('/customers', 'users.view', <Customers />)}
        {r('/customers/:id', 'users.view', <CustomerDetail />)}
        {r('/pros', 'pros.view', <Pros />)}
        {r('/pros/:id', 'pros.view', <ProDetail />)}
        {r('/applications', 'verification.manage', <Applications />)}
        {r('/verification', 'verification.manage', <Verification />)}
        {r('/services', 'catalogue.manage', <Services />)}
        {r('/pricing', 'catalogue.manage', <Pricing />)}
        {r('/offers', 'offers.manage', <Offers />)}
        {r('/transactions', 'finance.view', <Transactions />)}
        {r('/payouts', 'finance.view', <Payouts />)}
        {r('/balances', 'finance.view', <Balances />)}
        {r('/revenue', 'finance.view', <Revenue />)}
        {r('/support', 'support.manage', <Support />)}
        {r('/chats', 'chat.view', <Chats />)}
        {r('/reviews', 'reviews.manage', <Reviews />)}
        {r('/broadcasts', 'broadcast.send', <Broadcasts />)}
        {r('/analytics', 'reports.view', <Analytics />)}
        {r('/referrals', 'users.view', <Referrals />)}
        {r('/faqs', 'content.manage', <Faqs />)}
        {r('/settings', 'settings.manage', <SettingsPage />)}
        {r('/team', 'admins.manage', <Team />)}
        {r('/roles', 'admins.manage', <Roles />)}
        {r('/audit', 'audit.view', <Audit />)}
        <Route path="/account" element={<Suspense fallback={<Loading />}><Account /></Suspense>} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  )
}

export default function App() {
  return (
    <HashRouter>
      <AuthProvider>
        <UiProvider>
          <Shell />
        </UiProvider>
      </AuthProvider>
    </HashRouter>
  )
}
