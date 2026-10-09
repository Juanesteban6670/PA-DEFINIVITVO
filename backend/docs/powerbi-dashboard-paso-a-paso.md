# Dashboard Power BI - Cartagena Segura (Paso a paso)

## 1) Analisis rapido del backend (segun el codigo)

Este proyecto usa 2 motores de datos:

- MongoDB: `incidents`, `zones`, `logs`, `notifications`, `comments`, `incident_history`, `reports`
- PostgreSQL: `users`, `roles`, `emergency_contacts`

Para un dashboard de seguridad ciudadana, el nucleo esta en:

- `incidents` (hechos principales)
- `zones` (dimension geografica)
- `logs` (auditoria, opcional, requiere rol ADMIN)

## 2) Objetivo del dashboard

Crear un dashboard operativo con:

- Total de incidentes
- Incidentes pendientes, en progreso y resueltos
- Incidentes criticos
- Tendencia diaria/semanal
- Mapa de calor por latitud/longitud
- Top zonas por volumen

## 3) Endpoints que vamos a consumir

- `POST /api/auth/login` (publico) -> retorna token JWT
- `GET /api/incidents` (requiere JWT)
- `GET /api/zones` (requiere JWT)
- `GET /api/logs` (opcional, requiere rol ADMIN)

Todas las respuestas vienen con esta envoltura:

```json
{
  "success": true,
  "message": "OK",
  "data": [...]
}
```

## 4) Crear parametros en Power BI

En Power BI Desktop:

1. `Inicio` -> `Transformar datos` -> `Administrar parametros`
2. Crear estos parametros:

- `pBaseUrl` (Texto) ejemplo: `http://localhost:8080/`
- `pUsername` (Texto)
- `pPassword` (Texto)

Nota: deja slash final en `pBaseUrl`.

## 5) Query de autenticacion (token)

En Power Query, crea una consulta en blanco llamada `fnGetToken` y pega:

```powerquery
let
    Body = Json.FromValue([
        username = pUsername,
        password = pPassword
    ]),
    Response = Json.Document(
        Web.Contents(
            pBaseUrl,
            [
                RelativePath = "api/auth/login",
                Headers = [#"Content-Type" = "application/json"],
                Content = Body
            ]
        )
    ),
    Token = Response[data][token]
in
    Token
```

## 6) Query de incidentes (tabla principal)

Crea una consulta llamada `Incidents`:

```powerquery
let
    Token = fnGetToken,
    Response = Json.Document(
        Web.Contents(
            pBaseUrl,
            [
                RelativePath = "api/incidents",
                Headers = [Authorization = "Bearer " & Token]
            ]
        )
    ),
    Data = Response[data],
    ToTable = Table.FromList(Data, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    Expanded = Table.ExpandRecordColumn(
        ToTable,
        "Column1",
        {
            "id",
            "type",
            "description",
            "location",
            "latitude",
            "longitude",
            "zoneId",
            "reportedBy",
            "assignedTo",
            "imageUrls",
            "priority",
            "status",
            "createdAt",
            "updatedAt"
        },
        {
            "id",
            "type",
            "description",
            "location",
            "latitude",
            "longitude",
            "zoneId",
            "reportedBy",
            "assignedTo",
            "imageUrls",
            "priority",
            "status",
            "createdAt",
            "updatedAt"
        }
    ),
    Converted = Table.TransformColumns(
        Expanded,
        {
            {"createdAt", each try DateTime.From(_) otherwise null, type datetime},
            {"updatedAt", each try DateTime.From(_) otherwise null, type datetime}
        }
    ),
    Typed = Table.TransformColumnTypes(
        Converted,
        {
            {"latitude", type number},
            {"longitude", type number},
            {"id", type text},
            {"zoneId", type text},
            {"type", type text},
            {"priority", type text},
            {"status", type text},
            {"reportedBy", type text},
            {"assignedTo", type text}
        }
    ),
    AddDate = Table.AddColumn(Typed, "createdDate", each Date.From([createdAt]), type date),
    AddHour = Table.AddColumn(AddDate, "createdHour", each if [createdAt] = null then null else Time.Hour(Time.From([createdAt])), Int64.Type),
    AddImageCount = Table.AddColumn(AddHour, "imageCount", each if [imageUrls] = null then 0 else List.Count([imageUrls]), Int64.Type)
in
    AddImageCount
```

## 7) Query de zonas

Crea una consulta llamada `Zones`:

```powerquery
let
    Token = fnGetToken,
    Response = Json.Document(
        Web.Contents(
            pBaseUrl,
            [
                RelativePath = "api/zones",
                Headers = [Authorization = "Bearer " & Token]
            ]
        )
    ),
    Data = Response[data],
    ToTable = Table.FromList(Data, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    Expanded = Table.ExpandRecordColumn(
        ToTable,
        "Column1",
        {
            "id",
            "name",
            "description",
            "riskLevel",
            "centerLatitude",
            "centerLongitude",
            "totalIncidents",
            "pendingIncidents",
            "resolvedIncidents",
            "active"
        },
        {
            "id",
            "name",
            "description",
            "riskLevel",
            "centerLatitude",
            "centerLongitude",
            "totalIncidents",
            "pendingIncidents",
            "resolvedIncidents",
            "active"
        }
    ),
    Typed = Table.TransformColumnTypes(
        Expanded,
        {
            {"id", type text},
            {"name", type text},
            {"riskLevel", type text},
            {"centerLatitude", type number},
            {"centerLongitude", type number},
            {"totalIncidents", Int64.Type},
            {"pendingIncidents", Int64.Type},
            {"resolvedIncidents", Int64.Type},
            {"active", type logical}
        }
    )
in
    Typed
```

