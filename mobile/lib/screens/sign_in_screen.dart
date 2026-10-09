import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/session_controller.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({required this.session, super.key});

  final SessionController session;

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
  bool _registering = false;
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.shield_moon_outlined,
                      size: 64,
                      color: Color(0xFF155EEF),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cartagena Segura',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reporta situaciones y encuentra ayuda cerca de ti.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_registering) ...[
                      _field(_fullName, 'Nombre completo', required: true),
                      const SizedBox(height: 12),
                      _field(
                        _email,
                        'Correo electrónico',
                        required: true,
                        email: true,
                      ),
                      const SizedBox(height: 12),
                      _field(_phone, 'Teléfono'),
                      const SizedBox(height: 12),
                    ],
                    _field(_username, 'Usuario o correo', required: true),
                    const SizedBox(height: 12),
                    _field(
                      _password,
                      'Contraseña',
                      required: true,
                      password: true,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                                    : 'Iniciar sesión',
                              ),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _registering = !_registering;
                              _error = null;
                            }),
                      child: Text(
                        _registering
                            ? 'Ya tengo una cuenta'
                            : 'Crear una cuenta ciudadana',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool email = false,
    bool password = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: password,
      keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
      textCapitalization: email || password
          ? TextCapitalization.none
          : TextCapitalization.words,
      autocorrect: !email && !password,
      decoration: InputDecoration(labelText: label),
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
