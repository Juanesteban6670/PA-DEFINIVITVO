import { useEffect, useState } from 'react'
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet'
import { incidentService } from '@/Services/Services'
import { AlertTriangle, Loader2, Navigation, Layers, MapPin, X } from 'lucide-react'
import 'leaflet/dist/leaflet.css'
import L from 'leaflet'

delete L.Icon.Default.prototype._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
  iconUrl:       'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
  shadowUrl:     'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
})

const PRIORITY_COLOR = { LOW: '#10B981', MEDIUM: '#F59E0B', HIGH: '#F97316', CRITICAL: '#EF4444' }
const PRIORITY_LABEL = { LOW: 'Baja', MEDIUM: 'Media', HIGH: 'Alta', CRITICAL: 'Crítica' }
const CENTER = [10.3910, -75.4794]

const createIcon = (color, isMine) => L.divIcon({
  className: '',
  html: `<div style="position:relative;width:${isMine?36:28}px;height:${isMine?36:28}px">
    <div style="width:100%;height:100%;background:${color};border:${isMine?'3px':'2px'} solid white;border-radius:50% 50% 50% 0;transform:rotate(-45deg);box-shadow:0 4px 12px ${color}60;"></div>
    ${isMine ? `<div style="position:absolute;inset:-4px;border-radius:50% 50% 50% 0;border:2px solid ${color}40;transform:rotate(-45deg);"></div>` : ''}
  </div>`,
  iconSize: [isMine?36:28, isMine?36:28],
  iconAnchor: [isMine?18:14, isMine?36:28],
  popupAnchor: [0, -32],
})

const userIcon = L.divIcon({
  className: '',
  html: `<div style="position:relative;width:20px;height:20px">
    <div style="width:20px;height:20px;background:#3B82F6;border:3px solid white;border-radius:50%;box-shadow:0 2px 8px rgba(59,130,246,0.5)"></div>
    <div style="position:absolute;inset:-6px;border-radius:50%;border:2px solid rgba(59,130,246,0.3);animation:pulseRing 2s ease-out infinite"></div>
  </div>`,
  iconSize: [20, 20],
  iconAnchor: [10, 10],
})

function FlyTo({ coords }) {
  const map = useMap()
  useEffect(() => { if (coords) map.flyTo(coords, 16, { animate: true, duration: 1.5 }) }, [coords])
  return null
}

