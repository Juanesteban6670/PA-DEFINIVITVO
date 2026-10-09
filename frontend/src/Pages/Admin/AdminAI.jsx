import { useState, useEffect } from 'react'
import { Sparkles, Loader2, Brain, MapPin, AlertTriangle, RefreshCw, TrendingUp, Zap, Send, User, Bot } from 'lucide-react'
import { aiService } from '@/Services/Services'

function RichAssistantText({ text }) {
  if (!text) return null;
  
  // Dividir por líneas y filtrar vacías extra para mejor espaciado
  const lines = text.split('\n');
  
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
      {lines.map((line, i) => {
        const trimmedLine = line.trim();
        if (!trimmedLine) return <div key={i} style={{ height: '8px' }} />;
        
        // Detectar Listas (Bullets * o Numeradas 1., 2.)
        const listMatch = line.match(/^(\s*)([*-]|\d+\.)\s+(.*)/);
        const isList = !!listMatch;
        const content = isList ? listMatch[3] : trimmedLine;

        // Procesar negritas **texto** usando una expresión regular global
        // Dividimos la línea buscando los pares de **
        const parts = content.split(/(\*\*[^*]+\*\*)/g);
        
        const formattedLine = parts.map((part, index) => {
          if (part.startsWith('**') && part.endsWith('**')) {
            return (
              <strong key={index} style={{ 
                fontWeight: 700, 
                color: '#1E293B',
                background: 'rgba(139, 92, 246, 0.05)',
                padding: '0 2px',
                borderRadius: '2px'
              }}>
                {part.slice(2, -2)}
              </strong>
            );
          }
          return part;
        });

        return (
          <div key={i} style={{ 
            paddingLeft: isList ? '24px' : '0', 
            position: 'relative',
            lineHeight: '1.6',
            fontSize: '14px',
            color: '#334155'
          }}>
            {isList && (
              <span style={{ 
                position: 'absolute', 
                left: '4px', 
                color: '#8B5CF6', 
                fontWeight: 'bold',
                fontSize: listMatch[2].includes('.') ? '12px' : '16px'
              }}>
                {listMatch[2].includes('.') ? listMatch[2] : '•'}
              </span>
            )}
            {formattedLine}
          </div>
        );
      })}
    </div>
  );
}

function TypewriterText({ text, speed = 10 }) {
  const [displayed, setDisplayed] = useState('')
  const [done, setDone] = useState(false)
  
  useEffect(() => {
    if (!text) return
    setDisplayed(''); setDone(false)
    let i = 0
    const t = setInterval(() => { 
      i++; 
      setDisplayed(text.slice(0, i)); 
      if (i >= text.length) { 
        clearInterval(t); 
        setDone(true) 
      } 
    }, speed)
    return () => clearInterval(t)
  }, [text, speed])
  
  if (done) return <RichAssistantText text={text} />;
  
  // Mientras escribe, limpiamos los asteriscos para que no se vean feos
  const cleanDisplay = displayed.replace(/\*\*/g, '');
  
  return (
    <div style={{ whiteSpace: 'pre-wrap', lineHeight: '1.6', fontSize: '14px', color: '#334155' }}>
      {cleanDisplay}
      {!done && <span style={{ borderRight: '2px solid #8B5CF6', marginLeft: 2 }} className="animate-pulse">&nbsp;</span>}
    </div>
  );
}

const RISK_CONFIG = {
  LOW:      { color: '#10B981', bg: 'rgba(16,185,129,0.08)',  label: 'Bajo'    },
  MEDIUM:   { color: '#F59E0B', bg: 'rgba(245,158,11,0.08)',  label: 'Medio'   },
  HIGH:     { color: '#F97316', bg: 'rgba(249,115,22,0.08)',  label: 'Alto'    },
  CRITICAL: { color: '#EF4444', bg: 'rgba(239,68,68,0.08)',   label: 'Crítico' },
}

