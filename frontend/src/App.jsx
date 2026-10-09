import { Routes, Route, Navigate } from 'react-router-dom'
import useAuthStore from '@/Store/AuthStore'

import LandingPage from '@/Pages/LandingPage'
import LoginPage    from '@/Pages/Auth/LoginPage'
import RegisterPage from '@/Pages/Auth/RegisterPage'
import ForgotPasswordPage from '@/Pages/Auth/ForgotPasswordPage'
import ResetPasswordPage  from '@/Pages/Auth/ResetPasswordPage'

import AdminLayout    from '@/Components/Layout/AdminLayout'
import AdminDashboard from '@/Pages/Admin/AdminDashboard'
import AdminIncidents from '@/Pages/Admin/AdminIncidents'
import AdminZones     from '@/Pages/Admin/AdminZones'
import AdminLogs      from '@/Pages/Admin/AdminLogs'
import AdminEmergency from '@/Pages/Admin/AdminEmergency'
import AdminReports   from '@/Pages/Admin/AdminReports'
import AdminAI        from '@/Pages/Admin/AdminAI'

import CitizenLayout    from '@/Components/Layout/CitizenLayout'
import CitizenHome      from '@/Pages/Citizen/CitizenHome'
import CitizenIncidents from '@/Pages/Citizen/CitizenIncidents'
import CitizenMap       from '@/Pages/Citizen/CitizenMap'
import CitizenEmergency from '@/Pages/Citizen/CitizenEmergency'
import CitizenReports   from '@/Pages/Citizen/CitizenReports'
import CitizenProfile   from '@/Pages/Citizen/CitizenProfile'

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
  )
}
