import { useEffect, useState } from 'react'
import { emergencyService } from '@/Services/Services'
import { Phone, Plus, X, Loader2, Shield, Flame, Heart, Anchor, AlertTriangle } from 'lucide-react'
import toast from 'react-hot-toast'

const TYPE_CONFIG = {
  POLICE:       { label: 'Policía',        icon: Shield,        color: '#3B82F6', bg: 'rgba(59,130,246,0.08)',  border: 'rgba(59,130,246,0.15)'  },
  FIRE_STATION: { label: 'Bomberos',        icon: Flame,         color: '#F97316', bg: 'rgba(249,115,22,0.08)', border: 'rgba(249,115,22,0.15)'  },
  HOSPITAL:     { label: 'Hospital',        icon: Heart,         color: '#10B981', bg: 'rgba(16,185,129,0.08)', border: 'rgba(16,185,129,0.15)'  },
  AMBULANCE:    { label: 'Ambulancia',      icon: Heart,         color: '#EF4444', bg: 'rgba(239,68,68,0.08)',  border: 'rgba(239,68,68,0.15)'   },
  COAST_GUARD:  { label: 'Guardia Costera', icon: Anchor,        color: '#06B6D4', bg: 'rgba(6,182,212,0.08)', border: 'rgba(6,182,212,0.15)'   },
  OTHER:        { label: 'Otro',            icon: AlertTriangle, color: '#8B5CF6', bg: 'rgba(139,92,246,0.08)', border: 'rgba(139,92,246,0.15)'  },
}

const emptyForm = { name: '', phone: '', type: 'POLICE', address: '' }

