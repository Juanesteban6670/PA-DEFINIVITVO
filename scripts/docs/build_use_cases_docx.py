import os
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

def create_document():
    doc = docx.Document()

    # 1. Page Margins (Normal: 1 inch / 2.54 cm)
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
    HEX_SUBHEADER_BG = '0284C7'                # Cyan/Sky
    HEX_LIGHT_ROW = 'F8FAFC'                   # Slate 50
    HEX_ACCENT_BG = 'EFF6FF'                   # Blue 50
    HEX_BORDER = 'CBD5E1'                      # Slate 300

    # Helper: Set cell background
    def set_cell_background(cell, hex_color):
        tcPr = cell._tc.get_or_add_tcPr()
        shd = OxmlElement('w:shd')
        shd.set(qn('w:val'), 'clear')
        shd.set(qn('w:color'), 'auto')
        shd.set(qn('w:fill'), hex_color)
        tcPr.append(shd)

    # Helper: Set table borders
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

    # Helper: Set cell margins (padding)
    def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
        tcPr = cell._tc.get_or_add_tcPr()
        tcMar = OxmlElement('w:tcMar')
        for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
            node = OxmlElement(f'w:{m}')
            node.set(qn('w:w'), str(val))
            node.set(qn('w:type'), 'dxa')
            tcMar.append(node)
        tcPr.append(tcMar)

    # Set Base Normal Style
    normal_style = doc.styles['Normal']
    normal_style.font.name = 'Calibri'
    normal_style.font.size = Pt(11)
    normal_style.font.color.rgb = COLOR_TEXT
    normal_style.paragraph_format.line_spacing = 1.15
    normal_style.paragraph_format.space_after = Pt(6)

    # Helper: Heading 1
    def add_custom_h1(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(18)
        p.paragraph_format.space_after = Pt(8)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.font.name = 'Calibri'
        run.font.size = Pt(18)
        run.font.bold = True
        run.font.color.rgb = COLOR_SECONDARY
        return p

    # Helper: Heading 2
    def add_custom_h2(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(14)
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.font.name = 'Calibri'
        run.font.size = Pt(14)
        run.font.bold = True
        run.font.color.rgb = COLOR_ACCENT
        return p

    # Helper: Heading 3
    def add_custom_h3(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(10)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.font.name = 'Calibri'
        run.font.size = Pt(12)
        run.font.bold = True
        run.font.color.rgb = COLOR_PRIMARY
        return p

    # Helper: Callout box
    def add_callout_box(text, prefix="NOTA:"):
        table = doc.add_table(rows=1, cols=1)
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        cell = table.cell(0, 0)
        cell.width = Inches(6.5)
        set_cell_background(cell, 'F1F5F9')
        set_cell_margins(cell, top=140, bottom=140, left=180, right=180)

        # left border blue, others none
        tcPr = cell._tc.get_or_add_tcPr()
        tblBorders = OxmlElement('w:tcBorders')
        left = OxmlElement('w:left')
        left.set(qn('w:val'), 'single')
        left.set(qn('w:sz'), '24') # thick border
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

    # Helper: Add image with caption
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
        p_cov.paragraph_format.space_after = Pt(18)
        run_cov = p_cov.add_run()
        run_cov.add_picture("doc_assets/cover_banner.jpg", width=Inches(6.5))

    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_title.paragraph_format.space_before = Pt(14)
    p_title.paragraph_format.space_after = Pt(4)
    r_tit = p_title.add_run("ESPECIFICACIÓN DE CASOS DE USO")
    r_tit.font.name = 'Calibri'
    r_tit.font.size = Pt(24)
    r_tit.font.bold = True
    r_tit.font.color.rgb = COLOR_SECONDARY

    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_sub.paragraph_format.space_before = Pt(2)
    p_sub.paragraph_format.space_after = Pt(20)
    r_sub = p_sub.add_run("Plataforma de Seguridad Ciudadana, Monitoreo Geoespacial\ny Asistencia Inteligente — Cartagena Segura")
    r_sub.font.name = 'Calibri'
    r_sub.font.size = Pt(13)
    r_sub.font.color.rgb = COLOR_ACCENT

    # Metadata Table
    table_meta = doc.add_table(rows=7, cols=2)
    table_meta.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table_meta)

    meta_data = [
        ("Proyecto:", "Cartagena Segura (Plataforma Distrital de Seguridad Ciudadana)"),
        ("Tipo de Documento:", "Especificación Formal de Casos de Uso del Software (SRS / UML)"),
        ("Versión del Sistema:", "Versión 2.3.0 (Release de Producción)"),
        ("Despliegue Oficial en Vivo:", "https://pa-definivitvo.onrender.com (Render Cloud 24/7)"),
        ("Autores y Desarrolladores:", "Juan Esteban de los Ríos Tibocha\nRobinson Emiro Castaño Mercado\nÁlvaro Cervantes Noel"),
        ("Stack Tecnológico Base:", "Frontend: Flutter 3.47 (Web/PWA/Mobile) + Riverpod + Flutter Map\nBackend: Spring Boot 3.4.3 (Java 21 LTS) + Spring Security 6\nBases de Datos: PostgreSQL 16 (Relacional) + MongoDB 7 (NoSQL Geo)\nInteligencia Artificial: Motor RAG Dual (Groq Llama 3 / Heurístico Local)"),
        ("Fecha de Publicación:", "Noviembre de 2026"),
    ]

    for idx, (label, val) in enumerate(meta_data):
        row = table_meta.rows[idx]
        cell_lbl, cell_val = row.cells[0], row.cells[1]
        cell_lbl.width = Inches(2.3)
        cell_val.width = Inches(4.2)
        set_cell_background(cell_lbl, HEX_LIGHT_ROW)
        set_cell_background(cell_val, 'FFFFFF')
        set_cell_margins(cell_lbl, 80, 80, 120, 120)
        set_cell_margins(cell_val, 80, 80, 120, 120)

        p0 = cell_lbl.paragraphs[0]
        p0.paragraph_format.space_after = Pt(0)
        r0 = p0.add_run(label)
        r0.font.bold = True
        r0.font.size = Pt(10)
        r0.font.color.rgb = COLOR_SECONDARY

        p1 = cell_val.paragraphs[0]
        p1.paragraph_format.space_after = Pt(0)
        r1 = p1.add_run(val)
        r1.font.size = Pt(10)

    doc.add_page_break()

    # -------------------------------------------------------------
    # SECCIÓN 1: INTRODUCCIÓN Y ALCANCE
    # -------------------------------------------------------------
    add_custom_h1("1. Introducción y Alcance del Sistema")
    doc.add_paragraph(
        "El presente documento técnico establece la especificación detallada de los Casos de Uso que rigen la operación de "
        "la plataforma 'Cartagena Segura'. La solución responde a los desafíos críticos de seguridad pública, prevención "
        "delictiva y coordinación de emergencias en el Distrito Turístico y Cultural de Cartagena de Indias, integrando a "
        "la ciudadanía, a los visitantes internacionales, al cuerpo policial por cuadrantes y a los administradores del "
        "Centro de Mando Distrital (CAD)."
    )
    doc.add_paragraph(
        "A diferencia de aplicaciones convencionales de denuncia ciudadana, 'Cartagena Segura' implementa un enfoque preventivo "
        "y de reacción inmediata apoyado en georreferenciación satelital precisa, algoritmos de cálculo de rutas seguras tipo Waze, "
        "validación criptográfica de evidencias fotográficas (Magic Bytes) y un motor híbrido de Inteligencia Artificial contextual (RAG)."
    )

    add_callout_box(
        "Todos los casos de uso documentados a continuación se encuentran implementados, probados y verificados tanto "
        "en la suite de pruebas unitarias/de widgets como en el despliegue oficial cloud disponible en Render.",
        prefix="ESTADO OPERATIVO:"
    )

    # -------------------------------------------------------------
    # SECCIÓN 2: IDENTIFICACIÓN Y PERFILES DE ACTORES
    # -------------------------------------------------------------
    add_custom_h1("2. Identificación y Perfiles de Actores del Sistema")
    doc.add_paragraph(
        "El sistema delimita estrictamente el control de acceso basado en roles (RBAC) mediante Spring Security 6 y tokens JWT. "
        "A continuación se detallan los tres actores humanos principales y los sistemas externos interactuantes:"
    )

    table_actores = doc.add_table(rows=5, cols=3)
    table_actores.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table_actores)

    headers_act = ["Actor / Rol", "Tipo y Ámbito", "Responsabilidades y Capacidades Principales"]
    for i, h in enumerate(headers_act):
        cell = table_actores.rows[0].cells[i]
        set_cell_background(cell, HEX_HEADER_BG)
        set_cell_margins(cell, 100, 100, 120, 120)
        p = cell.paragraphs[0]
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(h)
        run.font.bold = True
        run.font.size = Pt(10)
        run.font.color.rgb = RGBColor(255, 255, 255)

    actores_info = [
        ("Ciudadano / Turista\n(USER)", "Actor Humano\n(Móvil / PWA)", 
         "• Generar reportes georreferenciados con evidencia fotográfica.\n"
         "• Explorar mapa interactivo con zonas de riesgo y clustering.\n"
         "• Solicitar rutas de desplazamiento seguro evitando focos delictivos.\n"
         "• Activar botón de pánico SOS y enlace telefónico 123.\n"
         "• Dialogar con el Asistente Virtual IA con RAG territorial.\n"
         "• Monitorear el progreso de sus reportes creados."),
        ("Oficial de Policía\n(OFFICER)", "Actor Humano\n(Móvil / Web)", 
         "• Visualizar cola de incidentes asignados a su cuadrante específico.\n"
         "• Actualizar estado operativo (En Proceso, Resuelto, Rechazado).\n"
         "• Registrar bitácoras y observaciones policiales en tiempo real.\n"
         "• Consultar directorio distrital de contactos de emergencia."),
        ("Administrador Distrital\n(ADMIN / CAD)", "Actor Humano\n(Web Dashboard)", 
         "• Supervisar Centro de Mando en vivo con cuadrícula Bento y KPIs.\n"
         "• Gestionar usuarios, cuadrantes policiales y polígonos de riesgo.\n"
         "• Modificar parámetros del motor de IA y prompts contextuales.\n"
         "• Generar informes oficiales en PDF (OpenPDF) y exportaciones CSV.\n"
         "• Auditar trazabilidad de actividades en logs inmutables."),
        ("Sistemas Externos &\nServicios Cloud", "Actor Sistema\n(Integraciones API)", 
         "• Groq Cloud API (Inferencia Llama 3 para el asistente RAG).\n"
         "• Cloudinary CDN (Almacenamiento seguro de fotos de incidentes).\n"
         "• OpenStreetMap & Esri (Suministro de teselas y mapas satelitales).\n"
         "• Google Apps Script (Servicio de despacho de emails transaccionales).")
    ]

    for idx, (act, tipo, resp) in enumerate(actores_info, start=1):
        row = table_actores.rows[idx]
        bg = HEX_LIGHT_ROW if idx % 2 == 1 else 'FFFFFF'
        for c_idx, text in enumerate([act, tipo, resp]):
            cell = row.cells[c_idx]
            set_cell_background(cell, bg)
            set_cell_margins(cell, 80, 80, 100, 100)
            p = cell.paragraphs[0]
            p.paragraph_format.space_after = Pt(0)
            run = p.add_run(text)
            run.font.size = Pt(9.5)
            if c_idx == 0:
                run.font.bold = True
                run.font.color.rgb = COLOR_SECONDARY

    doc.add_page_break()

    # -------------------------------------------------------------
    # SECCIÓN 3: DIAGRAMA GENERAL DE CASOS DE USO Y TRAZABILIDAD
    # -------------------------------------------------------------
    add_custom_h1("3. Diagrama General de Casos de Uso (UML)")
    doc.add_paragraph(
        "A continuación se ilustra el Diagrama General de Casos de Uso según la notación estándar UML, representando los límites "
        "del sistema, los actores involucrados y los 10 paquetes funcionales medulares:"
    )

    add_image_with_caption(
        "doc_assets/diagram_general_casos_uso.png",
        "Figura 1: Diagrama General de Casos de Uso (UML) — Plataforma Cartagena Segura"
    )

    add_custom_h2("3.1 Matriz de Trazabilidad: Actores vs. Casos de Uso")
    doc.add_paragraph(
        "La siguiente matriz formaliza la participación y permisos de ejecución de cada actor sobre los casos de uso definidos:"
    )

    table_matriz = doc.add_table(rows=13, cols=4)
    table_matriz.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table_matriz)

    m_headers = ["Identificador", "Nombre del Caso de Uso", "Actores Participantes", "Criticidad"]
    for i, h in enumerate(m_headers):
        cell = table_matriz.rows[0].cells[i]
        set_cell_background(cell, HEX_HEADER_BG)
        set_cell_margins(cell, 90, 90, 100, 100)
        p = cell.paragraphs[0]
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(h)
        run.font.bold = True
        run.font.size = Pt(9.5)
        run.font.color.rgb = RGBColor(255, 255, 255)

    matriz_rows = [
        ("CU-01", "Autenticación, Registro y Recuperación de Contraseña", "Ciudadano, Oficial, Administrador", "Alta"),
        ("CU-02", "Reporte Ciudadano con Evidencia Multimedia y GPS", "Ciudadano", "Crítica"),
        ("CU-03", "Exploración de Mapa Geoespacial y Zonas de Riesgo", "Ciudadano, Oficial, Administrador", "Alta"),
        ("CU-04", "Asistente de Rutas Seguras Inteligentes (Waze Preventivo)", "Ciudadano", "Alta"),
        ("CU-05", "Activación de Botón de Pánico SOS y Línea 123", "Ciudadano", "Crítica"),
        ("CU-06", "Asistencia Ciudadana Inteligente con IA (RAG)", "Ciudadano", "Media"),
        ("CU-07", "Monitoreo y Seguimiento de Reportes Propios", "Ciudadano", "Media"),
        ("CU-08", "Monitoreo Territorial en Vivo de Cuadrante Policial", "Oficial de Policía", "Crítica"),
        ("CU-09", "Gestión del Ciclo de Vida y Transición de Estados", "Oficial de Policía, Administrador", "Crítica"),
        ("CU-10", "Centro de Control Administrativo y Analítica (Bento Grid)", "Administrador Distrital", "Alta"),
        ("CU-11", "Configuración de Cuadrantes y Polígonos de Riesgo", "Administrador Distrital", "Media"),
        ("CU-12", "Generación de Informes Oficiales en PDF y CSV", "Administrador Distrital", "Media"),
    ]

    for idx, (cid, cname, cactors, ccrit) in enumerate(matriz_rows, start=1):
        row = table_matriz.rows[idx]
        bg = HEX_LIGHT_ROW if idx % 2 == 1 else 'FFFFFF'
        for c_idx, text in enumerate([cid, cname, cactors, ccrit]):
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
            if c_idx == 3:
                run.font.bold = True
                if text == "Crítica":
                    run.font.color.rgb = RGBColor(185, 28, 28) # Red
                elif text == "Alta":
                    run.font.color.rgb = RGBColor(217, 119, 6) # Amber
                else:
                    run.font.color.rgb = RGBColor(5, 150, 105) # Green

    doc.add_page_break()

    # -------------------------------------------------------------
    # SECCIÓN 4: ESPECIFICACIÓN DETALLADA DE CASOS DE USO
    # -------------------------------------------------------------
    add_custom_h1("4. Especificación Detallada de Casos de Uso")
    doc.add_paragraph(
        "A continuación se presenta la ficha técnica exhaustiva de cada caso de uso conforme al estándar internacional de "
        "ingeniería de requisitos, acompañada de sus respectivos diagramas de secuencia, arquitectura y flujos de datos."
    )

    # Helper to generate Use Case Table
    def add_use_case_table(cu_id, cu_name, actor, obj, pre, trigger, main_flow, alt_flow, rules, post):
        add_custom_h2(f"{cu_id}: {cu_name}")
        table = doc.add_table(rows=9, cols=2)
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        set_table_borders(table)

        fields = [
            ("Identificador y Nombre", f"{cu_id} — {cu_name}"),
            ("Actor(es) Principal(es)", actor),
            ("Objetivo del Caso de Uso", obj),
            ("Precondiciones", pre),
            ("Disparador (Trigger)", trigger),
            ("Flujo Principal de Eventos", main_flow),
            ("Flujos Alternativos / Excepciones", alt_flow),
            ("Reglas de Negocio y Seguridad", rules),
            ("Postcondiciones", post)
        ]

        for i, (fname, fval) in enumerate(fields):
            row = table.rows[i]
            c_lbl, c_val = row.cells[0], row.cells[1]
            c_lbl.width = Inches(2.1)
            c_val.width = Inches(4.4)
            set_cell_background(c_lbl, HEX_LIGHT_ROW)
            set_cell_background(c_val, 'FFFFFF')
            set_cell_margins(c_lbl, 70, 70, 100, 100)
            set_cell_margins(c_val, 70, 70, 100, 100)

            p0 = c_lbl.paragraphs[0]
            p0.paragraph_format.space_after = Pt(0)
            r0 = p0.add_run(fname)
            r0.font.bold = True
            r0.font.size = Pt(9.5)
            r0.font.color.rgb = COLOR_SECONDARY

            p1 = c_val.paragraphs[0]
            p1.paragraph_format.space_after = Pt(0)
            r1 = p1.add_run(fval)
            r1.font.size = Pt(9.5)

        p_sp = doc.add_paragraph()
        p_sp.paragraph_format.space_before = Pt(4)
        p_sp.paragraph_format.space_after = Pt(6)

    # ---------------- CU-01 ----------------
    add_use_case_table(
        cu_id="CU-01",
        cu_name="Autenticación, Registro y Recuperación de Contraseña",
        actor="Ciudadano, Oficial de Policía, Administrador Distrital",
        obj="Permitir a los usuarios crear cuentas seguras, autenticarse mediante JWT con control de roles y recuperar contraseñas extraviadas.",
        pre="La aplicación debe estar desplegada y tener conexión con la base de datos PostgreSQL.",
        trigger="El usuario accede a la pantalla de Inicio de Sesión o Registro en la aplicación.",
        main_flow=(
            "1. El usuario ingresa sus credenciales (nombre de usuario / correo y contraseña).\n"
            "2. El cliente Flutter valida la estructura de campos requeridos.\n"
            "3. La petición HTTP POST viaja al endpoint /api/auth/login.\n"
            "4. AuthService y Spring Security comparan la contraseña con el hash BCrypt en PostgreSQL.\n"
            "5. Si es correcta, JwtTokenProvider genera un token criptográfico firmado.\n"
            "6. La app almacena el token en FlutterSecureStorage y redirige según el rol (Admin Shell o Home Shell)."
        ),
        alt_flow=(
            "• Credenciales inválidas: Se retorna HTTP 401 Unauthorized y la UI muestra notificación de error.\n"
            "• Olvido de contraseña: El usuario solicita token de restablecimiento enviado vía Google Apps Script al correo registrado."
        ),
        rules=(
            "• Contraseñas de mínimo 8 caracteres con mayúscula, minúscula y símbolo.\n"
            "• Hashing unidireccional con BCrypt (salt dinámico).\n"
            "• Token JWT con firma HMAC-SHA256 y expiración predeterminada de 24 horas."
        ),
        post="El usuario cuenta con una sesión activa segura y permisos acordes a su rol."
    )

    # ---------------- CU-02 ----------------
    add_use_case_table(
        cu_id="CU-02",
        cu_name="Reporte Ciudadano de Incidente con Evidencia Multimedia y GPS",
        actor="Ciudadano / Turista (USER)",
        obj="Registrar en tiempo real una situación de riesgo (hurto, accidente, emergencia médica, disturbio) con coordenadas satelitales exactas y evidencia fotográfica certificada.",
        pre="El ciudadano debe contar con sesión autenticada y permisos de geolocalización concedidos.",
        trigger="El usuario pulsa el botón flotante 'Reportar' o navega a la pestaña de creación de reporte.",
        main_flow=(
            "1. La app obtiene la coordenada GPS satelital actual del dispositivo (Geolocator).\n"
            "2. El usuario selecciona la tipología del incidente (Robo, Accidente, Vandalismo, Sospechoso, etc.).\n"
            "3. Ingresa título descriptivo y detalles circunstanciales.\n"
            "4. Adjunta una fotografía desde la cámara o galería.\n"
            "5. Al pulsar 'Publicar Reporte', el archivo se envía a /api/upload validando Magic Bytes y subiendo a Cloudinary.\n"
            "6. Se invoca /api/incidents; el backend persiste el documento en MongoDB y audita en PostgreSQL.\n"
            "7. IncidentService emite el incidente en tiempo real al tópico STOMP /topic/incidents."
        ),
        alt_flow=(
            "• Sin permiso GPS: Se muestra diálogo guiado (LocationGuideDialog) para activación satelital.\n"
            "• Archivo malicioso o corrupto: FileUploadController rechaza la carga si los bytes de cabecera no coinciden con JPG/PNG/WEBP.\n"
            "• Pérdida temporal de señal: La app almacena el borrador en ReportDraftStore para envío diferido."
        ),
        rules=(
            "• Validación obligatoria de Magic Bytes binarios (anti-inyección de ejecutables).\n"
            "• Coordenadas restringidas al polígono geográfico distrital de Cartagena de Indias.\n"
            "• Tamaño máximo de fotografía: 10 MB."
        ),
        post="El incidente queda en estado REPORTADO disponible para atención de la patrulla del cuadrante."
    )

    add_image_with_caption(
        "doc_assets/diagram_flujo_reporte.png",
        "Figura 2: Diagrama de Flujo y Secuencia para el Caso de Uso CU-02 (Reporte de Incidentes)"
    )

    # ---------------- CU-03 ----------------
    add_use_case_table(
        cu_id="CU-03",
        cu_name="Exploración del Mapa Interactivo Geoespacial y Zonas de Riesgo",
        actor="Ciudadano, Oficial de Policía, Administrador",
        obj="Visualizar la distribución espacial de incidentes activos, polígonos de alerta distrital y radar de ubicación en tiempo real.",
        pre="Acceso a la vista principal del mapa.",
        trigger="El usuario selecciona la pestaña 'Mapa' en la barra de navegación.",
        main_flow=(
            "1. La aplicación realiza una petición a /api/incidents y /api/zones.\n"
            "2. El mapa renderiza las capas OpenStreetMap o Esri Satelital de alta resolución.\n"
            "3. Se dibujan los polígonos translúcidos de las zonas de riesgo (Rojo: Alto, Naranja: Medio).\n"
            "4. Los incidentes se agrupan mediante clustering dinámico para evitar sobrecarga visual.\n"
            "5. Un radar pulsante indica la posición satelital en tiempo real del usuario.\n"
            "6. Al tocar un marcador, se abre una tarjeta modal con fotografía, hora y estado del incidente."
        ),
        alt_flow=(
            "• Conmutación de capa: El usuario puede alternar entre mapa vectorial estándar y fotografía satelital.\n"
            "• Filtros avanzados: Filtrado por rango horario, tipo de delito y estado del incidente."
        ),
        rules=(
            "• Los marcadores deben renderizarse vectorialmente con fluidez a 60 FPS.\n"
            "• Privacidad ciudadana: La identidad personal del denunciante se anonimiza en la vista pública."
        ),
        post="El usuario cuenta con conciencia situacional completa del entorno urbano."
    )

    # ---------------- CU-04 ----------------
    add_use_case_table(
        cu_id="CU-04",
        cu_name="Asistente de Rutas Seguras Inteligentes (Waze Preventivo)",
        actor="Ciudadano / Turista (USER)",
        obj="Trazar trayectorias de desplazamiento a pie o vehículo que esquiven automáticamente cuadrantes con alta concentración de delitos y zonas de riesgo.",
        pre="Ubicación GPS fijada y mapa interactivo cargado.",
        trigger="El usuario pulsa el botón 'Ruta Segura' y selecciona su destino (ej. Torre del Reloj, Bocagrande, Manga).",
        main_flow=(
            "1. El usuario busca un destino mediante el diálogo DestinationSearchDialog.\n"
            "2. SafeRouteService calcula la ruta entre el origen actual y el destino empleando LatLong2.\n"
            "3. El algoritmo evalúa la proximidad de cada tramo vial frente a los polígonos de incidentes activos en MongoDB.\n"
            "4. Si un tramo atraviesa una zona catalogada como de alto riesgo, se calculan waypoints de desvío preventivo.\n"
            "5. Se dibuja en el mapa la polilínea azul de la ruta recomendada y se despliega la hoja modal SafeRouteSheet.\n"
            "6. El ciudadano inicia su trayecto con acompañamiento geográfico visual continuo."
        ),
        alt_flow=(
            "• Destino sin incidentes en el camino: Se despliega mensaje de confirmación de trayecto con bajo riesgo delictivo.\n"
            "• Desviación de ruta: El radar detecta si el usuario penetra una zona roja y emite alerta sonora/háptica."
        ),
        rules=(
            "• Prioridad de la seguridad física y prevención por encima de la distancia métrica más corta.\n"
            "• Recálculo automático si se generan nuevos incidentes críticos durante el viaje."
        ),
        post="El usuario se desplaza con un vector seguro trazado y supervisión satelital."
    )

    add_image_with_caption(
        "doc_assets/diagram_flujo_rutas_seguras.png",
        "Figura 3: Arquitectura y Lógica de Decisión para el Caso de Uso CU-04 (Rutas Seguras)"
    )

    # ---------------- CU-05 ----------------
    add_use_case_table(
        cu_id="CU-05",
        cu_name="Activación de Botón de Pánico SOS y Directorio 123",
        actor="Ciudadano / Turista (USER)",
        obj="Activar una alarma de auxilio crítico inmediata con transmisión de coordenadas satelitales al CAD y enlace telefónico a las líneas de emergencia distritales.",
        pre="Dispositivo móvil encendido y aplicación abierta.",
        trigger="El usuario mantiene presionado el botón central 'SOS' durante 2 segundos continuos.",
        main_flow=(
            "1. El usuario realiza una pulsación prolongada (LongPress) sobre el botón SOS de alto contraste.\n"
            "2. La app genera una vibración háptica de confirmación para evitar falsos positivos accidentales.\n"
            "3. Se captura la coordenada GPS satelital instantánea con máxima precisión.\n"
            "4. Se envía un paquete de emergencia prioritario al backend marcando alerta roja inmediata.\n"
            "5. El módulo UrlLauncher ejecuta la llamada directa a la línea de emergencias 123 de la Policía Nacional.\n"
            "6. En pantalla se despliegan accesos rápidos alternativos a Bomberos, Cruz Roja, Defensa Civil y Armada."
        ),
        alt_flow=(
            "• Presión breve involuntaria: La app muestra una animación guiada indicando 'Mantén presionado para activar'.\n"
            "• Dispositivo sin red celular: Se ejecuta directamente el enlace nativo de marcación de emergencia 123."
        ),
        rules=(
            "• Mecanismo anti-falso disparo de 2 segundos de presión continua.\n"
            "• Las alertas de pánico tienen prioridad absoluta en el procesamiento de colas del backend."
        ),
        post="Patrullas del cuadrante alertadas y llamada telefónica de emergencia en curso."
    )

    add_image_with_caption(
        "doc_assets/diagram_flujo_sos.png",
        "Figura 4: Diagrama de Despliegue de Emergencia para el Caso de Uso CU-05 (Botón de Pánico SOS)"
    )

    # ---------------- CU-06 ----------------
    add_use_case_table(
        cu_id="CU-06",
        cu_name="Asistencia Ciudadana Inteligente con IA (RAG Territorial)",
        actor="Ciudadano / Turista (USER)",
        obj="Proveer orientación preventiva personalizada, recomendaciones de seguridad barrial y tips turísticos mediante un agente de IA con conocimiento dinámico de la ciudad.",
        pre="Acceso a la interfaz de chat en la aplicación.",
        trigger="El usuario escribe una consulta o pregunta en la consola conversacional.",
        main_flow=(
            "1. El ciudadano formula una consulta (ej. '¿Qué precauciones tomar en el Mercado de Bazurto hoy?').\n"
            "2. El mensaje se transmite al controlador AiController en el backend.\n"
            "3. AiService activa el módulo de Recuperación Aumentada por Generación (RAG).\n"
            "4. Se consulta MongoDB para extraer los incidentes y cuadrantes recientes del sector mencionado.\n"
            "5. Se ensambla un prompt con contexto geoespacial real y pautas de seguridad oficiales.\n"
            "6. Se envía la solicitud al LLM Llama 3 vía Groq Cloud (o al Motor Heurístico Local si no hay API key).\n"
            "7. El asistente entrega una respuesta enriquecida con teléfonos de emergencia y sugerencias prácticas."
        ),
        alt_flow=(
            "• Pérdida de conexión con Groq: Fallback automático y transparente al Motor Local Inteligente sin degradar la experiencia de usuario.\n"
            "• Detección de peligro inminente: Si la IA detecta que el usuario está siendo agredido, interrumpe el chat y ofrece botón directo al 123."
        ),
        rules=(
            "• Respuestas estrictamente limitadas al contexto de seguridad y turismo en Cartagena de Indias.\n"
            "• Cero divulgación de información confidencial o sensible de denunciantes."
        ),
        post="El usuario recibe orientación experta, inmediata y basada en datos reales de la ciudad."
    )

    add_image_with_caption(
        "doc_assets/diagram_flujo_ia_rag.png",
        "Figura 5: Flujo de Inferencia Dual y Context-Aware RAG para el Caso de Uso CU-06"
    )

    # ---------------- CU-07 ----------------
    add_use_case_table(
        cu_id="CU-07",
        cu_name="Monitoreo y Seguimiento de Reportes Propios",
        actor="Ciudadano / Turista (USER)",
        obj="Permitir a los ciudadanos consultar el estado, avances, comentarios de la policía y evidencias de sus incidentes reportados.",
        pre="Usuario con reportes generados previamente.",
        trigger="El ciudadano ingresa a la pestaña 'Mis Reportes'.",
        main_flow=(
            "1. La app consulta el endpoint /api/incidents/my-reports transmitiendo el JWT del usuario.\n"
            "2. El backend filtra los incidentes en MongoDB donde el ID del autor coincide con el token.\n"
            "3. La interfaz renderiza tarjetas cronológicas con estados de color (Reportado, En Proceso, Resuelto).\n"
            "4. Al tocar un reporte, se visualizan las observaciones emitidas por el cuadrante policial y la fotografía adjunta."
        ),
        alt_flow=(
            "• Usuario sin reportes: Se muestra un estado vacío estilizado invitando a usar la app de forma preventiva."
        ),
        rules=(
            "• Aislamiento estricto: Ningún usuario ordinario puede ver el historial de reportes privados de otro ciudadano."
        ),
        post="El ciudadano valida la transparencia institucional y la efectividad de su denuncia."
    )

    # ---------------- CU-08 ----------------
    add_use_case_table(
        cu_id="CU-08",
        cu_name="Monitoreo Territorial en Vivo de Cuadrante Policial",
        actor="Oficial de Policía / Cuadrante (OFFICER)",
        obj="Monitorear y atender la cola de incidentes y emergencias asignadas específicamente a la jurisdicción de su cuadrante de patrullaje.",
        pre="Oficial con credenciales validadas y rol OFFICER asignado.",
        trigger="El oficial inicia turno o recibe una alerta de nuevo incidente.",
        main_flow=(
            "1. El oficial inicia sesión y la app detecta automáticamente su rol policial.\n"
            "2. Se establece una suscripción activa al WebSocket de incidentes del cuadrante.\n"
            "3. El mapa despliega los límites perimetrales del cuadrante asignado y los incidentes activos.\n"
            "4. Se priorizan los incidentes en estado PENDIENTE o ALERTAS SOS.\n"
            "5. El oficial pulsa un incidente para conocer la ruta de desplazamiento y la fotografía de la evidencia."
        ),
        alt_flow=(
            "• Cuadrante sin novedades: El mapa muestra estado operativo despejado y monitoreo pasivo de radio."
        ),
        rules=(
            "• Acceso restringido a incidentes del cuadrante asignado o cuadrantes vecinos en apoyo."
        ),
        post="Patrulla policial informada con datos geoespaciales precisos para su intervención en terreno."
    )

    # ---------------- CU-09 ----------------
    add_use_case_table(
        cu_id="CU-09",
        cu_name="Gestión del Ciclo de Vida y Transición de Estados de Incidentes",
        actor="Oficial de Policía, Administrador Distrital",
        obj="Auditar y gobernar la máquina de estados de un incidente desde su radicación ciudadana hasta su resolución o descarte oficial.",
        pre="Incidente existente en la base de datos.",
        trigger="El operador policial o administrador actualiza la situación de un reporte.",
        main_flow=(
            "1. El operador selecciona el incidente desde el panel de control o la consola de cuadrante.\n"
            "2. Evalúa las pruebas adjuntas y selecciona la nueva etapa en el selector de estados.\n"
            "3. La app envía una petición PATCH/PUT a /api/incidents/{id}/status con el nuevo estado (ej. EN_PROCESO, RESUELTO).\n"
            "4. IncidentService valida la máquina de estados permitida y almacena la bitácora en MongoDB.\n"
            "5. LogService registra una entrada inmutable de auditoría en la tabla audit_logs de PostgreSQL.\n"
            "6. Se notifica al ciudadano denunciante sobre la resolución de su caso."
        ),
        alt_flow=(
            "• Falsa Alarma o Reporte Inconsistente: El operador transiciona el estado a RECHAZADO especificando el motivo legal.\n"
            "• Transición inválida: Si se intenta reabrir un reporte ya concluido sin autorización, el sistema rechaza la solicitud."
        ),
        rules=(
            "• Transiciones autorizadas: REPORTADO -> EN_REVISION -> ASIGNADO -> EN_PROCESO -> RESUELTO / RECHAZADO.\n"
            "• Registro inmutable de usuario, hora y fecha en la auditoría distrital."
        ),
        post="Estado del incidente actualizado en toda la red de clientes en tiempo real."
    )

    add_image_with_caption(
        "doc_assets/diagram_ciclo_vida_incidente.png",
        "Figura 6: Máquina de Estados Finita para el Ciclo de Vida de los Incidentes (CU-09)"
    )

    # ---------------- CU-10 ----------------
    add_use_case_table(
        cu_id="CU-10",
        cu_name="Centro de Control Administrativo y Analítica en Tiempo Real (Bento Grid)",
        actor="Administrador Distrital (ADMIN)",
        obj="Supervisar integralmente las métricas operativas de la ciudad mediante cuadros de mando interactivos, gráficos dinámicos y telemetría de rendimiento.",
        pre="Usuario autenticado con rol ADMIN.",
        trigger="El administrador accede al panel de administración (AdminShell).",
        main_flow=(
            "1. La plataforma carga los indicadores consolidados desde PostgreSQL y MongoDB.\n"
            "2. La interfaz distribuye la información en una cuadrícula asimétrica estilo Bento Grid.\n"
            "3. Se visualizan contadores en tiempo real: Total Incidentes, En Proceso, Resueltos, Zonas Críticas y Usuarios.\n"
            "4. La biblioteca FL Chart grafica la evolución histórica y la distribución porcentual por tipología de delito.\n"
            "5. El administrador interactúa con los filtros para segmentar datos por comunas, fechas o severidad."
        ),
        alt_flow=(
            "• Pico delictivo anómalo: La UI resalta en color rojo Obsidian los sectores que sobrepasan el umbral de alerta."
        ),
        rules=(
            "• Las métricas deben calcularse mediante agregaciones optimizadas para evitar bloqueos de base de datos."
        ),
        post="El mando directivo cuenta con analítica situacional para la toma de decisiones preventivas."
    )

    add_image_with_caption(
        "doc_assets/diagram_centro_mando_admin.png",
        "Figura 7: Arquitectura de Componentes del Centro de Mando Administrativo (CU-10 / CU-12)"
    )

    # ---------------- CU-11 ----------------
    add_use_case_table(
        cu_id="CU-11",
        cu_name="Configuración de Cuadrantes y Polígonos de Riesgo Distrital",
        actor="Administrador Distrital (ADMIN)",
        obj="Delimitar, editar o redefinir áreas geográficas de riesgo y cuadrantes de cobertura policial para optimizar la respuesta ciudadana.",
        pre="Permisos de administrador concedidos.",
        trigger="El administrador ingresa a la pestaña 'Gestión de Zonas y Cuadrantes'.",
        main_flow=(
            "1. El administrador visualiza los polígonos de riesgo actuales superpuestos en el mapa.\n"
            "2. Selecciona la opción 'Crear Nueva Zona de Riesgo' o editar una existente.\n"
            "3. Define las coordenadas perimetrales del polígono (latitudes y longitudes).\n"
            "4. Asigna el nivel de severidad (Bajo, Medio, Alto, Crítico) y las recomendaciones específicas para transeúntes.\n"
            "5. Se envía petición a ZoneController; el backend almacena el polígono GeoJSON en MongoDB.\n"
            "6. La nueva zona entra en vigencia de inmediato en los cálculos de Rutas Seguras de la ciudadanía."
        ),
        alt_flow=(
            "• Vértices inválidos: El sistema exige un mínimo de 3 coordenadas para formar un polígono cerrado."
        ),
        rules=(
            "• Los polígonos de riesgo deben respetar la nomenclatura oficial de barrios y localidades del Distrito."
        ),
        post="Zonas de riesgo sincronizadas globalmente con el motor de mapas y ruteo."
    )

    # ---------------- CU-12 ----------------
    add_use_case_table(
        cu_id="CU-12",
        cu_name="Generación y Exportación de Informes Oficiales en PDF y CSV",
        actor="Administrador Distrital (ADMIN)",
        obj="Producir documentos ejecutivos oficiales en formato PDF y hojas de cálculo CSV con los reportes, auditorías y estadísticas de seguridad ciudadana.",
        pre="Existencia de datos de incidentes registrados en el período a consultar.",
        trigger="El administrador pulsa los botones 'Exportar Informe PDF' o 'Descargar CSV'.",
        main_flow=(
            "1. El administrador define el rango de fechas y los criterios de inclusión del informe.\n"
            "2. Al pulsar 'Exportar PDF', se invoca el servicio PdfReportService en Spring Boot.\n"
            "3. El motor OpenPDF compila dinámicamente el encabezado institucional, tablas de incidentes, estadísticas y sellos.\n"
            "4. El backend transmite el flujo binario 'application/pdf' con encabezado Content-Disposition.\n"
            "5. El navegador del administrador inicia la descarga inmediata del archivo formal de auditoría.\n"
            "6. La acción queda registrada en el log de auditoría del sistema."
        ),
        alt_flow=(
            "• Exportación en formato tabular: La opción CSV genera un archivo plano estructurado para su análisis en Excel o Power BI."
        ),
        rules=(
            "• Formato estandarizado de acuerdo a la reglamentación de documentos públicos distritales.\n"
            "• Inclusión de firma digital institucional y timestamp GMT-5."
        ),
        post="Documento formal descargado y archivado para rendición de cuentas o procesos judiciales."
    )

    doc.add_page_break()

    # -------------------------------------------------------------
    # SECCIÓN 5: REQUISITOS NO FUNCIONALES Y CRITERIOS DE CALIDAD
    # -------------------------------------------------------------
    add_custom_h1("5. Requisitos No Funcionales y Criterios de Aceptación")
    doc.add_paragraph(
        "Para garantizar la solidez institucional y operativa de los casos de uso descritos, el sistema satisface rigurosos "
        "criterios de ingeniería de software basados en el estándar ISO/IEC 25010:"
    )

    table_rnf = doc.add_table(rows=6, cols=3)
    table_rnf.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table_rnf)

    rnf_headers = ["Dimensión de Calidad", "Requisito Técnico Implementado", "Mecanismo de Verificación"]
    for i, h in enumerate(rnf_headers):
        cell = table_rnf.rows[0].cells[i]
        set_cell_background(cell, HEX_HEADER_BG)
        set_cell_margins(cell, 90, 90, 100, 100)
        p = cell.paragraphs[0]
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(h)
        run.font.bold = True
        run.font.size = Pt(9.5)
        run.font.color.rgb = RGBColor(255, 255, 255)

    rnf_data = [
        ("Seguridad Criptográfica\n(Security)", 
         "Validación estricta de Magic Bytes en subidas, hashing BCrypt, tokens JWT firmados y encabezados HTTP seguros (HSTS, CSP, X-Frame-Options).",
         "Pruebas de inyección binaria aprobadas en FileUploadControllerTest y escaneo de vulnerabilidades."),
        ("Rendimiento y Latencia\n(Performance)", 
         "Virtual Threads de Java 21, persistencia desacoplada en MongoDB y compresión gzip de activos web en Nginx 1.27.",
         "Tiempo de respuesta de endpoints de incidentes < 250 ms bajo condiciones normales de carga."),
        ("Disponibilidad y Resiliencia\n(Availability)", 
         "Despliegue cloud permanente en Render con healthchecks Actuator y tolerancia a fallos del motor de IA mediante fallback heurístico local.",
         "Monitoreo 24/7 en /actuator/health con estado UP continuo en producción."),
        ("Compatibilidad y Acceso\n(Portability)", 
         "Arquitectura Flutter PWA con diseño responsivo móvil/web y soporte para instalación directa en iOS (Safari) y Android (Chrome).",
         "Validación multiplataforma y Service Worker para ejecución como aplicación de escritorio/móvil."),
        ("Mantenibilidad y Código\n(Maintainability)", 
         "Arquitectura limpia por capas (Controller-Service-Repository), contratos DTO con MapStruct y gestión de estado con Riverpod.",
         "0 advertencias en flutter analyze y suite de 49 pruebas unitarias aprobadas al 100%.")
    ]

    for idx, (dim, req, ver) in enumerate(rnf_data, start=1):
        row = table_rnf.rows[idx]
        bg = HEX_LIGHT_ROW if idx % 2 == 1 else 'FFFFFF'
        for c_idx, text in enumerate([dim, req, ver]):
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

    # -------------------------------------------------------------
    # SECCIÓN 6: CONCLUSIONES Y APROBACIÓN
    # -------------------------------------------------------------
    add_custom_h1("6. Conclusiones y Validación Institucional")
    doc.add_paragraph(
        "El presente catálogo de casos de uso refleja con exactitud la madurez arquitectónica y funcional del proyecto "
        "'Cartagena Segura'. La coexistencia armónica de micro-flujos ciudadanos (reportes multimedia, rutas seguras, botón SOS) "
        "con capacidades tácticas y administrativas (Centro de Mando Bento Grid, exportación legal de actas y trazabilidad inmutable) "
        "convierte a la plataforma en un referente de innovación tecnológica al servicio del bienestar público."
    )

    # Signatures table
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
    print(f"Document saved successfully as '{output_path}'!")

if __name__ == "__main__":
    create_document()
