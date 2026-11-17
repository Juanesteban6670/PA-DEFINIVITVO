#!/usr/bin/env python3
"""
Render API Client Helper for Cartagena Segura
Allows listing services, checking deploy status, and triggering clean deploys.
Reads RENDER_API_KEY from environment or .env.render file.
"""

import os
import sys
import json
import urllib.request
import urllib.error

API_BASE = "https://api.render.com/v1"

def load_api_key():
    key = os.environ.get("RENDER_API_KEY")
    if key and key.strip():
        return key.strip()

    # Try reading from .env.render
    env_file = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env.render")
    if os.path.exists(env_file):
        with open(env_file, "r") as f:
            for line in f:
                line = line.strip()
                if line.startswith("RENDER_API_KEY="):
                    val = line.split("=", 1)[1].strip().strip('"').strip("'")
                    if val:
                        return val
    return None

def api_request(endpoint, method="GET", data=None):
    api_key = load_api_key()
    if not api_key:
        print("[ERROR] No se encontró RENDER_API_KEY. Configúrala en .env.render o como variable de entorno.", file=sys.stderr)
        sys.exit(1)

    url = f"{API_BASE}{endpoint}"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Accept": "application/json",
        "Content-Type": "application/json",
    }

    req_data = json.dumps(data).encode("utf-8") if data else None
    req = urllib.request.Request(url, data=req_data, headers=headers, method=method)

    try:
        with urllib.request.urlopen(req) as resp:
            content = resp.read().decode("utf-8")
            if content:
                return json.loads(content)
            return {}
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8")
        print(f"[HTTP {e.code}] Error en {endpoint}: {err_body}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"[ERROR] Error de conexión: {e}", file=sys.stderr)
        sys.exit(1)

def get_service_id():
    services = api_request("/services?limit=10")
    for s in services:
        svc = s.get("service", {})
        if "pa-definivitvo" in svc.get("name", "").lower() or "cartagena" in svc.get("name", "").lower():
            return svc.get("id"), svc.get("name")
    if services:
        first = services[0].get("service", {})
        return first.get("id"), first.get("name")
    return None, None

def cmd_status():
    svc_id, svc_name = get_service_id()
    if not svc_id:
        print("No se encontró ningún servicio en esta cuenta de Render.")
        return

    print(f"=== Servicio: {svc_name} ({svc_id}) ===")
    deploys = api_request(f"/services/{svc_id}/deploys?limit=5")
    for d in deploys:
        dep = d.get("deploy", {})
        dep_id = dep.get("id")
        status = dep.get("status")
        commit = dep.get("commit", {})
        commit_msg = commit.get("message", "").strip().split("\n")[0]
        commit_id = commit.get("id", "")[:7]
        created_at = dep.get("createdAt")
        finished_at = dep.get("finishedAt")
        print(f"Deploy [{dep_id}] - Estado: {status}")
        print(f"  Commit: {commit_id} - {commit_msg}")
        print(f"  Creado: {created_at} | Finalizado: {finished_at or 'En curso...'}")
        print("-" * 50)

def cmd_deploy(clear_cache=False):
    svc_id, svc_name = get_service_id()
    if not svc_id:
        print("No se encontró el servicio para desplegar.")
        return

    payload = {"clearCache": "clear" if clear_cache else "do_not_clear"}
    print(f"Disparando nuevo deploy para '{svc_name}' (clearCache={clear_cache})...")
    res = api_request(f"/services/{svc_id}/deploys", method="POST", data=payload)
    dep_id = res.get("id")
    print(f"[OK] Deploy iniciado con ID: {dep_id}")

def main():
    if len(sys.argv) < 2 or sys.argv[1] == "status":
        cmd_status()
    elif sys.argv[1] == "deploy":
        clear_cache = "--clear-cache" in sys.argv
        cmd_deploy(clear_cache)
    elif sys.argv[1] == "services":
        services = api_request("/services?limit=20")
        print(json.dumps(services, indent=2))
    else:
        print("Uso: python3 scripts/render_client.py [status|deploy|services] [--clear-cache]")

if __name__ == "__main__":
    main()
