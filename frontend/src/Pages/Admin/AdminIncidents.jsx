import { useEffect, useState } from 'react'
import CommentsSection from '@/Components/CommentsSection'
import { useSearchParams } from 'react-router-dom'
import { incidentService } from '@/Services/Services'
import { Loader2, AlertTriangle, MapPin, X, Image, FileText, Calendar, User, Zap, Search } from 'lucide-react'
import toast from 'react-hot-toast'

const S_LABEL = { PENDING: 'Pendiente', IN_PROGRESS: 'En progreso', RESOLVED: 'Resuelto', REJECTED: 'Rechazado' }
const S_COLOR = {
  PENDING:     { color: '#F59E0B', bg: 'rgba(245,158,11,0.1)'  },
  IN_PROGRESS: { color: '#3B82F6', bg: 'rgba(59,130,246,0.1)'  },
  RESOLVED:    { color: '#10B981', bg: 'rgba(16,185,129,0.1)'  },
  REJECTED:    { color: '#EF4444', bg: 'rgba(239,68,68,0.1)'   },
}
const P_COLOR = { LOW: '#10B981', MEDIUM: '#F59E0B', HIGH: '#F97316', CRITICAL: '#EF4444' }
const P_LABEL = { LOW: 'Baja', MEDIUM: 'Media', HIGH: 'Alta', CRITICAL: 'Crítica' }
const isImage = url => /\.(jpg|jpeg|png|webp|gif)(\?|$)/i.test(url)
const emptyForm = { status: '', priority: '', assignedTo: '', changeReason: '' }

