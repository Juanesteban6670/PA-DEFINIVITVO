// =============================================================================
// Cartagena Segura - Semilla de Datos MongoDB
// Genera zonas geográficas, incidentes con coordenadas reales, historial,
// comentarios comunitarios y notificaciones ciudadanas.
// =============================================================================

const db = db.getSiblingDB('cartagena_segura');

print('Iniciando carga de datos ficticios en MongoDB...');

// 1. ZONAS DE CARTAGENA
const zonesData = [
  {
    _id: 'zone_centro_historico',
    name: 'Centro Histórico y San Diego',
    description: 'Sector amurallado, patrimonio arquitectónico, comercios y alta afluencia turística.',
    riskLevel: 'MODERATE',
    centerLatitude: 10.4235,
    centerLongitude: -75.5485,
    totalIncidents: 4,
    pendingIncidents: 1,
    resolvedIncidents: 3,
    active: true,
    _class: 'Com.Backend.CartagenaSegura.Model.Zone'
  },
  {
    _id: 'zone_getsemani',
    name: 'Getsemaní',
    description: 'Barrio colonial bohemio, vida nocturna, restaurantes y plazas culturales.',
    riskLevel: 'MODERATE',
    centerLatitude: 10.4202,
    centerLongitude: -75.5448,
    totalIncidents: 3,
    pendingIncidents: 1,
    resolvedIncidents: 2,
    active: true,
    _class: 'Com.Backend.CartagenaSegura.Model.Zone'
  },
  {
    _id: 'zone_bocagrande',
    name: 'Bocagrande y Castillogrande',
    description: 'Zona costera moderna, rascacielos, playas, centros comerciales y hoteles.',
    riskLevel: 'LOW',
    centerLatitude: 10.4045,
    centerLongitude: -75.5565,
    totalIncidents: 3,
    pendingIncidents: 1,
    resolvedIncidents: 2,
    active: true,
    _class: 'Com.Backend.CartagenaSegura.Model.Zone'
  },
  {
    _id: 'zone_manga',
    name: 'Manga',
    description: 'Isla residencial tradicional, puerto marítimo, arquitectura republicana y paseos peatonales.',
    riskLevel: 'LOW',
    centerLatitude: 10.4132,
    centerLongitude: -75.5392,
    totalIncidents: 2,
    pendingIncidents: 1,
    resolvedIncidents: 1,
    active: true,
    _class: 'Com.Backend.CartagenaSegura.Model.Zone'
  },
  {
    _id: 'zone_pie_de_la_popa',
    name: 'Pie de la Popa y Cerro de la Popa',
    description: 'Sector residencial y punto histórico de acceso al convento de la Popa.',
    riskLevel: 'MODERATE',
    centerLatitude: 10.4205,
    centerLongitude: -75.5302,
    totalIncidents: 2,
    pendingIncidents: 1,
    resolvedIncidents: 1,
    active: true,
    _class: 'Com.Backend.CartagenaSegura.Model.Zone'
  },
  {
    _id: 'zone_bazurto',
    name: 'Mercado de Bazurto y La Quinta',
    description: 'Principal central de abastos y comercio popular de la ciudad con alta congestión.',
    riskLevel: 'HIGH',
    centerLatitude: 10.4082,
    centerLongitude: -75.5186,
    totalIncidents: 3,
    pendingIncidents: 2,
    resolvedIncidents: 1,
    active: true,
    _class: 'Com.Backend.CartagenaSegura.Model.Zone'
  },
  {
    _id: 'zone_olaya_herrera',
    name: 'Olaya Herrera y Boston',
    description: 'Zona suroriental con alta densidad demográfica y desafíos de seguridad comunitaria.',
    riskLevel: 'CRITICAL',
    centerLatitude: 10.3952,
    centerLongitude: -75.4982,
    totalIncidents: 3,
    pendingIncidents: 2,
    resolvedIncidents: 1,
    active: true,
    _class: 'Com.Backend.CartagenaSegura.Model.Zone'
  },
  {
    _id: 'zone_el_pozon',
    name: 'El Pozón y Villa Estrella',
    description: 'Extenso sector oriental de Cartagena, vulnerable a inundaciones pluviales y frentes barriales.',
    riskLevel: 'HIGH',
    centerLatitude: 10.3855,
    centerLongitude: -75.4725,
    totalIncidents: 2,
    pendingIncidents: 1,
    resolvedIncidents: 1,
    active: true,
    _class: 'Com.Backend.CartagenaSegura.Model.Zone'
  },
  {
    _id: 'zone_crespo_marbella',
    name: 'Crespo y Marbella',
    description: 'Franja norte costera, proximidad al aeropuerto internacional Rafael Núñez y playas del norte.',
    riskLevel: 'LOW',
    centerLatitude: 10.4432,
    centerLongitude: -75.5218,
    totalIncidents: 2,
    pendingIncidents: 1,
    resolvedIncidents: 1,
    active: true,
    _class: 'Com.Backend.CartagenaSegura.Model.Zone'
  },
  {
    _id: 'zone_la_plazuela',
    name: 'La Plazuela y San Fernando',
    description: 'Núcleo comercial de la zona suroccidental con intersecciones viales estratégicas.',
    riskLevel: 'MODERATE',
    centerLatitude: 10.3915,
    centerLongitude: -75.4802,
    totalIncidents: 2,
    pendingIncidents: 1,
    resolvedIncidents: 1,
    active: true,
    _class: 'Com.Backend.CartagenaSegura.Model.Zone'
  }
];