## 8) Query opcional de logs (solo admin)

Si tu usuario tiene rol ADMIN, crea `Logs`:

```powerquery
let
    Token = fnGetToken,
    Response = Json.Document(
        Web.Contents(
            pBaseUrl,
            [
                RelativePath = "api/logs",
                Headers = [Authorization = "Bearer " & Token]
            ]
        )
    ),
    Data = Response[data],
    ToTable = Table.FromList(Data, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    Expanded = Table.ExpandRecordColumn(
        ToTable,
        "Column1",
        {"id", "action", "user", "details", "entityType", "entityId", "level", "timestamp"},
        {"id", "action", "user", "details", "entityType", "entityId", "level", "timestamp"}
    ),
    Converted = Table.TransformColumns(Expanded, {{"timestamp", each try DateTime.From(_) otherwise null, type datetime}}),
    Typed = Table.TransformColumnTypes(Converted, {{"id", type text}, {"action", type text}, {"user", type text}, {"level", type text}})
in
    Typed
```

## 9) Modelo de datos (vista Modelo en Power BI)

Crear relaciones:

- `Incidents[zoneId]` (muchos) -> `Zones[id]` (uno)
- `Incidents[createdDate]` (muchos) -> `Calendar[Date]` (uno)
- Opcional: `Logs[timestamp]` -> `Calendar[DateTime]` o columna fecha derivada

Crear tabla de calendario con DAX:

```dax
Calendar =
ADDCOLUMNS(
    CALENDAR(MIN(Incidents[createdDate]), MAX(Incidents[createdDate])),
    "Year", YEAR([Date]),
    "MonthNo", MONTH([Date]),
    "Month", FORMAT([Date], "YYYY-MM"),
    "Week", WEEKNUM([Date], 2),
    "DayName", FORMAT([Date], "ddd")
)
```

## 10) Medidas DAX recomendadas

```dax
Total Incidentes = COUNTROWS(Incidents)

Pendientes =
CALCULATE([Total Incidentes], Incidents[status] = "PENDING")

En Progreso =
CALCULATE([Total Incidentes], Incidents[status] = "IN_PROGRESS")

Resueltos =
CALCULATE([Total Incidentes], Incidents[status] = "RESOLVED")

Criticos =
CALCULATE([Total Incidentes], Incidents[priority] = "CRITICAL")

Tasa Resolucion =
DIVIDE([Resueltos], [Total Incidentes], 0)

Incidentes Ultimos 7 Dias =
CALCULATE(
    [Total Incidentes],
    DATESINPERIOD(Calendar[Date], MAX(Calendar[Date]), -7, DAY)
)

Incidentes Semana Anterior =
CALCULATE(
    [Total Incidentes],
    DATESINPERIOD(Calendar[Date], MAX(Calendar[Date]) - 7, -7, DAY)
)

Variacion Semanal =
[Incidentes Ultimos 7 Dias] - [Incidentes Semana Anterior]
```

## 11) Visuales (orden sugerido)

Pagina 1 - Resumen Ejecutivo:

- Tarjetas: `Total Incidentes`, `Pendientes`, `Resueltos`, `Criticos`, `Tasa Resolucion`
- Linea: incidentes por `Calendar[Date]`
- Donut: incidentes por `status`
- Barras: Top 10 zonas (`Zones[name]`) por incidentes
- Mapa: `latitude`, `longitude`, tamano por conteo, color por `priority`

Pagina 2 - Operacion:

- Matriz: `Zones[name]` x `type` con conteo
- Barra apilada: `type` por `status`
- Tabla detalle: id, tipo, prioridad, estado, fecha, reportado por

Pagina 3 - Auditoria (opcional):

- Barras: `Logs[action]` por conteo
- Serie temporal: logs por fecha
- Segmentadores: `Logs[level]`, `Logs[user]`

## 12) Recomendaciones de calidad de datos

- Para KPIs principales, usa `Incidents` como fuente de verdad.
- Los campos de conteo en `Zones` (`totalIncidents`, `pendingIncidents`, `resolvedIncidents`) pueden desalinearse del historico real si no se sincronizan todos los cambios de estado.
- Si deseas refresh automatico en Power BI Service, define un mecanismo estable para renovar token JWT o expone un endpoint tecnico de solo lectura para BI.

## 13) Checklist de entrega

- [ ] Relaciones activas y en direccion correcta
- [ ] Medidas DAX sin errores
- [ ] Filtros por fecha, zona, tipo y prioridad
- [ ] Mapa geolocalizado funcionando
- [ ] Dashboard publicado
