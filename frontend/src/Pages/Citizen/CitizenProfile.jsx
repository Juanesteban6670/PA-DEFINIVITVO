import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { User, Mail, Phone, Shield, LogOut, Edit2, Check, X, Lock, ChevronRight, Bell, Globe } from 'lucide-react'
import useAuthStore from '@/Store/AuthStore'
import toast from 'react-hot-toast'

export default function CitizenProfile() {
  const { user, logout } = useAuthStore()
  const navigate = useNavigate()
  const [editing, setEditing] = useState(false)
  const [form, setForm] = useState({ fullName: user?.fullName ?? '', phone: user?.phone ?? '' })

  const handleLogout = () => { logout(); navigate('/login') }
  const handleSave = () => { toast.success('Perfil actualizado ✅'); setEditing(false) }

  const initial = user?.username?.[0]?.toUpperCase() ?? 'U'
  const colors  = ['#1D4ED8', '#7C3AED', '#DC2626', '#059669', '#D97706']
  const avatarColor = colors[user?.username?.charCodeAt(0) % colors.length] ?? '#1D4ED8'

  return (
    <div style={{ fontFamily: "'DM Sans', system-ui, sans-serif", padding: '0 0 40px', background: '#F8FAFC', minHeight: '100%' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700;800&display=swap');
        @keyframes fadeUp { from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)} }
        .prof-fade { animation: fadeUp 400ms ease-out both; }
        .s1{animation-delay:0ms}.s2{animation-delay:60ms}.s3{animation-delay:120ms}.s4{animation-delay:180ms}
        .prof-input { width:100%;padding:10px 14px;background:#F8FAFC;border:1px solid #E2E8F0;border-radius:12px;font-size:14px;color:#0F172A;font-family:inherit;outline:none;transition:all 0.2s;box-sizing:border-box; }
        .prof-input:focus { border-color:#3B82F6;box-shadow:0 0 0 3px rgba(59,130,246,0.12);background:#fff; }
        .menu-row { display:flex;align-items:center;gap:14px;padding:14px 16px;transition:all 0.2s;cursor:pointer;text-decoration:none;color:inherit; }
        .menu-row:hover { background:#F8FAFC; }
        .logout-btn { transition:all 0.2s;cursor:pointer;border:none;font-family:inherit; }
        .logout-btn:hover { background:rgba(239,68,68,0.08) !important; }
      `}</style>

      {/* Header */}
      <div style={{ background: 'linear-gradient(135deg, #0F172A, #1E3A5F)', padding: '28px 16px 60px', position: 'relative', overflow: 'hidden' }}>
        <div style={{ position: 'absolute', inset: 0, backgroundImage: 'radial-gradient(circle at 1px 1px, rgba(255,255,255,0.05) 1px, transparent 0)', backgroundSize: '24px 24px' }} />
        <div style={{ position: 'absolute', bottom: -50, right: -50, width: 180, height: 180, borderRadius: '50%', background: 'rgba(59,130,246,0.1)', filter: 'blur(20px)' }} />
        <div style={{ position: 'relative', textAlign: 'center' }}>
          <div style={{ width: 80, height: 80, borderRadius: '50%', background: `linear-gradient(135deg, ${avatarColor}, ${avatarColor}BB)`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 32, fontWeight: 800, color: '#fff', margin: '0 auto 12px', boxShadow: `0 8px 32px ${avatarColor}40`, border: '3px solid rgba(255,255,255,0.2)' }}>
            {initial}
          </div>
          <h2 style={{ fontSize: 18, fontWeight: 800, color: '#fff', letterSpacing: '-0.02em', marginBottom: 4 }}>{user?.username}</h2>
          <span style={{ fontSize: 11, fontWeight: 700, padding: '4px 12px', borderRadius: 100, background: 'rgba(255,255,255,0.1)', color: 'rgba(255,255,255,0.7)', border: '1px solid rgba(255,255,255,0.15)', textTransform: 'uppercase', letterSpacing: '0.08em' }}>Ciudadano</span>
        </div>
      </div>

      <div style={{ padding: '0 16px', marginTop: -28, display: 'flex', flexDirection: 'column', gap: 14 }}>

        {/* Info card */}
        <div className="prof-fade s1" style={{ background: '#fff', borderRadius: 20, border: '1px solid #F1F5F9', boxShadow: '0 4px 16px rgba(0,0,0,0.06)', overflow: 'hidden' }}>
          <div style={{ padding: '16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '1px solid #F8FAFC' }}>
            <p style={{ fontSize: 13, fontWeight: 700, color: '#0F172A' }}>Información personal</p>
            {!editing ? (
              <button onClick={() => setEditing(true)}
                style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 12, fontWeight: 700, color: '#1D4ED8', background: 'rgba(29,78,216,0.08)', border: 'none', padding: '6px 12px', borderRadius: 8, cursor: 'pointer', fontFamily: 'inherit' }}>
                <Edit2 size={11} /> Editar
              </button>
            ) : (
              <div style={{ display: 'flex', gap: 6 }}>
                <button onClick={handleSave}
                  style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 12, fontWeight: 700, color: '#10B981', background: 'rgba(16,185,129,0.08)', border: 'none', padding: '6px 12px', borderRadius: 8, cursor: 'pointer', fontFamily: 'inherit' }}>
                  <Check size={11} /> Guardar
                </button>
                <button onClick={() => setEditing(false)}
                  style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 12, fontWeight: 700, color: '#94A3B8', background: '#F8FAFC', border: 'none', padding: '6px 12px', borderRadius: 8, cursor: 'pointer', fontFamily: 'inherit' }}>
                  <X size={11} /> Cancelar
                </button>
              </div>
            )}
          </div>

          {[
            { icon: User,   label: 'Usuario',        value: user?.username,                    editable: false },
            { icon: Shield, label: 'Nombre completo', value: user?.fullName || 'No especificado', editable: true, key: 'fullName' },
            { icon: Mail,   label: 'Correo',          value: user?.email || 'No especificado',   editable: false },
            { icon: Phone,  label: 'Teléfono',        value: user?.phone || 'No especificado',   editable: true, key: 'phone' },
          ].map(({ icon: Icon, label, value, editable, key }, i) => (
            <div key={label} style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '14px 16px', borderBottom: i < 3 ? '1px solid #F8FAFC' : 'none' }}>
              <div style={{ width: 36, height: 36, borderRadius: 12, background: '#F1F5F9', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Icon size={15} style={{ color: '#64748B' }} />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <p style={{ fontSize: 10, color: '#94A3B8', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 3 }}>{label}</p>
                {editing && editable && key ? (
                  <input className="prof-input" value={form[key]}
                    onChange={e => setForm(f => ({...f, [key]: e.target.value}))}
                    placeholder={`Tu ${label.toLowerCase()}`} />
                ) : (
                  <p style={{ fontSize: 14, fontWeight: 600, color: value === 'No especificado' ? '#CBD5E1' : '#0F172A' }}>{value}</p>
                )}
              </div>
              {!editable && <Lock size={12} style={{ color: '#CBD5E1', flexShrink: 0 }} />}
            </div>
          ))}
        </div>

        {/* Menu options */}
        <div className="prof-fade s2" style={{ background: '#fff', borderRadius: 20, border: '1px solid #F1F5F9', overflow: 'hidden' }}>
          {[
            { icon: Bell,   label: 'Notificaciones',     sub: 'Configurar alertas',      color: '#8B5CF6' },
            { icon: Globe,  label: 'Idioma y región',    sub: 'Español (Colombia)',       color: '#06B6D4' },
            { icon: Shield, label: 'Privacidad',          sub: 'Gestionar mis datos',     color: '#10B981' },
          ].map(({ icon: Icon, label, sub, color }, i) => (
            <div key={label} className="menu-row" style={{ borderBottom: i < 2 ? '1px solid #F8FAFC' : 'none' }}>
              <div style={{ width: 36, height: 36, borderRadius: 12, background: `${color}10`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Icon size={15} style={{ color }} />
              </div>
              <div style={{ flex: 1 }}>
                <p style={{ fontSize: 14, fontWeight: 600, color: '#0F172A' }}>{label}</p>
                <p style={{ fontSize: 11, color: '#94A3B8' }}>{sub}</p>
              </div>
              <ChevronRight size={15} style={{ color: '#CBD5E1' }} />
            </div>
          ))}
        </div>

        {/* Logout */}
        <button className="prof-fade s3 logout-btn" onClick={handleLogout}
          style={{ width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, padding: '14px', borderRadius: 16, background: 'rgba(239,68,68,0.06)', border: '1px solid rgba(239,68,68,0.15)', color: '#EF4444', fontSize: 14, fontWeight: 700 }}>
          <LogOut size={15} /> Cerrar sesión
        </button>

        <p className="prof-fade s4" style={{ textAlign: 'center', fontSize: 11, color: '#CBD5E1' }}>Cartagena Segura v1.1.0 · 2026</p>
      </div>
    </div>
  )
}