// Limpiar colecciones manteniendo consistencia
db.zones.deleteMany({});
db.zones.insertMany(zonesData);
print(`✓ Zonas insertadas: ${zonesData.length}`);

// 2. INCIDENTES REALISTAS DE CARTAGENA
const now = new Date();
const daysAgo = (days, hours = 0) => new Date(now.getTime() - (days * 24 * 3600 * 1000) - (hours * 3600 * 1000));

const incidentsData = [
  // --- Centro Histórico ---
  {
    _id: 'inc-ch-001',
    type: 'ROBO',
    description: 'Hurto de teléfono móvil mediante modalidad de cosquilleo a turista en la Plaza de los Coches.',
    location: 'Plaza de los Coches frente a la Torre del Reloj',
    latitude: 10.4228,
    longitude: -75.5486,
    zoneId: 'zone_centro_historico',
    reportedBy: 'ciudadano_maria',
    imageUrls: [],
    priority: 'MEDIUM',
    status: 'RESOLVED',
    assignedTo: 'oficial_cuadrante4',
    createdAt: daysAgo(3, 4),
    updatedAt: daysAgo(2, 6),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },
  {
    _id: 'inc-ch-002',
    type: 'ACTIVIDAD_SOSPECHOSA',
    description: 'Sujetos en motocicleta merodeando de manera insistente clientes de joyerías en Calle de la Moneda.',
    location: 'Calle de la Moneda con Calle de la Iglesia',
    latitude: 10.4242,
    longitude: -75.5499,
    zoneId: 'zone_centro_historico',
    reportedBy: 'juan123',
    imageUrls: [],
    priority: 'LOW',
    status: 'PENDING',
    createdAt: daysAgo(0, 5),
    updatedAt: daysAgo(0, 5),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },
  {
    _id: 'inc-ch-003',
    type: 'OBSTACULO_VIAL',
    description: 'Desprendimiento de revoque en balcón colonial obstaculizando paso peatonal.',
    location: 'Calle San Juan de Dios #3-45',
    latitude: 10.4215,
    longitude: -75.5492,
    zoneId: 'zone_centro_historico',
    reportedBy: 'ciudadano_camilo',
    imageUrls: [],
    priority: 'MEDIUM',
    status: 'RESOLVED',
    assignedTo: 'admin',
    createdAt: daysAgo(5, 8),
    updatedAt: daysAgo(4, 2),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },

  // --- Getsemaní ---
  {
    _id: 'inc-get-001',
    type: 'PELEA',
    description: 'Altercado entre varias personas a la salida de un establecimiento nocturno por volumen excesivo.',
    location: 'Calle del Guerrero cerca a Plaza de la Trinidad',
    latitude: 10.4206,
    longitude: -75.5443,
    zoneId: 'zone_getsemani',
    reportedBy: 'juan123',
    imageUrls: [],
    priority: 'HIGH',
    status: 'RESOLVED',
    assignedTo: 'oficial_cuadrante4',
    createdAt: daysAgo(2, 12),
    updatedAt: daysAgo(2, 10),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },
  {
    _id: 'inc-get-002',
    type: 'LUMINARIA_DANADA',
    description: 'Tramo de tres luminarias públicas apagadas en el callejón angosto, propiciando inseguridad nocturna.',
    location: 'Callejón Angosto con Calle del Pozo',
    latitude: 10.4194,
    longitude: -75.5458,
    zoneId: 'zone_getsemani',
    reportedBy: 'ciudadano_maria',
    imageUrls: [],
    priority: 'LOW',
    status: 'IN_PROGRESS',
    assignedTo: 'admin',
    createdAt: daysAgo(1, 3),
    updatedAt: daysAgo(0, 8),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },
  {
    _id: 'inc-get-003',
    type: 'ACOSO',
    description: 'Vendedor ambulante agresivo intimidando a comensales en terraza gastronómica.',
    location: 'Plaza de la Trinidad, Getsemaní',
    latitude: 10.4201,
    longitude: -75.5447,
    zoneId: 'zone_getsemani',
    reportedBy: 'ciudadano_camilo',
    imageUrls: [],
    priority: 'MEDIUM',
    status: 'PENDING',
    createdAt: daysAgo(0, 2),
    updatedAt: daysAgo(0, 2),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },

  // --- Bocagrande & Castillogrande ---
  {
    _id: 'inc-bg-001',
    type: 'ACCIDENTE',
    description: 'Colisión lateral entre taxi y vehículo particular con derrame menor de aceite.',
    location: 'Avenida San Martín con Calle 8, Bocagrande',
    latitude: 10.4042,
    longitude: -75.5562,
    zoneId: 'zone_bocagrande',
    reportedBy: 'testdeploy',
    imageUrls: [],
    priority: 'MEDIUM',
    status: 'RESOLVED',
    assignedTo: 'oficial_cuadrante4',
    createdAt: daysAgo(4, 5),
    updatedAt: daysAgo(4, 3),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },
  {
    _id: 'inc-bg-002',
    type: 'OBSTACULO_VIAL',
    description: 'Rejilla metálica de drenaje pluvial partida en carril derecho vehicular.',
    location: 'Carrera 3 con Calle 6, Castillogrande',
    latitude: 10.4018,
    longitude: -75.5579,
    zoneId: 'zone_bocagrande',
    reportedBy: 'ciudadano_maria',
    imageUrls: [],
    priority: 'LOW',
    status: 'PENDING',
    createdAt: daysAgo(1, 1),
    updatedAt: daysAgo(1, 1),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },
  {
    _id: 'inc-bg-003',
    type: 'ACTIVIDAD_SOSPECHOSA',
    description: 'Persona tomando fotografías a cerraduras de residencias privadas en Castillogrande.',
    location: 'Carrera 6 #5-80, Castillogrande',
    latitude: 10.3955,
    longitude: -75.5524,
    zoneId: 'zone_bocagrande',
    reportedBy: 'juan123',
    imageUrls: [],
    priority: 'HIGH',
    status: 'IN_PROGRESS',
    assignedTo: 'oficial_cuadrante4',
    createdAt: daysAgo(0, 8),
    updatedAt: daysAgo(0, 4),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },

  // --- Manga ---
  {
    _id: 'inc-man-001',
    type: 'ROBO',
    description: 'Intento de hurto de bicicleta deportiva sobre el Puente Román en horas de la noche.',
    location: 'Puente Román costado Manga',
    latitude: 10.4168,
    longitude: -75.5422,
    zoneId: 'zone_manga',
    reportedBy: 'ciudadano_camilo',
    imageUrls: [],
    priority: 'HIGH',
    status: 'IN_PROGRESS',
    assignedTo: 'oficial_cuadrante4',
    createdAt: daysAgo(1, 14),
    updatedAt: daysAgo(1, 10),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },
  {
    _id: 'inc-man-002',
    type: 'ACCIDENTE',
    description: 'Ciclista cayó por desnivel sin señalizar en el paseo peatonal de la Bahía de Manga.',
    location: 'Avenida Miramar frente al fuerte San Sebastián del Pastelillo',
    latitude: 10.4182,
    longitude: -75.5398,
    zoneId: 'zone_manga',
    reportedBy: 'juan123',
    imageUrls: [],
    priority: 'LOW',
    status: 'RESOLVED',
    createdAt: daysAgo(6, 2),
    updatedAt: daysAgo(5, 18),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },

  // --- Pie de la Popa ---
  {
    _id: 'inc-pop-001',
    type: 'ROBO',
    description: 'Atraco a mano armada a pareja de caminantes en la rampa de subida al Convento de la Popa.',
    location: 'Camino peatonal al Cerro de la Popa',
    latitude: 10.4215,
    longitude: -75.5280,
    zoneId: 'zone_pie_de_la_popa',
    reportedBy: 'ciudadano_maria',
    imageUrls: [],
    priority: 'CRITICAL',
    status: 'IN_PROGRESS',
    assignedTo: 'oficial_cuadrante4',
    createdAt: daysAgo(1, 18),
    updatedAt: daysAgo(1, 12),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },
  {
    _id: 'inc-pop-002',
    type: 'OBSTACULO_VIAL',
    description: 'Árbol caído bloqueando completamente el carril sur de la Calle Real de la Popa.',
    location: 'Calle Real de la Popa #22-15',
    latitude: 10.4192,
    longitude: -75.5312,
    zoneId: 'zone_pie_de_la_popa',
    reportedBy: 'testdeploy',
    imageUrls: [],
    priority: 'MEDIUM',
    status: 'RESOLVED',
    createdAt: daysAgo(3, 10),
    updatedAt: daysAgo(3, 4),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },

  // --- Mercado de Bazurto ---
  {
    _id: 'inc-baz-001',
    type: 'ROBO',
    description: 'Hurto de mercancía y billetera en el sector El Platanal aprovechando aglomeración.',
    location: 'Sector El Platanal, Mercado de Bazurto',
    latitude: 10.4085,
    longitude: -75.5185,
    zoneId: 'zone_bazurto',
    reportedBy: 'ciudadano_camilo',
    imageUrls: [],
    priority: 'HIGH',
    status: 'PENDING',
    createdAt: daysAgo(0, 6),
    updatedAt: daysAgo(0, 6),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },
  {
    _id: 'inc-baz-002',
    type: 'PELEA',
    description: 'Riña entre carretilleros con botellas de vidrio frente a la estación de Transcaribe.',
    location: 'Avenida Pedro de Heredia, Estación Bazurto',
    latitude: 10.4098,
    longitude: -75.5170,
    zoneId: 'zone_bazurto',
    reportedBy: 'juan123',
    imageUrls: [],
    priority: 'HIGH',
    status: 'RESOLVED',
    assignedTo: 'oficial_cuadrante4',
    createdAt: daysAgo(2, 16),
    updatedAt: daysAgo(2, 14),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },
  {
    _id: 'inc-baz-003',
    type: 'OBSTACULO_VIAL',
    description: 'Camión de carga varado obstaculiza dos carriles mixtos generando trancón monumental.',
    location: 'Av. Pedro de Heredia con Diagonal 21',
    latitude: 10.4072,
    longitude: -75.5202,
    zoneId: 'zone_bazurto',
    reportedBy: 'ciudadano_maria',
    imageUrls: [],
    priority: 'MEDIUM',
    status: 'PENDING',
    createdAt: daysAgo(0, 1),
    updatedAt: daysAgo(0, 1),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },

  // --- Olaya Herrera ---
  {
    _id: 'inc-ola-001',
    type: 'PELEA',
    description: 'Confrontación entre jóvenes de sectores contiguos (Playa Blanca vs San Antonio).',
    location: 'Sector Playa Blanca, Olaya Herrera',
    latitude: 10.3955,
    longitude: -75.4980,
    zoneId: 'zone_olaya_herrera',
    reportedBy: 'ciudadano_camilo',
    imageUrls: [],
    priority: 'CRITICAL',
    status: 'PENDING',
    createdAt: daysAgo(0, 3),
    updatedAt: daysAgo(0, 3),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },
  {
    _id: 'inc-ola-002',
    type: 'ROBO',
    description: 'Atraco a cobrador de transporte público en parada de busetas.',
    location: 'Av. Pedro Romero Calle 32',
    latitude: 10.3980,
    longitude: -75.4940,
    zoneId: 'zone_olaya_herrera',
    reportedBy: 'juan123',
    imageUrls: [],
    priority: 'HIGH',
    status: 'IN_PROGRESS',
    assignedTo: 'oficial_cuadrante4',
    createdAt: daysAgo(1, 20),
    updatedAt: daysAgo(1, 15),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },
  {
    _id: 'inc-ola-003',
    type: 'EMERGENCIA',
    description: 'Canal pluvial colapsado por acumulación de residuos e inundando viviendas aledañas.',
    location: 'Sector Ricaurte, Calle 34B',
    latitude: 10.3930,
    longitude: -75.5010,
    zoneId: 'zone_olaya_herrera',
    reportedBy: 'ciudadano_maria',
    imageUrls: [],
    priority: 'HIGH',
    status: 'RESOLVED',
    assignedTo: 'admin',
    createdAt: daysAgo(4, 9),
    updatedAt: daysAgo(3, 11),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },

  // --- El Pozón ---
  {
    _id: 'inc-poz-001',
    type: 'EMERGENCIA',
    description: 'Creciente súbita del arroyo canalizado afectando tres manzanas residenciales.',
    location: 'Sector 1 de Mayo, El Pozón',
    latitude: 10.3850,
    longitude: -75.4720,
    zoneId: 'zone_el_pozon',
    reportedBy: 'ciudadano_camilo',
    imageUrls: [],
    priority: 'CRITICAL',
    status: 'PENDING',
    createdAt: daysAgo(0, 7),
    updatedAt: daysAgo(0, 7),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },
  {
    _id: 'inc-poz-002',
    type: 'ROBO',
    description: 'Robo de cableado eléctrico público dejando sin alumbrado toda la carrera principal.',
    location: 'Vía principal El Pozón manzana 42',
    latitude: 10.3872,
    longitude: -75.4695,
    zoneId: 'zone_el_pozon',
    reportedBy: 'juan123',
    imageUrls: [],
    priority: 'HIGH',
    status: 'RESOLVED',
    createdAt: daysAgo(5, 14),
    updatedAt: daysAgo(4, 16),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },

  // --- Crespo & Marbella ---
  {
    _id: 'inc-cre-001',
    type: 'ACCIDENTE',
    description: 'Peatón arrollado levemente por motocicleta al cruzar hacia las playas de Marbella.',
    location: 'Avenida Santander a la altura de Marbella frente al mar',
    latitude: 10.4325,
    longitude: -75.5342,
    zoneId: 'zone_crespo_marbella',
    reportedBy: 'ciudadano_maria',
    imageUrls: [],
    priority: 'HIGH',
    status: 'RESOLVED',
    assignedTo: 'oficial_cuadrante4',
    createdAt: daysAgo(3, 7),
    updatedAt: daysAgo(3, 5),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },
  {
    _id: 'inc-cre-002',
    type: 'ACTIVIDAD_SOSPECHOSA',
    description: 'Automóvil gris polarizado estacionado por más de 5 horas cerca del túnel de Crespo sin conductor visible.',
    location: 'Parque Lineal de Crespo salida del túnel',
    latitude: 10.4480,
    longitude: -75.5152,
    zoneId: 'zone_crespo_marbella',
    reportedBy: 'juan123',
    imageUrls: [],
    priority: 'LOW',
    status: 'PENDING',
    createdAt: daysAgo(0, 4),
    updatedAt: daysAgo(0, 4),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },

  // --- La Plazuela & San Fernando ---
  {
    _id: 'inc-plz-001',
    type: 'ROBO',
    description: 'Intento de fleteo a usuario saliendo de entidad bancaria en el Centro Comercial La Plazuela.',
    location: 'Plazoleta exterior C.C. La Plazuela',
    latitude: 10.3920,
    longitude: -75.4810,
    zoneId: 'zone_la_plazuela',
    reportedBy: 'juan123',
    imageUrls: [],
    priority: 'CRITICAL',
    status: 'IN_PROGRESS',
    assignedTo: 'oficial_cuadrante4',
    createdAt: daysAgo(1, 16),
    updatedAt: daysAgo(1, 14),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  },
  {
    _id: 'inc-plz-002',
    type: 'HURTO',
    description: 'Sustracción de espejos retrovisores de vehículo parqueado en vía pública.',
    location: 'Barrio San Fernando Calle 22 #58-30',
    latitude: 10.3985,
    longitude: -75.4855,
    zoneId: 'zone_la_plazuela',
    reportedBy: 'testdeploy',
    imageUrls: [],
    priority: 'MEDIUM',
    status: 'RESOLVED',
    createdAt: daysAgo(4, 18),
    updatedAt: daysAgo(4, 12),
    _class: 'Com.Backend.CartagenaSegura.Model.Incident'
  }
];

