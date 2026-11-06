import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/session_controller.dart';
import 'package:cartagena_segura/shared/theme.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({
    required this.session,
    this.initialResetting = false,
    this.initialToken = '',
    super.key,
  });

  final SessionController session;
  final bool initialResetting;
  final String initialToken;

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _token = TextEditingController();
  final _password = TextEditingController();
  late bool _resetting = widget.initialResetting;
  bool _busy = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _token.text = widget.initialToken;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      if (_resetting) {
        await widget.session.resetPassword(
          token: _token.text,
          newPassword: _password.text,
        );
        if (!mounted) return;
        setState(
          () => _message = 'Contraseña restablecida. Ya puedes iniciar sesión.',
        );
      } else {
        await widget.session.requestPasswordReset(_email.text);
        if (!mounted) return;
        setState(
          () => _message =
              'Si el correo está registrado, recibirás instrucciones para recuperar tu cuenta.',
        );
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _error = 'No se pudo completar la solicitud: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navy, AppColors.navyBlue, AppColors.blue],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: Colors.white, size: 30),
                SizedBox(height: 14),
                Text(
                  'Recupera el acceso a tu cuenta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Solicita un enlace y usa el token recibido para definir una nueva contraseña.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Enviar enlace'),
                          icon: Icon(Icons.email_outlined),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Restablecer'),
                          icon: Icon(Icons.lock_reset),
                        ),
                      ],
                      selected: {_resetting},
                      onSelectionChanged: _busy
                          ? null
                          : (selected) => setState(() {
                              _resetting = selected.first;
                              _error = null;
                              _message = null;
                            }),
                    ),
                    const SizedBox(height: 18),
                    if (!_resetting) ...[
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (value) =>
                            value == null ||
                                !RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(value.trim())
                            ? 'Escribe un correo válido'
                            : null,
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _token,
                        decoration: const InputDecoration(
                          labelText: 'Token recibido por correo',
                          prefixIcon: Icon(Icons.key_outlined),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Ingresa el token recibido'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Nueva contraseña',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) => value == null || value.length < 6
                            ? 'Usa al menos 6 caracteres'
                            : null,
                      ),
                    ],
                    if (_error != null || _message != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error ?? _message!,
                        style: TextStyle(
                          color: _error == null
                              ? AppColors.green
                              : Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _resetting
                                    ? 'Restablecer contraseña'
                                    : 'Solicitar enlace',
                              ),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () {
                              if (GoRouter.maybeOf(context) != null) {
                                context.go('/Login');
                              } else {
                                Navigator.of(context).maybePop();
                              }
                            },
                      child: const Text('Volver a iniciar sesión'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
