import { useEffect, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  AlertTriangle, ArrowRight, Bell, CheckCircle2,
  Lock, Map, Phone, ShieldCheck, Sparkles, Users, ChevronDown,
  Zap, Eye, Globe, TrendingUp, MessageSquare, LifeBuoy,
  Mail, Facebook, Twitter, Instagram, HelpCircle
} from 'lucide-react'
import { incidentService, zoneService } from '@/Services/Services'

/* ── Hooks ────────────────────────────────────────────────────────────── */
function useInView(threshold = 0.15) {
  const ref = useRef(null)
  const [inView, setInView] = useState(false)
  useEffect(() => {
    const obs = new IntersectionObserver(([e]) => { if (e.isIntersecting) setInView(true) }, { threshold })
    if (ref.current) obs.observe(ref.current)
    return () => obs.disconnect()
  }, [threshold])
  return [ref, inView]
}

function useCountUp(target, active, duration = 1800) {
  const [count, setCount] = useState(0)
  useEffect(() => {
    if (!active) return
    let start = 0
    const step = target / (duration / 16)
    const id = setInterval(() => {
      start += step
      if (start >= target) { setCount(target); clearInterval(id) }
      else setCount(Math.floor(start))
    }, 16)
    return () => clearInterval(id)
  }, [active, target, duration])
  return count
}

/* ── Data ─────────────────────────────────────────────────────────────── */
const features = [
  { icon: AlertTriangle, title: 'Reporte de incidentes', desc: 'Informa sobre robos, accidentes o vandalismo en segundos con geolocalización precisa.', accent: '#F59E0B', bg: 'rgba(245,158,11,0.08)' },
  { icon: Map, title: 'Mapa de calor', desc: 'Visualiza las zonas con mayor actividad de incidentes para tomar decisiones informadas.', accent: '#3B82F6', bg: 'rgba(59,130,246,0.08)' },
  { icon: Bell, title: 'Alertas en tiempo real', desc: 'Recibe notificaciones inmediatas sobre situaciones de riesgo en tu ubicación actual.', accent: '#EF4444', bg: 'rgba(239,68,68,0.08)' },
  { icon: ShieldCheck, title: 'Gestión de casos', desc: 'Seguimiento detallado desde el reporte hasta la resolución por parte de las autoridades.', accent: '#8B5CF6', bg: 'rgba(139,92,246,0.08)' },
  { icon: Sparkles, title: 'Inteligencia artificial', desc: 'Análisis predictivo y clasificación automática de reportes para priorizar emergencias.', accent: '#06B6D4', bg: 'rgba(6,182,212,0.08)' },
  { icon: Users, title: 'Participación ciudadana', desc: 'Conecta a la comunidad con los entes de control para una Cartagena más segura.', accent: '#10B981', bg: 'rgba(16,185,129,0.08)' },
]

const journey = [
  { step: '01', title: 'Regístrate ahora', desc: 'Registro rápido en menos de 2 minutos. Solo necesitas tu correo o teléfono.', icon: Users },
  { step: '02', title: 'Reporta con evidencia', desc: 'Describe el incidente, adjunta fotos o videos y comparte tu ubicación GPS exacta.', icon: Map },
  { step: '03', title: 'Haz seguimiento en vivo', desc: 'Consulta el estado del caso, recibe notificaciones y visualiza la respuesta de autoridades.', icon: Bell },
]

const faqs = [
  { q: '¿Es anónimo mi reporte?', a: 'Puedes elegir reportar de forma anónima para proteger tu identidad, aunque proporcionar tus datos ayuda a las autoridades a realizar un seguimiento más efectivo.' },
  { q: '¿Qué tipos de incidentes puedo reportar?', a: 'Desde robos y accidentes de tránsito hasta actos de vandalismo o situaciones sospechosas en la vía pública.' },
  { q: '¿Cómo protegen mis datos?', a: 'Usamos encriptación de grado bancario (AES-256) y cumplimos con la Ley de Protección de Datos Personales de Colombia.' },
  { q: '¿El sistema está conectado con la policía?', a: 'Sí, los reportes se categorizan y se envían a los centros de monitoreo correspondientes para una respuesta coordinada.' },
]