// Preservar los reportes previos y agregar los nuevos si no existen
for (const inc of incidentsData) {
  db.incidents.updateOne(
    { _id: inc._id },
    { $set: inc },
    { upsert: true }
  );
}
print(`✓ Incidentes sincronizados: ${incidentsData.length}`);

// 3. HISTORIAL DE INCIDENTES (IncidentHistory)
const historyData = [
  {
    incidentId: 'inc-ch-001',
    oldStatus: 'PENDING',
    newStatus: 'IN_PROGRESS',
    oldPriority: 'MEDIUM',
    newPriority: 'MEDIUM',
    changedBy: 'oficial_cuadrante4',
    changeReason: 'Patrulla de turismo acudió a la Plaza de los Coches.',
    changedAt: daysAgo(2, 10),
    _class: 'Com.Backend.CartagenaSegura.Model.IncidentHistory'
  },
  {
    incidentId: 'inc-ch-001',
    oldStatus: 'IN_PROGRESS',
    newStatus: 'RESOLVED',
    oldPriority: 'MEDIUM',
    newPriority: 'MEDIUM',
    changedBy: 'oficial_cuadrante4',
    changeReason: 'Dispositivo recuperado y devuelto a la turista. Sujeto aprehendido.',
    changedAt: daysAgo(2, 6),
    _class: 'Com.Backend.CartagenaSegura.Model.IncidentHistory'
  },
  {
    incidentId: 'inc-get-001',
    oldStatus: 'PENDING',
    newStatus: 'RESOLVED',
    oldPriority: 'HIGH',
    newPriority: 'HIGH',
    changedBy: 'oficial_cuadrante4',
    changeReason: 'Comitiva policial intervino, mediación comunitaria exitosa.',
    changedAt: daysAgo(2, 10),
    _class: 'Com.Backend.CartagenaSegura.Model.IncidentHistory'
  },
  {
    incidentId: 'inc-bg-001',
    oldStatus: 'PENDING',
    newStatus: 'RESOLVED',
    oldPriority: 'MEDIUM',
    newPriority: 'MEDIUM',
    changedBy: 'admin',
    changeReason: 'Tránsito Distrital levantó croquis y grúa retiró los vehículos.',
    changedAt: daysAgo(4, 3),
    _class: 'Com.Backend.CartagenaSegura.Model.IncidentHistory'
  },
  {
    incidentId: 'inc-plz-001',
    oldStatus: 'PENDING',
    newStatus: 'IN_PROGRESS',
    oldPriority: 'CRITICAL',
    newPriority: 'CRITICAL',
    changedBy: 'admin',
    changeReason: 'Plan candado activado en inmediaciones de La Plazuela y San Fernando.',
    changedAt: daysAgo(1, 14),
    _class: 'Com.Backend.CartagenaSegura.Model.IncidentHistory'
  }
];

