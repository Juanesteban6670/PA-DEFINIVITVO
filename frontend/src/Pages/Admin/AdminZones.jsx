// AdminZones.jsx
import { useEffect, useState } from 'react'
import { zoneService, aiService } from '@/Services/Services'
import { MapPin, Plus, X, Loader2, Shield, AlertTriangle, Brain, Sparkles, RefreshCw, TrendingUp } from 'lucide-react'
import toast from 'react-hot-toast'

const RISK_CONFIG = {
  LOW:      { color: '#10B981', bg: 'rgba(16,185,129,0.1)',  label: 'Bajo'    },
  MEDIUM:   { color: '#F59E0B', bg: 'rgba(245,158,11,0.1)',  label: 'Medio'   },
  HIGH:     { color: '#F97316', bg: 'rgba(249,115,22,0.1)',  label: 'Alto'    },
  CRITICAL: { color: '#EF4444', bg: 'rgba(239,68,68,0.1)',   label: 'Crítico' },
}
const emptyForm = { name: '', description: '', riskLevel: 'LOW', latitude: '', longitude: '' }

export function AdminZones() {
  const [zones, setZones]       = useState([])
  const [loading, setLoading]   = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [form, setForm]         = useState(emptyForm)
  const [saving, setSaving]     = useState(false)
  const [aiZones, setAiZones]   = useState([])
  const [aiLoading, setAiLoading] = useState(false)
  const [aiError, setAiError]   = useState(false)
  const [showAi, setShowAi]     = useState(false)

  const load = () => {
    setLoading(true)
    zoneService.getAll()
      .then(r => setZones(r.data?.data ?? r.data ?? []))
      .catch(() => setZones([]))
      .finally(() => setLoading(false))
  }
  useEffect(() => { load() }, [])

  const analyzeAI = async () => {
    setAiLoading(true); setAiError(false); setShowAi(true); setAiZones([])
    try {
      const r = await aiService.zonesAnalysis()
      const d = r.data?.zones ?? r.data?.data ?? r.data ?? []
      setAiZones(Array.isArray(d) ? d : [])
    } catch { setAiError(true) }
    finally { setAiLoading(false) }
  }

  const handleSubmit = async e => {
    e.preventDefault(); setSaving(true)
    try { await zoneService.create(form); toast.success('Zona creada ✅'); setShowForm(false); setForm(emptyForm); load() }
    catch { toast.error('Error al crear zona') }
    finally { setSaving(false) }
  }

  const handleDelete = async id => {
    if (!confirm('¿Eliminar esta zona?')) return
    try { await zoneService.delete(id); toast.success('Zona eliminada'); load() }
    catch { toast.error('Error al eliminar') }
  }

  return (
    <div style={{ padding: '20px 16px 32px', fontFamily: "'DM Sans', system-ui, sans-serif", background: '#F8FAFC', minHeight: '100%' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700;800&display=swap');
        @keyframes fadeUp { from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)} }
        @keyframes modalIn { from{opacity:0;transform:scale(0.97) translateY(20px)}to{opacity:1;transform:scale(1) translateY(0)} }
        .az-fade { animation: fadeUp 400ms ease-out both; }
        .s1{animation-delay:0ms}.s2{animation-delay:60ms}.s3{animation-delay:120ms}
        .zone-card { transition: all 0.25s; }
        .zone-card:hover { transform: translateY(-2px); box-shadow: 0 8px 24px rgba(0,0,0,0.08) !important; }
        .modal-inner { animation: modalIn 300ms cubic-bezier(0.16,1,0.3,1) both; }
        .admin-input { width:100%;padding:10px 14px;background:#F8FAFC;border:1px solid #E2E8F0;border-radius:12px;font-size:13px;color:#0F172A;font-family:inherit;outline:none;transition:all 0.2s;box-sizing:border-box; }
        .admin-input:focus { border-color:#3B82F6;box-shadow:0 0 0 3px rgba(59,130,246,0.12); }
        .admin-sel { appearance:none;width:100%;padding:10px 14px;background:#F8FAFC;border:1px solid #E2E8F0;border-radius:12px;font-size:13px;color:#0F172A;font-family:inherit;outline:none;cursor:pointer; }
        .admin-sel:focus { border-color:#3B82F6;box-shadow:0 0 0 3px rgba(59,130,246,0.12); }
      `}</style>

      {/* Header */}
      <div className="az-fade s1" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
        <div>
          <h1 style={{ fontSize: 22, fontWeight: 900, color: '#0F172A', letterSpacing: '-0.02em', marginBottom: 2 }}>Zonas</h1>
          <p style={{ fontSize: 13, color: '#94A3B8' }}>{zones.length} zonas registradas</p>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button onClick={analyzeAI} disabled={aiLoading}
            style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '9px 14px', borderRadius: 12, background: 'linear-gradient(135deg, #7C3AED, #8B5CF6)', color: '#fff', fontWeight: 700, fontSize: 12, border: 'none', cursor: 'pointer', fontFamily: 'inherit', opacity: aiLoading ? 0.7 : 1 }}>
            {aiLoading ? <Loader2 size={12} style={{ animation: 'spin 1s linear infinite' }} /> : <Brain size={12} />}
            IA
          </button>
          <button onClick={() => setShowForm(true)}
            style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '9px 16px', borderRadius: 12, background: 'linear-gradient(135deg, #1D4ED8, #3B82F6)', color: '#fff', fontWeight: 700, fontSize: 13, border: 'none', cursor: 'pointer', fontFamily: 'inherit', boxShadow: '0 4px 12px rgba(29,78,216,0.25)' }}>
            <Plus size={14} /> Nueva
          </button>
        </div>
      </div>

      {/* AI Panel */}
      {showAi && (
        <div className="az-fade s2" style={{ background: '#fff', borderRadius: 20, border: '1px solid rgba(139,92,246,0.2)', marginBottom: 16, overflow: 'hidden' }}>
          <div style={{ padding: '12px 16px', borderBottom: '1px solid rgba(139,92,246,0.1)', background: 'linear-gradient(135deg, rgba(139,92,246,0.04), rgba(59,130,246,0.02))', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Sparkles size={14} style={{ color: '#8B5CF6' }} />
              <p style={{ fontSize: 13, fontWeight: 700, color: '#0F172A' }}>Análisis de Riesgo IA</p>
            </div>
            <button onClick={() => setShowAi(false)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#94A3B8' }}><X size={14} /></button>
          </div>
          <div style={{ padding: 14 }}>
            {aiLoading && <div style={{ display: 'flex', alignItems: 'center', gap: 8, justifyContent: 'center', padding: '20px 0' }}><Loader2 size={16} style={{ color: '#8B5CF6', animation: 'spin 1s linear infinite' }} /><span style={{ fontSize: 13, color: '#94A3B8' }}>Analizando patrones...</span></div>}
            {aiError && <div style={{ padding: '12px', borderRadius: 12, background: '#FEF2F2', border: '1px solid #FECACA', textAlign: 'center' }}><p style={{ fontSize: 12, color: '#EF4444', fontWeight: 600 }}>IA no disponible</p><button onClick={analyzeAI} style={{ fontSize: 11, color: '#EF4444', background: 'none', border: 'none', cursor: 'pointer', fontFamily: 'inherit', marginTop: 6 }}>Reintentar</button></div>}
            {aiZones.length > 0 && !aiLoading && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {aiZones.map((z, i) => {
                  const rc = RISK_CONFIG[z.riskLevel] ?? RISK_CONFIG.LOW
                  const existing = zones.find(zone => zone.name?.toLowerCase() === z.name?.toLowerCase())
                  const differs = existing && existing.riskLevel !== z.riskLevel
                  return (
                    <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 10, padding: '10px 12px', borderRadius: 12, background: '#F8FAFC', border: '1px solid #F1F5F9' }}>
                      <Brain size={13} style={{ color: '#8B5CF6', flexShrink: 0, marginTop: 2 }} />
                      <div style={{ flex: 1 }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap', marginBottom: 4 }}>
                          <span style={{ fontSize: 13, fontWeight: 700, color: '#0F172A' }}>{z.name}</span>
                          <span style={{ fontSize: 10, fontWeight: 700, padding: '2px 8px', borderRadius: 6, background: rc.bg, color: rc.color }}>{rc.label}</span>
                          {differs && <span style={{ fontSize: 10, fontWeight: 600, padding: '2px 8px', borderRadius: 6, background: 'rgba(245,158,11,0.1)', color: '#D97706' }}>⚠️ Difiere ({existing.riskLevel})</span>}
                        </div>
                        {z.recommendation && <p style={{ fontSize: 12, color: '#64748B', lineHeight: 1.5 }}>{z.recommendation}</p>}
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        </div>
      )}

      {/* Zones grid */}
      {loading ? (
        <div style={{ padding: 48, textAlign: 'center' }}><Loader2 size={22} style={{ color: '#CBD5E1', animation: 'spin 1s linear infinite', display: 'inline-block' }} /></div>
      ) : zones.length === 0 ? (
        <div className="az-fade s3" style={{ padding: '48px 20px', textAlign: 'center', background: '#fff', borderRadius: 20, border: '1px solid #F1F5F9' }}>
          <MapPin size={28} style={{ color: '#E2E8F0', display: 'block', margin: '0 auto 12px' }} />
          <p style={{ fontSize: 14, color: '#94A3B8', fontWeight: 600, marginBottom: 16 }}>Sin zonas registradas</p>
          <button onClick={() => setShowForm(true)} style={{ padding: '10px 20px', borderRadius: 12, background: '#1D4ED8', color: '#fff', fontWeight: 700, fontSize: 13, border: 'none', cursor: 'pointer', fontFamily: 'inherit' }}>
            <Plus size={13} style={{ display: 'inline', marginRight: 6 }} />Crear primera zona
          </button>
        </div>
      ) : (
        <div className="az-fade s3" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(240px, 1fr))', gap: 12 }}>
          {zones.map(zone => {
            const rc = RISK_CONFIG[zone.riskLevel] ?? RISK_CONFIG.LOW
            return (
              <div key={zone.id} className="zone-card" style={{ background: '#fff', borderRadius: 18, border: `1px solid ${rc.color}20`, padding: '16px', boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}>
                <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 12 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <div style={{ width: 38, height: 38, borderRadius: 12, background: rc.bg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Shield size={17} style={{ color: rc.color }} />
                    </div>
                    <div>
                      <p style={{ fontSize: 14, fontWeight: 700, color: '#0F172A', marginBottom: 2 }}>{zone.name}</p>
                      <span style={{ fontSize: 10, fontWeight: 700, padding: '2px 8px', borderRadius: 6, background: rc.bg, color: rc.color }}>{rc.label}</span>
                    </div>
                  </div>
                  <button onClick={() => handleDelete(zone.id)} style={{ width: 26, height: 26, borderRadius: 8, border: 'none', background: 'rgba(239,68,68,0.08)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                    <X size={12} style={{ color: '#EF4444' }} />
                  </button>
                </div>
                {zone.description && <p style={{ fontSize: 12, color: '#64748B', lineHeight: 1.5, marginBottom: 10 }}>{zone.description.slice(0, 80)}{zone.description.length > 80 ? '...' : ''}</p>}
                <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, color: '#94A3B8' }}>
                  <AlertTriangle size={11} /><span>{zone.totalIncidents ?? 0} incidentes</span>
                </div>
              </div>
            )
          })}
        </div>
      )}

      {/* Modal */}
      {showForm && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'flex-end', justifyContent: 'center', zIndex: 1000, backdropFilter: 'blur(4px)' }}
          onClick={e => e.target === e.currentTarget && setShowForm(false)}>
          <div className="modal-inner" style={{ background: '#fff', borderRadius: '24px 24px 0 0', width: '100%', maxWidth: 480, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
            <div style={{ padding: '18px 20px', borderBottom: '1px solid #F1F5F9', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <h2 style={{ fontSize: 17, fontWeight: 800, color: '#0F172A' }}>Nueva Zona</h2>
              <button onClick={() => setShowForm(false)} style={{ width: 30, height: 30, borderRadius: 9, border: '1px solid #E2E8F0', background: '#F8FAFC', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><X size={13} style={{ color: '#64748B' }} /></button>
            </div>
            <form onSubmit={handleSubmit} style={{ padding: '16px 20px', display: 'flex', flexDirection: 'column', gap: 12 }}>
              <div>
                <label style={{ display: 'block', fontSize: 11, fontWeight: 700, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 6 }}>Nombre *</label>
                <input className="admin-input" required value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder="Ej: Getsemaní" />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: 11, fontWeight: 700, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 6 }}>Descripción</label>
                <textarea className="admin-input" rows={2} value={form.description} onChange={e => setForm({...form, description: e.target.value})} placeholder="Descripción de la zona" style={{ resize: 'none' }} />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: 11, fontWeight: 700, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 6 }}>Nivel de Riesgo</label>
                <select className="admin-sel" value={form.riskLevel} onChange={e => setForm({...form, riskLevel: e.target.value})}>
                  <option value="LOW">Bajo</option><option value="MEDIUM">Medio</option><option value="HIGH">Alto</option><option value="CRITICAL">Crítico</option>
                </select>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                <div>
                  <label style={{ display: 'block', fontSize: 11, fontWeight: 700, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 6 }}>Latitud</label>
                  <input className="admin-input" type="number" step="any" value={form.latitude} onChange={e => setForm({...form, latitude: e.target.value})} placeholder="10.4236" />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: 11, fontWeight: 700, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 6 }}>Longitud</label>
                  <input className="admin-input" type="number" step="any" value={form.longitude} onChange={e => setForm({...form, longitude: e.target.value})} placeholder="-75.5378" />
                </div>
              </div>
              <div style={{ display: 'flex', gap: 10, paddingTop: 4 }}>
                <button type="button" onClick={() => setShowForm(false)} style={{ flex: 1, padding: '12px', borderRadius: 12, border: '1px solid #E2E8F0', background: '#F8FAFC', color: '#64748B', fontWeight: 600, fontSize: 14, cursor: 'pointer', fontFamily: 'inherit' }}>Cancelar</button>
                <button type="submit" disabled={saving} style={{ flex: 2, padding: '12px', borderRadius: 12, background: 'linear-gradient(135deg, #1D4ED8, #3B82F6)', color: '#fff', fontWeight: 700, fontSize: 14, border: 'none', cursor: 'pointer', fontFamily: 'inherit', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
                  {saving ? <Loader2 size={14} style={{ animation: 'spin 1s linear infinite' }} /> : <><Plus size={14} /> Crear Zona</>}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}

export default AdminZones