export default function AdminAI() {
  const [summary, setSummary]       = useState('')
  const [sumLoading, setSumLoading] = useState(false)
  const [sumError, setSumError]     = useState(false)
  const [sumTime, setSumTime]       = useState(null)
  const [zones, setZones]           = useState([])
  const [zonesLoading, setZonesLoading] = useState(false)
  const [zonesError, setZonesError] = useState(false)
  
  // Chat states
  const [chatMsgs, setChatMsgs] = useState([{ role: 'assistant', content: 'Hola Administrador. Tengo acceso a los últimos incidentes y estados de zona. ¿En qué puedo ayudarte hoy?' }])
  const [chatInput, setChatInput] = useState('')
  const [chatLoading, setChatLoading] = useState(false)
  const chatEndRef = useState(null)

  const genSummary = async () => {
    setSumLoading(true); setSumError(false); setSummary('')
    try {
      const r = await aiService.summary()
      const txt = r.data?.summary ?? r.data?.message ?? r.data ?? ''
      setSummary(typeof txt === 'string' ? txt : JSON.stringify(txt))
      setSumTime(new Date().toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit' }))
    } catch { setSumError(true) }
    finally { setSumLoading(false) }
  }

  const analyzeZones = async () => {
    setZonesLoading(true); setZonesError(false); setZones([])
    try {
      const r = await aiService.zonesAnalysis()
      const d = r.data?.zones ?? r.data?.data ?? r.data ?? []
      setZones(Array.isArray(d) ? d : [])
    } catch { setZonesError(true) }
    finally { setZonesLoading(false) }
  }

  const sendChatMessage = async () => {
    const text = chatInput.trim()
    if (!text || chatLoading) return
    setChatMsgs(p => [...p, { role: 'user', content: text }])
    setChatInput('')
    setChatLoading(true)
    try {
      // Usamos el endpoint del ChatbotAgent que ya implementamos con contexto
      const res = await aiService.chat({ message: text })
      const reply = res.data?.reply ?? res.data?.message ?? res.data ?? 'Sin respuesta.'
      setChatMsgs(p => [...p, { role: 'assistant', content: reply }])
    } catch {
      setChatMsgs(p => [...p, { role: 'assistant', content: 'Error de conexión.' }])
    } finally { setChatLoading(false) }
  }

  return (
    <div style={{ padding: '20px 16px 32px', fontFamily: "'DM Sans', system-ui, sans-serif", background: '#F8FAFC', minHeight: '100%' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700;800&display=swap');
        @keyframes fadeUp { from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)} }
        .aai-fade { animation: fadeUp 400ms ease-out both; }
        .s1{animation-delay:0ms}.s2{animation-delay:80ms}.s3{animation-delay:160ms}
        .zone-ai-card { transition: all 0.2s; }
        .zone-ai-card:hover { transform: translateY(-2px); }
      `}</style>

      {/* Header banner */}
      <div className="aai-fade s1" style={{ borderRadius: 20, padding: '20px', background: 'linear-gradient(135deg, #0F172A, #1E3A5F, #1D4ED8)', marginBottom: 20, position: 'relative', overflow: 'hidden' }}>
        <div style={{ position: 'absolute', inset: 0, backgroundImage: 'radial-gradient(circle at 1px 1px, rgba(255,255,255,0.05) 1px, transparent 0)', backgroundSize: '22px 22px' }} />
        <div style={{ position: 'absolute', top: -40, right: -40, width: 160, height: 160, borderRadius: '50%', background: 'rgba(139,92,246,0.15)', filter: 'blur(30px)' }} />
        <div style={{ position: 'relative', display: 'flex', alignItems: 'center', gap: 14 }}>
          <div style={{ width: 48, height: 48, borderRadius: 16, background: 'rgba(255,255,255,0.1)', border: '1px solid rgba(255,255,255,0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Brain size={24} style={{ color: '#A78BFA' }} />
          </div>
          <div style={{ flex: 1 }}>
            <h1 style={{ fontSize: 18, fontWeight: 800, color: '#fff', letterSpacing: '-0.02em', marginBottom: 2 }}>Asistente Virtual</h1>
            <p style={{ fontSize: 12, color: 'rgba(255,255,255,0.5)' }}>Centro de operaciones con IA Inteligente</p>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '5px 12px', borderRadius: 100, background: 'rgba(167,139,250,0.2)', border: '1px solid rgba(167,139,250,0.3)' }}>
            <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#A78BFA' }} className="animate-pulse" />
            <span style={{ fontSize: 10, color: '#C4B5FD', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.1em' }}>Beta</span>
          </div>
        </div>
      </div>

      {/* Embedded Chat Card */}
      <div className="aai-fade s1" style={{ background: '#fff', borderRadius: 20, border: '1px solid #E2E8F0', marginBottom: 16, display: 'flex', flexDirection: 'column', height: 400, overflow: 'hidden', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.05)' }}>
        <div style={{ padding: '12px 16px', background: '#F8FAFC', borderBottom: '1px solid #E2E8F0', display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 32, height: 32, borderRadius: 10, background: 'rgba(59,130,246,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Bot size={18} style={{ color: '#3B82F6' }} />
          </div>
          <p style={{ fontSize: 14, fontWeight: 700, color: '#1E293B' }}>Chat con el Agente (Contexto Activo)</p>
        </div>
        
        <div style={{ flex: 1, overflowY: 'auto', padding: '16px', display: 'flex', flexDirection: 'column', gap: 12 }}>
          {chatMsgs.map((m, i) => (
            <div key={i} style={{ display: 'flex', gap: 10, flexDirection: m.role === 'user' ? 'row-reverse' : 'row' }}>
              <div style={{ width: 28, height: 28, borderRadius: 8, background: m.role === 'user' ? '#3B82F6' : '#F1F5F9', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                {m.role === 'user' ? <User size={14} style={{ color: '#fff' }} /> : <Bot size={14} style={{ color: '#3B82F6' }} />}
              </div>
              <div style={{ maxWidth: '85%', padding: '10px 14px', borderRadius: 14, fontSize: 13, background: m.role === 'user' ? '#3B82F6' : '#F8FAFC', color: m.role === 'user' ? '#fff' : '#1E293B', border: m.role === 'user' ? 'none' : '1px solid #E2E8F0' }}>
                {m.role === 'assistant' ? <RichAssistantText text={m.content} /> : m.content}
              </div>
            </div>
          ))}
          {chatLoading && <div style={{ fontSize: 11, color: '#94A3B8', fontStyle: 'italic', paddingLeft: 40 }}>El agente está consultando la base de datos...</div>}
        </div>

        <div style={{ padding: '12px', borderTop: '1px solid #E2E8F0', background: '#fff' }}>
          <div style={{ display: 'flex', gap: 8, background: '#F8FAFC', borderRadius: 12, padding: '8px 12px', border: '1px solid #E2E8F0' }}>
            <input 
              value={chatInput} 
              onChange={e => setChatInput(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && sendChatMessage()}
              placeholder="Pregunta sobre incidentes o zonas..."
              style={{ flex: 1, background: 'none', border: 'none', outline: 'none', fontSize: 13 }}
            />
            <button onClick={sendChatMessage} disabled={!chatInput.trim() || chatLoading}
              style={{ width: 30, height: 30, borderRadius: 8, background: '#3B82F6', border: 'none', color: '#fff', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', opacity: chatInput.trim() ? 1 : 0.5 }}>
              <Send size={14} />
            </button>
          </div>
        </div>
      </div>

      {/* Summary card */}
      <div className="aai-fade s2" style={{ background: '#fff', borderRadius: 20, border: '1px solid #F1F5F9', marginBottom: 16, overflow: 'hidden' }}>
        <div style={{ padding: '14px 16px', borderBottom: '1px solid #F8FAFC', display: 'flex', alignItems: 'center', justifyContent: 'space-between', background: 'linear-gradient(135deg, rgba(139,92,246,0.04), rgba(59,130,246,0.02))' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 36, height: 36, borderRadius: 12, background: 'linear-gradient(135deg, #7C3AED, #8B5CF6)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Sparkles size={16} style={{ color: '#fff' }} />
            </div>
            <div>
              <p style={{ fontSize: 14, fontWeight: 700, color: '#0F172A' }}>Resumen Inteligente</p>
              <p style={{ fontSize: 11, color: '#94A3B8' }}>
                {sumTime ? `Generado a las ${sumTime}` : 'Análisis narrativo del estado del sistema'}
              </p>
            </div>
          </div>
          <button onClick={genSummary} disabled={sumLoading}
            style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '8px 14px', borderRadius: 10, background: 'linear-gradient(135deg, #7C3AED, #8B5CF6)', color: '#fff', fontWeight: 700, fontSize: 12, border: 'none', cursor: sumLoading ? 'not-allowed' : 'pointer', fontFamily: 'inherit', opacity: sumLoading ? 0.7 : 1 }}>
            {sumLoading ? <Loader2 size={12} style={{ animation: 'spin 1s linear infinite' }} /> : <Sparkles size={12} />}
            {summary ? 'Regenerar' : 'Generar'}
          </button>
        </div>
        <div style={{ padding: '16px' }}>
          {!summary && !sumLoading && !sumError && (
            <div style={{ padding: '24px 0', textAlign: 'center' }}>
              <div style={{ width: 52, height: 52, borderRadius: 18, background: 'rgba(139,92,246,0.08)', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 12px' }}>
                <Sparkles size={24} style={{ color: '#8B5CF6' }} />
              </div>
              <p style={{ fontSize: 13, color: '#94A3B8', marginBottom: 16 }}>Genera un análisis narrativo del estado actual del sistema</p>
              <button onClick={genSummary}
                style={{ padding: '10px 24px', borderRadius: 12, background: 'linear-gradient(135deg, #7C3AED, #8B5CF6)', color: '#fff', fontWeight: 700, fontSize: 13, border: 'none', cursor: 'pointer', fontFamily: 'inherit', display: 'inline-flex', alignItems: 'center', gap: 8 }}>
                <Sparkles size={14} /> Generar Resumen con IA
              </button>
            </div>
          )}
          {sumLoading && (
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, justifyContent: 'center', padding: '24px 0' }}>
              <Loader2 size={18} style={{ color: '#8B5CF6', animation: 'spin 1s linear infinite' }} />
              <span style={{ fontSize: 13, color: '#94A3B8' }}>Analizando datos del sistema...</span>
            </div>
          )}
          {sumError && (
            <div style={{ padding: '12px', borderRadius: 12, background: '#FEF2F2', border: '1px solid #FECACA', textAlign: 'center' }}>
              <AlertTriangle size={20} style={{ color: '#EF4444', display: 'block', margin: '0 auto 8px' }} />
              <p style={{ fontSize: 12, color: '#EF4444', fontWeight: 600, marginBottom: 8 }}>Servicio de IA no disponible</p>
              <button onClick={genSummary} style={{ fontSize: 12, color: '#EF4444', background: 'none', border: 'none', cursor: 'pointer', fontFamily: 'inherit', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                <RefreshCw size={11} /> Reintentar
              </button>
            </div>
          )}
          {summary && !sumLoading && (
            <div style={{ padding: '14px', borderRadius: 14, background: 'linear-gradient(135deg, rgba(139,92,246,0.04), rgba(59,130,246,0.02))', border: '1px solid rgba(139,92,246,0.12)' }}>
              <p style={{ fontSize: 13, color: '#374151', lineHeight: 1.75, whiteSpace: 'pre-wrap' }}>
                <TypewriterText text={summary} />
              </p>
              <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 12, paddingTop: 10, borderTop: '1px solid rgba(139,92,246,0.1)' }}>
                <button onClick={genSummary} style={{ fontSize: 11, color: '#7C3AED', background: 'none', border: 'none', cursor: 'pointer', fontFamily: 'inherit', display: 'flex', alignItems: 'center', gap: 4 }}>
                  <RefreshCw size={11} /> Regenerar
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Zones analysis card */}
      <div className="aai-fade s3" style={{ background: '#fff', borderRadius: 20, border: '1px solid #F1F5F9', overflow: 'hidden' }}>
        <div style={{ padding: '14px 16px', borderBottom: '1px solid #F8FAFC', display: 'flex', alignItems: 'center', justifyContent: 'space-between', background: 'linear-gradient(135deg, rgba(59,130,246,0.04), rgba(6,182,212,0.02))' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 36, height: 36, borderRadius: 12, background: 'linear-gradient(135deg, #1D4ED8, #3B82F6)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <MapPin size={16} style={{ color: '#fff' }} />
            </div>
            <div>
              <p style={{ fontSize: 14, fontWeight: 700, color: '#0F172A' }}>Análisis de Zonas</p>
              <p style={{ fontSize: 11, color: '#94A3B8' }}>IA evalúa patrones y recomienda acciones por zona</p>
            </div>
          </div>
          <button onClick={analyzeZones} disabled={zonesLoading}
            style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '8px 14px', borderRadius: 10, background: 'linear-gradient(135deg, #1D4ED8, #3B82F6)', color: '#fff', fontWeight: 700, fontSize: 12, border: 'none', cursor: zonesLoading ? 'not-allowed' : 'pointer', fontFamily: 'inherit', opacity: zonesLoading ? 0.7 : 1 }}>
            {zonesLoading ? <Loader2 size={12} style={{ animation: 'spin 1s linear infinite' }} /> : <Brain size={12} />}
            {zones.length ? 'Re-analizar' : 'Analizar'}
          </button>
        </div>
        <div style={{ padding: '16px' }}>
          {!zones.length && !zonesLoading && !zonesError && (
            <div style={{ padding: '24px 0', textAlign: 'center' }}>
              <div style={{ width: 52, height: 52, borderRadius: 18, background: 'rgba(59,130,246,0.08)', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 12px' }}>
                <TrendingUp size={24} style={{ color: '#3B82F6' }} />
              </div>
              <p style={{ fontSize: 13, color: '#94A3B8', marginBottom: 16 }}>Analiza las zonas registradas y obtén recomendaciones de acción</p>
              <button onClick={analyzeZones}
                style={{ padding: '10px 24px', borderRadius: 12, background: 'linear-gradient(135deg, #1D4ED8, #3B82F6)', color: '#fff', fontWeight: 700, fontSize: 13, border: 'none', cursor: 'pointer', fontFamily: 'inherit', display: 'inline-flex', alignItems: 'center', gap: 8 }}>
                <Brain size={14} /> Analizar Zonas con IA
              </button>
            </div>
          )}
          {zonesLoading && (
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, justifyContent: 'center', padding: '24px 0' }}>
              <Loader2 size={18} style={{ color: '#3B82F6', animation: 'spin 1s linear infinite' }} />
              <span style={{ fontSize: 13, color: '#94A3B8' }}>Analizando patrones por zona...</span>
            </div>
          )}
          {zonesError && (
            <div style={{ padding: '12px', borderRadius: 12, background: '#FEF2F2', border: '1px solid #FECACA', textAlign: 'center' }}>
              <p style={{ fontSize: 12, color: '#EF4444', fontWeight: 600, marginBottom: 8 }}>IA no disponible</p>
              <button onClick={analyzeZones} style={{ fontSize: 12, color: '#EF4444', background: 'none', border: 'none', cursor: 'pointer', fontFamily: 'inherit', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                <RefreshCw size={11} /> Reintentar
              </button>
            </div>
          )}
          {zones.length > 0 && !zonesLoading && (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: 10 }}>
              {zones.map((z, i) => {
                const rc = RISK_CONFIG[z.riskLevel] ?? RISK_CONFIG.LOW
                return (
                  <div key={z.name ?? i} className="zone-ai-card"
                    style={{ padding: '14px', borderRadius: 14, background: rc.bg, border: `1px solid ${rc.color}20` }}>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                      <p style={{ fontSize: 14, fontWeight: 700, color: '#0F172A' }}>{z.name}</p>
                      <span style={{ fontSize: 10, fontWeight: 800, padding: '2px 8px', borderRadius: 6, background: rc.color, color: '#fff' }}>{rc.label}</span>
                    </div>
                    {z.recommendation && <p style={{ fontSize: 12, color: '#475569', lineHeight: 1.5, marginBottom: 8 }}>{z.recommendation}</p>}
                    <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 10, color: rc.color, fontWeight: 600 }}>
                      <Brain size={10} /> Analizado por IA
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
