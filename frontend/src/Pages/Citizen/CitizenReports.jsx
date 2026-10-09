export default function CitizenReports() {
  return (
    <div className="p-4 space-y-4 animate-fade-in">
      <div>
        <h1 className="text-xl font-bold text-gray-900">Estadísticas de la Ciudad</h1>
        <p className="text-sm text-gray-500 mt-0.5">Análisis de incidentes en Cartagena</p>
      </div>
      <div className="card overflow-hidden">
        <div className="w-full" style={{ height: 'calc(100vh - 220px)', minHeight: '450px' }}>
          <iframe
            title="Cartagena Segura - Estadísticas"
            src="https://app.powerbi.com/view?r=eyJrIjoiNmZiOGI1NWMtMjEzYi00ZmFiLWE2Y2MtZjVmMDdjMGE5ZjVmIiwidCI6IjlkMTJiZjNmLWU0ZjYtNDdhYi05MTJmLTFhMmYwZmM0OGFhNCIsImMiOjR9"
            frameBorder="0"
            allowFullScreen
            className="w-full h-full"
          />
        </div>
      </div>
    </div>
  )
}
