import { useEffect, useState, useRef } from 'react'
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet'
import { AlertTriangle, Clock, CheckCircle, XCircle, Loader2, Sparkles, RefreshCw, TrendingUp, Zap, Map, Navigation } from 'lucide-react'
import { incidentService, zoneService, aiService } from '@/Services/Services'
import 'leaflet/dist/leaflet.css'
import L from 'leaflet'

delete L.Icon.Default.prototype._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
  iconUrl:       'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
  shadowUrl:     'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
})

const P_COLOR = { LOW: '#10B981', MEDIUM: '#F59E0B', HIGH: '#F97316', CRITICAL: '#EF4444' }
const S_LABEL = { PENDING: 'Pendiente', IN_PROGRESS: 'En progreso', RESOLVED: 'Resuelto', REJECTED: 'Rechazado' }
const CENTER  = [10.3910, -75.4794]

const createIcon = color => L.divIcon({
  className: '',
  html: `<div style="width:22px;height:22px;background:${color};border:2px solid white;border-radius:50% 50% 50% 0;transform:rotate(-45deg);box-shadow:0 2px 8px ${color}60"></div>`,
  iconSize: [22, 22], iconAnchor: [11, 22], popupAnchor: [0, -26],
})

const userIcon = L.divIcon({
  className: '',
  html: `<div style="position:relative;width:18px;height:18px">
    <div style="width:18px;height:18px;background:#3B82F6;border:2px solid white;border-radius:50%;box-shadow:0 2px 6px rgba(59,130,246,0.5)"></div>
  </div>`,
  iconSize: [18, 18], iconAnchor: [9, 9],
})

function FlyTo({ coords }) {
  const map = useMap()
  useEffect(() => { if (coords) map.flyTo(coords, 16, { animate: true, duration: 1.5 }) }, [coords])
  return null
}

function useCountUp(target, duration = 1200) {
  const [count, setCount] = useState(0)
  const ref = useRef(null)
  useEffect(() => {
    const n = parseInt(target)
    if (isNaN(n)) return
    let start = null
    const step = ts => {
      if (!start) start = ts
      const p = Math.min((ts - start) / duration, 1)
      setCount(Math.round((1 - Math.pow(1 - p, 3)) * n))
      if (p < 1) ref.current = requestAnimationFrame(step)
    }
    ref.current = requestAnimationFrame(step)
    return () => cancelAnimationFrame(ref.current)
  }, [target, duration])
  return count
}