export default function AdminIncidents() {
  const [incidents, setIncidents] = useState([])
  const [loading, setLoading]     = useState(true)
  const [selected, setSelected]   = useState(null)
  const [form, setForm]           = useState(emptyForm)
  const [saving, setSaving]       = useState(false)
  const [filter, setFilter]       = useState('ALL')
  const [search, setSearch]       = useState('')

  const load = () => {
    setLoading(true)
    incidentService.getAll()
      .then(res => setIncidents(res.data?.data ?? res.data?.content ?? res.data ?? []))
      .catch(() => setIncidents([]))
      .finally(() => setLoading(false))
  }
  useEffect(() => { load() }, [])

  /* ── URL Params Handle ── */
  const [searchParams] = useSearchParams()
  useEffect(() => {
    const id = searchParams.get('id')
    if (id) {
      const found = incidents.find(x => String(x.id) === String(id))
      if (found) {
        openModal(found)
      } else if (!loading && incidents.length > 0) {
        incidentService.getById(id)
          .then(res => openModal(res.data?.data ?? res.data))
          .catch(() => {})
      }
    }
  }, [searchParams, incidents, loading])

  const openModal = inc => { setSelected(inc); setForm({ status: inc.status, priority: inc.priority, assignedTo: inc.assignedTo ?? '', changeReason: '' }) }

  const handleUpdate = async e => {
    e.preventDefault()
    if (!form.changeReason.trim()) { toast.error('Ingresa una razón del cambio'); return }
    setSaving(true)
    try {
      await incidentService.updateStatus(selected.id, form)
      toast.success('Incidente actualizado ✅')
      setSelected(null); load()
    } catch { toast.error('Error al actualizar') }
    finally { setSaving(false) }
  }

  const filtered = incidents.filter(inc => {
    const matchStatus = filter === 'ALL' || inc.status === filter
    const matchSearch = !search || inc.type?.toLowerCase().includes(search.toLowerCase()) || inc.description?.toLowerCase().includes(search.toLowerCase()) || inc.reportedBy?.toLowerCase().includes(search.toLowerCase())
    return matchStatus && matchSearch
  })

  return (
    <div style={{ padding: '20px 16px 32px', fontFamily: "'DM Sans', system-ui, sans-serif", background: '#F8FAFC', minHeight: '100%' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700;800&display=swap');
        @keyframes fadeUp { from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)} }
        @keyframes modalIn { from{opacity:0;transform:scale(0.97) translateY(20px)}to{opacity:1;transform:scale(1) translateY(0)} }
        .ai-fade { animation: fadeUp 400ms ease-out both; }
        .s1{animation-delay:0ms}.s2{animation-delay:60ms}.s3{animation-delay:120ms}
        .inc-row { transition: background 0.15s; border-bottom: 1px solid #F8FAFC; cursor: default; }
        .inc-row:hover { background: #F8FAFC !important; }
        .modal-inner { animation: modalIn 300ms cubic-bezier(0.16,1,0.3,1) both; }
        .filter-chip { transition: all 0.2s; cursor: pointer; border: none; font-family: inherit; }
        .admin-input { width:100%;padding:10px 14px;background:#F8FAFC;border:1px solid #E2E8F0;border-radius:12px;font-size:13px;color:#0F172A;font-family:inherit;outline:none;transition:all 0.2s;box-sizing:border-box; }
        .admin-input:focus { border-color:#3B82F6;box-shadow:0 0 0 3px rgba(59,130,246,0.12); }
        .admin-sel { appearance:none;width:100%;padding:10px 14px;background:#F8FAFC;border:1px solid #E2E8F0;border-radius:12px;font-size:13px;color:#0F172A;font-family:inherit;outline:none;cursor:pointer; }
        .admin-sel:focus { border-color:#3B82F6;box-shadow:0 0 0 3px rgba(59,130,246,0.12); }
        .img-thumb { transition: all 0.2s; }
        .img-thumb:hover { transform: scale(1.03); opacity: 0.9; }
      `}</style>

      {/* Header */}
      <div className="ai-fade s1" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
        <div>
          <h1 style={{ fontSize: 22, fontWeight: 900, color: '#0F172A', letterSpacing: '-0.02em', marginBottom: 2 }}>Incidentes</h1>
          <p style={{ fontSize: 13, color: '#94A3B8' }}>{incidents.length} registrados en el sistema</p>
        </div>
      </div>

      {/* Search + filters */}
      <div className="ai-fade s2" style={{ display: 'flex', flexDirection: 'column', gap: 10, marginBottom: 16 }}>
        <div style={{ position: 'relative' }}>
          <Search size={14} style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: '#CBD5E1' }} />
          <input className="admin-input" value={search} onChange={e => setSearch(e.target.value)}
            placeholder="Buscar por tipo, descripción, usuario..." style={{ paddingLeft: 36 }} />
        </div>
        <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 2 }}>
          {[['ALL','Todos'], ['PENDING','Pendientes'], ['IN_PROGRESS','En progreso'], ['RESOLVED','Resueltos'], ['REJECTED','Rechazados']].map(([val, label]) => {
            const sc = S_COLOR[val]
            const cnt = val === 'ALL' ? incidents.length : incidents.filter(i => i.status === val).length
            return (
              <button key={val} className="filter-chip" onClick={() => setFilter(val)}
                style={{ padding: '6px 14px', borderRadius: 100, fontSize: 12, fontWeight: 700, whiteSpace: 'nowrap', background: filter === val ? (sc?.color ?? '#1D4ED8') : '#fff', color: filter === val ? '#fff' : '#64748B', border: filter === val ? `1px solid ${sc?.color ?? '#1D4ED8'}` : '1px solid #E2E8F0', boxShadow: filter === val ? `0 4px 12px ${sc?.color ?? '#1D4ED8'}25` : 'none' }}>
                {label} <span style={{ opacity: 0.7, marginLeft: 4 }}>({cnt})</span>
              </button>
            )
          })}
        </div>
      </div>

      {/* List */}
      <div className="ai-fade s3" style={{ background: '#fff', borderRadius: 20, border: '1px solid #F1F5F9', overflow: 'hidden' }}>
        {loading ? (
          <div style={{ padding: 48, textAlign: 'center' }}>
            <Loader2 size={22} style={{ color: '#CBD5E1', animation: 'spin 1s linear infinite', display: 'inline-block' }} />
          </div>
        ) : filtered.length === 0 ? (
          <div style={{ padding: '48px 20px', textAlign: 'center' }}>
            <AlertTriangle size={28} style={{ color: '#E2E8F0', display: 'block', margin: '0 auto 12px' }} />
            <p style={{ fontSize: 14, color: '#94A3B8', fontWeight: 600 }}>Sin incidentes</p>
          </div>
        ) : filtered.map((inc, i) => {
          const sc = S_COLOR[inc.status] ?? S_COLOR.PENDING
          return (
            <div key={inc.id} className="inc-row" style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '14px 16px', background: '#fff' }}>
              <div style={{ width: 42, height: 42, borderRadius: 14, background: sc.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <AlertTriangle size={18} style={{ color: sc.color }} />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3, flexWrap: 'wrap' }}>
                  <p style={{ fontSize: 13, fontWeight: 700, color: '#0F172A' }}>{inc.type}</p>
                  <span style={{ fontSize: 10, fontWeight: 700, padding: '2px 8px', borderRadius: 6, background: sc.bg, color: sc.color }}>{S_LABEL[inc.status]}</span>
                  {inc.imageUrls?.length > 0 && (
                    <span style={{ fontSize: 10, fontWeight: 700, padding: '2px 8px', borderRadius: 6, background: 'rgba(59,130,246,0.08)', color: '#3B82F6', display: 'flex', alignItems: 'center', gap: 3 }}>
                      <Image size={10} /> {inc.imageUrls.length}
                    </span>
                  )}
                </div>
                <p style={{ fontSize: 11, color: '#94A3B8', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{inc.description || inc.location || '—'}</p>
                <p style={{ fontSize: 10, color: '#CBD5E1', marginTop: 2 }}>👤 {inc.reportedBy}</p>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 6, flexShrink: 0 }}>
                <span style={{ fontSize: 10, fontWeight: 700, padding: '2px 8px', borderRadius: 6, background: `${P_COLOR[inc.priority] ?? '#6B7280'}12`, color: P_COLOR[inc.priority] ?? '#6B7280' }}>{P_LABEL[inc.priority]}</span>
                <button onClick={() => openModal(inc)}
                  style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '6px 12px', borderRadius: 10, background: 'rgba(29,78,216,0.08)', border: 'none', color: '#1D4ED8', fontSize: 11, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit' }}>
                  <Zap size={11} /> Gestionar
                </button>
              </div>
            </div>
          )
        })}
      </div>

      {/* Modal */}
      {selected && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'flex-end', justifyContent: 'center', zIndex: 1000, backdropFilter: 'blur(4px)' }}
          onClick={e => e.target === e.currentTarget && setSelected(null)}>
          <div className="modal-inner" style={{ background: '#fff', borderRadius: '24px 24px 0 0', width: '100%', maxWidth: 520, maxHeight: '94vh', overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>

            {/* Modal header */}
            <div style={{ padding: '18px 20px', borderBottom: '1px solid #F1F5F9', display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexShrink: 0 }}>
              <div>
                <h2 style={{ fontSize: 17, fontWeight: 800, color: '#0F172A', letterSpacing: '-0.01em' }}>Gestionar Incidente</h2>
                <p style={{ fontSize: 11, color: '#94A3B8', marginTop: 2 }}>{selected.type} · Reportado por {selected.reportedBy}</p>
              </div>
              <button onClick={() => setSelected(null)} style={{ width: 32, height: 32, borderRadius: 10, border: '1px solid #E2E8F0', background: '#F8FAFC', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <X size={14} style={{ color: '#64748B' }} />
              </button>
            </div>

            <div style={{ flex: 1, overflowY: 'auto', padding: '16px 20px', display: 'flex', flexDirection: 'column', gap: 16 }}>

              {/* Info */}
              <div style={{ padding: '14px', borderRadius: 16, background: '#F8FAFC', border: '1px solid #F1F5F9' }}>
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 10 }}>
                  <span style={{ fontSize: 11, fontWeight: 700, padding: '3px 10px', borderRadius: 8, background: (S_COLOR[selected.status]?.bg), color: S_COLOR[selected.status]?.color }}>{S_LABEL[selected.status]}</span>
                  <span style={{ fontSize: 11, fontWeight: 700, padding: '3px 10px', borderRadius: 8, background: `${P_COLOR[selected.priority]}12`, color: P_COLOR[selected.priority] }}>{P_LABEL[selected.priority]}</span>
                  {selected.assignedTo && <span style={{ fontSize: 11, padding: '3px 10px', borderRadius: 8, background: 'rgba(59,130,246,0.08)', color: '#3B82F6', fontWeight: 600 }}>👤 {selected.assignedTo}</span>}
                </div>
                <p style={{ fontSize: 13, color: '#374151', lineHeight: 1.6, marginBottom: selected.location ? 8 : 0 }}>{selected.description || 'Sin descripción'}</p>
                {selected.location && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: 5, fontSize: 12, color: '#94A3B8' }}>
                    <MapPin size={12} style={{ color: '#3B82F6' }} /> {selected.location}
                  </div>
                )}
                {selected.createdAt && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: 5, fontSize: 11, color: '#CBD5E1', marginTop: 6 }}>
                    <Calendar size={11} /> {new Date(selected.createdAt).toLocaleString('es-CO')}
                  </div>
                )}
              </div>

              {/* Files */}
              {selected.imageUrls?.length > 0 && (
                <div>
                  <p style={{ fontSize: 11, fontWeight: 700, color: '#94A3B8', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 10 }}>
                    Evidencia adjunta ({selected.imageUrls.length})
                  </p>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 8 }}>
                    {selected.imageUrls.map((url, i) => (
                      isImage(url) ? (
                        <a key={i} href={url} target="_blank" rel="noreferrer" className="img-thumb"
                          style={{ borderRadius: 12, overflow: 'hidden', display: 'block', aspectRatio: '1', background: '#F1F5F9' }}>
                          <img src={url} alt={`foto-${i+1}`} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                        </a>
                      ) : (
                        <a key={i} href={url} target="_blank" rel="noreferrer"
                          style={{ borderRadius: 12, border: '1px solid #E2E8F0', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 4, aspectRatio: '1', background: '#F8FAFC', textDecoration: 'none', padding: 8 }}>
                          <FileText size={20} style={{ color: '#94A3B8' }} />
                          <span style={{ fontSize: 9, color: '#94A3B8', textAlign: 'center', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', width: '100%' }}>{url.split('/').pop()}</span>
                        </a>
                      )
                    ))}
                  </div>
                </div>
              )}

              {/* Comentarios */}
              <CommentsSection incidentId={selected.id} isAdmin />

              {/* Update form */}
              <div style={{ borderTop: '1px solid #F1F5F9', paddingTop: 16 }}>
                <p style={{ fontSize: 11, fontWeight: 700, color: '#94A3B8', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 14 }}>Actualizar incidente</p>
                <form onSubmit={handleUpdate} id="admin-inc-form" style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                    <div>
                      <label style={{ display: 'block', fontSize: 11, fontWeight: 700, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 6 }}>Estado</label>
                      <select className="admin-sel" value={form.status} onChange={e => setForm({...form, status: e.target.value})}>
                        <option value="PENDING">Pendiente</option>
                        <option value="IN_PROGRESS">En progreso</option>
                        <option value="RESOLVED">Resuelto</option>
                        <option value="REJECTED">Rechazado</option>
                      </select>
                    </div>
                    <div>
                      <label style={{ display: 'block', fontSize: 11, fontWeight: 700, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 6 }}>Prioridad</label>
                      <select className="admin-sel" value={form.priority} onChange={e => setForm({...form, priority: e.target.value})}>
                        <option value="LOW">Baja</option>
                        <option value="MEDIUM">Media</option>
                        <option value="HIGH">Alta</option>
                        <option value="CRITICAL">Crítica</option>
                      </select>
                    </div>
                  </div>
                  <div>
                    <label style={{ display: 'block', fontSize: 11, fontWeight: 700, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 6 }}>Asignar a</label>
                    <input className="admin-input" value={form.assignedTo} onChange={e => setForm({...form, assignedTo: e.target.value})} placeholder="username del agente (opcional)" />
                  </div>
                  <div>
                    <label style={{ display: 'block', fontSize: 11, fontWeight: 700, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 6 }}>Razón del cambio *</label>
                    <textarea className="admin-input" rows={3} required value={form.changeReason}
                      onChange={e => setForm({...form, changeReason: e.target.value})}
                      placeholder="Ej: Patrulla enviada al sector, incidente verificado..." style={{ resize: 'none' }} />
                  </div>
                </form>
              </div>
            </div>

            {/* Footer */}
            <div style={{ padding: '14px 20px', borderTop: '1px solid #F1F5F9', display: 'flex', gap: 10, flexShrink: 0 }}>
              <button onClick={() => setSelected(null)}
                style={{ flex: 1, padding: '12px', borderRadius: 12, border: '1px solid #E2E8F0', background: '#F8FAFC', color: '#64748B', fontWeight: 600, fontSize: 14, cursor: 'pointer', fontFamily: 'inherit' }}>
                Cancelar
              </button>
              <button type="submit" form="admin-inc-form" disabled={saving}
                style={{ flex: 2, padding: '12px', borderRadius: 12, background: saving ? '#93C5FD' : 'linear-gradient(135deg, #1D4ED8, #3B82F6)', color: '#fff', fontWeight: 700, fontSize: 14, border: 'none', cursor: saving ? 'not-allowed' : 'pointer', fontFamily: 'inherit', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, boxShadow: '0 4px 16px rgba(29,78,216,0.25)' }}>
                {saving ? <><Loader2 size={14} style={{ animation: 'spin 1s linear infinite' }} /> Guardando...</> : <><Zap size={14} /> Guardar cambios</>}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
