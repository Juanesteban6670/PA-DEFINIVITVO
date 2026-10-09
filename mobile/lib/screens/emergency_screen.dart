import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/api_client.dart';
import '../data/models.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({required this.api, super.key});

  final ApiClient api;

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  late Future<List<EmergencyContact>> _contacts;

  @override
  void initState() {
    super.initState();
    _contacts = _loadContacts();
  }

  Future<List<EmergencyContact>> _loadContacts() async {
    final response = await widget.api.get('EmergencyContacts');
    if (response is! List) {
      throw const FormatException(
        'La API devolvió una lista de contactos inválida',
      );
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(EmergencyContact.fromJson)
        .toList();
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      if (!await launchUrl(uri)) {
        throw Exception('El dispositivo no pudo iniciar la llamada');
      }
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EmergencyContact>>(
      future: _contacts,
      builder: (context, snapshot) {
        final contacts = snapshot.data ?? const <EmergencyContact>[];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              color: const Color(0xFFFEF3F2),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '¿Necesitas ayuda inmediata?',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text('Línea nacional de emergencias de Colombia'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB42318),
                      ),
                      onPressed: () => _call('123'),
                      icon: const Icon(Icons.call),
                      label: const Text('Llamar al 123'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Contactos disponibles',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (snapshot.hasError)
              _ContactsError(
                message: snapshot.error.toString(),
                onRetry: () => setState(() => _contacts = _loadContacts()),
              )
            else if (contacts.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Todavía no hay contactos publicados.'),
                ),
              )
            else
              ...contacts.map(
                (contact) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.local_police_outlined),
                    ),
                    title: Text(contact.name),
                    subtitle: Text(
                      [
                        _typeLabel(contact.type),
                        if (contact.address.isNotEmpty) contact.address,
                        if (contact.notes.isNotEmpty) contact.notes,
                      ].join(' · '),
                    ),
                    trailing: IconButton(
                      tooltip: 'Llamar ${contact.phone}',
                      onPressed: contact.phone.isEmpty
                          ? null
                          : () => _call(contact.phone),
                      icon: const Icon(Icons.call),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _typeLabel(String type) => switch (type) {
    'POLICE' => 'Policía',
    'FIRE_STATION' => 'Bomberos',
    'CIVIL_DEFENSE' => 'Defensa Civil',
    'HOSPITAL' => 'Hospital',
    'AMBULANCE' => 'Ambulancia',
    'COAST_GUARD' => 'Guardia Costera',
    'MUNICIPALITY' => 'Alcaldía',
    _ => 'Otro servicio',
  };
}

class _ContactsError extends StatelessWidget {
  const _ContactsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('No se pudieron cargar los contactos'),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}