function StatCard({ icon: Icon, label, value, color, accent, sub, delay = 0 }) {
  const count = useCountUp(value ?? 0)
  return (
    <div
      className="animate-slide-up-stagger"
      style={{
        animationDelay: `${delay}ms`,
        background: '#fff',
        borderRadius: 20,
        border: '1px solid #F1F5F9',
        padding: '20px',
        boxShadow: '0 1px 4px rgba(0,0,0,0.04)'
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
        <p style={{ fontSize: 12, color: '#94A3B8', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em' }}>
          {label}
        </p>
        <div
          style={{
            width: 36,
            height: 36,
            borderRadius: 12,
            background: color,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}
        >
          <Icon size={16} style={{ color: accent }} />
        </div>
      </div>

      <p style={{ fontSize: 32, fontWeight: 900, color: '#0F172A', letterSpacing: '-0.03em', lineHeight: 1 }}>
        {count}
      </p>

      {sub && (
        <p style={{ fontSize: 11, color: '#94A3B8', marginTop: 6 }}>
          {sub}
        </p>
      )}
    </div>
  )
}

export default function AdminDashboard() {
  const [incidents, setIncidents] = useState([])
  const [zones, setZones]         = useState([])
  const [loading, setLoading]     = useState(true)
  const [summary, setSummary]     = useState('')
  const [sumLoading, setSumLoading] = useState(false)
  const [sumError, setSumError]   = useState(false)
  const [displayed, setDisplayed] = useState('')
  const [userCoords, setUserCoords] = useState(null)
  const [gpsLoading, setGpsLoading] = useState(false)
  const [flyTo, setFlyTo]       = useState(null)

  useEffect(() => {
    Promise.all([incidentService.getAll(), zoneService.getAll()])
      .then(([inc, zon]) => {
        setIncidents(inc.data?.data ?? inc.data?.content ?? inc.data ?? [])
        setZones(zon.data?.data ?? zon.data ?? [])
      })
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  useEffect(() => {
    if (!summary) { setDisplayed(''); return }
    setDisplayed('')
    let i = 0
    const t = setInterval(() => { i++; setDisplayed(summary.slice(0, i)); if (i >= summary.length) clearInterval(t) }, 14)
    return () => clearInterval(t)
  }, [summary])

  const handleLocate = () => {
    if (!navigator.geolocation) return
    setGpsLoading(true)
    navigator.geolocation.getCurrentPosition(
      pos => { const c = [pos.coords.latitude, pos.coords.longitude]; setUserCoords(c); setFlyTo(c); setGpsLoading(false) },
      () => setGpsLoading(false),
      { enableHighAccuracy: true, timeout: 10000 }
    )
  }

  const genSummary = async () => {
    setSumLoading(true); setSumError(false); setSummary('')
    try {
      const res = await aiService.summary()
      const txt = res.data?.summary ?? res.data?.message ?? res.data ?? ''
      setSummary(typeof txt === 'string' ? txt : JSON.stringify(txt))
    } catch { setSumError(true) }
    finally { setSumLoading(false) }
  }

  const pending  = incidents.filter(i => i.status === 'PENDING').length
  const resolved = incidents.filter(i => i.status === 'RESOLVED').length
  const critical = incidents.filter(i => i.priority === 'CRITICAL').length
  const withCoords = incidents.filter(i => i.latitude && i.longitude)

  return (
    <div style={{ padding: '20px 16px 32px', fontFamily: "'DM Sans', system-ui, sans-serif", background: '#F8FAFC', minHeight: '100%' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700;800;900&display=swap');
        @keyframes fadeUp { from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:translateY(0)} }
        .dash-fade { animation: fadeUp 400ms ease-out both; }
        .s1{animation-delay:0ms}.s2{animation-delay:60ms}.s3{animation-delay:120ms}.s4{animation-delay:180ms}.s5{animation-delay:240ms}
        .inc-row { transition: all 0.2s; }
        .inc-row:hover { background: #F8FAFC !important; }
        .leaflet-popup-content-wrapper { border-radius: 14px !important; box-shadow: 0 8px 24px rgba(0,0,0,0.12) !important; }
        .leaflet-popup-tip-container { display: none; }
      `}</style>

      {/* Header */}
      <div className="dash-fade s1" style={{ marginBottom: 20 }}>
        <h1 style={{ fontSize: 22, fontWeight: 900, color: '#0F172A', letterSpacing: '-0.02em', marginBottom: 2 }}>Dashboard</h1>
        <p style={{ fontSize: 13, color: '#94A3B8' }}>Resumen operativo del sistema</p>
      </div>

      {/* Stats */}
      <div className="dash-fade s2 grid grid-cols-2 lg:grid-cols-4 gap-3 lg:gap-4 mb-5">
        <StatCard icon={AlertTriangle} label="Total"      value={incidents.length} color="rgba(59,130,246,0.1)"  accent="#3B82F6" sub="incidentes" delay={0}   />
        <StatCard icon={Clock}         label="Pendientes" value={pending}           color="rgba(245,158,11,0.1)"  accent="#F59E0B" sub="sin atender" delay={60}  />
        <StatCard icon={CheckCircle}   label="Resueltos"  value={resolved}          color="rgba(16,185,129,0.1)"  accent="#10B981" sub="cerrados" delay={120}    />
        <StatCard icon={XCircle}       label="Críticos"   value={critical}          color="rgba(239,68,68,0.1)"   accent="#EF4444" sub="urgentes" delay={180}    />
      </div>

      {/* AI Summary */}
      <div className="dash-fade s3" style={{ background: '#fff', borderRadius: 20, border: '1px solid #F1F5F9', marginBottom: 20, overflow: 'hidden' }}>
        <div style={{ padding: '14px 16px', borderBottom: '1px solid #F8FAFC', display: 'flex', alignItems: 'center', justifyContent: 'space-between', background: 'linear-gradient(135deg, rgba(139,92,246,0.04), rgba(59,130,246,0.03))' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 34, height: 34, borderRadius: 11, background: 'linear-gradient(135deg, #7C3AED, #8B5CF6)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Sparkles size={15} style={{ color: '#fff' }} />
            </div>
            <div>
              <p style={{ fontSize: 13, fontWeight: 700, color: '#0F172A' }}>Resumen IA</p>
              <p style={{ fontSize: 10, color: '#94A3B8' }}>Análisis generado por Spring AI</p>
            </div>
          </div>
          <button onClick={genSummary} disabled={sumLoading}
            style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '7px 14px', borderRadius: 10, background: 'linear-gradient(135deg, #7C3AED, #8B5CF6)', color: '#fff', fontWeight: 700, fontSize: 12, border: 'none', cursor: sumLoading ? 'not-allowed' : 'pointer', fontFamily: 'inherit', opacity: sumLoading ? 0.7 : 1 }}>
            {sumLoading ? <Loader2 size={12} style={{ animation: 'spin 1s linear infinite' }} /> : <Sparkles size={12} />}
            {summary ? 'Regenerar' : 'Generar'}
          </button>
        </div>
        <div style={{ padding: '14px 16px' }}>
          {!summary && !sumLoading && !sumError && (
            <p style={{ fontSize: 13, color: '#CBD5E1', textAlign: 'center', padding: '16px 0' }}>Haz clic en "Generar" para obtener un resumen inteligente del sistema</p>
          )}
          {sumLoading && (
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, justifyContent: 'center', padding: '16px 0' }}>
              <Loader2 size={16} style={{ color: '#8B5CF6', animation: 'spin 1s linear infinite' }} />
              <span style={{ fontSize: 13, color: '#94A3B8' }}>Generando análisis...</span>
            </div>
          )}
          {sumError && (
            <div style={{ padding: '12px', borderRadius: 12, background: '#FEF2F2', border: '1px solid #FECACA', textAlign: 'center' }}>
              <p style={{ fontSize: 12, color: '#EF4444', fontWeight: 600, marginBottom: 8 }}>Servicio de IA no disponible</p>
              <button onClick={genSummary} style={{ fontSize: 11, color: '#EF4444', background: 'none', border: 'none', cursor: 'pointer', fontFamily: 'inherit', display: 'flex', alignItems: 'center', gap: 4, margin: '0 auto' }}>
                <RefreshCw size={11} /> Reintentar
              </button>
            </div>
          )}
          {displayed && !sumLoading && (
            <p style={{ fontSize: 13, color: '#374151', lineHeight: 1.7, whiteSpace: 'pre-wrap' }}>
              {displayed}
              {displayed.length < summary.length && <span style={{ borderRight: '2px solid #8B5CF6', marginLeft: 2, animation: 'none' }}>&nbsp;</span>}
            </p>
          )}
        </div>
      </div>

      {/* Map */}
      <div className="dash-fade s4" style={{ background: '#fff', borderRadius: 20, border: '1px solid #F1F5F9', marginBottom: 20, overflow: 'hidden' }}>
        <div style={{ padding: '14px 16px', borderBottom: '1px solid #F8FAFC', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 34, height: 34, borderRadius: 11, background: 'rgba(59,130,246,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Map size={15} style={{ color: '#3B82F6' }} />
            </div>
            <div>
              <p style={{ fontSize: 13, fontWeight: 700, color: '#0F172A' }}>Mapa de Incidentes</p>
              <p style={{ fontSize: 10, color: '#94A3B8' }}>{withCoords.length} con ubicación GPS</p>
            </div>
          </div>
        </div>
        <div className="h-[250px] sm:h-[400px] relative z-0">
          <MapContainer center={CENTER} zoom={13} style={{ height: '100%', width: '100%' }} scrollWheelZoom>
            <TileLayer attribution='&copy; OpenStreetMap' url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
            {flyTo && <FlyTo coords={flyTo} />}
            {userCoords && (
              <Marker position={userCoords} icon={userIcon}>
                <Popup><p style={{ fontSize: 12, fontWeight: 700, color: '#3B82F6', margin: 0 }}>📍 Estás aquí</p></Popup>
              </Marker>
            )}
            {withCoords.map(inc => (
              <Marker key={inc.id} position={[inc.latitude, inc.longitude]} icon={createIcon(P_COLOR[inc.priority] ?? '#6B7280')}>
                <Popup>
                  <div style={{ padding: '10px 12px', minWidth: 160 }}>
                    <p style={{ fontSize: 13, fontWeight: 700, color: '#0F172A', marginBottom: 4 }}>{inc.type}</p>
                    {inc.description && <p style={{ fontSize: 11, color: '#64748B', marginBottom: 6 }}>{inc.description.slice(0, 60)}...</p>}
                    <div style={{ display: 'flex', gap: 6 }}>
                      <span style={{ fontSize: 10, fontWeight: 700, padding: '2px 8px', borderRadius: 6, background: `${P_COLOR[inc.priority] ?? '#6B7280'}15`, color: P_COLOR[inc.priority] ?? '#6B7280' }}>{inc.priority}</span>
                      <span style={{ fontSize: 10, padding: '2px 8px', borderRadius: 6, background: '#F1F5F9', color: '#64748B' }}>{S_LABEL[inc.status]}</span>
                    </div>
                  </div>
                </Popup>
              </Marker>
            ))}
          </MapContainer>

          {/* GPS button */}
          <button onClick={handleLocate} disabled={gpsLoading}
            style={{ position: 'absolute', bottom: 12, right: 12, zIndex: 1000, display: 'flex', alignItems: 'center', gap: 6, padding: '8px 12px', borderRadius: 10, background: '#fff', border: '1px solid #E2E8F0', boxShadow: '0 4px 12px rgba(0,0,0,0.1)', cursor: 'pointer', fontFamily: 'inherit', fontSize: 12, fontWeight: 700, color: '#0F172A' }}>
            {gpsLoading ? <Loader2 size={12} className="animate-spin" /> : <Navigation size={12} style={{ color: '#3B82F6' }} />}
            <span>Mi ubicación</span>
          </button>
        </div>
      </div>

      {/* Recent incidents */}
      <div className="dash-fade s5" style={{ background: '#fff', borderRadius: 20, border: '1px solid #F1F5F9', overflow: 'hidden' }}>
        <div style={{ padding: '14px 16px', borderBottom: '1px solid #F8FAFC', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <p style={{ fontSize: 13, fontWeight: 700, color: '#0F172A' }}>Incidentes Recientes</p>
          <span style={{ fontSize: 11, color: '#94A3B8' }}>{incidents.length} total</span>
        </div>
        {loading ? (
          <div style={{ padding: 32, textAlign: 'center' }}>
            <Loader2 size={20} style={{ color: '#CBD5E1', animation: 'spin 1s linear infinite', display: 'inline-block' }} />
          </div>
        ) : incidents.slice(0, 8).map((inc, i) => (
          <div key={inc.id} className="inc-row" style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderBottom: i < 7 ? '1px solid #F8FAFC' : 'none', background: '#fff' }}>
            <div style={{ width: 36, height: 36, borderRadius: 12, background: `${P_COLOR[inc.priority] ?? '#6B7280'}10`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <AlertTriangle size={15} style={{ color: P_COLOR[inc.priority] ?? '#6B7280' }} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <p style={{ fontSize: 13, fontWeight: 700, color: '#0F172A', marginBottom: 2 }}>{inc.type}</p>
              <p style={{ fontSize: 11, color: '#94A3B8', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{inc.description || inc.location || '—'}</p>
            </div>
            <span style={{ fontSize: 10, fontWeight: 700, padding: '3px 8px', borderRadius: 6, color: P_COLOR[inc.priority] ?? '#6B7280', background: `${P_COLOR[inc.priority] ?? '#6B7280'}12`, whiteSpace: 'nowrap' }}>{inc.priority}</span>
            <span style={{ fontSize: 11, color: '#94A3B8', whiteSpace: 'nowrap', display: 'none' }} className="sm:block">{S_LABEL[inc.status]}</span>
          </div>
        ))}
      </div>
    </div>
  )
}
