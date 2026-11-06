import 'dart:convert';
import 'dart:io';

import 'api_client.dart';
import 'session_controller.dart';

class ReportDraft {
  const ReportDraft({
    required this.type,
    required this.description,
    required this.location,
    required this.priority,
    required this.idempotencyKey,
    this.latitude,
    this.longitude,
    this.photoPaths = const [],
    this.uploadedImageUrls = const [],
  });

  final String type;
  final String description;
  final String location;
  final String priority;
  final String idempotencyKey;
  final double? latitude;
  final double? longitude;
  final List<String> photoPaths;
  final List<String> uploadedImageUrls;

  ReportDraft copyWith({List<String>? uploadedImageUrls}) => ReportDraft(
    type: type,
    description: description,
    location: location,
    priority: priority,
    idempotencyKey: idempotencyKey,
    latitude: latitude,
    longitude: longitude,
    photoPaths: photoPaths,
    uploadedImageUrls: uploadedImageUrls ?? this.uploadedImageUrls,
  );

  factory ReportDraft.fromJson(Map<String, dynamic> json) => ReportDraft(
    type: json['type']?.toString() ?? 'ROBO',
    description: json['description']?.toString() ?? '',
    location: json['location']?.toString() ?? '',
    priority: json['priority']?.toString() ?? 'MEDIUM',
    idempotencyKey: json['idempotencyKey']?.toString() ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    photoPaths:
        (json['photoPaths'] as List?)?.whereType<String>().toList() ?? const [],
    uploadedImageUrls:
        (json['uploadedImageUrls'] as List?)?.whereType<String>().toList() ??
        const [],
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'description': description,
    'location': location,
    'priority': priority,
    'idempotencyKey': idempotencyKey,
    'latitude': latitude,
    'longitude': longitude,
    'photoPaths': photoPaths,
    'uploadedImageUrls': uploadedImageUrls,
  };

  Map<String, dynamic> toRequest(List<String> imageUrls) => {
    'type': type,
    'description': description,
    'location': location,
    'latitude': latitude,
    'longitude': longitude,
    'priority': priority,
    'imageUrls': imageUrls,
    'idempotencyKey': idempotencyKey,
  };
}

class ReportDraftStore {
  const ReportDraftStore({required this.storage, required this.owner});

  final SessionStorage storage;
  final String owner;

  String get _draftKey => 'report.draft.$owner';
  String get _queueKey => 'report.outbox.$owner';

  Future<ReportDraft?> readDraft() async {
    final json = await storage.read(_draftKey);
    if (json == null) return null;
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El borrador guardado no es válido');
    }
    return ReportDraft.fromJson(decoded);
  }

  Future<void> saveDraft(ReportDraft draft) =>
      storage.write(_draftKey, jsonEncode(draft.toJson()));

  Future<void> clearDraft() => storage.delete(_draftKey);

  Future<List<ReportDraft>> readPending() async {
    final json = await storage.read(_queueKey);
    if (json == null) return const [];
    final decoded = jsonDecode(json);
    if (decoded is! List) {
      throw const FormatException('La cola de reportes guardada no es válida');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ReportDraft.fromJson)
        .toList(growable: false);
  }

  Future<void> enqueue(ReportDraft draft) async {
    final pending = await readPending();
    if (pending.any((item) => item.idempotencyKey == draft.idempotencyKey)) {
      return;
    }
    await storage.write(
      _queueKey,
      jsonEncode([...pending, draft].map((item) => item.toJson()).toList()),
    );
  }

  Future<void> removePending(String idempotencyKey) async {
    final pending = await readPending();
    await storage.write(
      _queueKey,
      jsonEncode(
        pending
            .where((item) => item.idempotencyKey != idempotencyKey)
            .map((item) => item.toJson())
            .toList(),
      ),
    );
  }

  Future<void> updatePending(ReportDraft updated) async {
    final pending = await readPending();
    await storage.write(
      _queueKey,
      jsonEncode(
        pending
            .map(
              (item) => item.idempotencyKey == updated.idempotencyKey
                  ? updated
                  : item,
            )
            .map((item) => item.toJson())
            .toList(),
      ),
    );
  }

  Future<void> clearAll() async {
    await clearDraft();
    await storage.delete(_queueKey);
  }
}

Future<void> submitReportDraft(
  ApiClient api,
  ReportDraft draft, {
  required Future<void> Function(ReportDraft updated) onImagesUploaded,
}) async {
  var imageUrls = draft.uploadedImageUrls;
  if (draft.photoPaths.isNotEmpty &&
      imageUrls.length != draft.photoPaths.length) {
    final files = <UploadFile>[];
    for (final path in draft.photoPaths) {
      final file = File(path);
      if (!await file.exists()) {
        throw const ApiException(
          'Falta una fotografía adjunta del borrador. Elimina el envío pendiente o vuelve a crear el reporte.',
        );
      }
      final name = path.split(Platform.pathSeparator).last;
      final extension = name.split('.').last.toLowerCase();
      final contentType = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => throw ApiException('Formato de imagen no permitido: .$extension'),
      };
      files.add(UploadFile(path: path, name: name, contentType: contentType));
    }
    final response = await api.uploadFiles(files);
    if (response is! Map<String, dynamic> || response['urls'] is! List) {
      throw const FormatException('La API devolvió URLs de archivos inválidas');
    }
    imageUrls = (response['urls'] as List).whereType<String>().toList();
    if (imageUrls.length != files.length) {
      throw const FormatException(
        'La API no confirmó la carga de todas las fotografías',
      );
    }
    await onImagesUploaded(draft.copyWith(uploadedImageUrls: imageUrls));
  }
  await api.post('Incidents', draft.toRequest(imageUrls));
}

Future<void> deleteReportPhotos(Iterable<String> paths) async {
  for (final path in paths) {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