db.incident_history.deleteMany({});
db.incident_history.insertMany(historyData);
print(`✓ Historial de incidentes insertado: ${historyData.length}`);

// 4. COMENTARIOS COMUNITARIOS Y OPERATIVOS
const commentsData = [
  {
    incidentId: 'inc-ch-001',
    userId: 'oficial_cuadrante4',
    username: 'oficial_cuadrante4',
    content: 'Revisión de cámaras del CAD San Diego confirmó la ruta de escape del sospechoso.',
    isInternal: false,
    createdAt: daysAgo(2, 8),
    deleted: false,
    _class: 'Com.Backend.CartagenaSegura.Model.Comment'
  },
  {
    incidentId: 'inc-ch-001',
    userId: 'ciudadano_maria',
    username: 'ciudadano_maria',
    content: 'Muchas gracias por la rápida reacción de la policía de turismo.',
    isInternal: false,
    createdAt: daysAgo(2, 6),
    deleted: false,
    _class: 'Com.Backend.CartagenaSegura.Model.Comment'
  },
  {
    incidentId: 'inc-get-002',
    userId: 'admin',
    username: 'admin',
    content: 'Se ofició a la empresa de alumbrado público EPM / Afinia radicado #8921-2026.',
    isInternal: true,
    createdAt: daysAgo(0, 8),
    deleted: false,
    _class: 'Com.Backend.CartagenaSegura.Model.Comment'
  },
  {
    incidentId: 'inc-pop-001',
    userId: 'oficial_cuadrante4',
    username: 'oficial_cuadrante4',
    content: 'Patrullaje motorizado intensificado en la subida a La Popa durante las mañanas.',
    isInternal: false,
    createdAt: daysAgo(1, 12),
    deleted: false,
    _class: 'Com.Backend.CartagenaSegura.Model.Comment'
  },
  {
    incidentId: 'inc-plz-001',
    userId: 'juan123',
    username: 'juan123',
    content: 'Había dos motocicletas sospechosas esperando sobre la marginal de la avenida.',
    isInternal: false,
    createdAt: daysAgo(1, 15),
    deleted: false,
    _class: 'Com.Backend.CartagenaSegura.Model.Comment'
  },
  {
    incidentId: 'inc-plz-001',
    userId: 'oficial_cuadrante4',
    username: 'oficial_cuadrante4',
    content: 'Anotación tomada, estamos cruzando placas con la central de monitoreo.',
    isInternal: false,
    createdAt: daysAgo(1, 14),
    deleted: false,
    _class: 'Com.Backend.CartagenaSegura.Model.Comment'
  }
];

