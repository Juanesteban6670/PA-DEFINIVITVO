import { BarChart2, ExternalLink, TrendingUp, Eye, RefreshCw } from 'lucide-react'

const POWER_BI_URL = 'https://app.powerbi.com/view?r=eyJrIjoiNmZiOGI1NWMtMjEzYi00ZmFiLWE2Y2MtZjVmMDdjMGE5ZjVmIiwidCI6IjlkMTJiZjNmLWU0ZjYtNDdhYi05MTJmLTFhMmYwZmM0OGFhNCIsImMiOjR9'

export default function AdminReports() {
  return (
    <div style={{ padding: '20px 16px 32px', fontFamily: "'DM Sans', system-ui, sans-serif", background: '#F8FAFC', minHeight: '100%' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700;800&display=swap');
        @keyframes fadeUp { from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)} }
        .ar-fade { animation: fadeUp 400ms ease-out both; }
        .s1{animation-delay:0ms}.s2{animation-delay:80ms}
      `}</style>

      {/* Header */}
      <div className="ar-fade s1" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
        <div>
          <h1 style={{ fontSize: 22, fontWeight: 900, color: '#0F172A', letterSpacing: '-0.02em', marginBottom: 2 }}>Reportes y Análisis</h1>
          <p style={{ fontSize: 13, color: '#94A3B8' }}>Tablero de Power BI con estadísticas del sistema</p>
        </div>
        <a href={POWER_BI_URL} target="_blank" rel="noopener noreferrer"
          style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '9px 14px', borderRadius: 12, border: '1px solid #E2E8F0', background: '#fff', color: '#64748B', fontWeight: 600, fontSize: 13, textDecoration: 'none', transition: 'all 0.2s' }}>
          <ExternalLink size={13} /> Abrir
        </a>
      </div>

      {/* Info chips */}
      <div className="ar-fade s1" style={{ display: 'flex', gap: 10, flexWrap: 'wrap', marginBottom: 16 }}>
        {[[TrendingUp, 'Actualización en tiempo real', '#10B981'], [Eye, 'Datos verificados', '#3B82F6']].map(([Icon, label, color]) => (
          <div key={label} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '6px 12px', borderRadius: 100, background: `${color}0C`, border: `1px solid ${color}20` }}>
            <Icon size={11} style={{ color }} />
            <span style={{ fontSize: 11, color, fontWeight: 600 }}>{label}</span>
          </div>
        ))}
      </div>

      {/* Power BI */}
      <div className="ar-fade s2" style={{ borderRadius: 20, overflow: 'hidden', border: '1px solid #E2E8F0', boxShadow: '0 4px 20px rgba(0,0,0,0.06)', background: '#fff' }}>
        <iframe
          title="Cartagena Segura - Power BI"
          src={POWER_BI_URL}
          style={{ width: '100%', height: 'calc(100vh - 220px)', minHeight: 520, border: 'none', display: 'block' }}
          allowFullScreen
        />
      </div>
    </div>
  )
}
