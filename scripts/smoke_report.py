"""Verify a report and its evidence against an isolated local stack."""

import argparse
import base64
import json
from urllib.error import HTTPError
from urllib.parse import urlsplit
from urllib.request import Request, urlopen
from uuid import uuid4


ADMIN = "ci_report_admin"
PASSWORD = "Local-only-validation-123!"
PHOTO = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/"
    "x8AAwMCAO+a3X8AAAAASUVORK5CYII="
)


def request(base, path, *, method="GET", payload=None, content_type="application/json",
            token=None, expected=200):
    headers = {}
    if isinstance(payload, dict):
        payload = json.dumps(payload).encode()
    if payload is not None:
        headers["Content-Type"] = content_type
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = Request(base + path, data=payload, headers=headers, method=method)
    try:
        with urlopen(req, timeout=15) as response:
            status, data = response.status, response.read()
    except HTTPError as error:
        status, data = error.code, error.read()
    assert status == expected, f"{method} {path}: HTTP {status}, expected {expected}"
    return data


def register(base, username):
    return json.loads(request(base, "/api/Auth/Register", method="POST", payload={
        "username": username, "password": PASSWORD,
        "email": f"{username}@example.test", "fullName": "Prueba Cartagena",
    }))["data"]["token"]


def verify(base):
    identifier = uuid4().hex[:10]
    citizen = register(base, f"qa_{identifier}")
    other = register(base, f"qa_other_{identifier}")
    admin = json.loads(request(base, "/api/Auth/Login", method="POST", payload={
        "username": ADMIN, "password": PASSWORD,
    }))["data"]["token"]
    boundary = f"report-{identifier}"
    multipart = (
        f'--{boundary}\r\nContent-Disposition: form-data; name="files"; filename="proof.png"'
        "\r\nContent-Type: image/png\r\n\r\n"
    ).encode() + PHOTO + f"\r\n--{boundary}--\r\n".encode()
    uploaded = request(base, "/api/Files/Upload", method="POST", payload=multipart,
                       content_type=f"multipart/form-data; boundary={boundary}", token=citizen)
    url = json.loads(uploaded)["data"]["urls"][0]
    photo = urlsplit(url).path
    request(base, photo, expected=401)
    request(base, photo, token=other, expected=404)
    assert request(base, photo, token=citizen) == PHOTO

    report = {
        "type": "ROBO", "description": "Prueba aislada de reporte y foto",
        "location": "Ubicación privada de ensayo", "latitude": 10.423456,
        "longitude": -75.543678, "priority": "HIGH",
        "imageUrls": [url], "idempotencyKey": identifier,
    }
    request(base, "/api/Incidents", method="POST", payload=report, token=other, expected=400)
    incident = json.loads(request(base, "/api/Incidents", method="POST",
                                  payload=report, token=citizen))["data"]
    repeat = json.loads(request(base, "/api/Incidents", method="POST",
                                payload=report, token=citizen))["data"]
    assert repeat["id"] == incident["id"]
    incident_id = incident["id"]
    own_reports = json.loads(request(base, "/api/Incidents/My", token=citizen))["data"]
    assert sum(item["id"] == incident_id for item in own_reports) == 1
    public_reports = json.loads(request(base, "/api/Incidents"))["data"]
    summary = next(item for item in public_reports if item["id"] == incident_id)
    assert {"reportedBy", "imageUrls", "description", "idempotencyKey"}.isdisjoint(summary)
    assert summary["latitude"] == 10.423 and summary["location"] == "Cartagena"
    request(base, "/api/Incidents/Seed", method="POST", token=citizen, expected=403)
    request(base, "/api/Incidents/Seed", method="POST", token=admin, expected=404)

    assert request(base, photo, token=admin) == PHOTO
    request(base, f"/api/Incidents/{incident_id}/Status", method="PATCH",
            payload={"status": "IN_PROGRESS", "changeReason": "Ensayo de seguimiento"},
            token=admin)
    notifications = json.loads(request(base, "/api/Notifications", token=citizen))["data"]
    notice = next(n for n in notifications
                  if n.get("relatedEntityId") == incident_id and n["type"] == "INCIDENT_UPDATED")
    request(base, f'/api/Notifications/{notice["id"]}/Read', method="PATCH", token=citizen)
    detail = json.loads(request(base, f"/api/Incidents/{incident_id}", token=citizen))["data"]
    assert detail["status"] == "IN_PROGRESS" and detail["imageUrls"] == [url]
    print("Reporte, foto privada, reenvío idempotente, cambio de estado y notificación verificados.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["register-admin", "verify"])
    parser.add_argument("--base", required=True)
    args = parser.parse_args()
    base = args.base.rstrip("/")
    if urlsplit(base).hostname not in {"127.0.0.1", "localhost"}:
        parser.error("usa una instancia local aislada")
    if args.mode == "register-admin":
        register(base, ADMIN)
    else:
        verify(base)


if __name__ == "__main__":
    main()
