import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/report_draft_store.dart';
import 'package:cartagena_segura/core/data/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ReportDraftStore', () {
    test('keeps drafts and pending reports private to their owner', () async {
      final storage = _MemorySessionStorage();
      final firstUser = ReportDraftStore(storage: storage, owner: 'citizen-a');
      final secondUser = ReportDraftStore(storage: storage, owner: 'citizen-b');
      const draft = ReportDraft(
        type: 'ROBO',
        description: 'Reporte',
        location: 'Centro',
        priority: 'HIGH',
        idempotencyKey: 'key-a',
      );

      await firstUser.saveDraft(draft);
      await firstUser.enqueue(draft);

      expect((await firstUser.readDraft())?.idempotencyKey, 'key-a');
      expect((await firstUser.readPending()).single.idempotencyKey, 'key-a');
      expect(await secondUser.readDraft(), isNull);
      expect(await secondUser.readPending(), isEmpty);
    });

    test(
      'prevents duplicate queued report keys and supports deletion',
      () async {
        final store = ReportDraftStore(
          storage: _MemorySessionStorage(),
          owner: 'citizen',
        );
        const draft = ReportDraft(
          type: 'ROBO',
          description: 'Reporte',
          location: 'Centro',
          priority: 'MEDIUM',
          idempotencyKey: 'same-key',
        );

        await store.enqueue(draft);
        await store.enqueue(draft);
        expect((await store.readPending()).length, 1);
        await store.removePending('same-key');
        expect(await store.readPending(), isEmpty);
      },
    );
  });

  test('reuses uploaded evidence URLs after a report request fails', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'report-draft-test-',
    );
    final image = File('${temporaryDirectory.path}/evidence.jpg');
    await image.writeAsBytes([0xFF, 0xD8, 0xFF]);
    var uploadCount = 0;
    var reportCount = 0;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/Files/Upload')) {
        uploadCount++;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'urls': ['https://files.test/evidence.jpg'],
            },
          }),
          200,
        );
      }

      reportCount++;
      if (reportCount == 1) {
        return http.Response(
          '{"success":false,"message":"Temporalmente no disponible"}',
          503,
        );
      }
      return http.Response('{"success":true,"data":{"id":"incident-1"}}', 200);
    });
    final api = ApiClient(
      baseUrl: 'https://api.example.test/api',
      client: client,
    );
    const original = ReportDraft(
      type: 'ROBO',
      description: 'Reporte',
      location: 'Centro',
      priority: 'HIGH',
      idempotencyKey: 'stable-key',
      photoPaths: [],
    );
    final draft = ReportDraft(
      type: original.type,
      description: original.description,
      location: original.location,
      priority: original.priority,
      idempotencyKey: original.idempotencyKey,
      photoPaths: [image.path],
    );
    var persistedDraft = draft;

    Future<void> persistUploaded(ReportDraft updated) async {
      persistedDraft = updated;
    }

    try {
      await expectLater(
        submitReportDraft(api, draft, onImagesUploaded: persistUploaded),
        throwsA(isA<ApiException>()),
      );
      await submitReportDraft(
        api,
        persistedDraft,
        onImagesUploaded: persistUploaded,
      );

      expect(uploadCount, 1);
      expect(reportCount, 2);
      expect(persistedDraft.uploadedImageUrls, [
        'https://files.test/evidence.jpg',
      ]);
    } finally {
      api.close();
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('uploads browser photo bytes without a filesystem path', () async {
    final uploadedBodies = <List<int>>[];
    final api = ApiClient(
      baseUrl: 'https://api.example.test/api',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/Files/Upload')) {
          uploadedBodies.add(request.bodyBytes);
          return http.Response(
            '{"success":true,"data":{"urls":["https://files.test/web.jpg"]}}',
            200,
          );
        }
        return http.Response(
          '{"success":true,"data":{"id":"incident-1"}}',
          200,
        );
      }),
    );
    const photoPath = 'web/evidence.jpg';
    const draft = ReportDraft(
      type: 'ROBO',
      description: 'Reporte',
      location: 'Centro',
      priority: 'HIGH',
      idempotencyKey: 'web-key',
      photoPaths: [photoPath],
    );
    final photoBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);
    var persistedDraft = draft;

    try {
      await submitReportDraft(
        api,
        draft,
        webPhotoBytes: {photoPath: photoBytes},
        onImagesUploaded: (updated) async => persistedDraft = updated,
      );

      expect(uploadedBodies, hasLength(1));
      expect(uploadedBodies.single, containsAll(photoBytes));
      expect(persistedDraft.uploadedImageUrls, ['https://files.test/web.jpg']);
    } finally {
      api.close();
    }
  });

  test(
    'uploads only new photos and preserves existing evidence URLs',
    () async {
      final uploadedBodies = <List<int>>[];
      Map<String, dynamic>? submitted;
      final api = ApiClient(
        baseUrl: 'https://api.example.test/api',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/Files/Upload')) {
            uploadedBodies.add(request.bodyBytes);
            return http.Response(
              '{"success":true,"data":{"urls":["https://files.test/new.jpg"]}}',
              200,
            );
          }
          submitted = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            '{"success":true,"data":{"id":"incident-1"}}',
            200,
          );
        }),
      );
      const oldPhotoPath = 'web/old.jpg';
      const newPhotoPath = 'web/new.jpg';
      const draft = ReportDraft(
        type: 'ROBO',
        description: 'Reporte',
        location: 'Centro',
        priority: 'HIGH',
        idempotencyKey: 'web-key',
        photoPaths: [oldPhotoPath, newPhotoPath],
        uploadedImageUrls: ['https://files.test/old.jpg'],
      );
      final newPhotoBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);
      var persistedDraft = draft;

      try {
        await submitReportDraft(
          api,
          draft,
          webPhotoBytes: {newPhotoPath: newPhotoBytes},
          onImagesUploaded: (updated) async => persistedDraft = updated,
        );

        expect(uploadedBodies, hasLength(1));
        expect(uploadedBodies.single, containsAll(newPhotoBytes));
        expect(persistedDraft.uploadedImageUrls, [
          'https://files.test/old.jpg',
          'https://files.test/new.jpg',
        ]);
        expect(submitted?['imageUrls'], [
          'https://files.test/old.jpg',
          'https://files.test/new.jpg',
        ]);
      } finally {
        api.close();
      }
    },
  );
}

class _MemorySessionStorage implements SessionStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
