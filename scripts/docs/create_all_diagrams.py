import os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as patches

os.makedirs("doc_assets", exist_ok=True)

plt.rcParams['font.family'] = 'sans-serif'
plt.rcParams['font.sans-serif'] = ['DejaVu Sans', 'Arial', 'Helvetica']

# Helper to draw rounded step boxes
def draw_step(ax, x, y, w, h, title, subtitle, color_bg, color_border, color_text):
    box = patches.FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.6,rounding_size=0.8",
                                 linewidth=1.8, edgecolor=color_border, facecolor=color_bg, zorder=2)
    ax.add_patch(box)
    ax.text(x + w/2, y + h*0.62, title, fontsize=10, fontweight='bold', ha='center', va='center', color=color_text, zorder=3)
    if subtitle:
        ax.text(x + w/2, y + h*0.28, subtitle, fontsize=8, ha='center', va='center', color='#475569', zorder=3)

def draw_arrow(ax, x1, y1, x2, y2, text=None):
    ax.annotate("", xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle="->", color="#2563EB", lw=2, mutation_scale=15), zorder=2)
    if text:
        mid_x = (x1 + x2) / 2
        mid_y = (y1 + y2) / 2 + 1.2
        ax.text(mid_x, mid_y, text, fontsize=7.5, fontweight='bold', ha='center', va='center',
                color='#1E40AF', bbox=dict(boxstyle="square,pad=0.2", fc="#FFFFFF", ec="none", alpha=0.85), zorder=4)

# -------------------------------------------------------------
# 2. DIAGRAMA DE FLUJO: CU-02 REPORTE DE INCIDENTE CIUDADANO
# -------------------------------------------------------------
def create_report_flow():
    fig, ax = plt.subplots(figsize=(13, 6), dpi=300)
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 50)
    ax.axis('off')
    fig.patch.set_facecolor('#F8FAFC')

    ax.text(50, 47, "FLUJO DEL CASO DE USO CU-02: REPORTE DE INCIDENTE CON MULTIMEDIA Y GPS", fontsize=13, fontweight='bold', ha='center', color='#0F172A')

    # Step 1: Citizen Input
    draw_step(ax, 2, 24, 16, 12, "1. Ciudadano", "Captura GPS + Foto\nSelecciona Categoría", "#EFF6FF", "#3B82F6", "#1D4ED8")
    # Step 2: Client Validation & Magic Bytes
    draw_step(ax, 22, 24, 16, 12, "2. App Flutter", "Previsualización\nValidación de formulario", "#F0FDF4", "#22C55E", "#15803D")
    # Step 3: Backend Security & Cloudinary
    draw_step(ax, 42, 24, 17, 12, "3. Spring Boot API", "Magic Bytes (JPG/PNG)\nUpload Cloudinary", "#FEF3C7", "#F59E0B", "#B45309")
    # Step 4: Polyglot Persistence
    draw_step(ax, 63, 24, 16, 12, "4. Persistencia", "MongoDB (Incidente)\nPostgreSQL (Auditoría)", "#F5F3FF", "#8B5CF6", "#6D28D9")
    # Step 5: Real-time Dispatch
    draw_step(ax, 82, 24, 16, 12, "5. Notificación", "WebSocket STOMP\nAlerta Cuadrante & Admin", "#FFF1F2", "#F43F5E", "#BE123C")

    # Connect arrows
    draw_arrow(ax, 18, 30, 22, 30, "Envía Reporte")
    draw_arrow(ax, 38, 30, 42, 30, "HTTP POST JWT")
    draw_arrow(ax, 59, 30, 63, 30, "Guarda JSON")
    draw_arrow(ax, 79, 30, 82, 30, "Emite Topic")

    # Legend / note box below
    note_box = patches.FancyBboxPatch((5, 5), 90, 12, boxstyle="round,pad=0.5,rounding_size=0.5",
                                     linewidth=1, edgecolor='#CBD5E1', facecolor='#FFFFFF', zorder=2)
    ax.add_patch(note_box)
    ax.text(7, 13, "PUNTOS CLAVE DE SEGURIDAD Y RENDIMIENTO:", fontsize=9, fontweight='bold', color='#1E293B')
    ax.text(7, 9.5, "• Validación Criptográfica de Magic Bytes para neutralizar archivos binarios o scripts maliciosos.", fontsize=8, color='#475569')
    ax.text(7, 6.8, "• Esquema NoSQL en MongoDB que permite enriquecer reportes con coordenadas, fotos y notas policiales sin alterar esquemas.", fontsize=8, color='#475569')

    plt.tight_layout()
    plt.savefig("doc_assets/diagram_flujo_reporte.png", dpi=300, bbox_inches='tight')
    plt.close()

