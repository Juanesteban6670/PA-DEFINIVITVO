import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'data/api_client.dart';
import 'data/session_controller.dart';
import 'screens/home_shell.dart';
import 'screens/sign_in_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CartagenaApp());
}

class CartagenaApp extends StatefulWidget {
  const CartagenaApp({super.key});

  @override
  State<CartagenaApp> createState() => _CartagenaAppState();
}

class _CartagenaAppState extends State<CartagenaApp> {
  late final SessionController _session;

  @override
  void initState() {
    super.initState();
    _session = SessionController(
      api: ApiClient(baseUrl: const String.fromEnvironment('API_BASE_URL')),
      storage: const SecureSessionStorage(FlutterSecureStorage()),
    )..initialize();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cartagena Segura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF155EEF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: AnimatedBuilder(
        animation: _session,
        builder: (context, _) {
          if (!_session.initialized) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (_session.initializationError != null) {
            return _StartupError(message: _session.initializationError!);
          }
          if (_session.user == null) {
            return SignInScreen(session: _session);
          }
          return HomeShell(session: _session);
        },
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'No se pudo restaurar la sesión',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
