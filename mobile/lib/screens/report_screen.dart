import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/location_service.dart';
import '../data/api_client.dart';
import '../data/report_draft_store.dart';
import '../theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({
    required this.api,
    required this.drafts,
    this.onReportSubmitted,
    super.key,
  });

  final ApiClient api;
  final ReportDraftStore drafts;
  final VoidCallback? onReportSubmitted;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _picker = ImagePicker();
  String _type = 'ROBO';
  String _priority = 'MEDIUM';
  String _idempotencyKey = const Uuid().v4();
  final List<String> _photoPaths = [];
  List<String> _uploadedImageUrls = const [];
  double? _latitude;
  double? _longitude;
  bool _locating = false;
  bool _sending = false;
  bool _draftRestored = false;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

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
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      await _saveDraft();
      if (!mounted) return;
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
      await submitReportDraft(
        widget.api,
        _currentDraft(),
        onImagesUploaded: (updated) async {
          if (mounted) {
            setState(() => _uploadedImageUrls = updated.uploadedImageUrls);
          }
          await widget.drafts.saveDraft(updated);
        },
      );
      if (!mounted) return;
      widget.onReportSubmitted?.call();
      final submittedPhotos = List.of(_photoPaths);
      _description.clear();
      _location.clear();
      setState(() {
        _photoPaths.clear();
        _uploadedImageUrls = const [];
        _latitude = null;
        _longitude = null;
        _idempotencyKey = const Uuid().v4();
      });
      try {
        await deleteReportPhotos(submittedPhotos);
        await widget.drafts.clearDraft();
      } on Exception catch (error) {
        _showMessage(
          'El servidor confirmó el reporte, pero no se pudo limpiar el borrador local: $error',
        );
      }
      _showMessage('Tu reporte fue enviado a Cartagena Segura');
    } on ApiException catch (error) {
      _showMessage(error.message);
    } on Exception catch (error) {
      _showMessage('No se pudo enviar el reporte: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  ReportDraft _currentDraft() => ReportDraft(
    type: _type,
    description: _description.text.trim(),
    location: _location.text.trim(),
    priority: _priority,
    idempotencyKey: _idempotencyKey,
    latitude: _latitude,
    longitude: _longitude,
    photoPaths: List.of(_photoPaths),
    uploadedImageUrls: _uploadedImageUrls,
  );

  Future<void> _restoreDraft() async {
    try {
      final draft = await widget.drafts.readDraft();
      if (!mounted) return;
      if (draft != null) {
        setState(() {
          _type = draft.type;
          _priority = draft.priority;
          _idempotencyKey = draft.idempotencyKey.isEmpty
              ? const Uuid().v4()
              : draft.idempotencyKey;
          _description.text = draft.description;
          _location.text = draft.location;
          _latitude = draft.latitude;
          _longitude = draft.longitude;
          _uploadedImageUrls = draft.uploadedImageUrls;
          _photoPaths
            ..clear()
            ..addAll(draft.photoPaths.where((path) => File(path).existsSync()));
        });
      }
    } on Exception catch (error) {
      if (mounted) _showMessage('No se pudo restaurar el borrador: $error');
    } finally {
      _draftRestored = true;
    }
  }

  Future<void> _saveDraft() async {
    if (!_draftRestored) return;
    try {
      await widget.drafts.saveDraft(_currentDraft());
    } on Exception catch (error) {
      _showMessage('No se pudo guardar el borrador local: $error');
    }
  }

  Future<void> _saveForLater() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final draft = _currentDraft();
      await widget.drafts.enqueue(draft);
      await widget.drafts.clearDraft();
      widget.onReportSubmitted?.call();
      if (!mounted) return;
      _description.clear();
      _location.clear();
      setState(() {
        _photoPaths.clear();
        _uploadedImageUrls = const [];
        _latitude = null;
        _longitude = null;
        _idempotencyKey = const Uuid().v4();
      });
      _showMessage('Guardado en el dispositivo para enviarlo después');
      Navigator.of(context).pop();
    } on Exception catch (error) {
      _showMessage('No se pudo guardar el envío pendiente: $error');
    }
  }

  Future<void> _pickPhotos(ImageSource source) async {
    final createdPaths = <String>[];
    try {
      final List<XFile> picked;
      if (source == ImageSource.gallery) {
        picked = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 1920);
      } else {
        final photo = await _picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1920,
        );
        picked = photo == null ? const [] : [photo];
      }
      final available = 5 - _photoPaths.length;
      if (available <= 0) {
        _showMessage('Puedes adjuntar hasta 5 fotografías');
        return;
      }
      final directory = await getApplicationDocumentsDirectory();
      final targetDirectory = Directory(
        '${directory.path}/report_evidence/${Uri.encodeComponent(widget.drafts.owner)}',
      );
      await targetDirectory.create(recursive: true);
      final added = <String>[];
      for (final image in picked.take(available)) {
        final contentType = image.mimeType?.toLowerCase();
        if (!const {
          'image/jpeg',
          'image/png',
          'image/webp',
        }.contains(contentType)) {
          _showMessage('Solo se aceptan fotografías JPEG, PNG o WebP');
          continue;
        }
        final bytes = await image.readAsBytes();
        if (bytes.length > 10 * 1024 * 1024) {
          _showMessage('${image.name} supera el límite de 10 MB');
          continue;
        }
        final extension = switch (contentType) {
          'image/jpeg' => 'jpg',
          'image/png' => 'png',
          _ => 'webp',
        };
        final target = File(
          '${targetDirectory.path}/${const Uuid().v4()}.$extension',
        );
        await target.writeAsBytes(bytes, flush: true);
        added.add(target.path);
        createdPaths.add(target.path);
      }
      if (!mounted) {
        await deleteReportPhotos(createdPaths);
        return;
      }
      setState(() {
        _photoPaths.addAll(added);
        if (added.isNotEmpty) _uploadedImageUrls = const [];
      });
      await _saveDraft();
    } on PlatformException catch (error) {
      try {
        await deleteReportPhotos(createdPaths);
      } on Exception catch (cleanupError) {
        if (mounted) {
          _showMessage(
            'No se pudo acceder a las fotos ($error) ni limpiar los archivos temporales ($cleanupError)',
          );
        }
        return;
      }
      if (mounted) {
        _showMessage(
          'No se concedió el permiso para acceder a la cámara o las fotos. Puedes elegir otra fuente o habilitar el permiso en los ajustes: ${error.message ?? error.code}',
        );
      }
    } on Exception catch (error) {
      try {
        await deleteReportPhotos(createdPaths);
      } on Exception catch (cleanupError) {
        if (mounted) {
          _showMessage(
            'No se pudieron adjuntar las fotografías ($error) ni limpiar los archivos temporales ($cleanupError)',
          );
        }
        return;
      }
      if (mounted) {
        _showMessage('No se pudieron adjuntar las fotografías: $error');
      }
    }
  }

  Future<void> _removePhoto(String path) async {
    try {
      await deleteReportPhotos([path]);
    } on Exception catch (error) {
      _showMessage('No se pudo quitar la fotografía: $error');
      return;
    }
    setState(() {
      _photoPaths.remove(path);
      _uploadedImageUrls = const [];
    });
    await _saveDraft();
  }

  Future<void> _deleteDraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar borrador'),
        content: const Text(
          'Se eliminarán los datos y las fotografías de este borrador del dispositivo. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await deleteReportPhotos(_photoPaths);
      await widget.drafts.clearDraft();
      if (!mounted) return;
      _description.clear();
      _location.clear();
      setState(() {
        _type = 'ROBO';
        _priority = 'MEDIUM';
        _photoPaths.clear();
        _uploadedImageUrls = const [];
        _latitude = null;
        _longitude = null;
        _idempotencyKey = const Uuid().v4();
      });
      _showMessage('Borrador eliminado del dispositivo');
    } on Exception catch (error) {
      _showMessage('No se pudo borrar el borrador: $error');
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
      appBar: AppBar(
        title: const Text('Nuevo reporte'),
        actions: [
          IconButton(
            tooltip: 'Borrar borrador',
            onPressed: _sending ? null : _deleteDraft,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
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
                            if (value != null) {
                              setState(() => _type = value);
                              _saveDraft();
                            }
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
                          onChanged: (_) => _saveDraft(),
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
                          onChanged: (_) => _saveDraft(),
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
                            _latitude == null || _longitude == null
                                ? 'Añadir ubicación GPS'
                                : 'GPS: ${_latitude!.toStringAsFixed(5)}, '
                                      '${_longitude!.toStringAsFixed(5)}',
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
                              _saveDraft();
                            }
                          },
                        ),
                        const SizedBox(height: 22),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: () => _pickPhotos(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Elegir fotos'),
                            ),
                            TextButton.icon(
                              onPressed: () => _pickPhotos(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: const Text('Tomar foto'),
                            ),
                            Center(
                              child: Text(
                                '${_photoPaths.length}/5',
                                style: const TextStyle(color: AppColors.muted),
                              ),
                            ),
                          ],
                        ),
                        if (_photoPaths.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final path in _photoPaths)
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        File(path),
                                        width: 76,
                                        height: 76,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            const SizedBox(
                                              width: 76,
                                              height: 76,
                                              child: Icon(
                                                Icons.broken_image_outlined,
                                              ),
                                            ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: IconButton(
                                        tooltip: 'Quitar fotografía',
                                        onPressed: () => _removePhoto(path),
                                        icon: const Icon(
                                          Icons.cancel,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        const SizedBox(height: 14),
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
                        TextButton.icon(
                          onPressed: _sending ? null : _saveForLater,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Guardar para enviar después'),
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