# -------------------------------------------------------------
# 3. DIAGRAMA DE FLUJO: CU-04 RUTAS SEGURAS (WAZE COMUNITARIO)
# -------------------------------------------------------------
def create_safe_route_flow():
    fig, ax = plt.subplots(figsize=(13, 6), dpi=300)
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 50)
    ax.axis('off')
    fig.patch.set_facecolor('#F8FAFC')

    ax.text(50, 47, "FLUJO DEL CASO DE USO CU-04: ASISTENTE DE RUTAS SEGURAS INTELIGENTES", fontsize=13, fontweight='bold', ha='center', color='#0F172A')

    draw_step(ax, 2, 24, 16, 12, "1. Selección Destino", "GPS Actual + Búsqueda\nde Destino en Mapa", "#EFF6FF", "#3B82F6", "#1D4ED8")
    draw_step(ax, 22, 24, 17, 12, "2. Análisis Geoespacial", "Consulta Polígonos de\nRiesgo e Incidentes", "#FEF3C7", "#F59E0B", "#B45309")
    draw_step(ax, 43, 24, 17, 12, "3. Algoritmo de Ruta", "Cálculo LatLong2\nPonderación de Seguridad", "#F0FDF4", "#22C55E", "#15803D")
    draw_step(ax, 64, 24, 16, 12, "4. Renderizado Visual", "Ruta Segura (Azul)\nZona Evitada (Rojo)", "#F5F3FF", "#8B5CF6", "#6D28D9")
    draw_step(ax, 83, 24, 15, 12, "5. Acompañamiento", "Radar Pulsante GPS\nMonitoreo en Trayecto", "#FFF1F2", "#F43F5E", "#BE123C")

    draw_arrow(ax, 18, 30, 22, 30, "Puntos (A, B)")
    draw_arrow(ax, 39, 30, 43, 30, "Filtrado Zonas")
    draw_arrow(ax, 60, 30, 64, 30, "Waypoints")
    draw_arrow(ax, 80, 30, 83, 30, "Navegación")

    note_box = patches.FancyBboxPatch((5, 5), 90, 12, boxstyle="round,pad=0.5,rounding_size=0.5",
                                     linewidth=1, edgecolor='#CBD5E1', facecolor='#FFFFFF', zorder=2)
    ax.add_patch(note_box)
    ax.text(7, 13, "LÓGICA PREVENTIVA TERRITORIAL:", fontsize=9, fontweight='bold', color='#1E293B')
    ax.text(7, 9.5, "• La ruta no solo prioriza el tiempo de desplazamiento más corto, sino la densidad mínima de incidentes activos.", fontsize=8, color='#475569')
    ax.text(7, 6.8, "• Detección inmediata si el ciudadano se desvía o entra a un polígono catalogado como de alta peligrosidad.", fontsize=8, color='#475569')

    plt.tight_layout()
    plt.savefig("doc_assets/diagram_flujo_rutas_seguras.png", dpi=300, bbox_inches='tight')
    plt.close()

