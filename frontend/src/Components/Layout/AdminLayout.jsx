import { useState } from 'react'
import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import {
  LayoutDashboard, AlertTriangle, Map, Phone, FileText,
  BarChart2, LogOut, Menu, X, Sparkles, ChevronRight, Shield
} from 'lucide-react'
import useAuthStore from '@/Store/AuthStore'
import NotificationPanel from '@/Components/NotificationPanel'


const navItems = [
  { to: '/Admin',           icon: LayoutDashboard, label: 'Dashboard',    end: true  },
  { to: '/Admin/Incidents', icon: AlertTriangle,   label: 'Incidentes'               },
  { to: '/Admin/Zones',     icon: Map,             label: 'Zonas'                    },
  { to: '/Admin/Emergency', icon: Phone,           label: 'Emergencias'              },
  { to: '/Admin/Logs',      icon: FileText,        label: 'Logs'                     },
  { to: '/Admin/Reports',   icon: BarChart2,       label: 'Reportes'                 },
  { to: '/Admin/Ai',        icon: Sparkles,        label: 'Asistente Virtual',  special: true },
]

export default function AdminLayout() {
  const { user, logout } = useAuthStore()
  const navigate = useNavigate()
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const handleLogout = () => {
    if (window.confirm('¿Estás seguro que deseas cerrar sesión?')) {
      navigate('/', { replace: true })
      // Damos un pequeño respiro al navegador para que termine la navegación
      setTimeout(() => logout(), 10)
    }
  }
  const initial = user?.username?.[0]?.toUpperCase() ?? 'A'

  const SidebarContent = () => (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      {/* Logo */}
      <div style={{ padding: '20px 16px 16px', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 36, height: 36, borderRadius: 12, background: 'rgba(59,130,246,0.15)', border: '1px solid rgba(59,130,246,0.25)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <img src="/LogoFull.png" alt="Logo" style={{ width: 22, height: 22, objectFit: 'contain' }} />
          </div>
          <div>
            <p style={{ fontSize: 13, fontWeight: 800, color: '#fff', letterSpacing: '-0.02em', lineHeight: 1.2 }}>Cartagena Segura</p>
            <p style={{ fontSize: 10, color: 'rgba(255,255,255,0.35)', textTransform: 'uppercase', letterSpacing: '0.08em' }}>Panel Admin</p>
          </div>
        </div>
      </div>

      {/* Nav */}
      <nav style={{ flex: 1, padding: '12px 10px', overflowY: 'auto' }}>
        <p style={{ fontSize: 9, fontWeight: 700, color: 'rgba(255,255,255,0.25)', textTransform: 'uppercase', letterSpacing: '0.12em', padding: '0 8px', marginBottom: 8 }}>Navegación</p>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          {navItems.map(({ to, icon: Icon, label, end, special }) => (
            <NavLink key={to} to={to} end={end} onClick={() => setSidebarOpen(false)} style={{ textDecoration: 'none' }}>
              {({ isActive }) => (
                <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 12px', borderRadius: 12, background: isActive ? 'rgba(59,130,246,0.15)' : 'transparent', border: isActive ? '1px solid rgba(59,130,246,0.25)' : '1px solid transparent', transition: 'all 0.2s', cursor: 'pointer' }}
                  onMouseEnter={e => { if (!isActive) e.currentTarget.style.background = 'rgba(255,255,255,0.05)' }}
                  onMouseLeave={e => { if (!isActive) e.currentTarget.style.background = 'transparent' }}>
                  <div style={{ width: 32, height: 32, borderRadius: 10, background: isActive ? 'rgba(59,130,246,0.2)' : special ? 'rgba(139,92,246,0.12)' : 'rgba(255,255,255,0.06)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                    <Icon size={15} style={{ color: isActive ? '#60A5FA' : special ? '#A78BFA' : 'rgba(255,255,255,0.5)' }} />
                  </div>
                  <span style={{ fontSize: 13, fontWeight: isActive ? 700 : 500, color: isActive ? '#fff' : 'rgba(255,255,255,0.55)', flex: 1 }}>{label}</span>
                  {isActive && <ChevronRight size={12} style={{ color: '#60A5FA' }} />}
                  {special && !isActive && <span style={{ fontSize: 9, fontWeight: 700, padding: '2px 6px', borderRadius: 5, background: 'rgba(139,92,246,0.2)', color: '#A78BFA' }}>AI</span>}
                </div>
              )}
            </NavLink>
          ))}
        </div>
      </nav>

      {/* User */}
      <div style={{ padding: '12px', borderTop: '1px solid rgba(255,255,255,0.06)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px', borderRadius: 14, background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.06)' }}>
          <div style={{ width: 34, height: 34, borderRadius: '50%', background: 'linear-gradient(135deg, #1D4ED8, #3B82F6)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 13, fontWeight: 800, color: '#fff', flexShrink: 0 }}>{initial}</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <p style={{ fontSize: 12, fontWeight: 700, color: '#fff', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{user?.username}</p>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
              <Shield size={9} style={{ color: '#60A5FA' }} />
              <p style={{ fontSize: 10, color: 'rgba(255,255,255,0.35)' }}>Administrador</p>
            </div>
          </div>
          <button onClick={handleLogout}
            style={{ width: 28, height: 28, borderRadius: 9, border: 'none', background: 'rgba(239,68,68,0.15)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <LogOut size={12} style={{ color: '#FCA5A5' }} />
          </button>
        </div>
      </div>
    </div>
  )

  return (
    <div style={{ display: 'flex', height: '100dvh', background: '#F8FAFC', fontFamily: "'DM Sans', system-ui, sans-serif" }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700;800&display=swap');
        @keyframes sidebarIn { from{opacity:0;transform:translateX(-100%)}to{opacity:1;transform:translateX(0)} }
        .sidebar-mobile { animation: sidebarIn 300ms cubic-bezier(0.16,1,0.3,1) both; }
      `}</style>

      {/* ✅ Sidebar desktop — SIN display en style, Tailwind lo controla */}
      <aside
        style={{ width: 240, background: '#0F172A', borderRight: '1px solid rgba(255,255,255,0.06)', flexShrink: 0 }}
        className="hidden md:flex flex-col"
      >
        <SidebarContent />
      </aside>

      {/* Sidebar mobile overlay */}
      {sidebarOpen && (
        <div style={{ position: 'fixed', inset: 0, zIndex: 200 }}>
          <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(4px)' }} onClick={() => setSidebarOpen(false)} />
          <aside className="sidebar-mobile" style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: 260, background: '#0F172A', display: 'flex', flexDirection: 'column' }}>
            <div style={{ position: 'absolute', top: 12, right: 12 }}>
              <button onClick={() => setSidebarOpen(false)} style={{ width: 28, height: 28, borderRadius: 8, background: 'rgba(255,255,255,0.08)', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <X size={14} style={{ color: '#fff' }} />
              </button>
            </div>
            <SidebarContent />
          </aside>
        </div>
      )}

      {/* Main */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        {/* Top bar */}
        <header style={{ height: 56, background: '#fff', borderBottom: '1px solid #F1F5F9', display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 16px', flexShrink: 0, boxShadow: '0 1px 3px rgba(0,0,0,0.04)', zIndex: 3000 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>

            {/* ✅ Botón hamburguesa — SIN display en style, Tailwind lo controla */}
            <button
              onClick={() => setSidebarOpen(true)}
              style={{ width: 34, height: 34, borderRadius: 10, border: '1px solid #F1F5F9', background: '#F8FAFC', cursor: 'pointer', alignItems: 'center', justifyContent: 'center' }}
              className="flex md:hidden"
            >
              <Menu size={16} style={{ color: '#64748B' }} />
            </button>

            <div>
              <p style={{ fontSize: 14, fontWeight: 700, color: '#0F172A', letterSpacing: '-0.01em' }}>Panel de Administración</p>
              <p style={{ fontSize: 11, color: '#94A3B8' }}>Cartagena Segura · Sistema operativo</p>
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '5px 10px', borderRadius: 100, background: 'rgba(16,185,129,0.08)', border: '1px solid rgba(16,185,129,0.15)' }}>
              <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#34D399' }} className="animate-pulse" />
              <span style={{ fontSize: 11, color: '#065F46', fontWeight: 600 }}>Sistema activo</span>
            </div>
            <NotificationPanel />
          </div>
        </header>

        {/* Content */}
        <main style={{ flex: 1, overflowY: 'auto' }}>
          <Outlet />
        </main>


      </div>
    </div>
  )
}
