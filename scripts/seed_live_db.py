#!/usr/bin/env python3
"""
Cartagena Segura - Siembra directa de incidentes realistas en la base de datos de producción (MongoDB Atlas).
"""
import urllib.request
import json
import datetime
import sys

BASE_URL = "https://pa-definivitvo.onrender.com/api"

def login():
    req = urllib.request.Request(
        f"{BASE_URL}/Auth/Login",
        data=json.dumps({"username": "admin", "password": "Password123!"}).encode("utf-8"),
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        token = data["data"]["token"]
        print("✓ Autenticado como admin. Token obtenido.")
        return token

def seed_incidents(token):
    # Lista de incidentes realistas de Cartagena
    incidents = [
        # Centro Histórico
        {"type": "ROBO", "description": "Hurto de celular en la Plaza de los Coches frente a la Torre del Reloj", "location": "Plaza de los Coches, Centro Histórico", "lat": 10.4228, "lon": -75.5486, "prio": "HIGH", "status": "RESOLVED"},
        {"type": "ACTIVIDAD_SOSPECHOSA", "description": "Sujetos merodeando joyerías en Calle de la Moneda", "location": "Calle de la Moneda, Centro Histórico", "lat": 10.4242, "lon": -75.5499, "prio": "LOW", "status": "PENDING"},
        {"type": "VIA_CERRADA", "description": "Obras de mantenimiento en Calle San Juan de Dios", "location": "Calle San Juan de Dios, Centro Histórico", "lat": 10.4215, "lon": -75.5492, "prio": "MEDIUM", "status": "RESOLVED"},
        {"type": "ALTERCADO", "description": "Discusión en terraza comercial de Plaza Santo Domingo", "location": "Plaza Santo Domingo, Centro Histórico", "lat": 10.4231, "lon": -75.5505, "prio": "MEDIUM", "status": "RESOLVED"},
        {"type": "SOS", "description": "Asistencia de primeros auxilios por golpe de calor", "location": "Baluarte de San Ignacio, Centro Histórico", "lat": 10.4208, "lon": -75.5512, "prio": "CRITICAL", "status": "RESOLVED"},

        # Bocagrande y Castillogrande
        {"type": "TRAFICO", "description": "Congestión vehicular pesada en Avenida San Martín", "location": "Avenida San Martín #8-45, Bocagrande", "lat": 10.4062, "lon": -75.5558, "prio": "MEDIUM", "status": "RESOLVED"},
        {"type": "ACCIDENTE_TRANSITO", "description": "Colisión simple de dos taxis en retorno vial", "location": "Carrera 2 con Calle 6, Bocagrande", "lat": 10.4021, "lon": -75.5582, "prio": "HIGH", "status": "RESOLVED"},
        {"type": "ROBO", "description": "Hurto de pertenencias desatendidas en playa", "location": "Playa Hollywood, Bocagrande", "lat": 10.4012, "lon": -75.5601, "prio": "MEDIUM", "status": "RESOLVED"},
        {"type": "TRAFICO", "description": "Semáforo averiado provocando retención", "location": "Avenida San Martín con Calle 10, Bocagrande", "lat": 10.4045, "lon": -75.5565, "prio": "LOW", "status": "RESOLVED"},
        {"type": "SEGURIDAD", "description": "Patrullaje marítimo preventivo en Bahía de Castillogrande", "location": "Club Naval, Castillogrande", "lat": 10.3950, "lon": -75.5540, "prio": "LOW", "status": "RESOLVED"},

        # Manga y Pie de la Popa
        {"type": "ALUMBRADO_PUBLICO", "description": "Alumbrado público sin funcionar en sendero", "location": "Avenida Miramar frente al Club de Pesca, Manga", "lat": 10.4145, "lon": -75.5385, "prio": "MEDIUM", "status": "RESOLVED"},
        {"type": "OBSTACULO_VIAL", "description": "Rama de árbol caída sobre carril peatonal", "location": "Callejón Dandy #22-14, Manga", "lat": 10.4120, "lon": -75.5398, "prio": "LOW", "status": "RESOLVED"},
        {"type": "TRAFICO", "description": "Tránsito lento en acceso a puente", "location": "Puente Román, Manga", "lat": 10.4182, "lon": -75.5410, "prio": "MEDIUM", "status": "RESOLVED"},
        {"type": "INFRAESTRUCTURA", "description": "Bache en curva de ascenso señalizado", "location": "Subida al Convento de la Popa, Pie de la Popa", "lat": 10.4215, "lon": -75.5310, "prio": "LOW", "status": "RESOLVED"},
        {"type": "ROBO", "description": "Intento de hurto frustrado por red comunitaria", "location": "Calle del Toril, Pie de la Popa", "lat": 10.4190, "lon": -75.5335, "prio": "HIGH", "status": "RESOLVED"},

        # Getsemaní
        {"type": "VIA_CERRADA", "description": "Obras de pavimentación en la calle de la Media Luna", "location": "Calle de la Media Luna, Getsemaní", "lat": 10.4198, "lon": -75.5435, "prio": "MEDIUM", "status": "RESOLVED"},
        {"type": "ALTERCADO", "description": "Discusión nocturna en vía pública controlada por policía", "location": "Plaza de la Trinidad, Getsemaní", "lat": 10.4195, "lon": -75.5452, "prio": "MEDIUM", "status": "RESOLVED"},
        {"type": "ALUMBRADO_PUBLICO", "description": "Falla en luminarias coloniales de calle angosta", "location": "Calle del Pozo, Getsemaní", "lat": 10.4188, "lon": -75.5441, "prio": "LOW", "status": "IN_PROGRESS"},

        # Bazurto
        {"type": "TRAFICO", "description": "Paso habilitado en Av. Pedro de Heredia con precaución", "location": "Avenida Pedro de Heredia frente a Transcaribe, Bazurto", "lat": 10.4085, "lon": -75.5195, "prio": "MEDIUM", "status": "RESOLVED"},
        {"type": "OBSTACULO_VIAL", "description": "Ocupación indebida de carril por carretas comerciales", "location": "Sector La Cuchilla, Bazurto", "lat": 10.4072, "lon": -75.5178, "prio": "LOW", "status": "IN_PROGRESS"},
        {"type": "PELEA", "description": "Riña entre particulares controlada de inmediato", "location": "Central de Abastos, Mercado Bazurto", "lat": 10.4091, "lon": -75.5202, "prio": "HIGH", "status": "RESOLVED"},

        # Olaya Herrera
        {"type": "ALTERCADO", "description": "Enfrentamiento barrial disuelto por cuadrante de vigilancia", "location": "Sector Stella Calle 32, Olaya Herrera", "lat": 10.3945, "lon": -75.4975, "prio": "CRITICAL", "status": "RESOLVED"},
        {"type": "INFRAESTRUCTURA", "description": "Acumulación de aguas lluvias en calzada", "location": "Carrera 50 con Calle 34, Olaya Herrera", "lat": 10.3962, "lon": -75.4990, "prio": "MEDIUM", "status": "PENDING"},
        {"type": "SEGURIDAD", "description": "Inspección y control en escenario deportivo comunitario", "location": "Cancha de Olaya Herrera", "lat": 10.3930, "lon": -75.4960, "prio": "LOW", "status": "RESOLVED"},
    ]

    created = 0
    for inc in incidents:
        payload = {
            "type": inc["type"],
            "description": inc["description"],
            "location": inc["location"],
            "latitude": inc["lat"],
            "longitude": inc["lon"],
            "priority": inc["prio"],
            "imageUrls": []
        }
        req = urllib.request.Request(
            f"{BASE_URL}/Incidents",
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {token}"
            }
        )
        try:
            with urllib.request.urlopen(req) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                inc_id = data["data"]["id"]
                created += 1

                # Actualizar estado si es RESOLVED
                if inc["status"] != "PENDING":
                    patch_req = urllib.request.Request(
                        f"{BASE_URL}/Incidents/{inc_id}/Status",
                        data=json.dumps({
                            "status": inc["status"],
                            "priority": inc["prio"],
                            "assignedTo": "oficial_cuadrante4",
                            "changeReason": "Gestión comunitaria verificada"
                        }).encode("utf-8"),
                        headers={
                            "Content-Type": "application/json",
                            "Authorization": f"Bearer {token}"
                        },
                        method="PATCH"
                    )
                    with urllib.request.urlopen(patch_req) as p_resp:
                        pass
        except Exception as e:
            print(f"Error creando incidente {inc['description'][:20]}: {e}")

    print(f"✓ Total incidentes sembrados exitosamente en MongoDB Atlas: {created}")

if __name__ == "__main__":
    t = login()
    seed_incidents(t)