# -------------------------------------------------------------
# 4. DIAGRAMA DE FLUJO: CU-05 BOTÓN DE PÁNICO SOS & RESPUESTA
# -------------------------------------------------------------
def create_sos_flow():
    fig, ax = plt.subplots(figsize=(13, 6), dpi=300)
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 50)
    ax.axis('off')
    fig.patch.set_facecolor('#F8FAFC')

    ax.text(50, 47, "FLUJO DEL CASO DE USO CU-05: ACTIVACIÓN DE BOTÓN DE PÁNICO SOS Y ATENCIÓN 123", fontsize=13, fontweight='bold', ha='center', color='#0F172A')

    draw_step(ax, 2, 24, 16, 12, "1. Presión SOS", "Pulsación Prolongada\nAnti-falsos positivos", "#FFF1F2", "#F43F5E", "#BE123C")
    draw_step(ax, 22, 24, 16, 12, "2. Telemetría GPS", "Fijación Satelital Exacta\nde Coordenadas", "#EFF6FF", "#3B82F6", "#1D4ED8")
    draw_step(ax, 42, 24, 17, 12, "3. Despacho CAD", "Alerta Crítica a Centro\nde Mando Distrital", "#FEF3C7", "#F59E0B", "#B45309")
    draw_step(ax, 63, 24, 17, 12, "4. Telefonía 123", "Marcación Automática\na Línea de Emergencia", "#F0FDF4", "#22C55E", "#15803D")
    draw_step(ax, 83, 24, 15, 12, "5. Patrulla", "Asignación Cuadrante\nIntervención Inmediata", "#F5F3FF", "#8B5CF6", "#6D28D9")

    draw_arrow(ax, 18, 30, 22, 30, "Hold 2 seg")
    draw_arrow(ax, 38, 30, 42, 30, "Prioridad ALTA")
    draw_arrow(ax, 59, 30, 63, 30, "UrlLauncher")
    draw_arrow(ax, 80, 30, 83, 30, "Despliegue")

    note_box = patches.FancyBboxPatch((5, 5), 90, 12, boxstyle="round,pad=0.5,rounding_size=0.5",
                                     linewidth=1, edgecolor='#CBD5E1', facecolor='#FFFFFF', zorder=2)
    ax.add_patch(note_box)
    ax.text(7, 13, "PROTOCOLOS DE CONTENCIÓN EN CRISIS:", fontsize=9, fontweight='bold', color='#1E293B')
    ax.text(7, 9.5, "• Integra confirmación háptica y visual para evitar pulsaciones involuntarias en el bolsillo del ciudadano.", fontsize=8, color='#475569')
    ax.text(7, 6.8, "• Acceso directo a números directos de Bomberos, Defensa Civil, Cruz Roja y Policía Metropolitana de Cartagena.", fontsize=8, color='#475569')

    plt.tight_layout()
    plt.savefig("doc_assets/diagram_flujo_sos.png", dpi=300, bbox_inches='tight')
    plt.close()