db.comments.deleteMany({});
db.comments.insertMany(commentsData);
print(`✓ Comentarios insertados: ${commentsData.length}`);

// 5. NOTIFICACIONES CIUDADANAS
const notificationsData = [
  {
    userId: 'juan123',
    title: '¡Bienvenido a Cartagena Segura!',
    message: 'Tu cuenta ciudadana está activa. Reporta incidentes en tiempo real y traza rutas seguras.',
    type: 'SYSTEM',
    relatedEntityId: null,
    relatedEntityType: null,
    read: true,
    createdAt: daysAgo(5),
    _class: 'Com.Backend.CartagenaSegura.Model.Notification'
  },
  {
    userId: 'juan123',
    title: 'Incidente Actualizado',
    message: 'Tu reporte en Getsemaní sobre altercado en vía pública ha pasado a estado RESUELTO.',
    type: 'INCIDENT_RESOLVED',
    relatedEntityId: 'inc-get-001',
    relatedEntityType: 'Incident',
    read: false,
    createdAt: daysAgo(2, 10),
    _class: 'Com.Backend.CartagenaSegura.Model.Notification'
  },
  {
    userId: 'juan123',
    title: 'Operativo en curso',
    message: 'La patrulla de vigilancia atendió el reporte de intento de fleteo en La Plazuela.',
    type: 'INCIDENT_UPDATED',
    relatedEntityId: 'inc-plz-001',
    relatedEntityType: 'Incident',
    read: false,
    createdAt: daysAgo(1, 14),
    _class: 'Com.Backend.CartagenaSegura.Model.Notification'
  },
  {
    userId: 'juan123',
    title: 'Alerta Preventiva de Tráfico',
    message: 'Congestión alta en sector Bazurto sobre Av. Pedro de Heredia por vehículo varado.',
    type: 'ZONE_ALERT',
    relatedEntityId: 'zone_bazurto',
    relatedEntityType: 'Zone',
    read: false,
    createdAt: daysAgo(0, 1),
    _class: 'Com.Backend.CartagenaSegura.Model.Notification'
  },
  {
    userId: 'admin',
    title: 'Alerta Operativa de Cuadrante',
    message: 'Incidente de prioridad CRÍTICA registrado en La Plazuela. Se requiere despacho de refuerzo.',
    type: 'ZONE_ALERT',
    relatedEntityId: 'inc-plz-001',
    relatedEntityType: 'Incident',
    read: false,
    createdAt: daysAgo(1, 14),
    _class: 'Com.Backend.CartagenaSegura.Model.Notification'
  },
  {
    userId: 'admin',
    title: 'Monitoreo de Zonas',
    message: 'Nivel de riesgo actualizado en sector Olaya Herrera tras intervenciones comunitarias.',
    type: 'ZONE_ALERT',
    relatedEntityId: 'zone_olaya_herrera',
    relatedEntityType: 'Zone',
    read: false,
    createdAt: daysAgo(0, 10),
    _class: 'Com.Backend.CartagenaSegura.Model.Notification'
  },
  {
    userId: 'admin',
    title: 'Mantenimiento del Sistema',
    message: 'Copia de seguridad y sincronización con Distriseguridad completada exitosamente.',
    type: 'SYSTEM',
    relatedEntityId: null,
    relatedEntityType: null,
    read: true,
    createdAt: daysAgo(2),
    _class: 'Com.Backend.CartagenaSegura.Model.Notification'
  },
  {
    userId: 'testdeploy',
    title: 'Reporte Atendido',
    message: 'El accidente reportado en Bocagrande (Av. San Martín) ha sido atendido por Tránsito.',
    type: 'INCIDENT_RESOLVED',
    relatedEntityId: 'inc-bg-001',
    relatedEntityType: 'Incident',
    read: true,
    createdAt: daysAgo(4, 3),
    _class: 'Com.Backend.CartagenaSegura.Model.Notification'
  },
  {
    userId: 'ciudadano_maria',
    title: 'Caso Resuelto',
    message: 'Tu reporte de hurto en la Plaza de los Coches fue resuelto exitosamente por el cuadrante 4.',
    type: 'INCIDENT_RESOLVED',
    relatedEntityId: 'inc-ch-001',
    relatedEntityType: 'Incident',
    read: false,
    createdAt: daysAgo(2, 6),
    _class: 'Com.Backend.CartagenaSegura.Model.Notification'
  }
];

db.notifications.deleteMany({});
db.notifications.insertMany(notificationsData);
print(`✓ Notificaciones insertadas: ${notificationsData.length}`);

print('=== ¡Datos ficticios cargados exitosamente en MongoDB! ===');
