import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cartagena_segura/core/data/session_controller.dart';
import 'package:cartagena_segura/features/admin/presentation/admin_shell.dart';
import 'package:cartagena_segura/features/auth/presentation/password_recovery_screen.dart';
import 'package:cartagena_segura/features/auth/presentation/sign_in_screen.dart';
import 'package:cartagena_segura/features/citizen/presentation/home_shell.dart';
import 'package:cartagena_segura/features/citizen/presentation/notifications_screen.dart';
import 'package:cartagena_segura/features/landing/presentation/landing_screen.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.read(sessionProvider);
  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: session,
    redirect: (context, state) => _redirect(session, state.matchedLocation),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LandingScreen()),
      GoRoute(
        path: '/Login',
        builder: (context, state) => SignInScreen(session: session),
      ),
      GoRoute(
        path: '/Register',
        builder: (context, state) =>
            SignInScreen(session: session, initialRegistering: true),
      ),
      GoRoute(
        path: '/ForgotPassword',
        builder: (context, state) => PasswordRecoveryScreen(session: session),
      ),
      GoRoute(
        path: '/ResetPassword',
        builder: (context, state) => PasswordRecoveryScreen(
          session: session,
          initialResetting: true,
          initialToken: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      GoRoute(
        path: '/App',
        builder: (context, state) => HomeShell(session: session),
      ),
      GoRoute(
        path: '/App/Incidents',
        builder: (context, state) => HomeShell(
          session: session,
          initialIndex: 1,
          initialIncidentId: state.uri.queryParameters['id'],
        ),
      ),
      GoRoute(
        path: '/App/Map',
        builder: (context, state) =>
            HomeShell(session: session, initialIndex: 2),
      ),
      GoRoute(
        path: '/App/Emergency',
        builder: (context, state) =>
            HomeShell(session: session, initialIndex: 3),
      ),
      GoRoute(
        path: '/App/Analytics',
        builder: (context, state) =>
            HomeShell(session: session, initialIndex: 1),
      ),
      GoRoute(
        path: '/App/Profile',
        builder: (context, state) =>
            HomeShell(session: session, initialIndex: 4),
      ),
      GoRoute(
        path: '/App/Notifications',
        builder: (context, state) => NotificationsScreen(
          api: session.api,
          isAdmin: session.user?.isAdmin ?? false,
        ),
      ),
      GoRoute(
        path: '/Admin',
        builder: (context, state) =>
            AdminShell(session: session, location: state.matchedLocation),
      ),
      for (final section in const [
        'Incidents',
        'Zones',
        'Logs',
        'Emergency',
        'Reports',
        'Ai',
      ])
        GoRoute(
          path: '/Admin/$section',
          builder: (context, state) => AdminShell(
            session: session,
            location: state.matchedLocation,
            initialIncidentId: state.uri.queryParameters['id'],
          ),
        ),
    ],
    errorBuilder: (context, state) => const LandingScreen(),
  );
  ref.onDispose(router.dispose);
  return router;
});

String? _redirect(SessionController session, String location) {
  if (!session.initialized) return null;
  final user = session.user;
  final isProtected =
      location.startsWith('/App') || location.startsWith('/Admin');
  if (user == null && isProtected) {
    return Uri(path: '/Login', queryParameters: {'from': location}).toString();
  }
  if (user != null && (location == '/Login' || location == '/Register')) {
    return user.isAdmin ? '/Admin' : '/App';
  }
  if (user != null && location.startsWith('/Admin') && !user.isAdmin) {
    return '/App';
  }
  return null;
}
