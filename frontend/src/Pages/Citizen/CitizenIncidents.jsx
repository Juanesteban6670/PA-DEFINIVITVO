import { useEffect, useState, useRef, useCallback } from 'react'
import CommentsSection from '@/Components/CommentsSection'
import { useSearchParams } from 'react-router-dom'
import { incidentService, aiService } from '@/Services/Services'
import {
  AlertTriangle, Plus, X, Loader2, MapPin, Navigation,
  Sparkles, Check, Image, Paperclip, Upload, Eye, Trash2,
  Clock, CheckCircle, XCircle, Filter, Search, ChevronDown,
  FileText, Camera, ArrowRight, Zap
} from 'lucide-react'
import toast from 'react-hot-toast'

/* ── Constants ────────────────────────────────────────────────────────── */
const STATUS_MAP = {
  PENDING:     { label: 'Pendiente',   color: '#F59E0B', bg: 'rgba(245,158,11,0.1)',  icon: Clock },
  IN_PROGRESS: { label: 'En progreso', color: '#3B82F6', bg: 'rgba(59,130,246,0.1)',  icon: Loader2 },
  RESOLVED:    { label: 'Resuelto',    color: '#10B981', bg: 'rgba(16,185,129,0.1)',  icon: CheckCircle },
  REJECTED:    { label: 'Rechazado',   color: '#EF4444', bg: 'rgba(239,68,68,0.1)',   icon: XCircle },
}
const PRIORITY_COLOR = {
  LOW:      { color: '#10B981', bg: 'rgba(16,185,129,0.1)',  label: 'Baja'    },
  MEDIUM:   { color: '#F59E0B', bg: 'rgba(245,158,11,0.1)',  label: 'Media'   },
  HIGH:     { color: '#F97316', bg: 'rgba(249,115,22,0.1)',  label: 'Alta'    },
  CRITICAL: { color: '#EF4444', bg: 'rgba(239,68,68,0.1)',   label: 'Crítica' },
}
const INCIDENT_TYPES = ['ROBO', 'ACCIDENTE', 'PELEA', 'INCENDIO', 'VANDALISMO', 'SOSPECHOSO', 'OTRO']
const emptyForm = { type: 'ROBO', description: '', location: '', latitude: '', longitude: '', priority: 'MEDIUM' }
const MAX_FILES = 5
const MAX_SIZE_MB = 10