# -------------------------------------------------------------
# 5. DIAGRAMA DE FLUJO: CU-06 MOTOR DE IA HÍBRIDO (RAG)
# -------------------------------------------------------------
def create_ai_rag_flow():
    fig, ax = plt.subplots(figsize=(13, 6), dpi=300)
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 50)
    ax.axis('off')
    fig.patch.set_facecolor('#F8FAFC')

    ax.text(50, 47, "FLUJO DEL CASO DE USO CU-06: ASISTENTE INTELIGENTE CON RAG CONTEXT-AWARE", fontsize=13, fontweight='bold', ha='center', color='#0F172A')

    draw_step(ax, 2, 24, 16, 12, "1. Pregunta Ciudadano", "¿Es seguro caminar\npor Getsemaní a las 10pm?", "#EFF6FF", "#3B82F6", "#1D4ED8")
    draw_step(ax, 22, 24, 17, 12, "2. Recuperador RAG", "Extracción de Incidentes\ny Zonas desde MongoDB", "#FEF3C7", "#F59E0B", "#B45309")
    draw_step(ax, 43, 24, 17, 12, "3. Inyección Contexto", "Construcción de Prompt\ncon Datos Territoriales", "#F5F3FF", "#8B5CF6", "#6D28D9")
    draw_step(ax, 64, 24, 16, 12, "4. Inferencia Dual", "Groq Cloud (Llama 3)\no Motor Local Heurístico", "#F0FDF4", "#22C55E", "#15803D")
    draw_step(ax, 83, 24, 15, 12, "5. Respuesta Guiada", "Recomendaciones,\nLíneas 123 y Alertas", "#FFF1F2", "#F43F5E", "#BE123C")

    draw_arrow(ax, 18, 30, 22, 30, "Consulta")
    draw_arrow(ax, 39, 30, 43, 30, "Hechos Reales")
    draw_arrow(ax, 60, 30, 64, 30, "Prompt Aumentado")
    draw_arrow(ax, 80, 30, 83, 30, "Respuesta Útil")

    note_box = patches.FancyBboxPatch((5, 5), 90, 12, boxstyle="round,pad=0.5,rounding_size=0.5",
                                     linewidth=1, edgecolor='#CBD5E1', facecolor='#FFFFFF', zorder=2)
    ax.add_patch(note_box)
    ax.text(7, 13, "ARQUITECTURA DE IA RESILIENTE A FALLOS:", fontsize=9, fontweight='bold', color='#1E293B')
    ax.text(7, 9.5, "• Si no hay conexión o no se cuenta con saldo/API key en Groq, conmuta sin fallar al Motor Local Inteligente.", fontsize=8, color='#475569')
    ax.text(7, 6.8, "• Respuestas con conocimiento local específico: Torre del Reloj, Bocagrande, Manga, Bazurto, Pie de la Popa, etc.", fontsize=8, color='#475569')

    plt.tight_layout()
    plt.savefig("doc_assets/diagram_flujo_ia_rag.png", dpi=300, bbox_inches='tight')
    plt.close()

# -------------------------------------------------------------
# 6. DIAGRAMA DE ESTADOS: CU-09 CICLO DE VIDA DE UN INCIDENTE
# -------------------------------------------------------------
def create_state_machine_flow():
    fig, ax = plt.subplots(figsize=(13, 6), dpi=300)
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 50)
    ax.axis('off')
    fig.patch.set_facecolor('#F8FAFC')

    ax.text(50, 47, "DIAGRAMA DE TRANSICIÓN DE ESTADOS: CICLO DE VIDA DEL INCIDENTE (CU-09)", fontsize=13, fontweight='bold', ha='center', color='#0F172A')

    # States
    draw_step(ax, 4, 25, 14, 11, "REPORTADO", "Creación por Ciudadano\nEstado inicial", "#EFF6FF", "#3B82F6", "#1D4ED8")
    draw_step(ax, 26, 25, 15, 11, "EN REVISIÓN", "Verificación CAD /\nMagic Bytes válidos", "#FEF3C7", "#F59E0B", "#B45309")
    draw_step(ax, 49, 25, 16, 11, "ASIGNADO", "Cuadrante Policial\nnotificado vía STOMP", "#F5F3FF", "#8B5CF6", "#6D28D9")
    draw_step(ax, 73, 25, 15, 11, "EN PROCESO", "Patrulla en el sitio\nOperativo activo", "#ECFDF5", "#10B981", "#047857")

    # Final states
    draw_step(ax, 55, 6, 17, 10, "RESUELTO", "Incidente atendido\nObservación policial", "#F0FDF4", "#22C55E", "#15803D")
    draw_step(ax, 26, 6, 16, 10, "RECHAZADO", "Falsa alarma / Duplicado\nMotivo documentado", "#FFF1F2", "#F43F5E", "#BE123C")

    # Arrows between states
    draw_arrow(ax, 18, 30.5, 26, 30.5, "Recepción")
    draw_arrow(ax, 41, 30.5, 49, 30.5, "Filtro OK")
    draw_arrow(ax, 65, 30.5, 73, 30.5, "Despacho")
    draw_arrow(ax, 80, 25, 64, 16, "Solucionado")
    draw_arrow(ax, 33.5, 25, 33.5, 16, "Inconsistente")

    plt.tight_layout()
    plt.savefig("doc_assets/diagram_ciclo_vida_incidente.png", dpi=300, bbox_inches='tight')
    plt.close()

