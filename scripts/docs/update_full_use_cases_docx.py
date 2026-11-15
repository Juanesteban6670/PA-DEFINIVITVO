import os
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

def build_complete_document():
    doc = docx.Document()

    # Page Margins (Normal: 1 inch / 2.54 cm)
    for section in doc.sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)
        section.page_width = Inches(8.5)
        section.page_height = Inches(11.0)

    # Palette Constants
    COLOR_PRIMARY = RGBColor(15, 23, 42)       # Slate 900
    COLOR_SECONDARY = RGBColor(30, 58, 138)    # Blue 900
    COLOR_ACCENT = RGBColor(2, 132, 199)       # Sky 600
    COLOR_TEXT = RGBColor(51, 65, 85)          # Slate 700
    HEX_HEADER_BG = '1E3A8A'                   # Dark Navy
    HEX_LIGHT_ROW = 'F8FAFC'                   # Slate 50
    HEX_ACCENT_BG = 'EFF6FF'                   # Blue 50
    HEX_BORDER = 'CBD5E1'                      # Slate 300

    def set_cell_background(cell, hex_color):
        tcPr = cell._tc.get_or_add_tcPr()
        shd = OxmlElement('w:shd')
        shd.set(qn('w:val'), 'clear')
        shd.set(qn('w:color'), 'auto')
        shd.set(qn('w:fill'), hex_color)
        tcPr.append(shd)

    def set_table_borders(table, color=HEX_BORDER, sz='4', val='single'):
        tblPr = table._tbl.tblPr
        tblBorders = OxmlElement('w:tblBorders')
        for border_name in ['top', 'left', 'bottom', 'right', 'insideH', 'insideV']:
            border = OxmlElement(f'w:{border_name}')
            border.set(qn('w:val'), val)
            border.set(qn('w:sz'), sz)
            border.set(qn('w:space'), '0')
            border.set(qn('w:color'), color)
            tblBorders.append(border)
        tblPr.append(tblBorders)

    def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
        tcPr = cell._tc.get_or_add_tcPr()
        tcMar = OxmlElement('w:tcMar')
        for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
            node = OxmlElement(f'w:{m}')
            node.set(qn('w:w'), str(val))
            node.set(qn('w:type'), 'dxa')
            tcMar.append(node)
        tcPr.append(tcMar)

    # Styles
    normal_style = doc.styles['Normal']
    normal_style.font.name = 'Calibri'
    normal_style.font.size = Pt(11)
    normal_style.font.color.rgb = COLOR_TEXT
    normal_style.paragraph_format.line_spacing = 1.15
    normal_style.paragraph_format.space_after = Pt(6)

    def add_custom_h1(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(18)
        p.paragraph_format.space_after = Pt(8)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.font.name = 'Calibri'
        run.font.size = Pt(17)
        run.font.bold = True
        run.font.color.rgb = COLOR_SECONDARY
        return p

    def add_custom_h2(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(13)
        p.paragraph_format.space_after = Pt(5)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.font.name = 'Calibri'
        run.font.size = Pt(13.5)
        run.font.bold = True
        run.font.color.rgb = COLOR_ACCENT
        return p

    def add_callout_box(text, prefix="NOTA:"):
        table = doc.add_table(rows=1, cols=1)
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        cell = table.cell(0, 0)
        cell.width = Inches(6.5)
        set_cell_background(cell, 'F1F5F9')
        set_cell_margins(cell, top=130, bottom=130, left=170, right=170)

        tcPr = cell._tc.get_or_add_tcPr()
        tblBorders = OxmlElement('w:tcBorders')
        left = OxmlElement('w:left')
        left.set(qn('w:val'), 'single')
        left.set(qn('w:sz'), '24')
        left.set(qn('w:color'), '2563EB')
        tblBorders.append(left)
        for b_name in ['top', 'bottom', 'right']:
            b = OxmlElement(f'w:{b_name}')
            b.set(qn('w:val'), 'none')
            tblBorders.append(b)
        tcPr.append(tblBorders)

        p = cell.paragraphs[0]
        p.paragraph_format.space_after = Pt(0)
        p.paragraph_format.line_spacing = 1.15
        r_pre = p.add_run(f"{prefix} ")
        r_pre.font.bold = True
        r_pre.font.color.rgb = COLOR_SECONDARY
        r_txt = p.add_run(text)
        r_txt.font.size = Pt(10)
        r_txt.font.color.rgb = COLOR_TEXT

        p_after = doc.add_paragraph()
        p_after.paragraph_format.space_before = Pt(4)
        p_after.paragraph_format.space_after = Pt(4)

    def add_image_with_caption(img_path, caption_text, width=Inches(6.2)):
        if os.path.exists(img_path):
            p_img = doc.add_paragraph()
            p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p_img.paragraph_format.space_before = Pt(10)
            p_img.paragraph_format.space_after = Pt(4)
            p_img.paragraph_format.keep_with_next = True
            run = p_img.add_run()
            run.add_picture(img_path, width=width)

            p_cap = doc.add_paragraph()
            p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p_cap.paragraph_format.space_before = Pt(0)
            p_cap.paragraph_format.space_after = Pt(12)
            r_cap = p_cap.add_run(caption_text)
            r_cap.font.name = 'Calibri'
            r_cap.font.size = Pt(9.5)
            r_cap.font.italic = True
            r_cap.font.color.rgb = RGBColor(100, 116, 139)

    # -------------------------------------------------------------
    # PORTADA (COVER PAGE)
    # -------------------------------------------------------------
    if os.path.exists("doc_assets/cover_banner.jpg"):
        p_cov = doc.add_paragraph()
        p_cov.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_cov.paragraph_format.space_before = Pt(0)
        p_cov.paragraph_format.space_after = Pt(14)
        run_cov = p_cov.add_run()
        run_cov.add_picture("doc_assets/cover_banner.jpg", width=Inches(6.5))

    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_title.paragraph_format.space_before = Pt(10)
    p_title.paragraph_format.space_after = Pt(4)
    r_tit = p_title.add_run("ESPECIFICACIÓN DE CASOS DE USO EN APPS MÓVILES")
    r_tit.font.name = 'Calibri'
    r_tit.font.size = Pt(22)
    r_tit.font.bold = True
    r_tit.font.color.rgb = COLOR_SECONDARY

    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_sub.paragraph_format.space_before = Pt(2)
    p_sub.paragraph_format.space_after = Pt(18)
    r_sub = p_sub.add_run("Particularidades Móviles, Flujo de Navegación de Pantallas y Fichas Técnicas\nPlataforma Distrital Cartagena Segura — Versión 2.3.0")
    r_sub.font.name = 'Calibri'
    r_sub.font.size = Pt(12.5)
    r_sub.font.color.rgb = COLOR_ACCENT

    table_meta = doc.add_table(rows=7, cols=2)
    table_meta.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table_meta)

    meta_data = [
        ("Proyecto:", "Cartagena Segura (Plataforma de Seguridad Ciudadana y Monitoreo Geoespacial)"),
        ("Tipo de Documento:", "Especificación de Casos de Uso Móviles (Marco Metodológico de Apps Móviles)"),
        ("Versión del Sistema:", "Versión 2.3.0 (Producción Cloud en Render)"),
        ("Despliegue Oficial en Vivo:", "https://pa-definivitvo.onrender.com (Web / PWA / Móvil 24/7)"),
        ("Autores y Desarrolladores:", "Juan Esteban de los Ríos Tibocha\nRobinson Emiro Castaño Mercado\nÁlvaro Cervantes Noel"),
        ("Stack de Implementación:", "Frontend: Flutter 3.47 (Web/PWA/Android/iOS) + Riverpod + GoRouter\nBackend: Spring Boot 3.4.3 (Java 21 LTS) + Spring Security 6 (JWT)\nPersistencia: PostgreSQL 16 (Transaccional) + MongoDB 7 (GeoJSON)\nInteligencia Artificial: RAG Dual (Groq Cloud Llama 3 / Motor Heurístico Local)"),
        ("Fecha de Publicación:", "Noviembre de 2026"),
    ]

    for idx, (label, val) in enumerate(meta_data):
        row = table_meta.rows[idx]
        cell_lbl, cell_val = row.cells[0], row.cells[1]
        cell_lbl.width = Inches(2.2)
        cell_val.width = Inches(4.3)
        set_cell_background(cell_lbl, HEX_LIGHT_ROW)
        set_cell_background(cell_val, 'FFFFFF')
        set_cell_margins(cell_lbl, 70, 70, 110, 110)
        set_cell_margins(cell_val, 70, 70, 110, 110)

        p0 = cell_lbl.paragraphs[0]
        p0.paragraph_format.space_after = Pt(0)
        r0 = p0.add_run(label)
        r0.font.bold = True
        r0.font.size = Pt(9.5)
        r0.font.color.rgb = COLOR_SECONDARY

        p1 = cell_val.paragraphs[0]
        p1.paragraph_format.space_after = Pt(0)
        r1 = p1.add_run(val)
        r1.font.size = Pt(9.5)

    doc.add_page_break()

    # -------------------------------------------------------------
    # SECCIÓN 1: MARCO CONCEPTUAL: CASOS DE USO EN UNA APP MÓVIL
    # -------------------------------------------------------------
    add_custom_h1("1. Marco Conceptual: Particularidades de los Casos de Uso en Apps Móviles")
    doc.add_paragraph(
        "El diseño y especificación de casos de uso para aplicaciones móviles difiere sustancialmente del software tradicional "
        "de escritorio o web por la presencia de restricciones de hardware, conectividad intermitente, eventos del sistema operativo "
        "y la interacción constante con sensores físicos (cámara, acelerómetro, chip satelital GPS)."
    )
    doc.add_paragraph(
        "Conforme a las directrices metodológicas de ingeniería de software móvil, se identifican cuatro particularidades fundamentales "
        "que transforman la redacción y ejecución de cada caso de uso en la plataforma 'Cartagena Segura':"
    )

    # TABLE: Adaptación Conceptual (Image 1)
    table_concept = doc.add_table(rows=5, cols=3)
    table_concept.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table_concept)

    c_headers = ["Particularidad", "Qué cambia en una App Móvil", "En Cartagena Segura (Implementación Real)"]
    for i, h in enumerate(c_headers):
        cell = table_concept.rows[0].cells[i]
        set_cell_background(cell, HEX_HEADER_BG)
        set_cell_margins(cell, 90, 90, 110, 110)
        p = cell.paragraphs[0]
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(h)
        run.font.bold = True
        run.font.size = Pt(9.5)
        run.font.color.rgb = RGBColor(255, 255, 255)

    concept_data = [
        ("Actores secundarios", 
         "Otros sistemas externos y componentes de hardware también actúan como actores interactuantes en el flujo.",
         "• Groq Cloud API (Inferencia Llama 3 para el asistente inteligente RAG).\n"
         "• Cloudinary CDN (Almacenamiento en la nube de evidencias multimedia).\n"
         "• Servidores de Mapas OpenStreetMap y Esri (Teselas vectoriales y satelitales).\n"
         "• Broker STOMP / WebSocket (Distribución de alertas en tiempo real al CAD).\n"
         "• Central Telefónica de Emergencias 123 (Telefonía GSM de la Policía Nacional).\n"
         "• Google Apps Script (Servicio de correos transaccionales)."),
        
        ("Permisos del teléfono", 
         "El usuario debe conceder autorizaciones explícitas del sistema operativo para acceder a sensores y recursos.",
         "• Ubicación satelital precisa (GPS): Georreferenciación de incidentes, cálculo de rutas seguras, radar en tiempo real y telemetría de pánico SOS.\n"
         "• Cámara y Galería (image_picker): Captura en vivo y adjunto de fotografías como evidencia física del incidente.\n"
         "• Llamadas / Telefonía (url_launcher): Enlace de marcación directa a la línea 123 ante presión del botón de pánico SOS.\n"
         "• Notificaciones del sistema: Recepción de alertas de cuadrante y seguimiento a denuncias."),
        
        ("Sin conexión (Modo Offline)", 
         "Define qué funciones permanecen operativas cuando el dispositivo pierde la señal de datos 3G/4G/WiFi.",
         "• Guardado de borradores de denuncias en ReportDraftStore para su posterior sincronización al recuperar conectividad.\n"
         "• Acceso irrestricto al directorio de emergencia (Policía, Bomberos, Cruz Roja) para llamadas de voz GSM directas sin internet.\n"
         "• Visualización de mapa en caché local y consulta de reportes previamente descargados."),
        
        ("Interrupciones del sistema", 
         "Manejo de eventos externos repentinos: llamadas entrantes, cambio de aplicación, alertas del sistema o batería baja.",
         "• Si entra una llamada durante la redacción de un reporte, la app preserva el texto, coordenadas y foto tomada sin pérdida de información.\n"
         "• Al regresar desde segundo plano, se restablece el vector de navegación de ruta segura y el estado reactivo del mapa.\n"
         "• Persistencia de sesión mediante FlutterSecureStorage para evitar cierres de sesión abruptos por ahorro de energía.")
    ]

    for idx, (p_name, p_change, p_app) in enumerate(concept_data, start=1):
        row = table_concept.rows[idx]
        bg = HEX_LIGHT_ROW if idx % 2 == 1 else 'FFFFFF'
        for c_idx, text in enumerate([p_name, p_change, p_app]):
            cell = row.cells[c_idx]
            set_cell_background(cell, bg)
            set_cell_margins(cell, 70, 70, 90, 90)
            p = cell.paragraphs[0]
            p.paragraph_format.space_after = Pt(0)
            run = p.add_run(text)
            run.font.size = Pt(9)
            if c_idx == 0:
                run.font.bold = True
                run.font.color.rgb = COLOR_SECONDARY
            if c_idx == 1:
                run.font.color.rgb = RGBColor(71, 85, 105)

    add_image_with_caption(
        "doc_assets/diagram_particularidades_moviles.png",
        "Figura 1: Marco Conceptual de Casos de Uso en Aplicaciones Móviles (Adaptación a Cartagena Segura)"
    )

    doc.add_page_break()

    # -------------------------------------------------------------
    # SECCIÓN 2: MAPA DE NAVEGACIÓN Y FLUJO DE PANTALLAS MÓVILES
    # -------------------------------------------------------------
    add_custom_h1("2. Diagrama de Navegación y Flujo de Pantallas Móviles")
    doc.add_paragraph(
        "Para modelar la interacción del usuario en la aplicación móvil, se emplea el diagrama de navegación de pantallas. "
        "Cada transición representa un evento explícito ejecutado por el usuario (toque, entrada de texto, selección de pestaña o confirmación), "
        "mientras que el botón físico/gesto 'Atrás' permite regresar a la pantalla inmediatamente anterior en la pila de navegación (GoRouter)."
    )

    add_image_with_caption(
        "doc_assets/diagram_navegacion_cartagena_segura.png",
        "Figura 2: Diagrama de Navegación y Flujo de Pantallas Móviles de Cartagena Segura"
    )

    add_callout_box(
        "Convenciones del Diagrama de Navegación:\n"
        "• Cuadros Azules: Pantallas intermedias de entrada y formularios de acción.\n"
        "• Cuadros Verdes: Pantallas a las que se llega directamente por selección de pestaña en la barra de navegación (HomeShell) "
        "o que cierran exitosamente un flujo de usuario (Confirmación de Reporte, Llamada SOS, Asistente IA).\n"
        "• Flechas con Etiquetas: Representan eventos explícitos del usuario (Entrar, Reportar, Cámara/GPS, Publicar, Pestaña, Chat IA).",
        prefix="REGLAS DE NAVEGACIÓN MÓVIL:"
    )

    add_custom_h2("2.1 Descripción de los Principales Flujos de Navegación")
    doc.add_paragraph(
        "1. Flujo de Acceso Inicial:\n"
        "   Inicio de Sesión --(Entrar)--> Inicio / Bienvenida (HomeShell).\n\n"
        "2. Flujo de Navegación por Pestañas (Bottom Navigation Bar):\n"
        "   Desde la pantalla de Inicio, el ciudadano puede alternar fluidamente entre las pestañas de 'Perfil', 'Mapa Interactivo', "
        "'Historial de Mis Reportes' y 'Emergencias SOS' sin recargar la aplicación ni perder estado.\n\n"
        "3. Flujo Crítico de Reporte Ciudadano:\n"
        "   Inicio / Mapa --(Reportar)--> Formulario de Reporte --(Cámara/GPS)--> Captura de Evidencia y Fijación Satelital --(Publicar)--> Confirmación de Reporte.\n\n"
        "4. Flujo de Rutas Seguras (Waze Preventivo):\n"
        "   Mapa Interactivo --(Trazar Ruta)--> Búsqueda de Destino --> Cálculo Evitando Zonas de Riesgo --> Asistente de Ruta Segura.\n\n"
        "5. Flujo de Asistencia Inteligente y Emergencias:\n"
        "   • Inicio / Mapa --(Chat IA)--> Asistente Virtual Ciudadano (RAG Territorial).\n"
        "   • Inicio / Emergencias --(Hold 2 seg)--> Alarma Crítica CAD / Marcación Telefónica al 123."
    )

    doc.add_page_break()

    # -------------------------------------------------------------
    # SECCIÓN 3: ACTORES DEL SISTEMA Y MATRIZ DE TRAZABILIDAD
    # -------------------------------------------------------------
    add_custom_h1("3. Actores del Sistema y Matriz de Trazabilidad")
    doc.add_paragraph(
        "El sistema combina actores humanos que desempeñan roles institucionales con actores secundarios (hardware y servicios cloud) "
        "que habilitan las capacidades de la plataforma:"
    )

    # Table of actors (Primary and Secondary)
    table_actores = doc.add_table(rows=6, cols=3)
    table_actores.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table_actores)

    h_act = ["Actor", "Categoría y Ámbito", "Responsabilidades y Capacidades Móviles"]
    for i, h in enumerate(h_act):
        cell = table_actores.rows[0].cells[i]
        set_cell_background(cell, HEX_HEADER_BG)
        set_cell_margins(cell, 80, 80, 100, 100)
        p = cell.paragraphs[0]
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(h)
        run.font.bold = True
        run.font.size = Pt(9.5)
        run.font.color.rgb = RGBColor(255, 255, 255)

    act_data = [
        ("Ciudadano / Turista\n(USER)", "Actor Primario Humano\n(App Móvil / PWA)", 
         "Generación de reportes con fotos y GPS, navegación de rutas seguras, activación de botón SOS y diálogo con asistente IA."),
        ("Oficial de Policía\n(OFFICER)", "Actor Primario Humano\n(App Móvil / Web)", 
         "Monitoreo territorial del cuadrante, atención de incidentes en terreno y actualización del estado operativo a 'En Proceso' o 'Resuelto'."),
        ("Administrador Distrital\n(ADMIN / CAD)", "Actor Primario Humano\n(Web / Dashboard)", 
         "Supervisión del Centro de Mando en vivo (Bento Grid), delimitación de zonas de riesgo, auditoría y exportación de actas PDF."),
        ("Hardware del Teléfono\n(GPS, Cámara, Teléfono)", "Actor Secundario\n(Dispositivo Físico)", 
         "Provisión de coordenadas satelitales en tiempo real, captura de evidencia gráfica y ejecución de llamadas de voz telefónicas."),
        ("Servicios Cloud &\nBrokers Externos", "Actor Secundario\n(APIs y Microservicios)", 
         "Groq Cloud API (Llama 3), Cloudinary CDN (imágenes), OpenStreetMap/Esri (mapas) y Broker STOMP WebSocket (alertas en vivo).")
    ]

    for idx, (a_name, a_cat, a_desc) in enumerate(act_data, start=1):
        row = table_actores.rows[idx]
        bg = HEX_LIGHT_ROW if idx % 2 == 1 else 'FFFFFF'
        for c_idx, text in enumerate([a_name, a_cat, a_desc]):
            cell = row.cells[c_idx]
            set_cell_background(cell, bg)
            set_cell_margins(cell, 60, 60, 80, 80)
            p = cell.paragraphs[0]
            p.paragraph_format.space_after = Pt(0)
            run = p.add_run(text)
            run.font.size = Pt(9)
            if c_idx == 0:
                run.font.bold = True
                run.font.color.rgb = COLOR_SECONDARY

    add_custom_h2("3.1 Diagrama General de Casos de Uso (UML)")
    doc.add_paragraph(
        "A continuación se presenta el Diagrama General de Casos de Uso modelando las interacciones entre los actores y los módulos principales:"
    )

    add_image_with_caption(
        "doc_assets/diagram_general_casos_uso.png",
        "Figura 3: Diagrama General de Casos de Uso (UML) — Plataforma Cartagena Segura"
    )

    add_custom_h2("3.2 Matriz de Trazabilidad: Actores vs. Casos de Uso Móviles")
    table_matriz = doc.add_table(rows=13, cols=5)
    table_matriz.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table_matriz)

    m_heads = ["ID", "Caso de Uso", "Actor Primario", "Actores Secundarios", "Permisos Móvil"]
    for i, h in enumerate(m_heads):
        cell = table_matriz.rows[0].cells[i]
        set_cell_background(cell, HEX_HEADER_BG)
        set_cell_margins(cell, 70, 70, 80, 80)
        p = cell.paragraphs[0]
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(h)
        run.font.bold = True
        run.font.size = Pt(9)
        run.font.color.rgb = RGBColor(255, 255, 255)

    matriz_full = [
        ("CU-01", "Autenticación, Registro y Perfil", "Ciudadano, Oficial, Admin", "Google Apps Script (Email)", "Ninguno"),
        ("CU-02", "Reporte de Incidente Ciudadano", "Ciudadano", "GPS, Cámara, Cloudinary, STOMP", "Ubicación GPS, Cámara"),
        ("CU-03", "Exploración de Mapa Geoespacial", "Ciudadano, Oficial, Admin", "OpenStreetMap, Esri, GPS", "Ubicación GPS"),
        ("CU-04", "Asistente de Rutas Seguras", "Ciudadano", "GPS, LatLong2, MongoDB Geo", "Ubicación GPS en primer plano"),
        ("CU-05", "Botón de Pánico SOS y Línea 123", "Ciudadano", "GPS, Telefonía 123, CAD STOMP", "Ubicación GPS, Teléfono"),
        ("CU-06", "Asistente IA Territorial (RAG)", "Ciudadano", "Groq AI (Llama 3), MongoDB", "Ninguno (opcional GPS)"),
        ("CU-07", "Historial de Mis Reportes", "Ciudadano", "Cloudinary CDN (Fotos)", "Ninguno"),
        ("CU-08", "Monitoreo de Cuadrante Policial", "Oficial de Policía", "GPS, Broker STOMP, OpenStreetMap", "Ubicación GPS"),
        ("CU-09", "Gestión del Ciclo de Vida de Incidentes", "Oficial, Administrador", "PostgreSQL (Auditoría), STOMP", "Ninguno"),
        ("CU-10", "Centro de Control Administrativo (Bento)", "Administrador Distrital", "FL Chart, PostgreSQL, MongoDB", "Ninguno"),
        ("CU-11", "Gestión de Cuadrantes y Zonas", "Administrador Distrital", "MongoDB GeoJSON", "Ninguno"),
        ("CU-12", "Exportación de Informes PDF / CSV", "Administrador Distrital", "OpenPDF, Sistema de Archivos", "Almacenamiento"),
    ]

    for idx, (cid, cname, cprim, csec, cperm) in enumerate(matriz_full, start=1):
        row = table_matriz.rows[idx]
        bg = HEX_LIGHT_ROW if idx % 2 == 1 else 'FFFFFF'
        for c_idx, text in enumerate([cid, cname, cprim, csec, cperm]):
            cell = row.cells[c_idx]
            set_cell_background(cell, bg)
            set_cell_margins(cell, 50, 50, 60, 60)
            p = cell.paragraphs[0]
            p.paragraph_format.space_after = Pt(0)
            run = p.add_run(text)
            run.font.size = Pt(8.5)
            if c_idx == 0:
                run.font.bold = True
                run.font.color.rgb = COLOR_SECONDARY

    doc.add_page_break()

    # -------------------------------------------------------------
    # SECCIÓN 4: ESPECIFICACIÓN DETALLADA DE CASOS DE USO MÓVILES
    # -------------------------------------------------------------
    add_custom_h1("4. Especificación Detallada de Casos de Uso Móviles")
    doc.add_paragraph(
        "Cada caso de uso está formulado siguiendo la plantilla metodológica avanzada para aplicaciones móviles, "
        "desglosando explícitamente: Actores Secundarios, Permisos Requeridos del Teléfono, Comportamiento Sin Conexión (Offline) "
        "y Manejo de Interrupciones del Sistema Operativo."
    )

    def add_mobile_use_case_table(cu_id, cu_name, actor_prim, actor_sec, permisos, obj, pre, trigger,
                                  main_flow, alt_flow, offline, interrupciones, rules, post):
        add_custom_h2(f"{cu_id}: {cu_name}")
        table = doc.add_table(rows=13, cols=2)
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        set_table_borders(table)

        fields = [
            ("Identificador y Nombre", f"{cu_id} — {cu_name}"),
            ("Actor(es) Principal(es)", actor_prim),
            ("Actores Secundarios (Sistemas/Hardware)", actor_sec),
            ("Permisos del Teléfono Requeridos", permisos),
            ("Objetivo del Caso de Uso", obj),
            ("Precondiciones", pre),
            ("Disparador (Trigger)", trigger),
            ("Flujo Principal de Eventos", main_flow),
            ("Flujos Alternativos / Excepciones", alt_flow),
            ("Sin Conexión (Modo Offline)", offline),
            ("Manejo de Interrupciones (Llamadas/Batería)", interrupciones),
            ("Reglas de Negocio y Seguridad", rules),
            ("Postcondiciones", post)
        ]

        for i, (fname, fval) in enumerate(fields):
            row = table.rows[i]
            c_lbl, c_val = row.cells[0], row.cells[1]
            c_lbl.width = Inches(2.2)
            c_val.width = Inches(4.3)
            set_cell_background(c_lbl, HEX_LIGHT_ROW)
            set_cell_background(c_val, 'FFFFFF')
            set_cell_margins(c_lbl, 55, 55, 80, 80)
            set_cell_margins(c_val, 55, 55, 80, 80)

            p0 = c_lbl.paragraphs[0]
            p0.paragraph_format.space_after = Pt(0)
            r0 = p0.add_run(fname)
            r0.font.bold = True
            r0.font.size = Pt(9)
            r0.font.color.rgb = COLOR_SECONDARY

            p1 = c_val.paragraphs[0]
            p1.paragraph_format.space_after = Pt(0)
            r1 = p1.add_run(fval)
            r1.font.size = Pt(9)

        p_sp = doc.add_paragraph()
        p_sp.paragraph_format.space_before = Pt(3)
        p_sp.paragraph_format.space_after = Pt(5)

    # CU-01
    add_mobile_use_case_table(
        cu_id="CU-01",
        cu_name="Autenticación, Registro y Recuperación de Contraseña",
        actor_prim="Ciudadano / Turista, Oficial de Policía, Administrador",
        actor_sec="Google Apps Script (despacho de emails), Base de Datos PostgreSQL",
        permisos="Ninguno requerido para esta operación.",
        obj="Permitir a los usuarios crear cuentas seguras, autenticarse mediante JWT con control de roles y recuperar el acceso ante olvido de contraseña.",
        pre="La aplicación debe estar desplegada y con conexión a la API REST.",
        trigger="El usuario abre la aplicación y visualiza la pantalla de bienvenida o pulsa 'Iniciar Sesión'.",
        main_flow=(
            "1. El usuario ingresa usuario/correo y contraseña en SignInScreen.\n"
            "2. El cliente valida que los campos no estén vacíos.\n"
            "3. Petición POST a /api/auth/login transmitiendo credenciales.\n"
            "4. Spring Security valida el hash BCrypt en PostgreSQL.\n"
            "5. Se emite token JWT con firma criptográfica y rol.\n"
            "6. FlutterSecureStorage almacena el token cifrado en el dispositivo.\n"
            "7. GoRouter redirige según rol: /Admin si es administrador o /App si es ciudadano."
        ),
        alt_flow=(
            "• Contraseña incorrecta: Muestra alerta modal de error y permite reintentar.\n"
            "• Recuperación de acceso: El usuario solicita token temporal enviado a su correo electrónico mediante Google Apps Script."
        ),
        offline="Sin internet, se muestra banner informando que la autenticación requiere conectividad. Si existía una sesión previa válida en caché seguro, se permite acceso en modo lectura.",
        interrupciones="Si entra una llamada mientras se escribe la contraseña, el campo permanece protegido y el formulario conserva los datos digitados.",
        rules="Contraseña mínima de 8 caracteres con mayúscula, número y símbolo. Hashing BCrypt unidireccional.",
        post="Usuario con sesión JWT activa y enrutamiento a su vista autorizada."
    )

    # CU-02
    add_mobile_use_case_table(
        cu_id="CU-02",
        cu_name="Reporte Ciudadano con Evidencia Multimedia y GPS",
        actor_prim="Ciudadano / Turista (USER)",
        actor_sec="Sensor GPS (Geolocator), Cámara/Galería (ImagePicker), Cloudinary CDN, Broker STOMP",
        permisos="Ubicación precisa (GPS en primer plano) y Acceso a Cámara / Almacenamiento multimedia.",
        obj="Registrar en tiempo real una situación de riesgo con coordenadas satelitales certificadas y fotografía de evidencia probatoria.",
        pre="Sesión iniciada y permisos de GPS y cámara otorgados.",
        trigger="El usuario pulsa el botón flotante 'Reportar' o navega a la pestaña de reportes.",
        main_flow=(
            "1. La app captura la coordenada satelital GPS actual con alta precisión mediante Geolocator.\n"
            "2. El usuario selecciona la tipología del delito (Hurto, Riña, Sospechoso, etc.) y digita el detalle.\n"
            "3. Pulsa 'Adjuntar Foto' abriendo la cámara o galería mediante image_picker.\n"
            "4. Pulsa 'Publicar Reporte': el archivo se envía a /api/upload validando Magic Bytes y subiendo a Cloudinary.\n"
            "5. Se invoca /api/incidents; el backend persiste el reporte en MongoDB y audita en PostgreSQL.\n"
            "6. Se notifica en tiempo real al tópico STOMP /topic/incidents para alerta en el cuadrante policial."
        ),
        alt_flow=(
            "• Permiso de GPS denegado: Se despliega diálogo guiado (LocationGuideDialog) para activación satelital.\n"
            "• Archivo binario malicioso: FileUploadController rechaza la imagen si las firmas de bytes no son JPG/PNG."
        ),
        offline="Si no hay datos móviles, el reporte completo (texto, coordenadas tomadas y foto) se almacena localmente en ReportDraftStore para sincronización automática al recuperar cobertura.",
        interrupciones="Si entra una llamada o la app se minimiza, el borrador y la fotografía tomada se retienen intactos en memoria sin obligar a reiniciar el reporte.",
        rules="Validación estricta de Magic Bytes. Coordenadas restringidas al área metropolitana de Cartagena.",
        post="Incidente registrado en MongoDB en estado REPORTADO y transmitido a patrullas."
    )

    add_image_with_caption(
        "doc_assets/diagram_flujo_reporte.png",
        "Figura 4: Flujo y Secuencia para el Caso de Uso CU-02 (Reporte con Multimedia y GPS)"
    )

    # CU-03
    add_mobile_use_case_table(
        cu_id="CU-03",
        cu_name="Exploración del Mapa Interactivo Geoespacial y Zonas de Riesgo",
        actor_prim="Ciudadano, Oficial de Policía, Administrador",
        actor_sec="Sensor GPS, Servidores OpenStreetMap y Esri Satelital, Base de Datos MongoDB",
        permisos="Ubicación precisa (GPS).",
        obj="Visualizar la distribución espacial de incidentes activos, polígonos de alerta y posición satelital propia.",
        pre="Acceso a la pestaña 'Mapa' en la barra de navegación.",
        trigger="El usuario pulsa la pestaña 'Mapa' o abre la aplicación.",
        main_flow=(
            "1. La app descarga los incidentes y polígonos de zonas de riesgo desde la API REST.\n"
            "2. Flutter Map renderiza las capas OpenStreetMap o Esri Satelital con vectorización fluida a 60 FPS.\n"
            "3. Se dibujan los polígonos translúcidos de riesgo y se agrupan incidentes mediante clustering dinámico.\n"
            "4. Un radar pulsante indica la ubicación GPS en tiempo real del usuario.\n"
            "5. Al tocar un marcador, se despliega una tarjeta flotante con foto, hora y estado del incidente."
        ),
        alt_flow=(
            "• Conmutación satelital: El usuario cambia entre mapa vectorial y vista fotográfica aérea Esri.\n"
            "• Filtros de mapa: Filtrado por gravedad, tipo de delito y estado (Reportado, En Proceso, Resuelto)."
        ),
        offline="Las teselas visualizadas recientemente se leen desde la memoria caché. Se muestran los incidentes previamente descargados con etiqueta de 'Datos cacheados'.",
        interrupciones="Al regresar de otra aplicación, el mapa restaura el nivel de zoom y centro de coordenadas exacto.",
        rules="Anonimización estricta de datos del denunciante en los marcadores públicos.",
        post="Usuario con conocimiento situacional del entorno barrial en Cartagena."
    )

    # CU-04
    add_mobile_use_case_table(
        cu_id="CU-04",
        cu_name="Asistente de Rutas Seguras Inteligentes (Waze Preventivo)",
        actor_prim="Ciudadano / Turista (USER)",
        actor_sec="Sensor GPS satelital, Motor LatLong2, Polígonos de Riesgo en MongoDB",
        permisos="Ubicación precisa en primer plano.",
        obj="Calcular y trazar rutas de desplazamiento que eludan polígonos delictivos de alta peligrosidad y concentración de hurtos.",
        pre="GPS activado y mapa cargado.",
        trigger="El usuario pulsa 'Ruta Segura' y selecciona su destino (ej. Torre del Reloj, Bocagrande, Getsemaní).",
        main_flow=(
            "1. El usuario selecciona su destino mediante DestinationSearchDialog.\n"
            "2. SafeRouteService calcula la ruta entre el origen GPS actual y el destino empleando LatLong2.\n"
            "3. El algoritmo evalúa la proximidad del trayecto frente a los polígonos de riesgo e incidentes en MongoDB.\n"
            "4. Si la ruta pasa por un sector crítico, se generan waypoints de desvío preventivo.\n"
            "5. Se renderiza la polilínea azul de trayecto seguro y se despliega la hoja SafeRouteSheet.\n"
            "6. El ciudadano inicia su navegación con radar satelital continuo."
        ),
        alt_flow=(
            "• Desvío involuntario: Si el usuario se aparta de la ruta y penetra una zona roja, la app emite alerta háptica y sonora preventiva."
        ),
        offline="Si se pierde la señal de internet durante el trayecto, la polilínea calculada permanece visible en pantalla con el indicador GPS nativo del teléfono.",
        interrupciones="Si el usuario apaga la pantalla temporalmente o atiende una llamada breve, al reabrir la app el trayecto trazado continúa guiándolo.",
        rules="La seguridad física y prevención prevalece sobre la distancia métrica más corta.",
        post="Ciudadano navegando con acompañamiento geográfico seguro."
    )

    add_image_with_caption(
        "doc_assets/diagram_flujo_rutas_seguras.png",
        "Figura 5: Lógica de Ponderación Geoespacial y Decisión de Rutas Seguras (CU-04)"
    )

    # CU-05
    add_mobile_use_case_table(
        cu_id="CU-05",
        cu_name="Activación de Botón de Pánico SOS y Línea 123",
        actor_prim="Ciudadano / Turista (USER)",
        actor_sec="Sensor GPS, Marcador Telefónico Nativo (UrlLauncher), Broker STOMP al CAD",
        permisos="Ubicación satelital precisa y Permiso para iniciar llamadas telefónicas.",
        obj="Enviar una señal de auxilio crítico con coordenadas satelitales al CAD y enlazar telefónicamente a la línea 123.",
        pre="Aplicación instalada y teléfono con señal de red.",
        trigger="El usuario mantiene presionado el botón rojo 'SOS' durante 2 segundos continuos.",
        main_flow=(
            "1. El ciudadano realiza una pulsación prolongada (LongPress) sobre el botón SOS.\n"
            "2. La app genera una vibración háptica de confirmación para evitar activaciones accidentales.\n"
            "3. Se obtiene la coordenada GPS instantánea con máxima precisión satelital.\n"
            "4. Se despacha un paquete de emergencia prioritario al backend marcando alerta roja.\n"
            "5. El módulo UrlLauncher inicia la marcación directa a la línea de emergencia 123 de la Policía Nacional.\n"
            "6. En pantalla se ofrecen accesos directos a Bomberos, Cruz Roja, Defensa Civil y Armada."
        ),
        alt_flow=(
            "• Pulsación corta accidental: La app no se activa y muestra animación indicando 'Mantén presionado por 2 segundos'."
        ),
        offline="Si no hay datos móviles, la app prioriza inmediatamente la llamada telefónica tradicional (Voz GSM) al 123, garantizando auxilio incluso sin cobertura de internet.",
        interrupciones="La marcación telefónica toma el control del sistema operativo de forma prioritaria sobre cualquier otra aplicación en segundo plano.",
        rules="Tiempo de activación anti-falsos positivos: 2.0 segundos de presión sostenida.",
        post="Centro de despacho CAD alertado y llamada de emergencia en curso con la Policía."
    )

    add_image_with_caption(
        "doc_assets/diagram_flujo_sos.png",
        "Figura 6: Despliegue de Emergencia y Enlace Telefónico para el Caso de Uso CU-05 (Botón SOS)"
    )

    # CU-06
    add_mobile_use_case_table(
        cu_id="CU-06",
        cu_name="Asistencia Ciudadana Inteligente con IA (RAG Territorial)",
        actor_prim="Ciudadano / Turista (USER)",
        actor_sec="Motor Groq Cloud API (Llama 3), Motor Heurístico Local, Colección de Incidentes MongoDB",
        permisos="Ninguno obligatorio (Ubicación GPS opcional para contexto barrial).",
        obj="Proveer recomendaciones de seguridad urbana, alertas y orientación turística mediante un asistente virtual con RAG.",
        pre="Acceso a la pantalla CitizenChatScreen.",
        trigger="El usuario formula una consulta sobre seguridad de un sector o prevención en la ciudad.",
        main_flow=(
            "1. El usuario digita su duda (ej. '¿Qué recomendaciones debo tener en Manga a las 9 PM?').\n"
            "2. El mensaje se transmite al controlador AiController en el backend.\n"
            "3. AiService recupera dinámicamente incidentes y sectores recientes desde MongoDB (RAG Contextual).\n"
            "4. Se ensambla un prompt enriquecido con datos territoriales de Cartagena.\n"
            "5. Se envía al modelo Llama 3 en Groq Cloud (o al Motor Heurístico Local en caso de falla externa).\n"
            "6. El asistente retorna una respuesta estructurada con tips prácticos y líneas de auxilio."
        ),
        alt_flow=(
            "• Detección de peligro inminente: Si la consulta indica una agresión activa, el chatbot ofrece enlace directo al 123.\n"
            "• Falla de API externa Groq: Conmutación transparente al motor heurístico local sin interrumpir el chat."
        ),
        offline="Si no hay internet, el chat notifica amablemente que requiere conectividad para procesar la consulta y ofrece el directorio telefónico de emergencia.",
        interrupciones="El historial de la conversación se guarda en el estado local de Riverpod, manteniéndose visible tras llamadas o cambio de app.",
        rules="Conocimiento territorial enfocado exclusivamente en Cartagena de Indias.",
        post="Ciudadano capacitado con pautas de prevención informadas."
    )

    add_image_with_caption(
        "doc_assets/diagram_flujo_ia_rag.png",
        "Figura 7: Arquitectura de Inferencia Dual y RAG Context-Aware para el Asistente IA (CU-06)"
    )

    # CU-07
    add_mobile_use_case_table(
        cu_id="CU-07",
        cu_name="Historial y Seguimiento de Reportes Propios ('Mis Reportes')",
        actor_prim="Ciudadano / Turista (USER)",
        actor_sec="Servidor Cloudinary CDN (imágenes), Base de Datos MongoDB",
        permisos="Ninguno requerido.",
        obj="Monitorear el estado, evolución y respuestas policiales sobre denuncias radicadas anteriormente por el usuario.",
        pre="Usuario con sesión autenticada.",
        trigger="El usuario pulsa la pestaña 'Reportes' en la barra inferior.",
        main_flow=(
            "1. La app solicita a /api/incidents/my-reports los reportes asociados al identificador del usuario.\n"
            "2. Se renderizan tarjetas cronológicas con insignias de estado (Reportado, En Proceso, Resuelto).\n"
            "3. Al tocar un reporte, se visualizan las observaciones agregadas por la policía y la foto de evidencia."
        ),
        alt_flow="• Usuario sin denuncias: Se muestra ilustración informativa invitando al uso preventivo.",
        offline="Se visualizan los reportes que quedaron cacheados en la última sincronización.",
        interrupciones="La lista mantiene su posición de scroll si el usuario cambia temporalmente de app.",
        rules="Privacidad estricta: ningún ciudadano puede ver reportes ajenos en su panel personal.",
        post="Ciudadano informado sobre las acciones tomadas frente a su reporte."
    )

    # CU-08
    add_mobile_use_case_table(
        cu_id="CU-08",
        cu_name="Monitoreo Territorial en Vivo de Cuadrante Policial",
        actor_prim="Oficial de Policía / Cuadrante (OFFICER)",
        actor_sec="Broker STOMP WebSocket, Sensor GPS, OpenStreetMap",
        permisos="Ubicación satelital precisa.",
        obj="Permitir a las patrullas policiales supervisar su zona de responsabilidad y reaccionar ante alertas tempranas.",
        pre="Oficial autenticado con credenciales de rol OFFICER.",
        trigger="El oficial inicia patrullaje o recibe una alerta de nuevo incidente.",
        main_flow=(
            "1. La app detecta el rol policial y habilita el modo operativo de cuadrante.\n"
            "2. Se establece conexión WebSocket STOMP al canal de novedades operativas.\n"
            "3. El mapa dibuja el perímetro del cuadrante asignado y los incidentes pendientes de atención.\n"
            "4. El oficial selecciona un incidente para conocer la ruta de llegada y ver las evidencias."
        ),
        alt_flow="• Sin incidentes en turno: Se muestra indicador de cuadrante despejado en vigilancia pasiva.",
        offline="El mapa satelital precargado permite orientarse aun si la red de datos oscila durante el recorrido.",
        interrupciones="Si el oficial atiende llamadas de la central radial, la app retoma el mapa operativo sin demoras.",
        rules="Acceso operativo restringido a la jurisdicción de su cuadrante asignado.",
        post="Patrulla policial desplegada con conciencia situacional geoespacial."
    )

    # CU-09
    add_mobile_use_case_table(
        cu_id="CU-09",
        cu_name="Gestión del Ciclo de Vida y Transición de Estados de Incidentes",
        actor_prim="Oficial de Policía, Administrador Distrital",
        actor_sec="Base de Datos PostgreSQL (Auditoría inmutable), Broker STOMP, MongoDB",
        permisos="Ninguno.",
        obj="Administrar la máquina de estados de un incidente desde su recepción hasta su resolución o descarte oficial.",
        pre="Incidente existente y usuario con rol OFFICER o ADMIN.",
        trigger="El operador policial o administrador atiende o concluye un caso.",
        main_flow=(
            "1. El operador abre el incidente desde la consola de gestión.\n"
            "2. Selecciona el nuevo estado operativo en el selector (ej. EN_PROCESO, RESUELTO).\n"
            "3. Ingresa las observaciones y actuaciones policiales realizadas.\n"
            "4. Se envía petición PATCH a /api/incidents/{id}/status actualizando MongoDB.\n"
            "5. LogService registra la acción en audit_logs de PostgreSQL con usuario y timestamp.\n"
            "6. Se notifica vía WebSocket al sistema y al ciudadano denunciante."
        ),
        alt_flow="• Falsa Alarma: Se transiciona a RECHAZADO documentando la inconsistencia detectada.",
        offline="La actualización de estados requiere confirmación en línea para asegurar la integridad jurídica.",
        interrupciones="El texto de la observación policial no se borra si se minimiza la app antes de guardar.",
        rules="Transiciones válidas: REPORTADO -> EN_REVISION -> ASIGNADO -> EN_PROCESO -> RESUELTO / RECHAZADO.",
        post="Estado del incidente sincronizado y registrado en la bitácora inmutable distrital."
    )

    add_image_with_caption(
        "doc_assets/diagram_ciclo_vida_incidente.png",
        "Figura 8: Máquina de Estados Finita para el Ciclo de Vida del Incidente (CU-09)"
    )

    # CU-10
    add_mobile_use_case_table(
        cu_id="CU-10",
        cu_name="Centro de Control Administrativo y Analítica en Tiempo Real (Bento Grid)",
        actor_prim="Administrador Distrital (ADMIN)",
        actor_sec="Motor FL Chart, PostgreSQL, MongoDB, STOMP WebSockets",
        permisos="Ninguno.",
        obj="Supervisar las métricas de criminalidad, tiempos de respuesta policial y efectividad mediante paneles Bento Grid.",
        pre="Usuario autenticado con rol ADMIN.",
        trigger="El administrador ingresa a la consola AdminShell.",
        main_flow=(
            "1. La plataforma consulta los indicadores agregados en PostgreSQL y MongoDB.\n"
            "2. Se disponen las métricas en cuadrícula asimétrica Bento Grid.\n"
            "3. Se visualizan contadores en vivo: Total Incidentes, Resueltos, Zonas Activas y Usuarios.\n"
            "4. FL Chart renderiza gráficos dinámicos de distribución por tipología delictiva.\n"
            "5. Se habilitan filtros por fecha, comuna y nivel de severidad."
        ),
        alt_flow="• Alerta de pico delictivo: La interfaz resalta en rojo Obsidian las comunas con anomalías.",
        offline="Permite visualizar las últimas métricas consolidadas en caché.",
        interrupciones="La consola se recarga reactivamente al volver al navegador o app.",
        rules="Consultas optimizadas para evitar sobrecarga en la base de datos de producción.",
        post="Cuadro directivo con telemetría integral para toma de decisiones públicas."
    )

    add_image_with_caption(
        "doc_assets/diagram_centro_mando_admin.png",
        "Figura 9: Arquitectura de Componentes del Centro de Mando Administrativo (CU-10 / CU-12)"
    )

    # CU-11
    add_mobile_use_case_table(
        cu_id="CU-11",
        cu_name="Configuración de Cuadrantes y Polígonos de Riesgo Distrital",
        actor_prim="Administrador Distrital (ADMIN)",
        actor_sec="Motor de Mapas, MongoDB GeoJSON",
        permisos="Ninguno.",
        obj="Delimitar, actualizar o rediseñar las áreas de riesgo y cuadrantes de cobertura policial.",
        pre="Permisos de administrador concedidos.",
        trigger="El administrador ingresa a la pestaña 'Zonas y Cuadrantes'.",
        main_flow=(
            "1. El administrador visualiza los polígonos de riesgo sobre el mapa de Cartagena.\n"
            "2. Pulsa 'Crear Zona' o selecciona un polígono existente para modificar.\n"
            "3. Traza las coordenadas perimetrales y define el nivel de criticidad (Bajo, Medio, Alto).\n"
            "4. Guarda la configuración en MongoDB mediante ZoneController.\n"
            "5. Las nuevas zonas entran en vigencia de inmediato en el cálculo de Rutas Seguras ciudadanas."
        ),
        alt_flow="• Polígono incompleto: El sistema exige al menos 3 vértices para formar un perímetro cerrado.",
        offline="Requiere conectividad con el cluster MongoDB.",
        interrupciones="Los vértices ingresados se conservan en el borrador si se interrumpe la edición.",
        rules="Las zonas deben corresponder a la división barrial oficial del Distrito de Cartagena.",
        post="Polígonos de riesgo actualizados e integrados en la cartografía comunitaria."
    )

    # CU-12
    add_mobile_use_case_table(
        cu_id="CU-12",
        cu_name="Generación y Exportación de Informes Oficiales en PDF y CSV",
        actor_prim="Administrador Distrital (ADMIN)",
        actor_sec="Motor OpenPDF en Spring Boot, Gestor de Descargas del Navegador/Móvil",
        permisos="Permiso de descarga / acceso al almacenamiento de archivos.",
        obj="Producir actas oficiales descargables con el consolidated de incidentes, estadísticas y bitácoras de auditoría.",
        pre="Datos existentes en el período consultado.",
        trigger="El administrador pulsa 'Exportar PDF' o 'Descargar CSV'.",
        main_flow=(
            "1. El administrador selecciona el rango de fechas y filtros deseados.\n"
            "2. Al pulsar 'Exportar PDF', PdfReportService compila el documento formal en Spring Boot con OpenPDF.\n"
            "3. Se genera un archivo PDF institucional con membrete, tablas y firmas digitales.\n"
            "4. El navegador o dispositivo móvil descarga automáticamente el documento binario.\n"
            "5. Se audita la exportación en audit_logs de PostgreSQL."
        ),
        alt_flow="• Exportación plana: La opción CSV genera una tabla compatible con Excel o Power BI.",
        offline="Requiere conexión para solicitar la compilación en el servidor.",
        interrupciones="La descarga se reanuda automáticamente si hay microcortes de red.",
        rules="Inclusión de fecha de expedición, sellos de autenticidad y marca de agua institucional.",
        post="Acta oficial archivada para soporte judicial o rendición de cuentas distritales."
    )

    doc.add_page_break()

    # -------------------------------------------------------------
    # SECCIÓN 5: REQUISITOS NO FUNCIONALES EN EL ENTORNO MÓVIL
    # -------------------------------------------------------------
    add_custom_h1("5. Requisitos No Funcionales Aplicados al Entorno Móvil")
    doc.add_paragraph(
        "Para responder satisfactoriamente a las particularidades de los dispositivos móviles señaladas en el marco conceptual, "
        "la plataforma satisface los siguientes estándares de calidad técnica (ISO/IEC 25010):"
    )

    table_rnf = doc.add_table(rows=6, cols=3)
    table_rnf.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table_rnf)

    rnf_h = ["Criterio de Calidad", "Desafío en el Dispositivo Móvil", "Solución Implementada en Cartagena Segura"]
    for i, h in enumerate(rnf_h):
        cell = table_rnf.rows[0].cells[i]
        set_cell_background(cell, HEX_HEADER_BG)
        set_cell_margins(cell, 80, 80, 100, 100)
        p = cell.paragraphs[0]
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(h)
        run.font.bold = True
        run.font.size = Pt(9.5)
        run.font.color.rgb = RGBColor(255, 255, 255)

    rnf_rows = [
        ("Eficiencia Energética\n(Batería)", 
         "El rastreo GPS continuo agota rápidamente la batería en desplazamientos a pie o en vehículo.",
         "Fijación satelital bajo demanda al reportar; en rutas seguras se emplean intervalos de actualización optimizados con umbrales de distancia."),
        ("Tolerancia a Conectividad\nIntermitente", 
         "Pérdida de señal de datos en sectores turísticos congestionados o zonas insulares.",
         "Persistencia local de borradores en ReportDraftStore, soporte para llamadas de voz GSM al 123 sin datos y caché de mapas vectoriales."),
        ("Seguridad y Cifrado\nLocal", 
         "Riesgo de extracción de credenciales ante extravío o hurto del teléfono.",
         "Almacenamiento del JWT en FlutterSecureStorage (Keystore en Android / Keychain en iOS). Validación criptográfica de Magic Bytes."),
        ("Tiempo de Respuesta y\nFluidez Visual", 
         "Procesamiento gráfico fluido en pantallas con diferentes tasas de refresco (60-120 Hz).",
         "Renderizado de mapas vectoriales con Flutter Map a 60 FPS estables y Virtual Threads en Java 21 para latencias de API < 200 ms."),
        ("Multiplataforma y\nAdaptabilidad PWA", 
         "Diferentes resoluciones de pantalla entre teléfonos compactos, tabletas y computadores.",
         "Diseño responsivo con Material Design 3, soporte PWA instalable con Service Worker y manifest.json sin necesidad de tiendas oficiales.")
    ]

    for idx, (crit, des, sol) in enumerate(rnf_rows, start=1):
        row = table_rnf.rows[idx]
        bg = HEX_LIGHT_ROW if idx % 2 == 1 else 'FFFFFF'
        for c_idx, text in enumerate([crit, des, sol]):
            cell = row.cells[c_idx]
            set_cell_background(cell, bg)
            set_cell_margins(cell, 60, 60, 80, 80)
            p = cell.paragraphs[0]
            p.paragraph_format.space_after = Pt(0)
            run = p.add_run(text)
            run.font.size = Pt(9)
            if c_idx == 0:
                run.font.bold = True
                run.font.color.rgb = COLOR_SECONDARY

    # -------------------------------------------------------------
    # SECCIÓN 6: CONCLUSIONES Y FIRMAS
    # -------------------------------------------------------------
    add_custom_h1("6. Conclusiones y Validación Formal")
    doc.add_paragraph(
        "La integración del marco conceptual móvil (Actores secundarios, Permisos del teléfono, Modo sin conexión e Interrupciones del sistema) "
        "con el diagrama de navegación de pantallas posiciona a 'Cartagena Segura' como una arquitectura de software rigurosa, "
        "altamente usable y preparada para escenarios críticos del mundo real."
    )

    p_sig = doc.add_paragraph()
    p_sig.paragraph_format.space_before = Pt(20)
    p_sig.paragraph_format.space_after = Pt(8)

    table_firmas = doc.add_table(rows=2, cols=3)
    table_firmas.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table_firmas, color='E2E8F0')

    firmas = [
        "Juan Esteban de los Ríos Tibocha\nLíder de Desarrollo & Arquitectura",
        "Robinson Emiro Castaño Mercado\nIngeniero Frontend & Geoespacial",
        "Álvaro Cervantes Noel\nIngeniero Backend & DevOps"
    ]

    for col_idx, ftext in enumerate(firmas):
        c0 = table_firmas.rows[0].cells[col_idx]
        c1 = table_firmas.rows[1].cells[col_idx]
        set_cell_margins(c0, 100, 10, 80, 80)
        set_cell_margins(c1, 10, 80, 80, 80)

        p_line = c0.paragraphs[0]
        p_line.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r_l = p_line.add_run("______________________________")
        r_l.font.color.rgb = RGBColor(148, 163, 184)

        p_txt = c1.paragraphs[0]
        p_txt.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r_t = p_txt.add_run(ftext)
        r_t.font.bold = True
        r_t.font.size = Pt(9)
        r_t.font.color.rgb = COLOR_SECONDARY

    output_path = "Casos_de_Uso_Cartagena_Segura.docx"
    doc.save(output_path)
    print(f"Updated document saved successfully as '{output_path}'!")

if __name__ == "__main__":
    build_complete_document()