export default function CitizenMap() {
  const [all, setAll]           = useState([])
  const [mine, setMine]         = useState([])
  const [loading, setLoading]   = useState(true)
  const [filter, setFilter]     = useState('all')
  const [userCoords, setUserCoords] = useState(null)
  const [gpsLoading, setGpsLoading] = useState(false)
  const [flyTo, setFlyTo]       = useState(null)
  const [selected, setSelected] = useState(null)

  useEffect(() => {
    Promise.all([
      incidentService.getAll().then(r => r.data?.data ?? r.data ?? []),
      incidentService.getMine().then(r => r.data?.data ?? r.data ?? []),
    ])
      .then(([a, m]) => { setAll(Array.isArray(a) ? a : []); setMine(Array.isArray(m) ? m : []) })
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  const handleLocate = () => {
    if (!navigator.geolocation) return
    setGpsLoading(true)
    navigator.geolocation.getCurrentPosition(
      pos => { const c = [pos.coords.latitude, pos.coords.longitude]; setUserCoords(c); setFlyTo(c); setGpsLoading(false) },
      () => setGpsLoading(false),
      { enableHighAccuracy: true, timeout: 10000 }
    )
  }

  const mineIds   = new Set(mine.map(i => i.id))
  const displayed = (filter === 'mine' ? mine : all).filter(i => i.latitude && i.longitude)
  const noCoords  = (filter === 'mine' ? mine : all).filter(i => !i.latitude || !i.longitude)

  if (loading) return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: 300 }}>
      <Loader2 size={24} style={{ color: '#3B82F6', animation: 'spin 1s linear infinite' }} />
    </div>
  )

  return (
    <div style={{ fontFamily: "'DM Sans', system-ui, sans-serif", height: '100%' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700;800&display=swap');
        @keyframes pulseRing { 0%{transform:scale(1);opacity:0.6}100%{transform:scale(2.5);opacity:0} }
        @keyframes slideUp { from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)} }
        .map-filter-btn { transition: all 0.2s; cursor: pointer; border: none; font-family: inherit; }
        .map-filter-btn:hover { opacity: 0.85; }
        .inc-chip { transition: all 0.2s; cursor: pointer; }
        .inc-chip:hover { transform: translateX(3px); }
        .leaflet-container { border-radius: 0; }
        .leaflet-popup-content-wrapper { border-radius: 16px !important; box-shadow: 0 8px 32px rgba(0,0,0,0.15) !important; border: 1px solid #F1F5F9 !important; padding: 0 !important; overflow: hidden; }
        .leaflet-popup-content { margin: 0 !important; }
        .leaflet-popup-tip-container { display: none; }
      `}</style>

      {/* Header */}
      <div style={{ padding: '16px 16px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div>
          <h1 style={{ fontSize: 20, fontWeight: 800, color: '#0F172A', letterSpacing: '-0.02em' }}>Mapa de Incidentes</h1>
          <p style={{ fontSize: 12, color: '#94A3B8', marginTop: 2 }}>{all.length} incidentes en la ciudad</p>
        </div>
        <div style={{ display: 'flex', gap: 4, background: '#F1F5F9', borderRadius: 12, padding: 4 }}>
          {[['all', 'Ciudad'], ['mine', 'Míos']].map(([val, label]) => (
            <button key={val} className="map-filter-btn" onClick={() => setFilter(val)}
              style={{ padding: '7px 14px', borderRadius: 9, fontSize: 12, fontWeight: 700, color: filter === val ? '#1D4ED8' : '#64748B', background: filter === val ? '#fff' : 'transparent', boxShadow: filter === val ? '0 1px 4px rgba(0,0,0,0.08)' : 'none' }}>
              {label}
            </button>
          ))}
        </div>
      </div>

      {/* Map */}
      <div style={{ position: 'relative', height: 420, margin: '0 0 0 0' }}>
        <MapContainer center={CENTER} zoom={13} style={{ height: '100%', width: '100%', zIndex: 0 }} scrollWheelZoom>
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          {flyTo && <FlyTo coords={flyTo} />}

          {userCoords && (
            <Marker position={userCoords} icon={userIcon}>
              <Popup>
                <div style={{ padding: '12px 14px', minWidth: 140 }}>
                  <p style={{ fontSize: 13, fontWeight: 700, color: '#1D4ED8' }}>📍 Estás aquí</p>
                  <p style={{ fontSize: 11, color: '#94A3B8', marginTop: 4 }}>{userCoords[0].toFixed(5)}, {userCoords[1].toFixed(5)}</p>
                </div>
              </Popup>
            </Marker>
          )}

          {displayed.map(inc => (
            <Marker key={inc.id} position={[inc.latitude, inc.longitude]}
              icon={createIcon(PRIORITY_COLOR[inc.priority] ?? '#6B7280', mineIds.has(inc.id))}
              eventHandlers={{ click: () => setSelected(inc) }}>
              <Popup>
                <div style={{ padding: '12px 14px', minWidth: 180 }}>
                  {mineIds.has(inc.id) && (
                    <span style={{ fontSize: 10, fontWeight: 700, padding: '2px 8px', borderRadius: 6, background: 'rgba(29,78,216,0.1)', color: '#1D4ED8', display: 'inline-block', marginBottom: 6 }}>Mi reporte</span>
                  )}
                  <p style={{ fontSize: 14, fontWeight: 700, color: '#0F172A', marginBottom: 4 }}>{inc.type}</p>
                  {inc.description && <p style={{ fontSize: 12, color: '#64748B', lineHeight: 1.5, marginBottom: 8 }}>{inc.description.slice(0, 80)}{inc.description.length > 80 ? '...' : ''}</p>}
                  {inc.location && <p style={{ fontSize: 11, color: '#94A3B8', display: 'flex', alignItems: 'center', gap: 4, marginBottom: 8 }}>📍 {inc.location}</p>}
                  <div style={{ display: 'flex', gap: 6 }}>
                    <span style={{ fontSize: 10, fontWeight: 700, padding: '3px 8px', borderRadius: 6, background: `${PRIORITY_COLOR[inc.priority] ?? '#6B7280'}18`, color: PRIORITY_COLOR[inc.priority] ?? '#6B7280' }}>
                      {PRIORITY_LABEL[inc.priority] ?? inc.priority}
                    </span>
                    <span style={{ fontSize: 10, fontWeight: 600, padding: '3px 8px', borderRadius: 6, background: '#F1F5F9', color: '#64748B' }}>{inc.status}</span>
                  </div>
                </div>
              </Popup>
            </Marker>
          ))}
        </MapContainer>

        {/* GPS button */}
        <button onClick={handleLocate} disabled={gpsLoading}
          style={{ position: 'absolute', bottom: 16, right: 16, zIndex: 1000, display: 'flex', alignItems: 'center', gap: 8, padding: '10px 16px', borderRadius: 12, background: '#fff', border: '1px solid #E2E8F0', boxShadow: '0 4px 16px rgba(0,0,0,0.12)', cursor: 'pointer', fontFamily: 'inherit', fontSize: 13, fontWeight: 700, color: '#0F172A', transition: 'all 0.2s' }}>
          {gpsLoading
            ? <Loader2 size={14} style={{ color: '#3B82F6', animation: 'spin 1s linear infinite' }} />
            : <Navigation size={14} style={{ color: '#3B82F6' }} />}
          <span>Mi ubicación</span>
        </button>

        {/* Stats overlay */}
        <div style={{ position: 'absolute', top: 12, left: 52, zIndex: 1000, display: 'flex', gap: 6 }}>
          {Object.entries(PRIORITY_COLOR).map(([lvl, color]) => {
            const count = displayed.filter(i => i.priority === lvl).length
            if (!count) return null
            return (
              <div key={lvl} style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '5px 10px', borderRadius: 100, background: 'rgba(255,255,255,0.95)', border: `1px solid ${color}30`, backdropFilter: 'blur(8px)', boxShadow: '0 2px 8px rgba(0,0,0,0.1)' }}>
                <div style={{ width: 7, height: 7, borderRadius: '50%', background: color }} />
                <span style={{ fontSize: 11, fontWeight: 700, color: '#0F172A' }}>{count}</span>
              </div>
            )
          })}
        </div>
      </div>

      {/* Legend */}
      <div style={{ padding: '12px 16px' }}>
        <div style={{ background: '#fff', borderRadius: 16, border: '1px solid #F1F5F9', padding: '12px 16px', display: 'flex', flexWrap: 'wrap', gap: 16, alignItems: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <Layers size={13} style={{ color: '#94A3B8' }} />
            <span style={{ fontSize: 11, color: '#94A3B8', fontWeight: 600 }}>Prioridad:</span>
          </div>
          {Object.entries(PRIORITY_COLOR).map(([lvl, color]) => (
            <div key={lvl} style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
              <div style={{ width: 8, height: 8, borderRadius: '50%', background: color }} />
              <span style={{ fontSize: 11, color: '#64748B', fontWeight: 500 }}>{PRIORITY_LABEL[lvl]}</span>
            </div>
          ))}
          <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
            <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#3B82F6' }} />
            <span style={{ fontSize: 11, color: '#64748B', fontWeight: 500 }}>Tú</span>
          </div>
        </div>
      </div>

      {/* No coords list */}
      {noCoords.length > 0 && (
        <div style={{ padding: '0 16px 16px' }}>
          <div style={{ background: '#fff', borderRadius: 16, border: '1px solid #F1F5F9', overflow: 'hidden' }}>
            <div style={{ padding: '12px 16px', borderBottom: '1px solid #F8FAFC' }}>
              <p style={{ fontSize: 12, fontWeight: 700, color: '#64748B' }}>{noCoords.length} sin coordenadas GPS</p>
            </div>
            {noCoords.map((inc, i) => (
              <div key={inc.id} className="inc-chip"
                style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderBottom: i < noCoords.length - 1 ? '1px solid #F8FAFC' : 'none' }}>
                <div style={{ width: 32, height: 32, borderRadius: 10, background: `${PRIORITY_COLOR[inc.priority] ?? '#6B7280'}10`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <MapPin size={14} style={{ color: PRIORITY_COLOR[inc.priority] ?? '#6B7280' }} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <p style={{ fontSize: 13, fontWeight: 700, color: '#0F172A' }}>{inc.type}</p>
                  <p style={{ fontSize: 11, color: '#94A3B8', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{inc.location || 'Sin dirección'}</p>
                </div>
                {mineIds.has(inc.id) && <span style={{ fontSize: 10, color: '#1D4ED8', fontWeight: 700, padding: '2px 8px', borderRadius: 6, background: 'rgba(29,78,216,0.08)' }}>Mío</span>}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
