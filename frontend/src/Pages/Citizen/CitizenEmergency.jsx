import { useEffect, useState } from 'react'
import { Phone, Loader2, Shield, Flame, Heart, Anchor, AlertTriangle, ChevronRight } from 'lucide-react'
import { emergencyService } from '@/Services/Services'

const TYPE_CONFIG = {
  POLICE:      { label: 'Policía',         icon: Shield,        color: '#3B82F6', bg: 'rgba(59,130,246,0.08)',  border: 'rgba(59,130,246,0.15)'  },
  FIRE_STATION:{ label: 'Bomberos',         icon: Flame,         color: '#F97316', bg: 'rgba(249,115,22,0.08)', border: 'rgba(249,115,22,0.15)'  },
  HOSPITAL:    { label: 'Hospital',         icon: Heart,         color: '#10B981', bg: 'rgba(16,185,129,0.08)', border: 'rgba(16,185,129,0.15)'  },
  AMBULANCE:   { label: 'Ambulancia',       icon: Heart,         color: '#EF4444', bg: 'rgba(239,68,68,0.08)',  border: 'rgba(239,68,68,0.15)'   },
  COAST_GUARD: { label: 'Guardia Costera',  icon: Anchor,        color: '#06B6D4', bg: 'rgba(6,182,212,0.08)', border: 'rgba(6,182,212,0.15)'   },
  OTHER:       { label: 'Otro',             icon: AlertTriangle, color: '#8B5CF6', bg: 'rgba(139,92,246,0.08)', border: 'rgba(139,92,246,0.15)'  },
}

