import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cartagena_segura/core/data/session_controller.dart';
import 'package:cartagena_segura/features/admin/presentation/admin_shell.dart';
import 'package:cartagena_segura/features/auth/presentation/password_recovery_screen.dart';
import 'package:cartagena_segura/features/auth/presentation/sign_in_screen.dart';
import 'package:cartagena_segura/features/citizen/presentation/all_reports_explorer_screen.dart';
import 'package:cartagena_segura/features/citizen/presentation/citizen_chat_screen.dart';
import 'package:cartagena_segura/features/citizen/presentation/home_shell.dart';
import 'package:cartagena_segura/features/citizen/presentation/notifications_screen.dart';
import 'package:cartagena_segura/features/landing/presentation/landing_screen.dart';

import 'providers.dart';

// Capture this before the temporary loading MaterialApp can change the URL.
final startupLocationProvider = Provider<String?>((ref) => null);

String? startupLocationFromUri(Uri uri) {
  final recovery = recoveryLocationFromUri(uri);
  if (recovery != null) return recovery;
  final hashRoute = Uri.tryParse(uri.fragment);
  final route =
      hashRoute != null &&
          !hashRoute.hasAuthority &&
          hashRoute.path.startsWith('/')
      ? hashRoute
      : uri;
  const publicPaths = {'/Login', '/Register', '/ForgotPassword', '/Chat'};
  if (!publicPaths.contains(route.path) && !_isProtected(route.path)) {
    return null;
  }
  return Uri(
    path: route.path,
    query: route.hasQuery ? route.query : null,
  ).toString();
}

String? recoveryLocationFromUri(Uri uri) {
  final hashRoute = uri.fragment.isEmpty ? null : Uri.tryParse(uri.fragment);
  final route = hashRoute?.path == '/ResetPassword' ? hashRoute! : uri;
  if (route.path != '/ResetPassword') return null;
  final token = route.queryParameters['token'];
  if (token == null || token.trim().isEmpty) return '/ForgotPassword';
  return Uri(
    path: '/ResetPassword',
    queryParameters: {'token': token},
  ).toString();
}

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.read(sessionProvider);
  final router = GoRouter(
    initialLocation: ref.read(startupLocationProvider) ?? '/',
    overridePlatformDefaultLocation: ref.read(startupLocationProvider) != null,
    refreshListenable: session,
    redirect: (context, state) => sessionRedirect(session, state.uri),
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
        path: '/Chat',
        builder: (context, state) => CitizenChatScreen(session: session),
      ),
      GoRoute(
        path: '/App',
        builder: (context, state) => HomeShell(session: session),
      ),
      GoRoute(
        path: '/App/Map',
        builder: (context, state) =>
            HomeShell(session: session, initialIndex: 1),
      ),
      GoRoute(
        path: '/App/Incidents',
        builder: (context, state) => HomeShell(
          session: session,
          initialIndex: 2,
          initialIncidentId: state.uri.queryParameters['id'],
        ),
      ),
      GoRoute(
        path: '/App/Incidents/Explorer',
        builder: (context, state) => AllReportsExplorerScreen(session: session),
      ),
      GoRoute(
        path: '/App/Chat',
        builder: (context, state) => CitizenChatScreen(session: session),
      ),
      GoRoute(
        path: '/App/Analytics',
        builder: (context, state) =>
            HomeShell(session: session, initialIndex: 3),
      ),
      GoRoute(
        path: '/App/Profile',
        builder: (context, state) =>
            HomeShell(session: session, initialIndex: 4),
      ),
      GoRoute(
        path: '/App/Emergency',
        builder: (context, state) =>
            HomeShell(session: session, initialIndex: 1),
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
        'Predictive',
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

bool _isAdminPath(String path) =>
    path == '/Admin' || path.startsWith('/Admin/');

bool _isProtected(String path) =>
    path == '/App' || path.startsWith('/App/') || _isAdminPath(path);

bool _isWrongWorkspace(String path, bool isAdmin) {
  if (!_isProtected(path) || path == '/App/Notifications') return false;
  return _isAdminPath(path) != isAdmin;
}

String? sessionRedirect(SessionController session, Uri uri) {
  if (!session.initialized) return null;
  final user = session.user;
  final location = uri.path;
  if (user == null && _isProtected(location)) {
    return Uri(
      path: '/Login',
      queryParameters: {'from': uri.toString()},
    ).toString();
  }
  if (user != null && (location == '/Login' || location == '/Register')) {
    final target = Uri.tryParse(uri.queryParameters['from'] ?? '');
    if (target != null &&
        !target.hasScheme &&
        !target.hasAuthority &&
        _isProtected(target.path) &&
        !_isWrongWorkspace(target.path, user.isAdmin)) {
      return target.toString();
    }
    return user.isAdmin ? '/Admin' : '/App';
  }
  if (user != null &&
      (_isWrongWorkspace(location, user.isAdmin) ||
          (location == '/' && user.isAdmin))) {
    return user.isAdmin ? '/Admin' : '/App';
  }
  return null;
}
