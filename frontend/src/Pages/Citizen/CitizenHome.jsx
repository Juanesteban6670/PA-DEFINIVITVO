import { useEffect, useState } from 'react'
import { AlertTriangle, Map, Phone, Plus, BarChart2, ArrowRight, Clock, CheckCircle, XCircle, Loader2, TrendingUp, Zap } from 'lucide-react'
import { incidentService } from '@/Services/Services'
import { Link } from 'react-router-dom'
import useAuthStore from '@/Store/AuthStore'

const STATUS_MAP = {
  PENDING:     { label: 'Pendiente',   color: '#F59E0B', bg: 'rgba(245,158,11,0.1)',   icon: Clock },
  IN_PROGRESS: { label: 'En progreso', color: '#3B82F6', bg: 'rgba(59,130,246,0.1)',   icon: Loader2 },
  RESOLVED:    { label: 'Resuelto',    color: '#10B981', bg: 'rgba(16,185,129,0.1)',   icon: CheckCircle },
  REJECTED:    { label: 'Rechazado',   color: '#EF4444', bg: 'rgba(239,68,68,0.1)',    icon: XCircle },
}

const PRIORITY_MAP = {
  LOW:      { label: 'Baja',    color: '#10B981' },
  MEDIUM:   { label: 'Media',   color: '#F59E0B' },
  HIGH:     { label: 'Alta',    color: '#F97316' },
  CRITICAL: { label: 'Crítica', color: '#EF4444' },
}

const quickLinks = [
  { to: '/App/Incidents', icon: AlertTriangle, label: 'Mis Reportes',  sub: 'Gestiona tus casos',    accent: '#F59E0B', bg: 'rgba(245,158,11,0.08)'  },
  { to: '/App/Map',       icon: Map,           label: 'Ver Mapa',      sub: 'Mapa en tiempo real',   accent: '#3B82F6', bg: 'rgba(59,130,246,0.08)'  },
  { to: '/App/Emergency', icon: Phone,         label: 'Emergencias',   sub: 'Contactos clave',       accent: '#EF4444', bg: 'rgba(239,68,68,0.08)'   },
  { to: '/App/Analytics', icon: BarChart2,     label: 'Estadísticas',  sub: 'Datos y métricas',      accent: '#8B5CF6', bg: 'rgba(139,92,246,0.08)'  },
]