export default function CitizenEmergency() {
  const [contacts, setContacts] = useState([])
  const [loading, setLoading]   = useState(true)
  const [activeType, setActiveType] = useState('ALL')

  useEffect(() => {
    emergencyService.getAll()
      .then(res => setContacts(res.data?.data ?? res.data ?? []))
      .catch(() => setContacts([]))
      .finally(() => setLoading(false))
  }, [])

  const types = ['ALL', ...new Set(contacts.map(c => c.type).filter(Boolean))]
  const filtered = activeType === 'ALL' ? contacts : contacts.filter(c => c.type === activeType)

  return (
    <div style={{ fontFamily: "'DM Sans', system-ui, sans-serif", padding: '0 0 32px', background: '#F8FAFC', minHeight: '100%' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700;800&display=swap');
        @keyframes fadeUp { from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)} }
        .em-card { animation: fadeUp 400ms ease-out both; transition: all 0.2s; }
        .em-card:hover { transform: translateY(-2px); box-shadow: 0 8px 24px rgba(0,0,0,0.08) !important; }
        .call-btn { transition: all 0.2s; text-decoration: none; }
        .call-btn:hover { filter: brightness(1.1); transform: scale(1.03); }
        .type-chip { transition: all 0.2s; cursor: pointer; border: none; font-family: inherit; }
      `}</style>

      {/* Header banner */}
      <div style={{ background: 'linear-gradient(135deg, #7F1D1D 0%, #DC2626 60%, #EF4444 100%)', padding: '24px 16px 20px', position: 'relative', overflow: 'hidden' }}>
        <div style={{ position: 'absolute', inset: 0, backgroundImage: 'radial-gradient(circle at 1px 1px, rgba(255,255,255,0.07) 1px, transparent 0)', backgroundSize: '20px 20px' }} />
        <div style={{ position: 'absolute', top: -40, right: -40, width: 140, height: 140, borderRadius: '50%', background: 'rgba(255,255,255,0.06)' }} />
        <div style={{ position: 'relative' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
            <div style={{ width: 40, height: 40, borderRadius: 14, background: 'rgba(255,255,255,0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Phone size={20} style={{ color: '#fff' }} />
            </div>
            <div>
              <h1 style={{ fontSize: 18, fontWeight: 800, color: '#fff', letterSpacing: '-0.02em' }}>Emergencias</h1>
              <p style={{ fontSize: 11, color: 'rgba(255,255,255,0.6)' }}>{contacts.length} contactos disponibles</p>
            </div>
          </div>
          <p style={{ fontSize: 12, color: 'rgba(255,255,255,0.65)', lineHeight: 1.5 }}>
            Llama directamente desde la app. En caso de emergencia inmediata marca <strong style={{ color: '#fff' }}>123</strong>.
          </p>
        </div>
      </div>

      <div style={{ padding: '16px' }}>

        {/* Filter chips */}
        {types.length > 1 && (
          <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 4, marginBottom: 16 }}>
            {types.map(t => {
              const cfg = TYPE_CONFIG[t]
              return (
                <button key={t} className="type-chip" onClick={() => setActiveType(t)}
                  style={{ padding: '7px 14px', borderRadius: 100, fontSize: 12, fontWeight: 700, whiteSpace: 'nowrap', background: activeType === t ? (cfg?.color ?? '#1D4ED8') : '#fff', color: activeType === t ? '#fff' : '#64748B', border: activeType === t ? `1px solid ${cfg?.color ?? '#1D4ED8'}` : '1px solid #E2E8F0', boxShadow: activeType === t ? `0 4px 12px ${cfg?.color ?? '#1D4ED8'}30` : 'none' }}>
                  {t === 'ALL' ? 'Todos' : (cfg?.label ?? t)}
                </button>
              )
            })}
          </div>
        )}

        {loading ? (
          <div style={{ padding: 48, textAlign: 'center' }}>
            <Loader2 size={24} style={{ color: '#CBD5E1', animation: 'spin 1s linear infinite', display: 'inline-block' }} />
          </div>
        ) : filtered.length === 0 ? (
          <div style={{ padding: '48px 20px', textAlign: 'center', background: '#fff', borderRadius: 20, border: '1px solid #F1F5F9' }}>
            <Phone size={32} style={{ color: '#CBD5E1', display: 'block', margin: '0 auto 12px' }} />
            <p style={{ fontSize: 14, color: '#94A3B8', fontWeight: 600 }}>Sin contactos registrados</p>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {filtered.map((c, i) => {
              const cfg = TYPE_CONFIG[c.type] ?? TYPE_CONFIG.OTHER
              const Icon = cfg.icon
              return (
                <div key={c.id} className="em-card"
                  style={{ animationDelay: `${i * 50}ms`, background: '#fff', borderRadius: 18, border: `1px solid ${cfg.border}`, padding: '16px', boxShadow: '0 1px 4px rgba(0,0,0,0.04)', display: 'flex', alignItems: 'center', gap: 14 }}>
                  <div style={{ width: 48, height: 48, borderRadius: 16, background: cfg.bg, border: `1px solid ${cfg.border}`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                    <Icon size={22} style={{ color: cfg.color }} />
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <p style={{ fontSize: 14, fontWeight: 700, color: '#0F172A', marginBottom: 2 }}>{c.name}</p>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <span style={{ fontSize: 10, fontWeight: 700, padding: '2px 8px', borderRadius: 6, background: cfg.bg, color: cfg.color }}>{cfg.label}</span>
                      {c.address && <span style={{ fontSize: 11, color: '#94A3B8', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 120 }}>{c.address}</span>}
                    </div>
                  </div>
                  <a href={`tel:${c.phone}`} className="call-btn"
                    style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '10px 16px', borderRadius: 12, background: cfg.color, color: '#fff', fontSize: 13, fontWeight: 700, boxShadow: `0 4px 12px ${cfg.color}35`, flexShrink: 0 }}>
                    <Phone size={13} /> {c.phone}
                  </a>
                </div>
              )
            })}
          </div>
        )}

        {/* Emergency tip */}
        <div style={{ marginTop: 20, padding: '14px 16px', borderRadius: 16, background: 'rgba(239,68,68,0.06)', border: '1px solid rgba(239,68,68,0.15)', display: 'flex', gap: 12 }}>
          <AlertTriangle size={18} style={{ color: '#EF4444', flexShrink: 0, marginTop: 1 }} />
          <div>
            <p style={{ fontSize: 13, fontWeight: 700, color: '#991B1B', marginBottom: 2 }}>Línea nacional de emergencias</p>
            <p style={{ fontSize: 12, color: '#B91C1C', lineHeight: 1.5 }}>Para emergencias inmediatas marca <strong>123</strong> (Policía) o <strong>119</strong> (Salud) desde cualquier teléfono.</p>
          </div>
        </div>
      </div>
    </div>
  )
}
