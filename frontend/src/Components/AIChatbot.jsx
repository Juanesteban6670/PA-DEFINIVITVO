import { useState, useRef, useEffect, useCallback } from 'react'
import { MessageCircle, X, Send, Sparkles, Bot, User, AlertCircle, Trash2, ChevronDown } from 'lucide-react'
import { aiService } from '@/Services/Services'
import useAuthStore from '@/Store/AuthStore'

/* ── Helpers ─────────────────────────────────────────────────────────── */
function getInitials(name) {
  if (!name) return '?'
  const parts = name.split(' ')
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase()
  return name.slice(0, 2).toUpperCase()
}

function avatarColor(name) {
  const colors = ['#3B82F6', '#8B5CF6', '#EC4899', '#F59E0B', '#10B981']
  if (!name) return colors[0]
  let hash = 0
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash)
  return colors[Math.abs(hash) % colors.length]
}

const WELCOME = {
  role: 'assistant',
  content: '¡Hola! 👋 Soy el **Agente Inteligente de Cartagena Segura**. Mi misión es asistirte en la gestión de incidentes y seguridad ciudadana.\n\n¿En qué puedo apoyarte hoy?\n\n• Reportar un incidente\n• Consultar zonas de riesgo\n• Protocolos de emergencia',
}

function fmt(text) {
  return text
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\n/g, '<br/>')
    .replace(/• /g, '&bull;&nbsp;')
}

function genId() { return 'cs-' + Math.random().toString(36).slice(2) }

