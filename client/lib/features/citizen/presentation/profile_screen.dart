import 'package:flutter/material.dart';

import 'package:cartagena_segura/core/data/session_controller.dart';
import 'package:cartagena_segura/shared/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.session, super.key});

  final SessionController session;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _startEditing() {
    final user = widget.session.user!;
    _fullName.text = user.fullName;
    _email.text = user.email;
    _phone.text = user.phone;
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    if (_fullName.text.trim().isEmpty || !_email.text.trim().contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un nombre y un correo válidos')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.session.updateProfile(
        fullName: _fullName.text,
        email: _email.text,
        phone: _phone.text,
      );
      if (mounted) setState(() => _editing = false);
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
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
                  controller: _editing ? _fullName : null,
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
                  controller: _editing ? _email : null,
                  keyboardType: TextInputType.emailAddress,
                ),
                const Divider(height: 1, indent: 58),
                _ProfileRow(
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: user.phone,
                  controller: _editing ? _phone : null,
                  keyboardType: TextInputType.phone,
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
        if (_editing)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () => setState(() => _editing = false),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Guardando…' : 'Guardar'),
                ),
              ),
            ],
          )
        else
          OutlinedButton.icon(
            onPressed: _startEditing,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar perfil'),
          ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Apariencia y Tema',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Center(child: ThemeModeSelector()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.red,
            side: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF7F1D1D)
                  : const Color(0xFFFEE2E2),
            ),
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
          'Tu información se actualiza con tu cuenta. Para eliminarla, contacta al equipo administrador.',
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
    this.controller,
    this.keyboardType,
  });

  final IconData icon;
  final String label;
  final String value;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder
              : const Color(0xFFF1F5F9),
          foregroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkTextMuted
              : const Color(0xFF64748B),
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
              if (controller != null)
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Tu ${label.toLowerCase()}',
                    isDense: true,
                  ),
                )
              else
                Text(
                  value.isEmpty ? 'No especificado' : value,
                  style: TextStyle(
                    color: value.isEmpty
                        ? AppColors.muted
                        : Theme.of(context).colorScheme.onSurface,
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
