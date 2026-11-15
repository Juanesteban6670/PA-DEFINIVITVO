import os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as patches

os.makedirs("doc_assets", exist_ok=True)

plt.rcParams['font.family'] = 'sans-serif'
plt.rcParams['font.sans-serif'] = ['DejaVu Sans', 'Arial', 'Helvetica']

def create_navigation_diagram():
    fig, ax = plt.subplots(figsize=(14, 8), dpi=300)
    ax.set_xlim(0, 140)
    ax.set_ylim(0, 85)
    ax.axis('off')
    fig.patch.set_facecolor('#F8FAFC')

    # Subtitle / Header tags matching Image 2
    ax.text(8, 80, "EJEMPLO / ARQUITECTURA DE FLUJO MÓVIL", fontsize=10, fontweight='bold', color='#64748B')
    ax.text(8, 75, "Navegación de Cartagena Segura", fontsize=20, fontweight='bold', color='#0F172A')

    # "Pantalla inicial" label
    ax.text(12, 63, "Pantalla inicial", fontsize=9, fontweight='bold', color='#475569')

    # Helper to draw screen boxes
    def draw_screen(x, y, w, h, text, is_green=False):
        if is_green:
            bg_color = '#DCFCE7'      # Soft emerald green (like Image 2)
            border_color = '#86EFAC'  # Light green border
            text_color = '#14532D'    # Dark green text
        else:
            bg_color = '#E0F2FE'      # Soft sky blue (like Image 2)
            border_color = '#BAE6FD'  # Light blue border
            text_color = '#0369A1'    # Dark blue text

        box = patches.FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.5,rounding_size=1.2",
                                     linewidth=1.8, edgecolor=border_color, facecolor=bg_color, zorder=2)
        ax.add_patch(box)
        ax.text(x + w/2, y + h/2, text, fontsize=10.5, fontweight='bold', ha='center', va='center',
                color=text_color, zorder=3)

    # Helper to draw arrows with action text
    def draw_nav_arrow(x1, y1, x2, y2, text, text_pos='above', bidirectional=False):
        style = "<->" if bidirectional else "->"
        ax.annotate("", xy=(x2, y2), xytext=(x1, y1),
                    arrowprops=dict(arrowstyle=style, color="#64748B", lw=1.6, mutation_scale=12), zorder=2)
        mid_x = (x1 + x2) / 2
        mid_y = (y1 + y2) / 2
        offset_y = 1.8 if text_pos == 'above' else -1.8
        offset_x = 0
        if x1 == x2: # Vertical arrow
            offset_y = 0
            offset_x = 4.5 if text_pos == 'right' else -4.5
        ax.text(mid_x + offset_x, mid_y + offset_y, text, fontsize=8.5, ha='center', va='center',
                color='#1E293B', bbox=dict(boxstyle="square,pad=0.15", fc="#F8FAFC", ec="none", alpha=0.9), zorder=4)

    # ROW 1 (Main Citizen Flow: Auth -> Home -> Report Flow)
    # 1. Inicio de Sesión
    draw_screen(8, 48, 20, 12, "Inicio de\nsesión")
    
    # 2. Pantalla Principal / Inicio
    draw_screen(38, 48, 20, 12, "Inicio /\nBienvenida")

    # 3. Formulario Reportar
    draw_screen(68, 48, 20, 12, "Formulario de\nreporte")

    # 4. Captura Evidencia
    draw_screen(98, 48, 20, 12, "Captura de\nevidencia GPS")

    # 5. Confirmación (Green)
    draw_screen(114, 25, 20, 12, "Confirmación\nde reporte", is_green=True)

    # Connect Main Horizontal Flow
    draw_nav_arrow(28, 54, 38, 54, "Entrar")
    draw_nav_arrow(58, 54, 68, 54, "Reportar")
    draw_nav_arrow(88, 54, 98, 54, "Cámara/GPS")
    draw_nav_arrow(108, 48, 124, 37, "Publicar", text_pos='above')

    # ROW 2 (Tab Screens reached from Inicio / Home Shell)
    # Perfil (Green)
    draw_screen(10, 25, 18, 12, "Perfil", is_green=True)
    draw_nav_arrow(42, 48, 22, 37, "Pestaña", text_pos='above')

    # Mapa Interactivo (Green)
    draw_screen(36, 25, 22, 12, "Mapa interactivo\ny rutas seguras", is_green=True)
    draw_nav_arrow(48, 48, 48, 37, "Pestaña", text_pos='right')

    # Mis Reportes (Green)
    draw_screen(64, 25, 20, 12, "Historial de\nmis reportes", is_green=True)
    draw_nav_arrow(52, 48, 70, 37, "Pestaña", text_pos='above')

    # Emergencias SOS (Green)
    draw_screen(90, 25, 18, 12, "Botón SOS /\nLlamada 123", is_green=True)
    draw_nav_arrow(56, 48, 92, 37, "Pestaña / SOS", text_pos='above')

    # Chatbot IA (reached from Inicio or Floating Button)
    draw_screen(38, 5, 22, 11, "Asistente IA\n(Chat RAG)", is_green=True)
    draw_nav_arrow(48, 25, 48, 16, "Chat IA", text_pos='right')

    # Rutas Seguras (reached from Mapa Interactivo)
    draw_screen(70, 5, 22, 11, "Asistente de\nrutas seguras", is_green=True)
    draw_nav_arrow(58, 27, 72, 16, "Trazar ruta", text_pos='above')

    # Footnote matching Image 2
    ax.text(8, 2, "Cada flecha es un evento del usuario. El botón Atrás vuelve a la pantalla anterior en todo el flujo.\nEn verde: pantallas a las que se llega por pestaña o que cierran el flujo.",
            fontsize=9.5, color='#475569', ha='left', va='bottom')

    plt.tight_layout()
    plt.savefig("doc_assets/diagram_navegacion_cartagena_segura.png", dpi=300, bbox_inches='tight')
    plt.close()
    print("Created diagram_navegacion_cartagena_segura.png successfully!")

create_navigation_diagram()
