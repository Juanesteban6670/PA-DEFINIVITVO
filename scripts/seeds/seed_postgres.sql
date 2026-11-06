-- =============================================================================
-- Cartagena Segura - Semilla de Datos PostgreSQL
-- Inserta roles, usuarios de prueba con contraseñas seguras y contactos de emergencia.
-- Contraseña de usuarios de prueba: Password123* (hash BCrypt estándar)
-- =============================================================================

-- 1. ROLES
INSERT INTO roles (id, name, description)
VALUES 
    (1, 'ADMIN', 'Administrador del sistema con acceso total'),
    (2, 'OFFICER', 'Oficial de policía y operador de cuadrante'),
    (5, 'USER', 'Ciudadano estándar de Cartagena')
ON CONFLICT (name) DO UPDATE 
SET description = EXCLUDED.description;

-- Sincronizar secuencia de roles
SELECT setval(pg_get_serial_sequence('roles', 'id'), COALESCE(MAX(id), 1)) FROM roles;

-- 2. USUARIOS
-- Hash BCrypt para 'Password123!': $2a$10$hdsIPyfub2eCquZ19Jx/qeaZiGtMCT8aTRYRXKKNPF/6pQ7hKJ572
INSERT INTO users (username, password, email, full_name, phone, enabled, account_non_locked, created_at)
VALUES 
    ('admin', '$2a$10$hdsIPyfub2eCquZ19Jx/qeaZiGtMCT8aTRYRXKKNPF/6pQ7hKJ572', 'admin@cartagenasegura.gov.co', 'Comisario Distrital de Cartagena', '3001234567', true, true, NOW()),
    ('oficial_cuadrante4', '$2a$10$hdsIPyfub2eCquZ19Jx/qeaZiGtMCT8aTRYRXKKNPF/6pQ7hKJ572', 'cuadrante4@policia.gov.co', 'Subteniente Carlos Mendoza (Cuadrante 4)', '3102427891', true, true, NOW()),
    ('ciudadano_maria', '$2a$10$hdsIPyfub2eCquZ19Jx/qeaZiGtMCT8aTRYRXKKNPF/6pQ7hKJ572', 'maria.castillo@gmail.com', 'María Fernanda Castillo', '3157890123', true, true, NOW()),
    ('ciudadano_camilo', '$2a$10$hdsIPyfub2eCquZ19Jx/qeaZiGtMCT8aTRYRXKKNPF/6pQ7hKJ572', 'camilo.torres@hotmail.com', 'Camilo Andrés Torres', '3184561234', true, true, NOW())
ON CONFLICT (username) DO NOTHING;

-- 3. ASIGNACIÓN DE ROLES (user_roles)
-- Otorgar rol ADMIN al usuario 'juan123' y 'testdeploy' para pruebas completas
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u, roles r 
WHERE u.username IN ('juan123', 'testdeploy', 'admin') AND r.name = 'ADMIN'
ON CONFLICT DO NOTHING;

-- Otorgar rol USER a todos los usuarios
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u, roles r 
WHERE r.name = 'USER'
ON CONFLICT DO NOTHING;

-- Otorgar rol OFFICER a 'oficial_cuadrante4'
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u, roles r 
WHERE u.username = 'oficial_cuadrante4' AND r.name = 'OFFICER'
ON CONFLICT DO NOTHING;

-- 4. CONTACTOS Y LÍNEAS DE EMERGENCIA DE CARTAGENA
-- Type enum: 0: POLICE, 1: FIRE_STATION, 2: CIVIL_DEFENSE, 3: HOSPITAL, 4: AMBULANCE, 5: COAST_GUARD, 6: MUNICIPALITY, 7: OTHER
DELETE FROM emergency_contacts;

INSERT INTO emergency_contacts (name, phone, alternative_phone, type, zone, address, notes, active)
VALUES
    ('CAI San Diego - Centro Histórico', '123', '3102427892', 0, 'Centro Histórico', 'Plaza de San Diego, Murallas de Cartagena', 'Atención 24/7 zona amurallada y sector turístico', true),
    ('CAI Bocagrande - Policía de Turismo', '018000910600', '3102427891', 0, 'Bocagrande', 'Cra. 2 con Calle 10, Bocagrande', 'Patrullaje especializado hotelero, playas y sector gastronómico', true),
    ('Estación de Policía Manga', '(605) 660-1234', '3102427893', 0, 'Manga', 'Calle 28 #21-45, Manga', 'Cuadrante Manga, Pie de la Popa y Barrio Chino', true),
    ('Estación de Policía La Candelaria', '(605) 669-1122', '3102427894', 0, 'Olaya Herrera', 'Av. Pedro Romero, Sector La Candelaria', 'Atención inmediata zona suroriental y barrios periféricos', true),
    ('Fiscalía General de la Nación - URI Crespo', '122', '(605) 656-9100', 0, 'Crespo', 'Calle 70 con Carrera 3, Crespo', 'Unidad de Reacción Inmediata para radicación de denuncias penales', true),
    ('Policía de Infancia y Adolescencia', '141', '(605) 656-1199', 0, 'Cartagena', 'Sector Pie del Cerro', 'Protección integral y respuesta para menores de edad', true),
    ('Cuerpo de Bomberos - Estación Santa Lucía', '119', '(605) 663-1282', 1, 'Santa Lucía', 'Transversal 54 #31-89, Av. El Bosque', 'Estación central de bomberos para incendios y rescate', true),
    ('Cuerpo de Bomberos - Subestación Bocagrande', '119', '(605) 665-5119', 1, 'Bocagrande', 'Cra. 3 #7-20, Bocagrande', 'Respuesta rápida en rascacielos y sector hotelero', true),
    ('Defensa Civil Colombiana - Seccional Bolívar', '144', '(605) 669-4210', 2, 'Cartagena', 'Barrio Amberes Calle 30 #38-12', 'Atención ante emergencias climáticas, vendavales e inundaciones', true),
    ('Cruz Roja Colombiana - Seccional Bolívar', '132', '(605) 662-5487', 2, 'Manga', 'Calle Real de Manga #24-110', 'Atención prehospitalaria, banco de sangre y socorro', true),
    ('Hospital Universitario del Caribe (HUC)', '(605) 672-4340', '(605) 672-4341', 3, 'Zaragocilla', 'Calle 29 #50-50, Zaragocilla', 'Hospital público de alta complejidad nivel III y IV', true),
    ('Clínica MediHelp Services', '(605) 654-0000', '3164821035', 3, 'Castillogrande', 'Cra. 6 #5-101, Castillogrande', 'Urgencias médicas las 24 horas y atención bilingüe', true),
    ('Centro Regulador de Urgencias y Emergencias (CRUE - Ambulancias)', '125', '(605) 664-5612', 4, 'Cartagena', 'Calle San Agustín #36-40, Centro', 'Despacho y coordinación central de ambulancias públicas y privadas', true),
    ('Estación de Guardacostas - Armada Nacional', '146', '(605) 655-0211', 5, 'Bahía de Cartagena', 'Base Naval ARC Bolívar, Bocagrande', 'Rescate marítimo, seguridad en bahía y playas insulares (Tierrabomba/Barú)', true),
    ('Distriseguridad - Centro de Monitoreo', '123', '(605) 641-1370', 6, 'Cartagena', 'Centro Empresarial Ronda Real, Piso 4', 'Línea unificada distrital y monitoreo con cámaras de videovigilancia', true),
    ('Línea Púrpura - Atención a la Mujer', '155', '018000112137', 6, 'Cartagena', 'Edificio Banco Agrario, Centro', 'Línea de orientación psicológica y jurídica ante violencia de género', true);
