import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/api_client.dart';
import '../data/location_service.dart';
import '../theme.dart';

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
      final position = await LocationService.currentPosition();
      if (!mounted) return;
      setState(() => _position = position);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ubicación actualizada')));
    } on LocationAccessException catch (error) {
      _showLocationError(error);
    } on Exception catch (error) {
      _showMessage(
        'No se pudo obtener la ubicación. Revisa la señal GPS e inténtalo de nuevo: $error',
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showLocationError(LocationAccessException error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message),
        duration: const Duration(seconds: 8),
        action: error.settingsTarget == null
            ? null
            : SnackBarAction(
                label: 'Abrir ajustes',
                onPressed: () async {
                  final opened = await LocationService.openSettings(
                    error.settingsTarget!,
                  );
                  if (!opened && mounted) {
                    _showMessage(
                      'No fue posible abrir los ajustes del sistema.',
                    );
                  }
                },
              ),
      ),
    );
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
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo reporte')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.navy,
                      AppColors.navyBlue,
                      AppColors.blue,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reportar un incidente',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Describe la situación para que pueda ser atendida.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
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
                            DropdownMenuItem(
                              value: 'ROBO',
                              child: Text('Robo'),
                            ),
                            DropdownMenuItem(
                              value: 'ACCIDENTE',
                              child: Text('Accidente'),
                            ),
                            DropdownMenuItem(
                              value: 'PELEA',
                              child: Text('Pelea'),
                            ),
                            DropdownMenuItem(
                              value: 'INCENDIO',
                              child: Text('Incendio'),
                            ),
                            DropdownMenuItem(
                              value: 'EMERGENCIA',
                              child: Text('Emergencia'),
                            ),
                            DropdownMenuItem(
                              value: 'OTRO',
                              child: Text('Otro'),
                            ),
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
                          validator: (value) =>
                              value == null || value.trim().isEmpty
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
                          validator: (value) =>
                              value == null || value.trim().isEmpty
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
                          decoration: const InputDecoration(
                            labelText: 'Prioridad',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'LOW', child: Text('Baja')),
                            DropdownMenuItem(
                              value: 'MEDIUM',
                              child: Text('Media'),
                            ),
                            DropdownMenuItem(
                              value: 'HIGH',
                              child: Text('Alta'),
                            ),
                            DropdownMenuItem(
                              value: 'CRITICAL',
                              child: Text('Crítica'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _priority = value);
                            }
                          },
                        ),
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: _sending ? null : _submit,
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_outlined),
                          label: Text(
                            _sending ? 'Enviando…' : 'Enviar reporte',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
