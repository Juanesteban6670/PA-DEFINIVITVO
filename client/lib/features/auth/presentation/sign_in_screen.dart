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
  bool _obscurePassword = true;
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
          username: _username.text.trim(),
          fullName: _fullName.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
        );
      } else {
        await widget.session.login(_username.text.trim(), _password.text);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 393),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Emblema de confianza (Figma Frame 2:193)
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F0F8),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F4C81).withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Image.asset(
                        'assets/brand/app-icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Título institucional
                  const Text(
                    'Cartagena Segura',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F4C81),
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Movilidad y alertas en tiempo real',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Encabezado de acceso
                  Text(
                    _registering
                        ? 'Crear cuenta ciudadana'
                        : 'Bienvenido de nuevo',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF142C40),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _registering
                        ? 'Regístrate para reportar incidentes y cuidar tu comunidad.'
                        : 'Conectados por una ciudad más segura.',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Formulario
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_registering) ...[
                          _inputLabel('Nombre completo'),
                          const SizedBox(height: 6),
                          _field(
                            _fullName,
                            'Tu nombre y apellidos',
                            icon: Icons.badge_outlined,
                            required: true,
                          ),
                          const SizedBox(height: 16),
                          _inputLabel('Correo electrónico'),
                          const SizedBox(height: 6),
                          _field(
                            _email,
                            'correo@ejemplo.com',
                            icon: Icons.mail_outline_rounded,
                            required: true,
                            email: true,
                          ),
                          const SizedBox(height: 16),
                          _inputLabel('Teléfono de contacto'),
                          const SizedBox(height: 6),
                          _field(
                            _phone,
                            '300 000 0000',
                            icon: Icons.phone_outlined,
                            phone: true,
                          ),
                          const SizedBox(height: 16),
                          _inputLabel('Nombre de usuario'),
                          const SizedBox(height: 6),
                          _field(
                            _username,
                            'nombre_usuario',
                            icon: Icons.person_outline_rounded,
                            required: true,
                            username: true,
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          _inputLabel('Correo electrónico o usuario'),
                          const SizedBox(height: 6),
                          _field(
                            _username,
                            'Correo electrónico',
                            icon: Icons.mail_outline_rounded,
                            required: true,
                            username: true,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _inputLabel('Contraseña'),
                        const SizedBox(height: 6),
                        _field(
                          _password,
                          'Contraseña',
                          icon: Icons.lock_outline_rounded,
                          required: true,
                          password: true,
                          isPasswordVisible: !_obscurePassword,
                          onTogglePassword: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        if (!_registering) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: _busy
                                  ? null
                                  : () {
                                      if (GoRouter.maybeOf(context) != null) {
                                        context.go('/ForgotPassword');
                                      } else {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                PasswordRecoveryScreen(
                                              session: widget.session,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 2,
                                ),
                                child: Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F4C81),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (_error != null ||
                            widget.session.sessionNotice != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFCA5A5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error ?? widget.session.sessionNotice!,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      color: Color(0xFF991B1B),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        // Botón principal (Figma Frame 2:214)
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F4C81),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _registering
                                            ? 'Crear cuenta ciudadana'
                                            : 'Iniciar sesión',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 19,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Alternar registro / login (Figma 2:218 y 2:219)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _registering
                                  ? '¿Ya tienes una cuenta? '
                                  : '¿No tienes cuenta? ',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            InkWell(
                              onTap: _busy
                                  ? null
                                  : () {
                                      final location = _registering
                                          ? '/Login'
                                          : '/Register';
                                      if (GoRouter.maybeOf(context) != null) {
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
                                    ? 'Inicia sesión aquí'
                                    : 'Regístrate aquí',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F4C81),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF142C40),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    required IconData icon,
    bool required = false,
    bool email = false,
    bool password = false,
    bool username = false,
    bool phone = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: password && !isPasswordVisible,
      keyboardType: email
          ? TextInputType.emailAddress
          : phone
              ? TextInputType.phone
              : TextInputType.text,
      textCapitalization: email || password || username || phone
          ? TextCapitalization.none
          : TextCapitalization.words,
      autocorrect: !email && !password && !username && !phone,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: Color(0xFF142C40),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF94A3B8),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, color: const Color(0xFF64748B), size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        suffixIcon: password
            ? IconButton(
                icon: Icon(
                  isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0F4C81), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
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
