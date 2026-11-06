import 'package:flutter/material.dart';

import '../data/session_controller.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.session, super.key});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final user = session.user!;
    final initial = user.username.isEmpty
        ? 'U'
        : user.username[0].toUpperCase();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 38),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.navy, AppColors.navyBlue],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.blue,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'CIUDADANO',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -20),
          child: Card(
            child: Column(
              children: [
                _ProfileRow(
                  icon: Icons.person_outline,
                  label: 'Nombre completo',
                  value: user.fullName,
                ),
                const Divider(height: 1, indent: 58),
                _ProfileRow(
                  icon: Icons.alternate_email,
                  label: 'Usuario',
                  value: user.username,
                ),
                const Divider(height: 1, indent: 58),
                _ProfileRow(
                  icon: Icons.mail_outline,
                  label: 'Correo',
                  value: user.email,
                ),
                const Divider(height: 1, indent: 58),
                _ProfileRow(
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: user.phone,
                ),
              ],
            ),
          ),
        ),
        if (session.sessionNotice != null) ...[
          Text(
            session.sessionNotice!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.red,
            side: const BorderSide(color: Color(0xFFFEE2E2)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () async {
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cerrar sesión'),
                content: const Text('¿Quieres salir de tu cuenta?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            );
            if (shouldLogout == true) await session.logout();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tus datos de perfil son los que devuelve la API. La edición de nombre y teléfono no está disponible en el backend.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFF1F5F9),
          foregroundColor: const Color(0xFF64748B),
          child: Icon(icon, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value.isEmpty ? 'No especificado' : value,
                style: TextStyle(
                  color: value.isEmpty ? AppColors.muted : AppColors.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
