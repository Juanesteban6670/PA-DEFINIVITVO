import { Routes, Route, Navigate } from 'react-router-dom'
import { lazy, Suspense } from 'react'
import useAuthStore from '@/Store/AuthStore'

const LandingPage = lazy(() => import('@/Pages/LandingPage'))
const LoginPage = lazy(() => import('@/Pages/Auth/LoginPage'))
const RegisterPage = lazy(() => import('@/Pages/Auth/RegisterPage'))
const ForgotPasswordPage = lazy(() => import('@/Pages/Auth/ForgotPasswordPage'))
const ResetPasswordPage = lazy(() => import('@/Pages/Auth/ResetPasswordPage'))

import AdminLayout    from '@/Components/Layout/AdminLayout'
const AdminDashboard = lazy(() => import('@/Pages/Admin/AdminDashboard'))
const AdminIncidents = lazy(() => import('@/Pages/Admin/AdminIncidents'))
const AdminZones = lazy(() => import('@/Pages/Admin/AdminZones'))
const AdminLogs = lazy(() => import('@/Pages/Admin/AdminLogs'))
const AdminEmergency = lazy(() => import('@/Pages/Admin/AdminEmergency'))
const AdminReports = lazy(() => import('@/Pages/Admin/AdminReports'))
const AdminAI = lazy(() => import('@/Pages/Admin/AdminAI'))

import CitizenLayout    from '@/Components/Layout/CitizenLayout'
const CitizenHome = lazy(() => import('@/Pages/Citizen/CitizenHome'))
const CitizenIncidents = lazy(() => import('@/Pages/Citizen/CitizenIncidents'))
const CitizenMap = lazy(() => import('@/Pages/Citizen/CitizenMap'))
const CitizenEmergency = lazy(() => import('@/Pages/Citizen/CitizenEmergency'))
const CitizenReports = lazy(() => import('@/Pages/Citizen/CitizenReports'))
const CitizenProfile = lazy(() => import('@/Pages/Citizen/CitizenProfile'))

const PrivateRoute = ({ children }) => {
  const { token } = useAuthStore()
  return token ? children : <Navigate to="/Login" replace />
}

const AdminRoute = ({ children }) => {
  const { token, isAdmin } = useAuthStore()
  if (!token) return <Navigate to="/Login" replace />
  if (!isAdmin()) return <Navigate to="/App" replace />
  return children
}

export default function App() {
  return (
    <Suspense fallback={<div role="status" className="p-6 text-center">Cargando...</div>}>
      <Routes>
        <Route path="/"         element={<LandingPage />} />
        <Route path="/Login"    element={<LoginPage />} />
        <Route path="/Register" element={<RegisterPage />} />
        <Route path="/ForgotPassword" element={<ForgotPasswordPage />} />
        <Route path="/ResetPassword"  element={<ResetPasswordPage />} />

        <Route path="/App" element={<PrivateRoute><CitizenLayout /></PrivateRoute>}>
          <Route index              element={<CitizenHome />} />
          <Route path="Incidents"   element={<CitizenIncidents />} />
          <Route path="Map"         element={<CitizenMap />} />
          <Route path="Emergency"   element={<CitizenEmergency />} />
          <Route path="Analytics"   element={<CitizenReports />} />
          <Route path="Profile"     element={<CitizenProfile />} />
        </Route>

        <Route path="/Admin" element={<AdminRoute><AdminLayout /></AdminRoute>}>
          <Route index              element={<AdminDashboard />} />
          <Route path="Incidents"   element={<AdminIncidents />} />
          <Route path="Zones"       element={<AdminZones />} />
          <Route path="Logs"        element={<AdminLogs />} />
          <Route path="Emergency"   element={<AdminEmergency />} />
          <Route path="Reports"     element={<AdminReports />} />
          <Route path="Ai"          element={<AdminAI />} />
        </Route>

        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Suspense>
  )
}