/* ── Animated Counter ─────────────────────────────────────────────────── */
function StatCard({ stat, active }) {
  const count = useCountUp(stat.value, active)
  const Icon = stat.icon
  return (
    <div style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.08)', backdropFilter: 'blur(12px)' }}
      className="rounded-2xl p-6 flex flex-col gap-3 hover:bg-white/[0.07] transition-all duration-300 group">
      <div className="flex items-center justify-between">
        <Icon className="w-4 h-4 text-blue-400 opacity-60 group-hover:opacity-100 transition-opacity" />
        <div className="w-1.5 h-1.5 rounded-full bg-green-400 animate-pulse" />
      </div>
      <div>
        <p className="text-3xl font-black text-white tracking-tight tabular-nums">
          {count.toLocaleString()}<span className="text-blue-400 text-2xl">{stat.suffix}</span>
        </p>
        <p className="text-xs text-white/40 mt-1 font-medium tracking-wide uppercase">{stat.label}</p>
      </div>
    </div>
  )
}

/* ── Main Component ───────────────────────────────────────────────────── */
export default function LandingPage() {
  const [scrollY, setScrollY] = useState(0)
  const [statsRef, statsInView] = useInView(0.3)
  const [liveStats, setLiveStats] = useState({ total: 847, resolved: 98, zones: 40 })
  const [featRef, featInView] = useInView(0.1)
  const [journeyRef, journeyInView] = useInView(0.1)
  const [ctaRef, ctaInView] = useInView(0.2)

  useEffect(() => {
    Promise.all([
      incidentService.getAll().catch(() => null),
      zoneService.getAll().catch(() => null)
    ]).then(([incRes, zoneRes]) => {
      const incs = incRes?.data?.data ?? incRes?.data ?? []
      const zones = zoneRes?.data?.data ?? zoneRes?.data ?? []
      const totalCount = incs.length > 0 ? incs.length : 847
      const zoneCount = zones.length > 0 ? zones.length : 40
      const resolved = incs.filter(i => i.status === 'RESOLVED').length
      const rate = incs.length > 0 ? Math.round((resolved / incs.length) * 100) : 98
      setLiveStats({ total: totalCount, resolved: rate, zones: zoneCount })
    })
  }, [])

  useEffect(() => {
    const onScroll = () => setScrollY(window.scrollY)
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  const navOpaque = scrollY > 40

  return (
    <div className="min-h-screen overflow-x-hidden" style={{ background: '#060B14', fontFamily: "'DM Sans', system-ui, sans-serif" }}>

      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;700;900&family=DM+Serif+Display&display=swap');
        @keyframes heroReveal { from { opacity: 0; transform: translateY(32px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes floatA { 0%,100% { transform: translateY(0px); } 50% { transform: translateY(-12px); } }
        @keyframes scanLine { 0% { transform: translateY(-100%); } 100% { transform: translateY(400%); } }
        @keyframes gradientFlow { 0%,100% { background-position: 0% 50%; } 50% { background-position: 100% 50%; } }
        
        .gradient-text {
          background: linear-gradient(135deg, #fff 0%, #60A5FA 50%, #fff 100%);
          background-size: 200% 200%;
          animation: gradientFlow 5s ease infinite;
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
          background-clip: text;
        }
        .scan-line {
          position: absolute; inset-x-0; height: 2px;
          background: linear-gradient(90deg, transparent, rgba(59,130,246,0.5), transparent);
          animation: scanLine 3s linear infinite;
        }
        .grid-bg { background-image: radial-gradient(rgba(59,130,246,0.1) 1px, transparent 1px); background-size: 40px 40px; }
        .reveal { opacity: 0; transform: translateY(20px); transition: all 0.6s cubic-bezier(0.16,1,0.3,1); }
        .reveal.visible { opacity: 1; transform: translateY(0); }
      `}</style>

      {/* ── NAV ─────────────────────────────────────────────────────────── */}
      <nav style={{
        position: 'fixed', 
        top: navOpaque ? '16px' : '0',
        left: '50%',
        transform: 'translateX(-50%)',
        width: navOpaque ? 'calc(100% - 32px)' : '100%',
        maxWidth: navOpaque ? '1100px' : '100%',
        zIndex: 100,
        background: navOpaque ? 'rgba(6,11,20,0.7)' : 'transparent',
        backdropFilter: navOpaque ? 'blur(20px)' : 'none',
        border: navOpaque ? '1px solid rgba(255,255,255,0.08)' : 'none',
        borderRadius: navOpaque ? '24px' : '0',
        transition: 'all 0.5s cubic-bezier(0.16, 1, 0.3, 1)'
      }}>
        <div className="max-w-7xl mx-auto px-6 flex items-center justify-between h-16 sm:h-20">
          <div className="flex items-center gap-4">
            <div className="relative group cursor-pointer">
              <div className="absolute inset-0 bg-blue-500/20 blur-xl rounded-full opacity-0 group-hover:opacity-100 transition-opacity" />
              <div className="relative w-10 h-10 rounded-xl bg-gradient-to-br from-blue-500/20 to-blue-600/5 border border-blue-500/30 flex items-center justify-center shadow-inner">
                <img src="/LogoFull.png" alt="Logo" className="w-6 h-6 object-contain" />
              </div>
            </div>
            <div className="hidden sm:block">
              <p className="text-white text-sm font-black leading-tight tracking-tight">Cartagena Segura</p>
              <p className="text-blue-400/50 text-[9px] font-black uppercase tracking-[0.2em]">Live Sentinel</p>
            </div>
          </div>

          <div className="hidden lg:flex items-center gap-8">
            {[
              { name: 'Inicio', path: '#' },
              { name: 'Funciones', path: '#features' },
              { name: 'Estadísticas', path: '#stats' },
              { name: 'Nuestra Misión', path: '#mission' },
              { name: 'FAQ', path: '#faq' },
            ].map(link => (
              <a key={link.name} href={link.path} className="text-white/40 hover:text-white text-xs font-bold uppercase tracking-widest transition-all hover:scale-105">
                {link.name}
              </a>
            ))}
          </div>

          <div className="flex items-center gap-4">
            <Link to="/Login" className="text-white/60 hover:text-white text-xs font-bold uppercase tracking-widest transition-colors hidden xs:block">Entrar</Link>
            <Link to="/Register" className="bg-blue-600 hover:bg-blue-500 text-white text-xs font-black uppercase tracking-widest px-6 py-3 rounded-xl transition-all shadow-xl shadow-blue-500/20 active:scale-95">
              Únete ahora
            </Link>
          </div>
        </div>
      </nav>

      {/* ── HERO ────────────────────────────────────────────────────────── */}
      <section className="relative min-h-screen flex items-center overflow-hidden grid-bg pt-20">
        <div className="absolute top-1/4 -left-20 w-80 h-80 bg-blue-600/10 blur-[100px] rounded-full" />
        <div className="absolute bottom-1/4 -right-20 w-80 h-80 bg-purple-600/10 blur-[100px] rounded-full" />

        <div className="max-w-7xl mx-auto px-4 sm:px-6 relative w-full">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <div className="flex flex-col gap-6 sm:gap-8 animate-[heroReveal_0.8s_ease-out]">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-500/10 border border-blue-500/20 w-fit">
                <Zap size={14} className="text-blue-400" />
                <span className="text-xs font-bold text-blue-400 uppercase tracking-widest">Plataforma activa en Cartagena ✨</span>
                <div className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse ml-1" />
              </div>
              
              <h1 style={{ fontFamily: "'DM Serif Display', serif" }} className="text-4xl sm:text-5xl lg:text-7xl font-black text-white leading-[1.08] tracking-tight">
                <span className="gradient-text">Tu ciudad,</span><br/>
                <span className="text-white/95">conectada y</span><br/>
                <span className="text-white/95">protegida.</span>
              </h1>
              
              <p className="text-lg sm:text-xl text-white/45 leading-relaxed max-w-lg">
                Centraliza reportes, monitoreo y comunicación entre ciudadanía y autoridades para una respuesta inmediata y eficiente.
              </p>

              <div className="flex flex-col sm:flex-row gap-4 mt-2">
                <Link to="/Register" className="px-8 py-4 rounded-2xl bg-blue-600 hover:bg-blue-500 text-white font-bold text-lg transition-all shadow-xl shadow-blue-500/25 flex items-center justify-center gap-2 group">
                  Registrarse <ArrowRight size={20} className="group-hover:translate-x-1 transition-transform" />
                </Link>
                <Link to="/Login" className="px-8 py-4 rounded-2xl bg-white/5 hover:bg-white/10 text-white font-bold text-lg transition-all border border-white/10 flex items-center justify-center">
                  Ya tengo cuenta
                </Link>
              </div>

              <div className="flex items-center gap-6 mt-4 pt-6 border-t border-white/10">
                {[['🔒', 'Datos seguros'], ['⚡', 'Tiempo real'], ['📍', 'GPS preciso']].map(([icon, label]) => (
                  <div key={label} className="flex items-center gap-2">
                    <span className="text-base">{icon}</span>
                    <span className="text-xs text-white/35 font-medium uppercase tracking-wider">{label}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="relative hidden lg:block animate-[heroReveal_1s_ease-out]">
              <div style={{ position: 'absolute', inset: -40, background: 'url(/Assets/Hero.png)', backgroundSize: 'cover', opacity: 0.15, filter: 'blur(40px)' }} />
              
              <div className="relative p-3 rounded-[32px] border border-white/10 bg-white/5 backdrop-blur-2xl shadow-2xl overflow-hidden group">
                <div className="scan-line" />
                <img 
                  src="/Assets/Dashboard.png" 
                  alt="Dashboard Preview" 
                  className="w-full h-full object-cover rounded-[24px] opacity-80 group-hover:opacity-100 transition-opacity duration-500" 
                />
                
                <div className="absolute inset-0 bg-gradient-to-t from-[#060B14] via-transparent to-transparent opacity-60" />
              </div>

              <div className="absolute -bottom-6 -left-6 p-4 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 backdrop-blur-xl flex items-center gap-3 animate-[floatA_4s_infinite]">
                 <div className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse" />
                 <div>
                    <p className="text-xs font-bold text-white">Sistema activo</p>
                    <p className="text-[10px] text-white/40">Monitoreo 24/7</p>
                 </div>
              </div>
            </div>
          </div>
          
          <div className="flex flex-col items-center gap-2 text-white/20 mt-16 animate-pulse">
            <span className="text-[10px] uppercase font-bold tracking-[0.2em]">Explorar</span>
            <ChevronDown size={16} />
          </div>
        </div>
      </section>

      {/* ── STATS ───────────────────────────────────────────────────────── */}
      <section id="stats" ref={statsRef} className="py-20 relative">
        <div className="max-w-7xl mx-auto px-4 sm:px-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 sm:gap-6">
            {[
              { value: liveStats.total, suffix: '+', label: 'Reportes registrados', icon: TrendingUp },
              { value: 24, suffix: '/7', label: 'Monitoreo activo', icon: Eye },
              { value: liveStats.zones, suffix: ' barrios', label: 'Conectados activamente', icon: Globe },
              { value: liveStats.resolved, suffix: '%', label: 'Tasa de resolución', icon: CheckCircle2 },
            ].map((stat, i) => (
              <div key={i} className={`reveal ${statsInView ? 'visible' : ''}`} style={{ transitionDelay: `${i * 100}ms` }}>
                <StatCard stat={stat} active={statsInView} />
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── FEATURES ────────────────────────────────────────────────────── */}
      <section ref={featRef} id="features" className="py-24 relative overflow-hidden">
        <div className="max-w-7xl mx-auto px-4 sm:px-6">
          <div className={`text-center mb-16 reveal ${featInView ? 'visible' : ''}`}>
            <p className="text-blue-400 text-xs font-black uppercase tracking-[0.2em] mb-4">Funcionalidades</p>
            <h2 style={{ fontFamily: "'DM Serif Display', serif" }} className="text-3xl sm:text-5xl font-black text-white tracking-tight mb-6">
              Herramientas que <span className="gradient-text">transforman la seguridad</span>
            </h2>
            <p className="text-white/40 text-lg max-w-2xl mx-auto">
              Una experiencia enfocada en usabilidad, velocidad y claridad para ciudadanos y equipos de respuesta.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {features.map((feat, i) => {
              const Icon = feat.icon
              return (
                <div key={i} className={`glass p-8 rounded-3xl reveal ${featInView ? 'visible' : ''}`} style={{ transitionDelay: `${i * 100}ms` }}>
                  <div className="w-12 h-12 rounded-2xl flex items-center justify-center mb-6" style={{ background: feat.bg }}>
                    <Icon size={22} style={{ color: feat.accent }} />
                  </div>
                  <h3 className="text-white text-lg font-bold mb-3">{feat.title}</h3>
                  <p className="text-white/40 text-sm leading-relaxed">{feat.desc}</p>
                </div>
              )
            })}
          </div>
        </div>
      </section>


      {/* ── HOW IT WORKS ────────────────────────────────────────────────── */}
      <section id="process" ref={journeyRef} className="py-24 relative bg-white/[0.01]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6">
          <div className={`text-center mb-16 reveal ${journeyInView ? 'visible' : ''}`}>
            <p className="text-blue-400 text-xs font-black uppercase tracking-[0.2em] mb-4">El Proceso</p>
            <h2 style={{ fontFamily: "'DM Serif Display', serif" }} className="text-3xl sm:text-5xl font-black text-white tracking-tight mb-6">
              Tu reporte en <span className="gradient-text">3 simples pasos</span>
            </h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-12 relative">
            {/* Connector Line (Desktop) */}
            <div className="hidden md:block absolute top-1/2 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-blue-500/20 to-transparent -translate-y-1/2" />
            
            {journey.map((item, i) => {
              const Icon = item.icon
              return (
                <div key={i} className={`relative flex flex-col items-center text-center reveal ${journeyInView ? 'visible' : ''}`} style={{ transitionDelay: `${i * 200}ms` }}>
                  <div className="w-20 h-20 rounded-3xl bg-blue-600/10 border border-blue-500/20 flex items-center justify-center mb-8 relative z-10 backdrop-blur-xl group hover:scale-110 transition-transform">
                    <div className="absolute -top-3 -right-3 w-8 h-8 rounded-full bg-blue-600 text-white text-[10px] font-black flex items-center justify-center shadow-lg">{item.step}</div>
                    <Icon className="text-blue-400" size={32} />
                  </div>
                  <h3 className="text-white text-xl font-bold mb-4">{item.title}</h3>
                  <p className="text-white/40 text-sm leading-relaxed max-w-[280px]">{item.desc}</p>
                </div>
              )
            })}
          </div>
        </div>
      </section>

      {/* ── MISSION ─────────────────────────────────────────────────────── */}
      <section id="mission" className="py-32 relative overflow-hidden">
        <div className="absolute inset-0 bg-blue-600/5" />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 relative">
          <div className="grid lg:grid-cols-2 gap-16 items-center">
            <div className="order-2 lg:order-1">
              <div className="relative aspect-video rounded-[32px] overflow-hidden border border-white/10 group">
                <div className="absolute inset-0 bg-gradient-to-tr from-blue-600/20 to-transparent z-10" />
                <img 
                  src="/Assets/Mission.png" 
                  alt="Cartagena" 
                  className="w-full h-full object-cover opacity-70 group-hover:opacity-100 transition-all duration-700 scale-110 group-hover:scale-100" 
                />
                <div className="absolute bottom-8 left-8 right-8 z-20">
                  <div className="glass p-6 rounded-2xl border-white/20">
                    <p className="text-white text-sm font-medium italic">"Una Cartagena más segura no se construye solo con muros, sino con la participación activa de cada ciudadano."</p>
                  </div>
                </div>
              </div>
            </div>
            <div className="order-1 lg:order-2 space-y-8">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 w-fit">
                <ShieldCheck size={14} className="text-emerald-400" />
                <span className="text-[10px] font-bold text-emerald-400 uppercase tracking-widest">Nuestra Misión</span>
              </div>
              <h2 style={{ fontFamily: "'DM Serif Display', serif" }} className="text-3xl sm:text-5xl font-black text-white leading-tight">
                Transparencia, <br/>
                <span className="gradient-text">Acción y Seguridad</span>
              </h2>
              <div className="space-y-6">
                <p className="text-white/50 text-lg leading-relaxed">
                  Cartagena Segura nace como una respuesta tecnológica a la necesidad de conectar a la comunidad con los entes de control de forma directa y sin intermediarios.
                </p>
                <div className="grid grid-cols-2 gap-6">
                  {[
                    { label: 'Respuesta rápida', val: '92%', icon: Zap },
                    { label: 'Datos precisos', val: '100%', icon: Map },
                  ].map((item, i) => (
                    <div key={i} className="flex flex-col gap-2">
                      <item.icon size={20} className="text-blue-400" />
                      <p className="text-2xl font-black text-white">{item.val}</p>
                      <p className="text-[10px] uppercase tracking-wider text-white/30">{item.label}</p>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── FAQ ─────────────────────────────────────────────────────────── */}
      <section id="faq" className="py-24 relative">
        <div className="max-w-4xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-16">
            <HelpCircle className="mx-auto text-blue-500 mb-4" size={40} />
            <h2 style={{ fontFamily: "'DM Serif Display', serif" }} className="text-3xl sm:text-4xl font-black text-white mb-4">Preguntas Frecuentes</h2>
            <p className="text-white/40">Todo lo que necesitas saber sobre la plataforma</p>
          </div>
          
          <div className="grid gap-4">
            {faqs.map((faq, i) => (
              <details key={i} className="group bg-white/[0.03] border border-white/5 rounded-2xl overflow-hidden hover:bg-white/[0.05] transition-all">
                <summary className="flex items-center justify-between p-6 cursor-pointer list-none">
                  <h3 className="text-white font-bold pr-6">{faq.q}</h3>
                  <ChevronDown className="text-white/30 group-open:rotate-180 transition-transform" size={20} />
                </summary>
                <div className="px-6 pb-6 pt-0">
                  <p className="text-white/40 leading-relaxed">{faq.a}</p>
                </div>
              </details>
            ))}
          </div>
        </div>
      </section>

      {/* ── FINAL CTA ───────────────────────────────────────────────────── */}
      <section ref={ctaRef} className="py-24 relative overflow-hidden">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 relative">
          <div className={`relative p-12 sm:p-20 rounded-[48px] overflow-hidden text-center reveal ${ctaInView ? 'visible' : ''}`}>
            <div className="absolute inset-0 bg-blue-600 z-0" />
            <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/carbon-fibre.png')] opacity-20 mix-blend-overlay" />
            <div className="absolute -top-24 -left-24 w-96 h-96 bg-white/20 blur-[100px] rounded-full" />
            <div className="absolute -bottom-24 -right-24 w-96 h-96 bg-black/20 blur-[100px] rounded-full" />
            
            <div className="relative z-10 max-w-2xl mx-auto">
              <h2 style={{ fontFamily: "'DM Serif Display', serif" }} className="text-4xl sm:text-6xl font-black text-white mb-8 leading-tight">
                Haz parte del cambio hoy mismo.
              </h2>
              <p className="text-white/80 text-lg mb-10">
                Únete a miles de ciudadanos que ya están trabajando por una Cartagena más segura y conectada.
              </p>
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <Link to="/Register" className="bg-white text-blue-600 px-10 py-5 rounded-2xl font-black text-xl hover:scale-105 transition-all shadow-2xl">
                  Registrarme Gratis
                </Link>
                <Link to="/Login" className="bg-transparent border-2 border-white/30 text-white px-10 py-5 rounded-2xl font-black text-xl hover:bg-white/10 transition-all">
                  Contactar Soporte
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── FOOTER ──────────────────────────────────────────────────────── */}
      <footer className="py-20 border-t border-white/5 relative bg-[#04080F]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-12 mb-16">
            <div className="space-y-6">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-2xl bg-blue-600/10 border border-blue-500/20 flex items-center justify-center shadow-lg">
                  <img src="/LogoFull.png" alt="Logo" className="w-7 h-7" />
                </div>
                <div>
                  <span className="text-white font-black text-xl tracking-tighter">Cartagena Segura</span>
                  <p className="text-blue-500 text-[10px] font-bold uppercase tracking-[0.3em]">Distrito Táctico</p>
                </div>
              </div>
              <p className="text-white/30 text-sm leading-relaxed max-w-xs">
                Plataforma avanzada de inteligencia ciudadana y monitoreo en tiempo real para el distrito de Cartagena de Indias.
              </p>
              <div className="flex gap-4">
                {[Facebook, Twitter, Instagram].map((Icon, i) => (
                  <a key={i} href="#" className="w-10 h-10 rounded-full bg-white/5 flex items-center justify-center text-white/40 hover:bg-blue-600 hover:text-white transition-all">
                    <Icon size={18} />
                  </a>
                ))}
              </div>
            </div>


            <div>
              <h4 className="text-white font-bold mb-6">Comunidad</h4>
              <ul className="space-y-4">
                {[
                  { name: 'Guía de uso', path: '#process' },
                  { name: 'Misión', path: '#mission' },
                  { name: 'Preguntas', path: '#faq' },
                  { name: 'Centro de ayuda', path: '/Login' }
                ].map(link => (
                  <li key={link.name}>
                    {link.path.startsWith('#') ? (
                      <a href={link.path} className="text-white/30 hover:text-white text-sm transition-colors">{link.name}</a>
                    ) : (
                      <Link to={link.path} className="text-white/30 hover:text-white text-sm transition-colors">{link.name}</Link>
                    )}
                  </li>
                ))}
              </ul>
            </div>

            <div>
              <h4 className="text-white font-bold mb-6">Contacto</h4>
              <ul className="space-y-4">
                <li className="flex items-center gap-3 text-white/30 text-sm">
                  <Mail size={16} /> cartagenasegura6to@gmail.com
                </li>
                <li className="flex items-center gap-3 text-white/30 text-sm">
                  <Phone size={16} /> +57 (605) 123 4567
                </li>
                <li className="flex items-center gap-3 text-white/30 text-sm">
                  <Globe size={16} /> Cartagena, Colombia
                </li>
              </ul>
            </div>
          </div>

          <div className="pt-8 border-t border-white/5 flex flex-col md:flex-row items-center justify-between gap-6">
            <p className="text-white/20 text-xs font-medium">© 2026 Cartagena Segura. Todos los derechos reservados.</p>
            <div className="flex items-center gap-8 text-[10px] uppercase font-bold tracking-widest text-white/20">
              <span>Hecho con ❤️ en Cartagena</span>
            </div>
          </div>
        </div>
      </footer>
    </div>
  )
}
