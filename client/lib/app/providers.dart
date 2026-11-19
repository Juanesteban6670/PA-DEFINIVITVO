import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/session_controller.dart';

const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

final apiClientProvider = Provider<ApiClient>(
  (ref) {
    final effectiveUrl = _envBaseUrl.isNotEmpty
        ? _envBaseUrl
        : (kIsWeb ? '/api' : 'https://pa-definivitvo.onrender.com/api');
    return ApiClient(baseUrl: effectiveUrl);
  },
);

final sessionProvider = ChangeNotifierProvider<SessionController>((ref) {
  final session = SessionController(
    api: ref.watch(apiClientProvider),
    storage: const SecureSessionStorage(FlutterSecureStorage()),
  );
  unawaited(session.initialize());
  return session;
});
