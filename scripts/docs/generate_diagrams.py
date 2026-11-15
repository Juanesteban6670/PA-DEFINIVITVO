import os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as patches

os.makedirs("doc_assets", exist_ok=True)

# Set base aesthetics
plt.rcParams['font.family'] = 'sans-serif'
plt.rcParams['font.sans-serif'] = ['DejaVu Sans', 'Arial', 'Helvetica']

# -------------------------------------------------------------
# 1. DIAGRAMA GENERAL DE CASOS DE USO (UML Use Case Diagram)
# -------------------------------------------------------------
def create_uml_use_case_diagram():
    fig, ax = plt.subplots(figsize=(14, 10), dpi=300)
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)
    ax.axis('off')

    # Background
    fig.patch.set_facecolor('#F8FAFC')
    ax.set_facecolor('#F8FAFC')

    # Title
    ax.text(50, 97, "DIAGRAMA GENERAL DE CASOS DE USO (UML)", fontsize=18, fontweight='bold', ha='center', color='#0F172A')
    ax.text(50, 94.5, "Plataforma de Seguridad Ciudadana — Cartagena Segura", fontsize=12, fontstyle='italic', ha='center', color='#475569')

    # System boundary box
    sys_box = patches.FancyBboxPatch((24, 4), 52, 87, boxstyle="round,pad=1.5,rounding_size=2",
                                     linewidth=2.5, edgecolor='#2563EB', facecolor='#FFFFFF', zorder=1)
    ax.add_patch(sys_box)
    ax.text(50, 88.5, "Límite del Sistema: Cartagena Segura (Web / PWA / Móvil)", fontsize=13, fontweight='bold', ha='center', color='#1E40AF', zorder=2)

    # Actors
    # Actor 1: Ciudadano / Turista (Left)
    ax.plot(10, 68, 'o', markersize=26, color='#3B82F6', zorder=3)
    ax.plot([10, 10], [53, 65], color='#1E40AF', lw=4, zorder=3) # Body
    ax.plot([4, 16], [60, 60], color='#1E40AF', lw=3.5, zorder=3) # Arms
    ax.plot([10, 5], [53, 44], color='#1E40AF', lw=3.5, zorder=3) # Left Leg
    ax.plot([10, 15], [53, 44], color='#1E40AF', lw=3.5, zorder=3) # Right Leg
    ax.text(10, 39, "CIUDADANO /\nTURISTA", fontsize=11, fontweight='bold', ha='center', color='#1E293B')

    # Actor 2: Oficial de Policía / Cuadrante (Right Top)
    ax.plot(90, 72, 'o', markersize=24, color='#10B981', zorder=3)
    ax.plot([90, 90], [58, 69], color='#065F46', lw=4, zorder=3)
    ax.plot([85, 95], [64, 64], color='#065F46', lw=3.5, zorder=3)
    ax.plot([90, 86], [58, 50], color='#065F46', lw=3.5, zorder=3)
    ax.plot([90, 94], [58, 50], color='#065F46', lw=3.5, zorder=3)
    ax.text(90, 45, "OFICIAL DE\nPOLICÍA (CUADRANTE)", fontsize=11, fontweight='bold', ha='center', color='#065F46')

    # Actor 3: Administrador / Despachador CAD (Right Bottom)
    ax.plot(90, 26, 'o', markersize=24, color='#F59E0B', zorder=3)
    ax.plot([90, 90], [14, 23], color='#92400E', lw=4, zorder=3)
    ax.plot([85, 95], [19, 19], color='#92400E', lw=3.5, zorder=3)
    ax.plot([90, 86], [14, 6], color='#92400E', lw=3.5, zorder=3)
    ax.plot([90, 94], [14, 6], color='#92400E', lw=3.5, zorder=3)
    ax.text(90, 1.5, "ADMINISTRADOR /\nDESPACHADOR CAD", fontsize=11, fontweight='bold', ha='center', color='#92400E')

    # Use Cases list: (name, x, y, width, height, actors_connected)
    use_cases = [
        ("CU01: Autenticación & Perfil", 50, 83, 34, 4.5, ["citizen", "officer", "admin"]),
        ("CU02: Reportar Incidente (GPS + Foto)", 50, 75, 36, 4.8, ["citizen"]),
        ("CU03: Explorar Mapa & Zonas Calor", 50, 67, 34, 4.5, ["citizen", "officer", "admin"]),
        ("CU04: Calcular Ruta Segura", 50, 59, 32, 4.5, ["citizen"]),
        ("CU05: Botón de Pánico SOS / 123", 50, 51, 33, 4.5, ["citizen"]),
        ("CU06: Asistente IA Territorial (RAG)", 50, 43, 34, 4.5, ["citizen"]),
        ("CU07: Mis Reportes & Seguimiento", 50, 35, 33, 4.5, ["citizen"]),
        ("CU08: Monitorear Cuadrante Policial", 50, 27, 34, 4.5, ["officer"]),
        ("CU09: Gestionar Estados Incidente", 50, 19, 33, 4.5, ["officer", "admin"]),
        ("CU10: Métricas en Vivo & Bento Grid", 50, 11, 34, 4.5, ["admin"]),
    ]

    for name, cx, cy, w, h, connected in use_cases:
        ellipse = patches.Ellipse((cx, cy), w, h, edgecolor='#0284C7', facecolor='#EFF6FF', lw=1.8, zorder=2)
        ax.add_patch(ellipse)
        ax.text(cx, cy, name, fontsize=9.5, fontweight='bold', ha='center', va='center', color='#0369A1', zorder=3)

        # Lines to actors
        left_edge_x = cx - w/2
        right_edge_x = cx + w/2

        if "citizen" in connected:
            ax.plot([14, left_edge_x], [55, cy], color='#94A3B8', lw=1.2, ls='-', zorder=1)
        if "officer" in connected:
            ax.plot([right_edge_x, 86], [cy, 58], color='#94A3B8', lw=1.2, ls='-', zorder=1)
        if "admin" in connected:
            ax.plot([right_edge_x, 86], [cy, 18], color='#94A3B8', lw=1.2, ls='-', zorder=1)

    plt.tight_layout()
    plt.savefig("doc_assets/diagram_general_casos_uso.png", dpi=300, bbox_inches='tight')
    plt.close()

create_uml_use_case_diagram()
print("Created diagram_general_casos_uso.png")
