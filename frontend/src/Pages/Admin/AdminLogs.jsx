import { useEffect, useState } from 'react'
import { logService } from '@/Services/Services'
import { FileText, Loader2, RefreshCw, Search, Activity } from 'lucide-react'

const LEVEL_CONFIG = {
  INFO:  { color: '#3B82F6', bg: 'rgba(59,130,246,0.1)'  },
  WARN:  { color: '#F59E0B', bg: 'rgba(245,158,11,0.1)'  },
  ERROR: { color: '#EF4444', bg: 'rgba(239,68,68,0.1)'   },
  DEBUG: { color: '#94A3B8', bg: 'rgba(148,163,184,0.1)' },
}

export default function AdminLogs() {
  const [logs, setLogs]       = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch]   = useState('')
  const [level, setLevel]     = useState('ALL')

  const load = () => {
    setLoading(true)
    logService.getAll()
      .then(r => setLogs(r.data?.data ?? r.data ?? []))
      .catch(() => setLogs([]))
      .finally(() => setLoading(false))
  }
  useEffect(() => { load() }, [])

  const filtered = logs.filter(l => {
    const matchLevel = level === 'ALL' || (l.level ?? 'INFO') === level
    const matchSearch = !search || (l.message ?? l.action ?? '').toLowerCase().includes(search.toLowerCase()) || (l.userId ?? '').toLowerCase().includes(search.toLowerCase())
    return matchLevel && matchSearch
  })

  return (
    <div style={{ padding: '20px 16px 32px', fontFamily: "'DM Sans', system-ui, sans-serif", background: '#F8FAFC', minHeight: '100%' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700;800&display=swap');
        @keyframes fadeUp { from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)} }
        .log-fade { animation: fadeUp 400ms ease-out both; }
        .s1{animation-delay:0ms}.s2{animation-delay:60ms}.s3{animation-delay:120ms}
        .log-row { transition: background 0.15s; border-bottom: 1px solid #F8FAFC; }
        .log-row:hover { background: #F8FAFC !important; }
        .admin-input { width:100%;padding:10px 14px;background:#F8FAFC;border:1px solid #E2E8F0;border-radius:12px;font-size:13px;color:#0F172A;font-family:inherit;outline:none;transition:all 0.2s;box-sizing:border-box; }
        .admin-input:focus { border-color:#3B82F6;box-shadow:0 0 0 3px rgba(59,130,246,0.12); }
        .lvl-chip { transition: all 0.2s; cursor: pointer; border: none; font-family: inherit; }
      `}</style>

      {/* Header */}
      <div className="log-fade s1" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
        <div>
          <h1 style={{ fontSize: 22, fontWeight: 900, color: '#0F172A', letterSpacing: '-0.02em', marginBottom: 2 }}>Logs del Sistema</h1>
          <p style={{ fontSize: 13, color: '#94A3B8' }}>{logs.length} registros de actividad</p>
        </div>
        <button onClick={load} disabled={loading}
          style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '9px 14px', borderRadius: 12, border: '1px solid #E2E8F0', background: '#fff', color: '#64748B', fontWeight: 600, fontSize: 13, cursor: 'pointer', fontFamily: 'inherit', transition: 'all 0.2s' }}>
          <RefreshCw size={13} style={{ animation: loading ? 'spin 1s linear infinite' : 'none' }} /> Actualizar
        </button>
      </div>

      {/* Filters */}
      <div className="log-fade s2" style={{ display: 'flex', flexDirection: 'column', gap: 10, marginBottom: 16 }}>
        <div style={{ position: 'relative' }}>
          <Search size={14} style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: '#CBD5E1' }} />
          <input className="admin-input" value={search} onChange={e => setSearch(e.target.value)} placeholder="Buscar en logs..." style={{ paddingLeft: 36 }} />
        </div>
        <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 2 }}>
          {['ALL', 'INFO', 'WARN', 'ERROR', 'DEBUG'].map(l => {
            const cfg = LEVEL_CONFIG[l]
            return (
              <button key={l} className="lvl-chip" onClick={() => setLevel(l)}
                style={{ padding: '6px 14px', borderRadius: 100, fontSize: 12, fontWeight: 700, whiteSpace: 'nowrap', background: level === l ? (cfg?.color ?? '#1D4ED8') : '#fff', color: level === l ? '#fff' : '#64748B', border: level === l ? `1px solid ${cfg?.color ?? '#1D4ED8'}` : '1px solid #E2E8F0' }}>
                {l}
              </button>
            )
          })}
        </div>
      </div>

      {/* Logs */}
      <div className="log-fade s3" style={{ background: '#fff', borderRadius: 20, border: '1px solid #F1F5F9', overflow: 'hidden', fontFamily: 'inherit' }}>
        {loading ? (
          <div style={{ padding: 48, textAlign: 'center' }}><Loader2 size={22} style={{ color: '#CBD5E1', animation: 'spin 1s linear infinite', display: 'inline-block' }} /></div>
        ) : filtered.length === 0 ? (
          <div style={{ padding: '48px 20px', textAlign: 'center' }}>
            <FileText size={28} style={{ color: '#E2E8F0', display: 'block', margin: '0 auto 12px' }} />
            <p style={{ fontSize: 14, color: '#94A3B8', fontWeight: 600 }}>Sin logs</p>
          </div>
        ) : filtered.map((log, i) => {
          const cfg = LEVEL_CONFIG[log.level ?? 'INFO'] ?? LEVEL_CONFIG.INFO
          return (
            <div key={log.id ?? i} className="log-row" style={{ display: 'flex', alignItems: 'flex-start', gap: 12, padding: '12px 16px', background: '#fff' }}>
              <span style={{ fontSize: 10, fontWeight: 800, padding: '3px 8px', borderRadius: 6, background: cfg.bg, color: cfg.color, whiteSpace: 'nowrap', flexShrink: 0, marginTop: 1, letterSpacing: '0.04em' }}>
                {log.level ?? 'INFO'}
              </span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <p style={{ fontSize: 13, color: '#0F172A', lineHeight: 1.5, marginBottom: log.userId ? 3 : 0 }}>{log.message ?? log.action ?? 'Sin mensaje'}</p>
                {log.userId && <p style={{ fontSize: 11, color: '#94A3B8' }}>Usuario: {log.userId}</p>}
              </div>
              {log.createdAt && (
                <span style={{ fontSize: 10, color: '#CBD5E1', whiteSpace: 'nowrap', flexShrink: 0, marginTop: 2 }}>
                  {new Date(log.createdAt).toLocaleString('es-CO', { dateStyle: 'short', timeStyle: 'short' })}
                </span>
              )}
            </div>
          )
        })}
      </div>
    </div>
  )
}