export default function AIChatbot() {
  const user = useAuthStore(s => s.user)
  const [open, setOpen]       = useState(false)
  const [msgs, setMsgs]       = useState([])
  const [input, setInput]     = useState('')
  const [loading, setLoading] = useState(false)
  const [sessionId]           = useState(genId)
  const bottomRef             = useRef(null)
  const inputRef              = useRef(null)

  // Mensaje de bienvenida personalizado
  useEffect(() => {
    const name = user?.fullName || user?.username || 'Ciudadano'
    setMsgs([{
      role: 'assistant',
      content: `¡Hola, **${name}**! 👋 Soy el **Agente Inteligente de Cartagena Segura**. Mi misión es asistirte en la gestión de incidentes y seguridad ciudadana.\n\n¿En qué puedo apoyarte hoy?\n\n• Reportar un incidente\n• Consultar zonas de riesgo\n• Protocolos de emergencia`,
    }])
  }, [user])

  useEffect(() => {
    if (open) {
      setTimeout(() => bottomRef.current?.scrollIntoView({ behavior: 'smooth' }), 100)
      setTimeout(() => inputRef.current?.focus(), 350)
    }
  }, [open, msgs])

  const send = async () => {
    const text = input.trim()
    if (!text || loading) return
    setMsgs(p => [...p, { role: 'user', content: text }])
    setInput('')
    setLoading(true)
    try {
      // Inyectamos el nombre del usuario en el mensaje para que la IA lo sepa si el backend no lo hace aún
      const userName = user?.fullName || user?.username || 'Ciudadano'
      const res = await aiService.chat({ 
        message: `(Usuario: ${userName}) ${text}`, 
        sessionId 
      })
      const reply = res.data?.reply ?? res.data?.message ?? res.data ?? 'Sin respuesta.'
      setMsgs(p => [...p, { role: 'assistant', content: typeof reply === 'string' ? reply : JSON.stringify(reply) }])
    } catch {
      setMsgs(p => [...p, { role: 'assistant', content: '⚠️ No pude conectarme con el asistente. Intenta de nuevo.', error: true }])
    } finally { setLoading(false) }
  }

  const onKey = (e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send() } }
  const clear = () => {
    const name = user?.fullName || user?.username || 'Ciudadano'
    setMsgs([{
      role: 'assistant',
      content: `¡Hola, **${name}**! 👋 Soy el **Agente Inteligente de Cartagena Segura**. Mi misión es asistirte en la gestión de incidentes y seguridad ciudadana.`,
    }])
  }

  return (
    <>
      {/* FAB */}
      {!open && (
        <button onClick={() => setOpen(true)}
          style={{ position: 'fixed', bottom: 80, right: 16, zIndex: 2000, width: 52, height: 52, borderRadius: 16, background: 'linear-gradient(135deg, #1D4ED8, #3B82F6)', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 8px 32px rgba(29,78,216,0.4)', fontFamily: 'inherit' }}
          className="animate-glow-pulse sm:bottom-6 sm:right-6">
          <MessageCircle size={22} style={{ color: '#fff' }} />
          <span style={{ position: 'absolute', top: -3, right: -3, width: 14, height: 14, borderRadius: '50%', background: '#34D399', border: '2px solid #fff' }} />
        </button>
      )}

      {/* Drawer */}
      {open && (
        <div style={{ position: 'fixed', inset: 0, zIndex: 2000, display: 'flex', justifyContent: 'flex-end', padding: '0' }}
          onClick={e => e.target === e.currentTarget && setOpen(false)}>
          <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', backdropFilter: 'blur(4px)' }} onClick={() => setOpen(false)} />

          <div className="animate-drawer-slide"
            style={{ position: 'relative', width: '100%', maxWidth: 400, height: '100%', display: 'flex', flexDirection: 'column', background: '#F8FAFC', boxShadow: '-8px 0 48px rgba(0,0,0,0.2)', fontFamily: "'DM Sans', system-ui, sans-serif" }}>

            {/* Header */}
            <div style={{ padding: '16px 16px 14px', background: 'linear-gradient(135deg, #1E3A5F, #1D4ED8)', borderBottom: '1px solid rgba(255,255,255,0.1)', display: 'flex', alignItems: 'center', gap: 12, flexShrink: 0 }}>
              <div style={{ width: 38, height: 38, borderRadius: 13, background: 'rgba(255,255,255,0.12)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Sparkles size={18} style={{ color: '#fff' }} />
              </div>
              <div style={{ flex: 1 }}>
                <p style={{ fontSize: 14, fontWeight: 800, color: '#fff', letterSpacing: '-0.01em' }}>Agente Cartagena Segura</p>
                <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                  <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#34D399' }} className="animate-pulse" />
                  <p style={{ fontSize: 10, color: 'rgba(255,255,255,0.7)' }}>IA Operativa • LLM v3.1</p>
                </div>
              </div>
              <div style={{ display: 'flex', gap: 6 }}>
                <button onClick={clear}
                  style={{ width: 30, height: 30, borderRadius: 9, background: 'rgba(255,255,255,0.1)', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
                  title="Limpiar chat">
                  <Trash2 size={12} style={{ color: 'rgba(255,255,255,0.7)' }} />
                </button>
                <button onClick={() => setOpen(false)}
                  style={{ width: 30, height: 30, borderRadius: 9, background: 'rgba(255,255,255,0.1)', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <ChevronDown size={14} style={{ color: '#fff' }} />
                </button>
              </div>
            </div>

            {/* Messages */}
            <div style={{ flex: 1, overflowY: 'auto', padding: '16px', display: 'flex', flexDirection: 'column', gap: 12 }}>
              {msgs.map((msg, i) => (
                <div key={i} className="animate-chat-slide-in"
                  style={{ display: 'flex', gap: 10, flexDirection: msg.role === 'user' ? 'row-reverse' : 'row', animationDelay: `${Math.min(i * 30, 200)}ms` }}>

                  <div style={{ 
                    width: 32, height: 32, borderRadius: 12, flexShrink: 0, display: 'flex', 
                    alignItems: 'center', justifyContent: 'center', marginTop: 2, 
                    background: msg.role === 'user' ? `${avatarColor(user?.fullName || user?.username)}15` : msg.error ? 'rgba(239,68,68,0.1)' : 'linear-gradient(135deg, #1D4ED8, #3B82F6)',
                    border: msg.role === 'user' ? `1px solid ${avatarColor(user?.fullName || user?.username)}30` : 'none'
                  }}>
                    {msg.role === 'user'
                      ? <span style={{ fontSize: 11, fontWeight: 800, color: avatarColor(user?.fullName || user?.username) }}>{getInitials(user?.fullName || user?.username)}</span>
                      : msg.error
                        ? <AlertCircle size={14} style={{ color: '#EF4444' }} />
                        : <Bot size={14} style={{ color: '#fff' }} />}
                  </div>

                  <div style={{ maxWidth: '80%', padding: '10px 14px', borderRadius: msg.role === 'user' ? '16px 4px 16px 16px' : '4px 16px 16px 16px', fontSize: 13, lineHeight: 1.6, background: msg.role === 'user' ? 'linear-gradient(135deg, #1D4ED8, #3B82F6)' : msg.error ? '#FEF2F2' : '#fff', color: msg.role === 'user' ? '#fff' : msg.error ? '#991B1B' : '#1E293B', border: msg.role === 'user' ? 'none' : msg.error ? '1px solid #FECACA' : '1px solid #F1F5F9', boxShadow: msg.role === 'user' ? '0 4px 12px rgba(29,78,216,0.2)' : '0 1px 4px rgba(0,0,0,0.06)' }}
                    dangerouslySetInnerHTML={{ __html: fmt(msg.content) }} />
                </div>
              ))}

              {loading && (
                <div className="animate-chat-slide-in" style={{ display: 'flex', gap: 10 }}>
                  <div style={{ width: 28, height: 28, borderRadius: 10, background: 'linear-gradient(135deg, #1D4ED8, #3B82F6)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                    <Bot size={13} style={{ color: '#fff' }} />
                  </div>
                  <div style={{ padding: '12px 16px', borderRadius: '4px 16px 16px 16px', background: '#fff', border: '1px solid #F1F5F9', display: 'flex', gap: 5, alignItems: 'center' }}>
                    <span className="typing-dot" style={{ width: 7, height: 7, borderRadius: '50%', background: '#3B82F6', display: 'inline-block' }} />
                    <span className="typing-dot" style={{ width: 7, height: 7, borderRadius: '50%', background: '#3B82F6', display: 'inline-block' }} />
                    <span className="typing-dot" style={{ width: 7, height: 7, borderRadius: '50%', background: '#3B82F6', display: 'inline-block' }} />
                  </div>
                </div>
              )}
              <div ref={bottomRef} />
            </div>

            {/* Quick suggestions */}
            {msgs.length <= 1 && (
              <div style={{ padding: '0 16px 12px', display: 'flex', gap: 6, overflowX: 'auto', flexShrink: 0 }}>
                {['¿Cómo reportar?', '¿Qué es zona de riesgo?', 'Emergencias disponibles'].map(s => (
                  <button key={s} onClick={() => { setInput(s); inputRef.current?.focus() }}
                    style={{ padding: '6px 12px', borderRadius: 100, fontSize: 11, fontWeight: 600, color: '#1D4ED8', background: 'rgba(29,78,216,0.06)', border: '1px solid rgba(29,78,216,0.15)', cursor: 'pointer', whiteSpace: 'nowrap', fontFamily: 'inherit' }}>
                    {s}
                  </button>
                ))}
              </div>
            )}

            {/* Input */}
            <div style={{ padding: '14px 16px', borderTop: '1px solid #F1F5F9', background: '#fff', flexShrink: 0 }}>
              <div style={{ 
                display: 'flex', gap: 10, alignItems: 'center', background: '#F8FAFC', 
                borderRadius: 20, padding: '6px 6px 6px 16px', border: '1px solid #E2E8F0', 
                transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                boxShadow: 'inset 0 1px 2px rgba(0,0,0,0.02)'
              }}
                onFocusCapture={e => {
                  e.currentTarget.style.borderColor = '#3B82F6'
                  e.currentTarget.style.boxShadow = '0 0 0 4px rgba(59,130,246,0.1)'
                  e.currentTarget.style.background = '#fff'
                }}
                onBlurCapture={e => {
                  e.currentTarget.style.borderColor = '#E2E8F0'
                  e.currentTarget.style.boxShadow = 'inset 0 1px 2px rgba(0,0,0,0.02)'
                  e.currentTarget.style.background = '#F8FAFC'
                }}>
                <textarea ref={inputRef} value={input} onChange={e => setInput(e.target.value)} onKeyDown={onKey}
                  placeholder="Escribe tu mensaje..." disabled={loading} rows={1}
                  style={{ 
                    flex: 1, background: 'none', border: 'none', outline: 'none', 
                    fontSize: 14, color: '#0F172A', fontFamily: 'inherit', resize: 'none', 
                    lineHeight: 1.5, maxHeight: 100, padding: '8px 0', overflowY: 'auto' 
                  }} />
                <button onClick={send} disabled={!input.trim() || loading}
                  style={{ 
                    width: 38, height: 38, borderRadius: 16, 
                    background: input.trim() && !loading ? 'linear-gradient(135deg, #1D4ED8, #3B82F6)' : '#F1F5F9', 
                    border: 'none', cursor: input.trim() && !loading ? 'pointer' : 'not-allowed', 
                    display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, 
                    transition: 'all 0.2s',
                    boxShadow: input.trim() && !loading ? '0 4px 12px rgba(29,78,216,0.25)' : 'none'
                  }}>
                  <Send size={16} style={{ color: input.trim() && !loading ? '#fff' : '#CBD5E1', transform: input.trim() && !loading ? 'translateX(1px)' : 'none' }} />
                </button>
              </div>
              <p style={{ textAlign: 'center', fontSize: 10, color: '#CBD5E1', marginTop: 8 }}>Potenciado por Spring AI · Groq</p>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