# -------------------------------------------------------------
# 7. DIAGRAMA: CU-10 CENTRO DE MANDO Y CONTROL OPERACIONAL
# -------------------------------------------------------------
def create_admin_operations_flow():
    fig, ax = plt.subplots(figsize=(13, 6), dpi=300)
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 50)
    ax.axis('off')
    fig.patch.set_facecolor('#F8FAFC')

    ax.text(50, 47, "CENTRO DE CONTROL ADMINISTRATIVO Y MANDO EN TIEMPO REAL (CU-10 / CU-12)", fontsize=13, fontweight='bold', ha='center', color='#0F172A')

    draw_step(ax, 2, 24, 16, 12, "Dashboard Bento", "KPIs de Incidentes,\nTasa de Resolución", "#EFF6FF", "#3B82F6", "#1D4ED8")
    draw_step(ax, 22, 24, 16, 12, "Capas Geoespaciales", "Cuadrantes, Polígonos\ny Clústeres de Riesgo", "#FEF3C7", "#F59E0B", "#B45309")
    draw_step(ax, 42, 24, 17, 12, "Gestión Operativa", "Cambio de Estados,\nNotas y Asignaciones", "#F0FDF4", "#22C55E", "#15803D")
    draw_step(ax, 63, 24, 17, 12, "Centro IA Oficial", "Resúmenes Ejecutivos,\nPatrones de Delito", "#F5F3FF", "#8B5CF6", "#6D28D9")
    draw_step(ax, 83, 24, 15, 12, "Exportación Legal", "Actas Oficiales PDF\nData Cruda CSV", "#FFF1F2", "#F43F5E", "#BE123C")

    draw_arrow(ax, 18, 30, 22, 30, "Monitoreo")
    draw_arrow(ax, 38, 30, 42, 30, "Acción")
    draw_arrow(ax, 59, 30, 63, 30, "Análisis")
    draw_arrow(ax, 80, 30, 83, 30, "Reportes")

    note_box = patches.FancyBboxPatch((5, 5), 90, 12, boxstyle="round,pad=0.5,rounding_size=0.5",
                                     linewidth=1, edgecolor='#CBD5E1', facecolor='#FFFFFF', zorder=2)
    ax.add_patch(note_box)
    ax.text(7, 13, "CAPACIDADES DE ALTA DISPONIBILIDAD PARA EL DISTRITO:", fontsize=9, fontweight='bold', color='#1E293B')
    ax.text(7, 9.5, "• Gráficos dinámicos con FL Chart que reflejan la distribución por tipología: Hurtos, Accidentes, Vandalismo, Emergencias.", fontsize=8, color='#475569')
    ax.text(7, 6.8, "• Generación instantánea de actas policiales descargables en PDF con OpenPDF y log inmutable de auditoría PostgreSQL.", fontsize=8, color='#475569')

    plt.tight_layout()
    plt.savefig("doc_assets/diagram_centro_mando_admin.png", dpi=300, bbox_inches='tight')
    plt.close()

create_report_flow()
create_safe_route_flow()
create_sos_flow()
create_ai_rag_flow()
create_state_machine_flow()
create_admin_operations_flow()
print("All 6 specialized diagrams created successfully in doc_assets/")
