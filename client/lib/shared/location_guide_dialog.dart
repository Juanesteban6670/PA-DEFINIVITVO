import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:cartagena_segura/core/data/location_service.dart';

/// Muestra un modal previo (Permission Priming) explicando por qué se necesita la ubicación
/// antes de activar el pop-up irrevocable del navegador web.
Future<bool> showLocationPrimingDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on,
              color: Color(0xFF1D4ED8),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Ubicación GPS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cartagena Segura utiliza tu ubicación para situar los reportes en el mapa de la ciudad y conectar con los cuadrantes cercanos.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          SizedBox(height: 12),
          Text(
            'El navegador te solicitará autorización a continuación. Te sugerimos seleccionar "Permitir mientras se usa el sitio".',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Ingresar manual'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Continuar'),
        ),
      ],
    ),
  );

  return result ?? false;
}

/// Muestra instrucciones paso a paso para desbloquear la ubicación en navegadores móviles (Chrome / Safari),
/// evitando el error de intentar abrir los ajustes del sistema operativo desde la web.
Future<void> showLocationBlockedDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_off,
              color: Color(0xFFDC2626),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Ubicación bloqueada',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'El permiso de ubicación fue denegado en el navegador. Para reactivarlo, sigue estos pasos según tu teléfono:',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'En Android (Chrome):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '1. Toca el ícono de opciones/candado 🔒 junto a la URL arriba.\n'
                    '2. Toca "Permisos" > "Ubicación".\n'
                    '3. Cambia a "Permitir" y recarga la página.',
                    style: TextStyle(fontSize: 12, height: 1.35),
                  ),
                  Divider(height: 18),
                  Text(
                    'En iPhone / iPad (Safari):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '1. Toca el botón "aA" a la izquierda de la barra de direcciones.\n'
                    '2. Toca "Configuración del sitio web" > "Ubicación" > "Permitir".\n'
                    '3. Recarga la página.',
                    style: TextStyle(fontSize: 12, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'También puedes continuar escribiendo la dirección o barrio manualmente.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        if (!kIsWeb)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              LocationService.openSettings(LocationSettingsTarget.app);
            },
            child: const Text('Abrir ajustes del teléfono'),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}
