import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/session_controller.dart';

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: '/api'),
  ),
);

final sessionProvider = ChangeNotifierProvider<SessionController>((ref) {
  final session = SessionController(
    api: ref.watch(apiClientProvider),
    storage: const SecureSessionStorage(FlutterSecureStorage()),
  );
  unawaited(session.initialize());
  return session;
});
