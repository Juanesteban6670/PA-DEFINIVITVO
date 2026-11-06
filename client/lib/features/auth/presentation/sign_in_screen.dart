import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/session_controller.dart';
import 'package:cartagena_segura/shared/theme.dart';
import 'password_recovery_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    required this.session,
    this.initialRegistering = false,
    super.key,
  });

  final SessionController session;
  final bool initialRegistering;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  late bool _registering = widget.initialRegistering;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SignInScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRegistering != widget.initialRegistering) {
      _registering = widget.initialRegistering;
      _error = null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_registering) {
        await widget.session.register(
          username: _username.text,
          fullName: _fullName.text,
          email: _email.text,
          phone: _phone.text,
          password: _password.text,
        );
      } else {
        await widget.session.login(_username.text, _password.text);
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _error = 'No se pudo guardar la sesión: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _registering
                ? 'assets/brand/register-background.png'
                : 'assets/brand/login-background.png',
            fit: BoxFit.cover,
          ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.62)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Image.asset('assets/brand/app-icon.png'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Cartagena Segura',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sistema de Seguridad Ciudadana',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    _registering
                                        ? 'Crear cuenta ciudadana'
                                        : 'Iniciar sesión',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  if (_registering) ...[
                                    _field(
                                      _fullName,
                                      'Nombre completo',
                                      required: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _field(
                                      _email,
                                      'Correo electrónico',
                                      required: true,
                                      email: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _field(_phone, 'Teléfono', phone: true),
                                    const SizedBox(height: 12),
                                  ],
                                  _field(
                                    _username,
                                    _registering
                                        ? 'Usuario'
                                        : 'Usuario, correo o teléfono',
                                    required: true,
                                    username: true,
                                  ),
                                  const SizedBox(height: 12),
                                  _field(
                                    _password,
                                    'Contraseña',
                                    required: true,
                                    password: true,
                                  ),
                                  if (!_registering)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _busy
                                            ? null
                                            : () {
                                                if (GoRouter.maybeOf(context) !=
                                                    null) {
                                                  context.go('/ForgotPassword');
                                                } else {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute<void>(
                                                      builder: (_) =>
                                                          PasswordRecoveryScreen(
                                                            session:
                                                                widget.session,
                                                          ),
                                                    ),
                                                  );
                                                }
                                              },
                                        child: const Text(
                                          '¿Olvidaste tu contraseña?',
                                          style: TextStyle(
                                            color: Color(0xFF93C5FD),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_error != null ||
                                      widget.session.sessionNotice != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      _error ?? widget.session.sessionNotice!,
                                      style: TextStyle(
                                        color: theme.colorScheme.errorContainer,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: _busy ? null : _submit,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: _busy
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              _registering
                                                  ? 'Crear cuenta'
                                                  : 'Ingresar',
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () {
                                            final location = _registering
                                                ? '/Login'
                                                : '/Register';
                                            if (GoRouter.maybeOf(context) !=
                                                null) {
                                              context.go(location);
                                            } else {
                                              setState(() {
                                                _registering = !_registering;
                                                _error = null;
                                              });
                                            }
                                          },
                                    child: Text(
                                      _registering
                                          ? 'Ya tengo una cuenta'
                                          : '¿No tienes cuenta? Regístrate',
                                      style: const TextStyle(
                                        color: Color(0xFFBFDBFE),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool email = false,
    bool password = false,
    bool username = false,
    bool phone = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: password,
      keyboardType: email
          ? TextInputType.emailAddress
          : phone
          ? TextInputType.phone
          : TextInputType.text,
      textCapitalization: email || password || username || phone
          ? TextCapitalization.none
          : TextCapitalization.words,
      autocorrect: !email && !password && !username && !phone,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        prefixIcon: Icon(
          password
              ? Icons.lock_outline
              : email
              ? Icons.mail_outline
              : Icons.person_outline,
          color: Colors.white70,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF93C5FD), width: 1.4),
        ),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return 'Este campo es obligatorio';
        if (email && text.isNotEmpty && !text.contains('@')) {
          return 'Escribe un correo válido';
        }
        if (password && text.isNotEmpty && text.length < 6) {
          return 'La contraseña debe tener al menos 6 caracteres';
        }
        return null;
      },
    );
  }
}
