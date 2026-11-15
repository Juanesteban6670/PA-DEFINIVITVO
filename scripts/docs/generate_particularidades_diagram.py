import os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as patches

os.makedirs("doc_assets", exist_ok=True)

plt.rcParams['font.family'] = 'sans-serif'
plt.rcParams['font.sans-serif'] = ['DejaVu Sans', 'Arial', 'Helvetica']

def create_particularities_diagram():
    fig, ax = plt.subplots(figsize=(13, 6.5), dpi=300)
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 60)
    ax.axis('off')
    fig.patch.set_facecolor('#F8FAFC')

    # Header tags matching Image 1
    ax.text(5, 56, "CONCEPTUAL", fontsize=10, fontweight='bold', color='#64748B')
    ax.text(5, 51.5, "Casos de uso en una app móvil (Adaptado a Cartagena Segura)", fontsize=18, fontweight='bold', color='#0F172A')

    # Table coordinates
    cols_x = [5, 25, 55, 95]
    row_height = 8.5
    start_y = 44

    # Header row
    hdr_box = patches.FancyBboxPatch((5, start_y - 5), 90, 6.5, boxstyle="round,pad=0.2,rounding_size=0.5",
                                     linewidth=1, edgecolor='#CBD5E1', facecolor='#EFF6FF', zorder=2)
    ax.add_patch(hdr_box)
    ax.text(7, start_y - 2, "Particularidad", fontsize=11, fontweight='bold', color='#1E40AF')
    ax.text(27, start_y - 2, "Qué cambia", fontsize=11, fontweight='bold', color='#1E40AF')
    ax.text(57, start_y - 2, "En Cartagena Segura (Implementación Real)", fontsize=11, fontweight='bold', color='#1E40AF')

    rows_data = [
        ("Actores secundarios", 
         "Otros sistemas\ntambién son actores", 
         "Groq AI (Llama 3), Cloudinary (fotos), OpenStreetMap/Esri,\nBroker STOMP WebSocket y Central Telefónica 123."),
        
        ("Permisos del teléfono", 
         "Cámara, ubicación\ny notificaciones", 
         "Ubicación GPS precisa para reportes y rutas seguras;\nCámara para fotos del incidente; Teléfono para llamadas 123."),
        
        ("Sin conexión", 
         "Qué se puede hacer\nsin internet", 
         "Borrador automático de reportes (ReportDraftStore);\nLlamadas SOS por voz GSM sin datos; Mapa en caché local."),
        
        ("Interrupciones", 
         "Llamadas, otras apps,\nbatería baja", 
         "Preservación de formulario si entra llamada al reportar;\nRestauración de ruta segura y radar GPS al volver a la app.")
    ]

    curr_y = start_y - 6.5
    for idx, (part, cambia, app_desc) in enumerate(rows_data):
        bg = '#FFFFFF' if idx % 2 == 0 else '#F8FAFC'
        r_box = patches.Rectangle((5, curr_y - row_height), 90, row_height,
                                  linewidth=0.8, edgecolor='#E2E8F0', facecolor=bg, zorder=2)
        ax.add_patch(r_box)

        ax.text(7, curr_y - row_height/2, part, fontsize=10, fontweight='bold', va='center', color='#0F172A', zorder=3)
        ax.text(27, curr_y - row_height/2, cambia, fontsize=9.5, va='center', color='#334155', zorder=3)
        ax.text(57, curr_y - row_height/2, app_desc, fontsize=9.2, va='center', color='#1E293B', zorder=3)

        curr_y -= row_height

    plt.tight_layout()
    plt.savefig("doc_assets/diagram_particularidades_moviles.png", dpi=300, bbox_inches='tight')
    plt.close()
    print("Created diagram_particularidades_moviles.png successfully!")

create_particularities_diagram()
