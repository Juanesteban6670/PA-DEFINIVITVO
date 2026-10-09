import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/api_client.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({required this.api, this.onReportSubmitted, super.key});

  final ApiClient api;
  final VoidCallback? onReportSubmitted;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _location = TextEditingController();
  String _type = 'ROBO';
  String _priority = 'MEDIUM';
  Position? _position;
  bool _locating = false;
  bool _sending = false;

  @override
  void dispose() {
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const ApiException(
          'Activa los servicios de ubicación del teléfono',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const ApiException(
          'Se requiere permiso de ubicación para usar el GPS',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        throw const ApiException(
          'El permiso de ubicación está bloqueado. Actívalo desde los ajustes del teléfono',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() => _position = position);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ubicación actualizada')));
    } on ApiException catch (error) {
      _showMessage(error.message);
    } on Exception catch (error) {
      _showMessage('No se pudo obtener la ubicación: $error');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await widget.api.post('Incidents', {
        'type': _type,
        'description': _description.text.trim(),
        'location': _location.text.trim(),
        'latitude': _position?.latitude,
        'longitude': _position?.longitude,
        'priority': _priority,
        'imageUrls': <String>[],
      });
      if (!mounted) return;
      widget.onReportSubmitted?.call();
      _description.clear();
      _location.clear();
      setState(() => _position = null);
      _showMessage('Tu reporte fue enviado a Cartagena Segura');
    } on ApiException catch (error) {
      _showMessage(error.message);
    } on Exception catch (error) {
      _showMessage('No se pudo enviar el reporte: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Reportar un incidente',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Describe la situación para que pueda ser atendida.'),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo de incidente',
                ),
                items: const [
                  DropdownMenuItem(value: 'ROBO', child: Text('Robo')),
                  DropdownMenuItem(
                    value: 'ACCIDENTE',
                    child: Text('Accidente'),
                  ),
                  DropdownMenuItem(value: 'PELEA', child: Text('Pelea')),
                  DropdownMenuItem(value: 'INCENDIO', child: Text('Incendio')),
                  DropdownMenuItem(
                    value: 'EMERGENCIA',
                    child: Text('Emergencia'),
                  ),
                  DropdownMenuItem(value: 'OTRO', child: Text('Otro')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: '¿Qué ocurrió?',
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Describe brevemente el incidente'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(
                  labelText: 'Dirección o referencia',
                  hintText: 'Barrio, calle o punto de referencia',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Indica dónde ocurrió'
                    : null,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _locating ? null : _getCurrentLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  _position == null
                      ? 'Añadir ubicación GPS'
                      : 'GPS: ${_position!.latitude.toStringAsFixed(5)}, '
                            '${_position!.longitude.toStringAsFixed(5)}',
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Prioridad'),
                items: const [
                  DropdownMenuItem(value: 'LOW', child: Text('Baja')),
                  DropdownMenuItem(value: 'MEDIUM', child: Text('Media')),
                  DropdownMenuItem(value: 'HIGH', child: Text('Alta')),
                  DropdownMenuItem(value: 'CRITICAL', child: Text('Crítica')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _priority = value);
                },
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _sending ? null : _submit,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(_sending ? 'Enviando…' : 'Enviar reporte'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