export default function CitizenHome() {
  const { user } = useAuthStore()
  const [incidents, setIncidents] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    incidentService.getMine()
      .then(res => setIncidents(res.data?.data ?? res.data ?? []))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  const stats = [
    { label: 'Total',       value: incidents.length,                                                           color: '#60A5FA' },
    { label: 'Pendientes',  value: incidents.filter(i => i.status === 'PENDING').length,                       color: '#F59E0B' },
    { label: 'En progreso', value: incidents.filter(i => i.status === 'IN_PROGRESS').length,                   color: '#3B82F6' },
    { label: 'Resueltos',   value: incidents.filter(i => i.status === 'RESOLVED').length,                      color: '#10B981' },
  ]

  const hour = new Date().getHours()
  const greeting = hour < 12 ? 'Buenos días' : hour < 18 ? 'Buenas tardes' : 'Buenas noches'

  return (
    <div style={{ padding: '0 0 32px', fontFamily: "'DM Sans', system-ui, sans-serif", minHeight: '100%', background: '#F8FAFC' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700;800;900&family=DM+Serif+Display&display=swap');
        @keyframes fadeUp { from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:translateY(0)} }
        @keyframes countPop { 0%{transform:scale(0.8);opacity:0}60%{transform:scale(1.05)}100%{transform:scale(1);opacity:1} }
        .citizen-fade { animation: fadeUp 500ms ease-out both; }
        .s1{animation-delay:0ms} .s2{animation-delay:60ms} .s3{animation-delay:120ms} .s4{animation-delay:180ms} .s5{animation-delay:240ms}
        .quick-card { transition: all 0.3s cubic-bezier(0.16,1,0.3,1); }
        .quick-card:hover { transform: translateY(-3px); box-shadow: 0 12px 32px rgba(0,0,0,0.1) !important; }
        .incident-row { transition: all 0.2s; }
        .incident-row:hover { background: rgba(59,130,246,0.04) !important; }
      `}</style>

      {/* ── Hero Banner ─────────────────────────────────────────────────── */}
      <div className="citizen-fade s1" style={{
        margin: 0, padding: '32px 20px 28px',
        background: 'linear-gradient(135deg, #0F172A 0%, #1E3A5F 50%, #1D4ED8 100%)',
        position: 'relative', overflow: 'hidden'
      }}>
        {/* Background pattern */}
        <div style={{ position: 'absolute', inset: 0, backgroundImage: 'radial-gradient(circle at 1px 1px, rgba(255,255,255,0.06) 1px, transparent 0)', backgroundSize: '24px 24px' }} />
        <div style={{ position: 'absolute', top: -60, right: -60, width: 200, height: 200, borderRadius: '50%', background: 'radial-gradient(circle, rgba(59,130,246,0.25), transparent)', filter: 'blur(30px)' }} />

        <div style={{ position: 'relative' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
            <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#34D399' }} className="animate-pulse" />
            <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.5)', textTransform: 'uppercase', letterSpacing: '0.1em', fontWeight: 600 }}>Sistema activo</span>
          </div>
          <p style={{ fontSize: 13, color: 'rgba(255,255,255,0.5)', marginBottom: 4 }}>{greeting},</p>
          <h1 style={{ fontSize: 26, fontWeight: 800, color: '#fff', letterSpacing: '-0.02em', marginBottom: 4 }}>
            {user?.fullName || user?.username} 👋
          </h1>
          <p style={{ fontSize: 13, color: 'rgba(255,255,255,0.4)' }}>Ciudadano activo · Cartagena Segura</p>

          {/* Quick CTA */}
          <Link to="/App/Incidents" style={{
            display: 'inline-flex', alignItems: 'center', gap: 8, marginTop: 20,
            padding: '10px 20px', borderRadius: 12, fontWeight: 700, fontSize: 13,
            color: '#1D4ED8', background: '#fff', textDecoration: 'none',
            boxShadow: '0 4px 16px rgba(0,0,0,0.2)', transition: 'all 0.2s'
          }}>
            <Plus size={14} /> Nuevo reporte <ArrowRight size={13} />
          </Link>
        </div>
      </div>

      <div style={{ padding: '20px 16px', display: 'flex', flexDirection: 'column', gap: 20 }}>

        {/* ── Stats row ──────────────────────────────────────────────────── */}
        <div className="citizen-fade s2 grid grid-cols-2 md:grid-cols-4 gap-2.5">
          {stats.map((stat, i) => (
            <div key={i} style={{ background: '#fff', borderRadius: 16, padding: '14px 10px', textAlign: 'center', border: '1px solid #F1F5F9', boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}>
              <p style={{ fontSize: 22, fontWeight: 800, color: stat.color, letterSpacing: '-0.02em' }}>{stat.value}</p>
              <p style={{ fontSize: 10, color: '#94A3B8', marginTop: 2, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>{stat.label}</p>
            </div>
          ))}
        </div>

        {/* ── Quick links ────────────────────────────────────────────────── */}
        <div className="citizen-fade s3">
          <p style={{ fontSize: 11, color: '#94A3B8', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.1em', marginBottom: 12 }}>Accesos rápidos</p>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
            {quickLinks.map(({ to, icon: Icon, label, sub, accent, bg }) => (
              <Link key={to} to={to} className="quick-card"
                style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '16px', borderRadius: 18, background: '#fff', border: '1px solid #F1F5F9', boxShadow: '0 1px 4px rgba(0,0,0,0.04)', textDecoration: 'none', cursor: 'pointer' }}>
                <div style={{ width: 42, height: 42, borderRadius: 13, background: bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <Icon size={18} style={{ color: accent }} />
                </div>
                <div style={{ minWidth: 0 }}>
                  <p style={{ fontSize: 13, fontWeight: 700, color: '#0F172A', marginBottom: 1 }}>{label}</p>
                  <p style={{ fontSize: 11, color: '#94A3B8' }}>{sub}</p>
                </div>
              </Link>
            ))}
          </div>
        </div>

        {/* ── Recent incidents ───────────────────────────────────────────── */}
        <div className="citizen-fade s4">
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
            <p style={{ fontSize: 11, color: '#94A3B8', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.1em' }}>Mis reportes recientes</p>
            <Link to="/App/Incidents" style={{ fontSize: 12, color: '#3B82F6', fontWeight: 600, textDecoration: 'none', display: 'flex', alignItems: 'center', gap: 4 }}>
              Ver todos <ArrowRight size={12} />
            </Link>
          </div>

          <div style={{ background: '#fff', borderRadius: 20, border: '1px solid #F1F5F9', boxShadow: '0 1px 4px rgba(0,0,0,0.04)', overflow: 'hidden' }}>
            {loading ? (
              <div style={{ padding: 32, textAlign: 'center' }}>
                <Loader2 size={20} style={{ color: '#CBD5E1', animation: 'spin 1s linear infinite', display: 'inline-block' }} />
              </div>
            ) : incidents.length === 0 ? (
              <div style={{ padding: '40px 20px', textAlign: 'center' }}>
                <div style={{ width: 48, height: 48, borderRadius: 16, background: '#F8FAFC', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 12px' }}>
                  <AlertTriangle size={22} style={{ color: '#CBD5E1' }} />
                </div>
                <p style={{ fontSize: 14, color: '#94A3B8', marginBottom: 4, fontWeight: 600 }}>Sin reportes aún</p>
                <p style={{ fontSize: 12, color: '#CBD5E1', marginBottom: 16 }}>Sé el primero en reportar un incidente</p>
                <Link to="/App/Incidents" style={{ display: 'inline-flex', alignItems: 'center', gap: 6, padding: '9px 18px', borderRadius: 10, background: '#1D4ED8', color: '#fff', fontSize: 13, fontWeight: 600, textDecoration: 'none' }}>
                  <Plus size={13} /> Reportar ahora
                </Link>
              </div>
            ) : (
              incidents.slice(0, 5).map((inc, i) => {
                const st = STATUS_MAP[inc.status] ?? STATUS_MAP.PENDING
                const pr = PRIORITY_MAP[inc.priority] ?? PRIORITY_MAP.LOW
                const StIcon = st.icon
                return (
                  <div key={inc.id} className="incident-row"
                    style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '14px 16px', borderBottom: i < Math.min(incidents.length, 5) - 1 ? '1px solid #F8FAFC' : 'none', cursor: 'default' }}>
                    <div style={{ width: 38, height: 38, borderRadius: 12, background: st.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                      <StIcon size={16} style={{ color: st.color }} />
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 2 }}>
                        <p style={{ fontSize: 13, fontWeight: 700, color: '#0F172A' }}>{inc.type}</p>
                        <span style={{ fontSize: 9, fontWeight: 700, padding: '1px 7px', borderRadius: 5, color: pr.color, background: `${pr.color}14`, textTransform: 'uppercase', letterSpacing: '0.05em' }}>{pr.label}</span>
                      </div>
                      <p style={{ fontSize: 11, color: '#94A3B8', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 200 }}>{inc.description || inc.location || '—'}</p>
                    </div>
                    <span style={{ fontSize: 11, color: st.color, fontWeight: 600, whiteSpace: 'nowrap' }}>{st.label}</span>
                  </div>
                )
              })
            )}
          </div>
        </div>

        {/* ── Tip card ────────────────────────────────────────────────────── */}
        <div className="citizen-fade s5" style={{ padding: '16px 18px', borderRadius: 18, background: 'linear-gradient(135deg, rgba(139,92,246,0.08), rgba(59,130,246,0.06))', border: '1px solid rgba(139,92,246,0.15)', display: 'flex', alignItems: 'flex-start', gap: 12 }}>
          <div style={{ width: 36, height: 36, borderRadius: 11, background: 'rgba(139,92,246,0.12)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <Zap size={16} style={{ color: '#8B5CF6' }} />
          </div>
          <div>
            <p style={{ fontSize: 13, fontWeight: 700, color: '#4C1D95', marginBottom: 3 }}>Tip: Usa la IA para clasificar</p>
            <p style={{ fontSize: 12, color: '#6D28D9', lineHeight: 1.5, opacity: 0.7 }}>Al reportar, la IA analizará tu descripción y sugerirá automáticamente el tipo y prioridad del incidente.</p>
          </div>
        </div>

      </div>
    </div>
  )
}
