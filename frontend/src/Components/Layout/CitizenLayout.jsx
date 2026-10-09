import { Outlet, NavLink, useNavigate, Link } from 'react-router-dom'
import { Home, AlertTriangle, Map, Phone, LogOut, BarChart2, User } from 'lucide-react'
import useAuthStore from '@/Store/AuthStore'
import NotificationPanel from '@/Components/NotificationPanel'
import AIChatbot from '@/Components/AIChatbot'

const navItems = [
  { to: '/App',           icon: Home,          label: 'Inicio',     end: true  },
  { to: '/App/Incidents', icon: AlertTriangle, label: 'Reportes'              },
  { to: '/App/Map',       icon: Map,           label: 'Mapa'                  },
  { to: '/App/Emergency', icon: Phone,         label: 'Emergencias'           },
  { to: '/App/Analytics', icon: BarChart2,     label: 'Análisis'              },
]

export default function CitizenLayout() {
  const { user, logout } = useAuthStore()
  const navigate = useNavigate()
  const handleLogout = () => {
    if (window.confirm('¿Estás seguro que deseas cerrar sesión?')) {
      navigate('/', { replace: true })
      // Damos un pequeño respiro al navegador para que termine la navegación
      setTimeout(() => logout(), 10)
    }
  }
  const initial = user?.username?.[0]?.toUpperCase() ?? 'U'

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100dvh', background: '#F8FAFC', fontFamily: "'DM Sans', system-ui, sans-serif" }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700;800&display=swap');
        .nav-link-item { transition: all 0.2s; text-decoration: none; }
        .nav-link-item:hover .nav-icon { background: rgba(29,78,216,0.06) !important; }
        .top-avatar { transition: all 0.2s; }
        .top-avatar:hover { opacity: 0.8; }
      `}</style>

      {/* TOP BAR */}
      <header style={{ background: '#fff', borderBottom: '1px solid #F1F5F9', padding: '0 16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', height: 56, flexShrink: 0, boxShadow: '0 1px 3px rgba(0,0,0,0.04)', position: 'sticky', top: 0, zIndex: 3000 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 32, height: 32, borderRadius: 10, background: 'rgba(29,78,216,0.06)', border: '1px solid rgba(29,78,216,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <img src="/LogoFull.png" alt="Logo" style={{ width: 20, height: 20, objectFit: 'contain' }} />
          </div>
          <div>
            <p style={{ fontSize: 13, fontWeight: 800, color: '#0F172A', letterSpacing: '-0.02em', lineHeight: 1.2 }}>Cartagena Segura</p>
            <p style={{ fontSize: 10, color: '#94A3B8', letterSpacing: '0.04em' }}>Ciudadano</p>
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <NotificationPanel />
          <Link to="/App/Profile" className="top-avatar" style={{ display: 'flex', alignItems: 'center', gap: 8, textDecoration: 'none', padding: '4px 8px 4px 4px', borderRadius: 100, border: '1px solid #F1F5F9', background: '#F8FAFC' }}>
            <div style={{ width: 28, height: 28, borderRadius: '50%', background: 'linear-gradient(135deg, #1D4ED8, #3B82F6)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12, fontWeight: 800, color: '#fff' }}>
              {initial}
            </div>
            <span style={{ fontSize: 12, fontWeight: 600, color: '#475569', display: 'none' }} className="sm:block">{user?.username}</span>
          </Link>
          <button onClick={handleLogout} 
            className="flex items-center justify-center"
            style={{ width: 32, height: 32, borderRadius: 10, border: '1px solid #FEE2E2', background: '#FFF5F5', cursor: 'pointer', transition: 'all 0.2s', flexShrink: 0 }}
            onMouseEnter={e => { e.currentTarget.style.background = '#FEE2E2' }}
            onMouseLeave={e => { e.currentTarget.style.background = '#FFF5F5' }}>
            <LogOut size={14} style={{ color: '#EF4444' }} />
          </button>
        </div>
      </header>

      {/* MAIN */}
      <main style={{ flex: 1, overflowY: 'auto', paddingBottom: 72 }}>
        <Outlet />
      </main>

      <AIChatbot />

      {/* BOTTOM NAV */}
      <nav style={{ position: 'fixed', bottom: 0, left: 0, right: 0, background: '#fff', borderTop: '1px solid #F1F5F9', boxShadow: '0 -4px 20px rgba(0,0,0,0.06)', zIndex: 100, paddingBottom: 'max(8px, env(safe-area-inset-bottom))' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-around', padding: '8px 4px', maxWidth: 600, margin: '0 auto' }}>
          {navItems.map(({ to, icon: Icon, label, end }) => (
            <NavLink key={to} to={to} end={end} className="nav-link-item"
              style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2, padding: '4px 8px', borderRadius: 12, flex: 1, minWidth: 0 }}>
              {({ isActive }) => (
                <>
                  <div className="nav-icon" style={{ width: 36, height: 36, borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', background: isActive ? 'rgba(29,78,216,0.08)' : 'transparent', transition: 'all 0.2s' }}>
                    <Icon size={18} style={{ color: isActive ? '#1D4ED8' : '#94A3B8', transition: 'color 0.2s' }} />
                  </div>
                  <span style={{ fontSize: 9, fontWeight: 700, color: isActive ? '#1D4ED8' : '#94A3B8', textTransform: 'uppercase', letterSpacing: '0.06em', transition: 'color 0.2s' }}>{label}</span>
                </>
              )}
            </NavLink>
          ))}
        </div>
      </nav>
    </div>
  )
}