/* ── FilePreview ──────────────────────────────────────────────────────── */
function FilePreview({ file, onRemove }) {
  const [preview, setPreview] = useState(null)
  const isImage = file.type.startsWith('image/')

  useEffect(() => {
    if (isImage) {
      const url = URL.createObjectURL(file)
      setPreview(url)
      return () => URL.revokeObjectURL(url)
    }
  }, [file, isImage])

  const sizeMB = (file.size / 1024 / 1024).toFixed(1)

  return (
    <div style={{ position: 'relative', borderRadius: 12, border: '1px solid #E2E8F0', overflow: 'hidden', background: '#F8FAFC', display: 'flex', flexDirection: 'column' }}>
      {isImage && preview ? (
        <div style={{ height: 80, overflow: 'hidden', position: 'relative' }}>
          <img src={preview} alt={file.name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
          <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(to top, rgba(0,0,0,0.5), transparent)' }} />
        </div>
      ) : (
        <div style={{ height: 80, display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'linear-gradient(135deg, #F1F5F9, #E2E8F0)' }}>
          <FileText size={28} style={{ color: '#94A3B8' }} />
        </div>
      )}
      <div style={{ padding: '6px 8px', display: 'flex', alignItems: 'center', gap: 4 }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <p style={{ fontSize: 10, color: '#475569', fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{file.name}</p>
          <p style={{ fontSize: 9, color: '#94A3B8' }}>{sizeMB} MB</p>
        </div>
        <button onClick={onRemove} style={{ width: 20, height: 20, borderRadius: 6, background: 'rgba(239,68,68,0.1)', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
          <X size={10} style={{ color: '#EF4444' }} />
        </button>
      </div>
    </div>
  )
}

/* ── IncidentDetailModal (ciudadano) ──────────────────────────────────── */
function IncidentDetailModal({ inc, onClose }) {
  const isImage = (url) => /\.(jpg|jpeg|png|webp|gif)(\?|$)/i.test(url)
  const st = STATUS_MAP[inc.status] ?? STATUS_MAP.PENDING
  const pr = PRIORITY_COLOR[inc.priority] ?? PRIORITY_COLOR.MEDIUM
  const StIcon = st.icon

  return (
    <div
      style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'flex-end', justifyContent: 'center', zIndex: 1100, backdropFilter: 'blur(4px)' }}
      onClick={e => e.target === e.currentTarget && onClose()}
    >
      <div className="modal-inner" style={{ background: '#fff', borderRadius: '24px 24px 0 0', width: '100%', maxWidth: 520, maxHeight: '85vh', overflow: 'hidden', display: 'flex', flexDirection: 'column', boxShadow: '0 -20px 60px rgba(0,0,0,0.3)' }}>

        {/* Header */}
        <div style={{ padding: '20px 20px 16px', borderBottom: '1px solid #F1F5F9', display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexShrink: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 44, height: 44, borderRadius: 16, background: st.bg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <StIcon size={20} style={{ color: st.color }} />
            </div>
            <div>
              <p style={{ fontSize: 17, fontWeight: 800, color: '#0F172A', letterSpacing: '-0.01em' }}>{inc.type}</p>
              <p style={{ fontSize: 11, color: '#94A3B8', marginTop: 1 }}>
                {inc.createdAt ? new Date(inc.createdAt).toLocaleDateString('es-CO', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : 'Fecha desconocida'}
              </p>
            </div>
          </div>
          <button onClick={onClose} style={{ width: 34, height: 34, borderRadius: 10, border: '1px solid #E2E8F0', background: '#F8FAFC', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <X size={15} style={{ color: '#64748B' }} />
          </button>
        </div>

        <div style={{ flex: 1, overflowY: 'auto', padding: '18px 20px', display: 'flex', flexDirection: 'column', gap: 16 }}>

          {/* Badges estado + prioridad */}
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <span style={{ fontSize: 12, fontWeight: 700, padding: '5px 14px', borderRadius: 10, background: st.bg, color: st.color }}>{st.label}</span>
            <span style={{ fontSize: 12, fontWeight: 700, padding: '5px 14px', borderRadius: 10, background: pr.bg, color: pr.color }}>Prioridad {pr.label}</span>
          </div>

          {/* Descripción */}
          <div style={{ background: '#F8FAFC', borderRadius: 16, padding: 16 }}>
            <p style={{ fontSize: 11, fontWeight: 700, color: '#94A3B8', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 8 }}>Descripción</p>
            <p style={{ fontSize: 14, color: '#334155', lineHeight: 1.65 }}>{inc.description || 'Sin descripción'}</p>
          </div>

          {/* Ubicación */}
          {(inc.location || inc.latitude) && (
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10, padding: '12px 14px', borderRadius: 14, background: 'rgba(59,130,246,0.05)', border: '1px solid rgba(59,130,246,0.12)' }}>
              <MapPin size={16} style={{ color: '#3B82F6', flexShrink: 0, marginTop: 2 }} />
              <div>
                {inc.location && <p style={{ fontSize: 13, color: '#1E40AF', fontWeight: 600 }}>{inc.location}</p>}
                {inc.latitude && <p style={{ fontSize: 11, color: '#94A3B8', marginTop: 3 }}>📍 {inc.latitude}, {inc.longitude}</p>}
              </div>
            </div>
          )}

          {/* Fotos / Archivos */}
          {inc.imageUrls?.length > 0 ? (
            <div>
              <p style={{ fontSize: 11, fontWeight: 700, color: '#94A3B8', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 10 }}>
                Evidencia adjunta ({inc.imageUrls.length})
              </p>
              <div className="grid grid-cols-3 sm:grid-cols-4 gap-2">
                {inc.imageUrls.map((url, i) => (
                  isImage(url) ? (
                    <a key={i} href={url} target="_blank" rel="noreferrer"
                      style={{ borderRadius: 14, overflow: 'hidden', display: 'block', aspectRatio: '1', background: '#F1F5F9', cursor: 'zoom-in' }}>
                      <img src={url} alt={`evidencia-${i + 1}`} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                    </a>
                  ) : (
                    <a key={i} href={url} target="_blank" rel="noreferrer"
                      style={{ borderRadius: 14, border: '1px solid #E2E8F0', padding: '10px 8px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 6, background: '#F8FAFC', textDecoration: 'none', aspectRatio: '1' }}>
                      <FileText size={22} style={{ color: '#94A3B8' }} />
                      <span style={{ fontSize: 9, color: '#64748B', fontWeight: 600, textAlign: 'center', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', width: '90%' }}>
                        {url.split('/').pop()}
                      </span>
                    </a>
                  )
                ))}
              </div>
            </div>
          ) : (
            <div style={{ padding: 16, textAlign: 'center', borderRadius: 14, background: '#F8FAFC', border: '1px solid #F1F5F9' }}>
              <Image size={22} style={{ color: '#CBD5E1', display: 'block', margin: '0 auto 8px' }} />
              <p style={{ fontSize: 12, color: '#CBD5E1' }}>Sin archivos adjuntos</p>
            </div>
          )}

          {/* Comentarios */}
          <CommentsSection incidentId={inc.id} />
        </div>
      </div>
    </div>
  )
}

/* ── Main Component ───────────────────────────────────────────────────── */
export default function CitizenIncidents() {
  const [incidents, setIncidents]       = useState([])
  const [loading, setLoading]           = useState(true)
  const [showForm, setShowForm]         = useState(false)
  const [viewingInc, setViewingInc]     = useState(null)
  const [form, setForm]                 = useState(emptyForm)
  const [saving, setSaving]             = useState(false)
  const [gpsLoading, setGpsLoading]     = useState(false)
  const [files, setFiles]               = useState([])
  const [dragOver, setDragOver]         = useState(false)
  const [filterStatus, setFilterStatus] = useState('ALL')
  const [search, setSearch]             = useState('')
  const [classifying, setClassifying]   = useState(false)
  const [suggestion, setSuggestion]     = useState(null)
  const [suggApplied, setSuggApplied]   = useState(false)
  const [activeTab, setActiveTab]       = useState('form')
  const debounceRef  = useRef(null)
  const fileInputRef = useRef(null)
  const dropRef      = useRef(null)

  const load = () => {
    setLoading(true)
    incidentService.getMine()
      .then(res => setIncidents(res.data?.data ?? res.data ?? []))
      .catch(() => setIncidents([]))
      .finally(() => setLoading(false))
  }
  useEffect(() => { load() }, [])

  /* ── URL Params Handle ── */
  const [searchParams] = useSearchParams()
  useEffect(() => {
    const id = searchParams.get('id')
    if (id) {
      // Intentamos buscarlo en la lista actual
      const found = incidents.find(x => String(x.id) === String(id))
      if (found) {
        setViewingInc(found)
      } else if (!loading && incidents.length > 0) {
        // Si no está y ya terminó de cargar, intentamos traerlo directo
        incidentService.getById(id)
          .then(res => setViewingInc(res.data?.data ?? res.data))
          .catch(() => {})
      }
    }
  }, [searchParams, incidents, loading])

  /* ── AI Classification ── */
  const classifyDescription = useCallback(async (desc) => {
    if (desc.length < 30) { setSuggestion(null); return }
    setClassifying(true); setSuggApplied(false)
    try {
      const res = await aiService.classify({ description: desc })
      const data = res.data
      if (data?.type || data?.priority)
        setSuggestion({ type: data.type ?? null, priority: data.priority ?? null, confidence: data.confidence ?? null })
    } catch { setSuggestion(null) }
    finally { setClassifying(false) }
  }, [])

  const handleDesc = (e) => {
    const val = e.target.value
    setForm(f => ({ ...f, description: val }))
    setSuggApplied(false)
    if (debounceRef.current) clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(() => classifyDescription(val), 1200)
  }

  const applySuggestion = () => {
    if (!suggestion) return
    setForm(f => ({ ...f, type: suggestion.type ?? f.type, priority: suggestion.priority ?? f.priority }))
    setSuggApplied(true)
    toast.success('Sugerencia de IA aplicada ✨')
  }

  /* ── File Handling ── */
  const addFiles = (newFiles) => {
    const arr = Array.from(newFiles)
    const valid = arr.filter(f => {
      if (f.size > MAX_SIZE_MB * 1024 * 1024) { toast.error(`${f.name} supera ${MAX_SIZE_MB}MB`); return false }
      return true
    })
    setFiles(prev => {
      const combined = [...prev, ...valid]
      if (combined.length > MAX_FILES) { toast.error(`Máximo ${MAX_FILES} archivos`); return prev.slice(0, MAX_FILES) }
      return combined.slice(0, MAX_FILES)
    })
  }

  const handleDrop = (e) => {
    e.preventDefault(); setDragOver(false)
    addFiles(e.dataTransfer.files)
  }

  /* ── GPS ── */
  const detectGPS = () => {
    if (!navigator.geolocation) { toast.error('GPS no soportado'); return }
    setGpsLoading(true)
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setForm(f => ({ ...f, latitude: pos.coords.latitude.toFixed(6), longitude: pos.coords.longitude.toFixed(6) }))
        toast.success('📍 Ubicación GPS detectada')
        setGpsLoading(false)
      },
      () => { toast.error('No se pudo obtener GPS'); setGpsLoading(false) },
      { enableHighAccuracy: true, timeout: 10000 }
    )
  }

  /* ── Submit ── */
  const handleSubmit = async (e) => {
    e.preventDefault()
    setSaving(true)
    try {
      // 1. Subir archivos primero si hay
      let imageUrls = []
      if (files.length > 0) {
        const uploadRes = await incidentService.uploadFiles(files)
        imageUrls = uploadRes.data?.data?.urls ?? uploadRes.data?.urls ?? []
      }

      // 2. Crear el incidente con las URLs ya resueltas
      await incidentService.create({
        ...form,
        latitude:  form.latitude  ? parseFloat(form.latitude)  : null,
        longitude: form.longitude ? parseFloat(form.longitude) : null,
        imageUrls,
      })

      toast.success('✅ Incidente reportado correctamente')
      setShowForm(false); setForm(emptyForm); setFiles([]); setSuggestion(null); setActiveTab('form')
      load()
    } catch {
      toast.error('Error al reportar el incidente')
    } finally {
      setSaving(false)
    }
  }

  const closeForm = () => { setShowForm(false); setSuggestion(null); setFiles([]); setActiveTab('form') }

  /* ── Filtered list ── */
  const filtered = incidents.filter(inc => {
    const matchStatus = filterStatus === 'ALL' || inc.status === filterStatus
    const matchSearch = !search ||
      inc.type?.toLowerCase().includes(search.toLowerCase()) ||
      inc.description?.toLowerCase().includes(search.toLowerCase())
    return matchStatus && matchSearch
  })

  return (
    <div style={{ padding: '0 0 32px', fontFamily: "'DM Sans', system-ui, sans-serif", minHeight: '100%', background: '#F8FAFC' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700;800;900&display=swap');
        @keyframes fadeUp   { from{opacity:0;transform:translateY(16px)} to{opacity:1;transform:translateY(0)} }
        @keyframes modalIn  { from{opacity:0;transform:scale(0.96) translateY(16px)} to{opacity:1;transform:scale(1) translateY(0)} }
        @keyframes slideIn  { from{opacity:0;transform:translateX(-8px)} to{opacity:1;transform:translateX(0)} }
        @keyframes spin     { to{transform:rotate(360deg)} }
        .inc-fade  { animation: fadeUp 400ms ease-out both; }
        .s1{animation-delay:0ms} .s2{animation-delay:60ms}
        .modal-inner { animation: modalIn 350ms cubic-bezier(0.16,1,0.3,1) both; }
        .inc-row { transition: all 0.2s; border-bottom: 1px solid #F1F5F9; cursor: pointer; }
        .inc-row:hover { background: #F0F7FF !important; }
        .inc-row:last-child { border-bottom: none; }
        .tab-btn   { transition: all 0.2s; cursor: pointer; border: none; background: none; }
        .filter-chip { transition: all 0.2s; cursor: pointer; border: none; }
        .drop-zone { transition: all 0.3s; }
        .drop-zone.active { border-color: #3B82F6 !important; background: rgba(59,130,246,0.04) !important; }
        .file-input { display: none; }
        .ai-badge { animation: slideIn 300ms ease-out both; }
        select.input-sel {
          appearance: none; width: 100%; padding: 10px 14px;
          background: #F8FAFC; border: 1px solid #E2E8F0;
          border-radius: 12px; font-size: 13px; color: #0F172A;
          font-family: inherit; cursor: pointer; outline: none; transition: all 0.2s;
        }
        select.input-sel:focus { border-color: #3B82F6; box-shadow: 0 0 0 3px rgba(59,130,246,0.12); }
        .text-input {
          width: 100%; padding: 10px 14px; background: #F8FAFC;
          border: 1px solid #E2E8F0; border-radius: 12px; font-size: 13px;
          color: #0F172A; font-family: inherit; outline: none; resize: none;
          transition: all 0.2s; box-sizing: border-box;
        }
        .text-input:focus { border-color: #3B82F6; box-shadow: 0 0 0 3px rgba(59,130,246,0.12); background: #fff; }
        .text-input::placeholder { color: #CBD5E1; }
      `}</style>

      {/* ── Header ── */}
      <div style={{ padding: '20px 16px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
        <div>
          <h1 style={{ fontSize: 20, fontWeight: 800, color: '#0F172A', letterSpacing: '-0.02em' }}>Mis Reportes</h1>
          <p style={{ fontSize: 12, color: '#94A3B8', marginTop: 2 }}>{incidents.length} incidente{incidents.length !== 1 ? 's' : ''} registrado{incidents.length !== 1 ? 's' : ''}</p>
        </div>
        <button onClick={() => setShowForm(true)}
          style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '10px 18px', borderRadius: 12, background: 'linear-gradient(135deg, #1D4ED8, #3B82F6)', color: '#fff', fontWeight: 700, fontSize: 13, border: 'none', cursor: 'pointer', boxShadow: '0 4px 16px rgba(29,78,216,0.3)', fontFamily: 'inherit' }}>
          <Plus size={14} /> Reportar
        </button>
      </div>

      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 14 }}>

        {/* ── Search & Filter ── */}
        <div className="inc-fade s1" style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <div style={{ position: 'relative' }}>
            <Search size={14} style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: '#CBD5E1' }} />
            <input className="text-input" value={search} onChange={e => setSearch(e.target.value)}
              placeholder="Buscar por tipo o descripción..." style={{ paddingLeft: 36 }} />
          </div>
          <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 4 }}>
            {[['ALL','Todos'],['PENDING','Pendientes'],['IN_PROGRESS','En progreso'],['RESOLVED','Resueltos'],['REJECTED','Rechazados']].map(([val, label]) => (
              <button key={val} className="filter-chip" onClick={() => setFilterStatus(val)}
                style={{ padding: '6px 14px', borderRadius: 100, fontSize: 12, fontWeight: 600, whiteSpace: 'nowrap', background: filterStatus === val ? '#1D4ED8' : '#fff', color: filterStatus === val ? '#fff' : '#64748B', border: filterStatus === val ? '1px solid #1D4ED8' : '1px solid #E2E8F0', fontFamily: 'inherit' }}>
                {label}
              </button>
            ))}
          </div>
        </div>

        {/* ── Lista de incidentes ── */}
        <div className="inc-fade s2">
          {loading ? (
            <div style={{ padding: 48, textAlign: 'center' }}>
              <Loader2 size={24} style={{ color: '#CBD5E1', animation: 'spin 1s linear infinite', display: 'inline-block' }} />
            </div>
          ) : filtered.length === 0 ? (
            <div style={{ padding: '48px 20px', textAlign: 'center', background: '#fff', borderRadius: 20, border: '1px solid #F1F5F9' }}>
              <div style={{ width: 56, height: 56, borderRadius: 18, background: '#F8FAFC', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 14px' }}>
                <AlertTriangle size={24} style={{ color: '#CBD5E1' }} />
              </div>
              <p style={{ fontSize: 15, fontWeight: 700, color: '#475569', marginBottom: 6 }}>
                {search || filterStatus !== 'ALL' ? 'Sin resultados' : 'Sin reportes aún'}
              </p>
              <p style={{ fontSize: 13, color: '#94A3B8', marginBottom: 20 }}>
                {search || filterStatus !== 'ALL' ? 'Intenta con otros filtros' : 'Sé el primero en reportar un incidente'}
              </p>
              {filterStatus === 'ALL' && !search && (
                <button onClick={() => setShowForm(true)}
                  style={{ display: 'inline-flex', alignItems: 'center', gap: 6, padding: '10px 20px', borderRadius: 12, background: '#1D4ED8', color: '#fff', fontSize: 13, fontWeight: 700, border: 'none', cursor: 'pointer', fontFamily: 'inherit' }}>
                  <Plus size={14} /> Hacer primer reporte
                </button>
              )}
            </div>
          ) : (
            <div style={{ background: '#fff', borderRadius: 20, border: '1px solid #F1F5F9', boxShadow: '0 1px 4px rgba(0,0,0,0.04)', overflow: 'hidden' }}>
              {filtered.map(inc => {
                const st = STATUS_MAP[inc.status] ?? STATUS_MAP.PENDING
                const pr = PRIORITY_COLOR[inc.priority] ?? PRIORITY_COLOR.MEDIUM
                const StIcon = st.icon
                const hasPhotos = inc.imageUrls?.length > 0
                return (
                  <div key={inc.id} className="inc-row" onClick={() => setViewingInc(inc)}
                    style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '14px 16px', background: '#fff' }}>
                    <div style={{ width: 42, height: 42, borderRadius: 14, background: st.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                      <StIcon size={18} style={{ color: st.color }} />
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3 }}>
                        <p style={{ fontSize: 13, fontWeight: 700, color: '#0F172A' }}>{inc.type}</p>
                        <span style={{ fontSize: 9, fontWeight: 700, padding: '2px 7px', borderRadius: 6, color: pr.color, background: pr.bg, textTransform: 'uppercase', letterSpacing: '0.04em' }}>{pr.label}</span>
                        {hasPhotos && (
                          <span style={{ fontSize: 9, fontWeight: 700, padding: '2px 7px', borderRadius: 6, color: '#3B82F6', background: 'rgba(59,130,246,0.1)', display: 'flex', alignItems: 'center', gap: 3 }}>
                            <Image size={8} /> {inc.imageUrls.length}
                          </span>
                        )}
                      </div>
                      <p style={{ fontSize: 12, color: '#94A3B8', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 200 }}>
                        {inc.description || inc.location || 'Sin descripción'}
                      </p>
                      {inc.location && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginTop: 3 }}>
                          <MapPin size={10} style={{ color: '#CBD5E1' }} />
                          <span style={{ fontSize: 10, color: '#CBD5E1' }}>{inc.location}</span>
                        </div>
                      )}
                    </div>
                    <div style={{ textAlign: 'right', flexShrink: 0, display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 4 }}>
                      <span style={{ fontSize: 11, color: st.color, fontWeight: 700 }}>{st.label}</span>
                      <ArrowRight size={12} style={{ color: '#CBD5E1' }} />
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </div>
      </div>

      {/* ── Modal detalle ciudadano ── */}
      {viewingInc && <IncidentDetailModal inc={viewingInc} onClose={() => setViewingInc(null)} />}

      {/* ── Modal nuevo reporte ── */}
      {showForm && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'flex-end', justifyContent: 'center', zIndex: 1000, backdropFilter: 'blur(4px)' }}
          onClick={e => e.target === e.currentTarget && closeForm()}>
          <div className="modal-inner" style={{ background: '#fff', borderRadius: '24px 24px 0 0', width: '100%', maxWidth: 520, maxHeight: '85vh', overflow: 'hidden', display: 'flex', flexDirection: 'column', boxShadow: '0 -20px 60px rgba(0,0,0,0.3)' }}>

            {/* Modal header */}
            <div style={{ padding: '20px 20px 0', flexShrink: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
                <div>
                  <h2 style={{ fontSize: 18, fontWeight: 800, color: '#0F172A', letterSpacing: '-0.02em' }}>Nuevo Reporte</h2>
                  <p style={{ fontSize: 12, color: '#94A3B8', marginTop: 2 }}>La IA analizará tu descripción automáticamente</p>
                </div>
                <button onClick={closeForm} style={{ width: 32, height: 32, borderRadius: 10, border: '1px solid #E2E8F0', background: '#F8FAFC', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <X size={14} style={{ color: '#64748B' }} />
                </button>
              </div>

              {/* Tabs */}
              <div style={{ display: 'flex', gap: 4, background: '#F8FAFC', borderRadius: 12, padding: 4, marginBottom: 4 }}>
                {[['form', 'Detalles', FileText], ['files', `Archivos (${files.length})`, Paperclip]].map(([tab, label, Icon]) => (
                  <button key={tab} className="tab-btn" onClick={() => setActiveTab(tab)}
                    style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, padding: '9px', borderRadius: 10, fontSize: 13, fontWeight: 600, color: activeTab === tab ? '#1D4ED8' : '#64748B', background: activeTab === tab ? '#fff' : 'transparent', boxShadow: activeTab === tab ? '0 1px 4px rgba(0,0,0,0.08)' : 'none', fontFamily: 'inherit' }}>
                    <Icon size={13} /> {label}
                  </button>
                ))}
              </div>
            </div>

            {/* Modal body */}
            <div style={{ flex: 1, overflowY: 'auto', padding: '16px 20px' }}>
              <form onSubmit={handleSubmit} id="incident-form">

                {activeTab === 'form' && (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                      <div>
                        <label style={{ display: 'block', fontSize: 11, fontWeight: 700, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 6 }}>Tipo</label>
                        <select className="input-sel" value={form.type} onChange={e => setForm({...form, type: e.target.value})}>
                          {INCIDENT_TYPES.map(t => <option key={t} value={t}>{t}</option>)}
                        </select>
                      </div>
                      <div>
                        <label style={{ display: 'block', fontSize: 11, fontWeight: 700, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 6 }}>Prioridad</label>
                        <select className="input-sel" value={form.priority} onChange={e => setForm({...form, priority: e.target.value})}>
                          <option value="LOW">Baja</option>
                          <option value="MEDIUM">Media</option>
                          <option value="HIGH">Alta</option>
                          <option value="CRITICAL">Crítica</option>
                        </select>
                      </div>
                    </div>

                    <div>
                      <label style={{ display: 'block', fontSize: 11, fontWeight: 700, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 6 }}>Descripción *</label>
                      <textarea className="text-input" rows={4} required value={form.description}
                        onChange={handleDesc}
                        placeholder="Describe lo que ocurrió con el mayor detalle posible..." />

                      {classifying && (
                        <div className="ai-badge" style={{ marginTop: 8, display: 'flex', alignItems: 'center', gap: 8, padding: '8px 12px', borderRadius: 10, background: 'rgba(59,130,246,0.06)', border: '1px solid rgba(59,130,246,0.15)' }}>
                          <Loader2 size={12} style={{ color: '#3B82F6', animation: 'spin 1s linear infinite' }} />
                          <span style={{ fontSize: 12, color: '#3B82F6', fontWeight: 600 }}>IA analizando descripción...</span>
                        </div>
                      )}

                      {suggestion && !classifying && (
                        <div className="ai-badge" style={{ marginTop: 8, padding: '10px 14px', borderRadius: 12, background: 'linear-gradient(135deg, rgba(139,92,246,0.06), rgba(59,130,246,0.04))', border: '1px solid rgba(139,92,246,0.2)' }}>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 8 }}>
                            <Sparkles size={12} style={{ color: '#8B5CF6' }} />
                            <span style={{ fontSize: 11, fontWeight: 700, color: '#6D28D9' }}>Sugerencia de IA</span>
                            {suggestion.confidence && <span style={{ fontSize: 10, color: '#8B5CF6', marginLeft: 'auto' }}>{Math.round(suggestion.confidence * 100)}% confianza</span>}
                          </div>
                          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 8 }}>
                            {suggestion.type && <span style={{ fontSize: 11, fontWeight: 700, padding: '3px 10px', borderRadius: 8, background: 'rgba(139,92,246,0.1)', color: '#7C3AED' }}>{suggestion.type}</span>}
                            {suggestion.priority && <span style={{ fontSize: 11, fontWeight: 700, padding: '3px 10px', borderRadius: 8, background: PRIORITY_COLOR[suggestion.priority]?.bg, color: PRIORITY_COLOR[suggestion.priority]?.color }}>{PRIORITY_COLOR[suggestion.priority]?.label}</span>}
                          </div>
                          {!suggApplied ? (
                            <button type="button" onClick={applySuggestion}
                              style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 12, fontWeight: 700, color: '#7C3AED', background: 'none', border: 'none', cursor: 'pointer', padding: 0, fontFamily: 'inherit' }}>
                              <Check size={12} /> Aplicar sugerencia
                            </button>
                          ) : (
                            <p style={{ fontSize: 11, color: '#10B981', fontWeight: 600, display: 'flex', alignItems: 'center', gap: 4 }}>
                              <Check size={11} /> Aplicada correctamente
                            </p>
                          )}
                        </div>
                      )}
                    </div>

                    {/* Ubicación */}
                    <div style={{ borderRadius: 16, border: '1px solid #E2E8F0', padding: 14, background: '#F8FAFC' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 12 }}>
                        <MapPin size={14} style={{ color: '#3B82F6' }} />
                        <span style={{ fontSize: 12, fontWeight: 700, color: '#0F172A' }}>Ubicación / Punto de Referencia *</span>
                      </div>
                      <button type="button" onClick={detectGPS} disabled={gpsLoading}
                        style={{ width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, padding: '11px', borderRadius: 12, background: gpsLoading ? '#E2E8F0' : 'linear-gradient(135deg, #1D4ED8, #3B82F6)', color: gpsLoading ? '#94A3B8' : '#fff', fontWeight: 700, fontSize: 13, border: 'none', cursor: gpsLoading ? 'not-allowed' : 'pointer', marginBottom: 12, fontFamily: 'inherit', transition: 'all 0.2s' }}>
                        {gpsLoading ? <><Loader2 size={14} style={{ animation: 'spin 1s linear infinite' }} /> Detectando GPS...</> : <><Navigation size={14} /> Usar mi ubicación GPS</>}
                      </button>

                      {form.latitude && form.longitude && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '8px 12px', borderRadius: 10, background: 'rgba(16,185,129,0.08)', border: '1px solid rgba(16,185,129,0.2)', marginBottom: 10 }}>
                          <MapPin size={12} style={{ color: '#10B981' }} />
                          <span style={{ fontSize: 11, color: '#065F46', fontWeight: 600, flex: 1 }}>📍 {form.latitude}, {form.longitude}</span>
                          <button type="button" onClick={() => setForm(f => ({...f, latitude:'', longitude:''}))}
                            style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#10B981', padding: 0 }}>
                            <X size={12} />
                          </button>
                        </div>
                      )}

                      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
                        <div style={{ flex: 1, height: 1, background: '#E2E8F0' }} />
                        <span style={{ fontSize: 11, color: '#CBD5E1' }}>o describe el punto de referencia</span>
                        <div style={{ flex: 1, height: 1, background: '#E2E8F0' }} />
                      </div>

                      <input className="text-input" required value={form.location}
                        onChange={e => setForm({...form, location: e.target.value})}
                        placeholder="Ej: Carrera 3 con Calle 10, Getsemaní" />
                    </div>
                  </div>
                )}

                {activeTab === 'files' && (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                    <div ref={dropRef}
                      className={`drop-zone ${dragOver ? 'active' : ''}`}
                      onDragOver={e => { e.preventDefault(); setDragOver(true) }}
                      onDragLeave={() => setDragOver(false)}
                      onDrop={handleDrop}
                      onClick={() => fileInputRef.current?.click()}
                      style={{ border: `2px dashed ${dragOver ? '#3B82F6' : '#E2E8F0'}`, borderRadius: 16, padding: '32px 20px', textAlign: 'center', cursor: 'pointer', background: dragOver ? 'rgba(59,130,246,0.04)' : '#F8FAFC' }}>
                      <input ref={fileInputRef} className="file-input" type="file" multiple
                        accept="image/*,.pdf,.doc,.docx,.txt"
                        onChange={e => addFiles(e.target.files)} />
                      <div style={{ width: 48, height: 48, borderRadius: 16, background: dragOver ? 'rgba(59,130,246,0.1)' : '#E2E8F0', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 12px' }}>
                        <Upload size={22} style={{ color: dragOver ? '#3B82F6' : '#94A3B8' }} />
                      </div>
                      <p style={{ fontSize: 14, fontWeight: 700, color: dragOver ? '#1D4ED8' : '#475569', marginBottom: 4 }}>
                        {dragOver ? 'Suelta aquí' : 'Arrastra archivos o haz clic'}
                      </p>
                      <p style={{ fontSize: 12, color: '#94A3B8' }}>Imágenes, PDF, documentos · Máx. {MAX_SIZE_MB}MB · {MAX_FILES} archivos</p>
                    </div>

                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
                      {[[Camera, 'Tomar foto', 'image/*', '#3B82F6'], [FileText, 'Adjuntar doc', '.pdf,.doc,.docx', '#8B5CF6']].map(([Icon, label, accept, color]) => (
                        <button key={label} type="button"
                          onClick={() => {
                            const inp = document.createElement('input')
                            inp.type = 'file'; inp.accept = accept; inp.multiple = true
                            inp.onchange = e => addFiles(e.target.files)
                            inp.click()
                          }}
                          style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '12px', borderRadius: 12, border: `1px solid ${color}25`, background: `${color}08`, cursor: 'pointer', fontFamily: 'inherit', fontSize: 13, fontWeight: 600, color }}>
                          <Icon size={14} /> {label}
                        </button>
                      ))}
                    </div>

                    {files.length > 0 && (
                      <div>
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
                          <p style={{ fontSize: 12, fontWeight: 700, color: '#475569' }}>{files.length} archivo{files.length !== 1 ? 's' : ''} seleccionado{files.length !== 1 ? 's' : ''}</p>
                          <button type="button" onClick={() => setFiles([])}
                            style={{ fontSize: 11, color: '#EF4444', fontWeight: 600, background: 'none', border: 'none', cursor: 'pointer', fontFamily: 'inherit' }}>
                            Eliminar todos
                          </button>
                        </div>
                        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
                          {files.map((f, i) => (
                            <FilePreview key={i} file={f} onRemove={() => setFiles(prev => prev.filter((_, j) => j !== i))} />
                          ))}
                        </div>
                      </div>
                    )}

                    {files.length === 0 && (
                      <div style={{ padding: '20px', textAlign: 'center', borderRadius: 12, background: 'rgba(59,130,246,0.04)', border: '1px solid rgba(59,130,246,0.1)' }}>
                        <Image size={24} style={{ color: '#CBD5E1', display: 'block', margin: '0 auto 8px' }} />
                        <p style={{ fontSize: 12, color: '#94A3B8' }}>Sin archivos adjuntos. Las imágenes ayudan a procesar el reporte más rápido.</p>
                      </div>
                    )}
                  </div>
                )}
              </form>
            </div>

            {/* Modal footer */}
            <div style={{ padding: '14px 20px', borderTop: '1px solid #F1F5F9', display: 'flex', gap: 10, flexShrink: 0, background: '#fff' }}>
              <button type="button" onClick={closeForm}
                style={{ flex: 1, padding: '12px', borderRadius: 12, border: '1px solid #E2E8F0', background: '#F8FAFC', color: '#64748B', fontWeight: 600, fontSize: 14, cursor: 'pointer', fontFamily: 'inherit' }}>
                Cancelar
              </button>
              <button type="submit" form="incident-form" disabled={saving}
                style={{ flex: 2, padding: '12px', borderRadius: 12, background: saving ? '#93C5FD' : 'linear-gradient(135deg, #1D4ED8, #3B82F6)', color: '#fff', fontWeight: 700, fontSize: 14, border: 'none', cursor: saving ? 'not-allowed' : 'pointer', fontFamily: 'inherit', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, boxShadow: '0 4px 16px rgba(29,78,216,0.25)', transition: 'all 0.2s' }}>
                {saving
                  ? <><Loader2 size={14} style={{ animation: 'spin 1s linear infinite' }} /> {files.length > 0 ? 'Subiendo archivos...' : 'Enviando...'}</>
                  : <><Zap size={14} /> Enviar Reporte {files.length > 0 ? `· ${files.length} archivo${files.length > 1 ? 's' : ''}` : ''}</>
                }
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