export default function AdminEmergency() {
  const [contacts, setContacts] = useState([])
  const [loading, setLoading]   = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [form, setForm]         = useState(emptyForm)
  const [saving, setSaving]     = useState(false)

  const load = () => {
    setLoading(true)
    emergencyService.getAll()
      .then(r => setContacts(r.data?.data ?? r.data ?? []))
      .catch(() => setContacts([]))
      .finally(() => setLoading(false))
  }
  useEffect(() => { load() }, [])

  const handleSubmit = async e => {
    e.preventDefault(); setSaving(true)
    try { await emergencyService.create(form); toast.success('Contacto creado ✅'); setShowForm(false); setForm(emptyForm); load() }
    catch { toast.error('Error al crear contacto') }
    finally { setSaving(false) }
  }

  const handleDelete = async id => {
    if (!confirm('¿Eliminar este contacto?')) return
    try { await emergencyService.delete(id); toast.success('Contacto eliminado'); load() }
    catch { toast.error('Error al eliminar') }
  }

  return (
    <div style={{ padding: '20px 16px 32px', fontFamily: "'DM Sans', system-ui, sans-serif", background: '#F8FAFC', minHeight: '100%' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700;800&display=swap');
        @keyframes fadeUp { from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)} }
        @keyframes modalIn { from{opacity:0;transform:scale(0.97) translateY(20px)}to{opacity:1;transform:scale(1) translateY(0)} }
        .ae-fade { animation: fadeUp 400ms ease-out both; }
        .s1{animation-delay:0ms}.s2{animation-delay:60ms}.s3{animation-delay:120ms}
        .em-card { transition: all 0.25s; }
        .em-card:hover { transform: translateY(-2px); box-shadow: 0 8px 24px rgba(0,0,0,0.08) !important; }
        .modal-inner { animation: modalIn 300ms cubic-bezier(0.16,1,0.3,1) both; }
        .admin-input { width:100%;padding:10px 14px;background:#F8FAFC;border:1px solid #E2E8F0;border-radius:12px;font-size:13px;color:#0F172A;font-family:inherit;outline:none;transition:all 0.2s;box-sizing:border-box; }
        .admin-input:focus { border-color:#3B82F6;box-shadow:0 0 0 3px rgba(59,130,246,0.12); }
        .admin-sel { appearance:none;width:100%;padding:10px 14px;background:#F8FAFC;border:1px solid #E2E8F0;border-radius:12px;font-size:13px;color:#0F172A;font-family:inherit;outline:none;cursor:pointer; }
        .admin-sel:focus { border-color:#3B82F6;box-shadow:0 0 0 3px rgba(59,130,246,0.12); }
        .call-btn { text-decoration:none;transition:all 0.2s; }
        .call-btn:hover { filter:brightness(1.1);transform:scale(1.02); }
      `}</style>

      {/* Header */}
      <div className="ae-fade s1" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
        <div>
          <h1 style={{ fontSize: 22, fontWeight: 900, color: '#0F172A', letterSpacing: '-0.02em', marginBottom: 2 }}>Emergencias</h1>
          <p style={{ fontSize: 13, color: '#94A3B8' }}>{contacts.length} contactos registrados</p>
        </div>
        <button onClick={() => setShowForm(true)}
          style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '9px 16px', borderRadius: 12, background: 'linear-gradient(135deg, #1D4ED8, #3B82F6)', color: '#fff', fontWeight: 700, fontSize: 13, border: 'none', cursor: 'pointer', fontFamily: 'inherit', boxShadow: '0 4px 12px rgba(29,78,216,0.25)' }}>
          <Plus size={14} /> Nuevo
        </button>
      </div>

      {/* Contacts grid */}
      {loading ? (
        <div style={{ padding: 48, textAlign: 'center' }}>
          <Loader2 size={22} style={{ color: '#CBD5E1', animation: 'spin 1s linear infinite', display: 'inline-block' }} />
        </div>
      ) : contacts.length === 0 ? (
        <div className="ae-fade s2" style={{ padding: '48px 20px', textAlign: 'center', background: '#fff', borderRadius: 20, border: '1px solid #F1F5F9' }}>
          <Phone size={28} style={{ color: '#E2E8F0', display: 'block', margin: '0 auto 12px' }} />
          <p style={{ fontSize: 14, color: '#94A3B8', fontWeight: 600, marginBottom: 16 }}>Sin contactos registrados</p>
          <button onClick={() => setShowForm(true)} style={{ padding: '10px 20px', borderRadius: 12, background: '#1D4ED8', color: '#fff', fontWeight: 700, fontSize: 13, border: 'none', cursor: 'pointer', fontFamily: 'inherit' }}>
            Agregar primer contacto
          </button>
        </div>
      ) : (
        <div className="ae-fade s2" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: 12 }}>
          {contacts.map((c, i) => {
            const cfg = TYPE_CONFIG[c.type] ?? TYPE_CONFIG.OTHER
            const Icon = cfg.icon
            return (
              <div key={c.id} className="em-card"
                style={{ background: '#fff', borderRadius: 18, border: `1px solid ${cfg.border}`, padding: '16px', boxShadow: '0 1px 4px rgba(0,0,0,0.04)', display: 'flex', alignItems: 'center', gap: 14 }}>
                <div style={{ width: 46, height: 46, borderRadius: 15, background: cfg.bg, border: `1px solid ${cfg.border}`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <Icon size={20} style={{ color: cfg.color }} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <p style={{ fontSize: 14, fontWeight: 700, color: '#0F172A', marginBottom: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{c.name}</p>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <span style={{ fontSize: 10, fontWeight: 700, padding: '2px 7px', borderRadius: 6, background: cfg.bg, color: cfg.color }}>{cfg.label}</span>
                    {c.address && <span style={{ fontSize: 11, color: '#94A3B8', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 100 }}>{c.address}</span>}
                  </div>
                </div>
                <a href={`tel:${c.phone}`} className="call-btn"
                  style={{ padding: '8px 14px', borderRadius: 10, background: cfg.color, color: '#fff', fontSize: 12, fontWeight: 700, boxShadow: `0 4px 12px ${cfg.color}30`, flexShrink: 0, display: 'flex', alignItems: 'center', gap: 5 }}>
                  <Phone size={12} /> {c.phone}
                </a>
                <button onClick={() => handleDelete(c.id)}
                  style={{ width: 28, height: 28, borderRadius: 9, border: 'none', background: 'rgba(239,68,68,0.08)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <X size={12} style={{ color: '#EF4444' }} />
                </button>
              </div>
            )
          })}
        </div>
      )}

      {/* Modal */}
      {showForm && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'flex-end', justifyContent: 'center', zIndex: 1000, backdropFilter: 'blur(4px)' }}
          onClick={e => e.target === e.currentTarget && setShowForm(false)}>
          <div className="modal-inner" style={{ background: '#fff', borderRadius: '24px 24px 0 0', width: '100%', maxWidth: 480, display: 'flex', flexDirection: 'column' }}>
            <div style={{ padding: '18px 20px', borderBottom: '1px solid #F1F5F9', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <h2 style={{ fontSize: 17, fontWeight: 800, color: '#0F172A' }}>Nuevo Contacto</h2>
              <button onClick={() => setShowForm(false)} style={{ width: 30, height: 30, borderRadius: 9, border: '1px solid #E2E8F0', background: '#F8FAFC', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <X size={13} style={{ color: '#64748B' }} />
              </button>
            </div>
            <form onSubmit={handleSubmit} style={{ padding: '16px 20px', display: 'flex', flexDirection: 'column', gap: 12 }}>
              <div>
                <label style={{ display: 'block', fontSize: 11, fontWeight: 700, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 6 }}>Nombre *</label>
                <input className="admin-input" required value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder="Ej: Policía Nacional" />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: 11, fontWeight: 700, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 6 }}>Teléfono *</label>
                <input className="admin-input" required value={form.phone} onChange={e => setForm({...form, phone: e.target.value})} placeholder="123" />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: 11, fontWeight: 700, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 6 }}>Tipo</label>
                <select className="admin-sel" value={form.type} onChange={e => setForm({...form, type: e.target.value})}>
                  {Object.entries(TYPE_CONFIG).map(([val, cfg]) => <option key={val} value={val}>{cfg.label}</option>)}
                </select>
              </div>
              <div>
                <label style={{ display: 'block', fontSize: 11, fontWeight: 700, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 6 }}>Dirección</label>
                <input className="admin-input" value={form.address} onChange={e => setForm({...form, address: e.target.value})} placeholder="Dirección (opcional)" />
              </div>
              <div style={{ display: 'flex', gap: 10, paddingTop: 4 }}>
                <button type="button" onClick={() => setShowForm(false)} style={{ flex: 1, padding: '12px', borderRadius: 12, border: '1px solid #E2E8F0', background: '#F8FAFC', color: '#64748B', fontWeight: 600, fontSize: 14, cursor: 'pointer', fontFamily: 'inherit' }}>Cancelar</button>
                <button type="submit" disabled={saving} style={{ flex: 2, padding: '12px', borderRadius: 12, background: 'linear-gradient(135deg, #1D4ED8, #3B82F6)', color: '#fff', fontWeight: 700, fontSize: 14, border: 'none', cursor: 'pointer', fontFamily: 'inherit', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
                  {saving ? <Loader2 size={14} style={{ animation: 'spin 1s linear infinite' }} /> : <><Plus size={14} /> Crear Contacto</>}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
