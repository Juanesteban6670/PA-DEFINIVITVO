import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cartagena_segura/shared/theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static final _featuresKey = GlobalKey();
  static final _missionKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Row(
              children: [
                Image.asset('assets/brand/app-icon.png', width: 36, height: 36),
                const SizedBox(width: 10),
                const Text('Cartagena Segura'),
              ],
            ),
            actions: [
              if (wide) ...[
                TextButton(
                  onPressed: () => _scrollTo(_featuresKey),
                  child: const Text('Funciones'),
                ),
                TextButton(
                  onPressed: () => _scrollTo(_missionKey),
                  child: const Text('Nuestra misión'),
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: FilledButton(
                  onPressed: () => context.go('/Login'),
                  child: const Text('Ingresar'),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _hero(context, wide),
                _features(context),
                _mission(context),
                _howItWorks(context),
                _faq(context),
                _footer(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, bool wide) => Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(
      horizontal: wide ? 48 : 24,
      vertical: wide ? 96 : 56,
    ),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.navy, AppColors.navyBlue, AppColors.blue],
      ),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Wrap(
          spacing: 48,
          runSpacing: 32,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: wide ? 520 : 700,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Chip(
                    avatar: Icon(Icons.shield_outlined, size: 18),
                    label: Text('Seguridad ciudadana'),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Una ciudad más segura empieza contigo',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Reporta incidentes, consulta información y encuentra ayuda de emergencia en Cartagena.',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: Colors.white70, height: 1.55),
                  ),
                  const SizedBox(height: 26),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.go('/Register'),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Crear cuenta'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/Login'),
                        icon: const Icon(Icons.login),
                        label: const Text('Iniciar sesión'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: wide ? 460 : 700,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/brand/login-background.png',
                  height: wide ? 320 : 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 250,
                    color: Colors.white12,
                    child: const Center(
                      child: Icon(
                        Icons.location_city,
                        color: Colors.white,
                        size: 96,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _features(BuildContext context) => _section(
    context,
    sectionKey: _featuresKey,
    title: 'Herramientas para cuidarnos entre todos',
    subtitle: 'Información clara y canales de atención para actuar a tiempo.',
    child: LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 3 : 1;
        const items = [
          (
            Icons.campaign_outlined,
            'Reporta',
            'Comparte incidentes con ubicación y evidencia.',
          ),
          (
            Icons.map_outlined,
            'Consulta el mapa',
            'Explora incidentes y zonas de interés.',
          ),
          (
            Icons.phone_in_talk_outlined,
            'Encuentra ayuda',
            'Accede a contactos y números de emergencia.',
          ),
        ];
        return Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            for (final item in items)
              SizedBox(
                width: (constraints.maxWidth - (columns - 1) * 18) / columns,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.$1, size: 32, color: AppColors.blue),
                        const SizedBox(height: 12),
                        Text(
                          item.$2,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(item.$3),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );

  Widget _mission(BuildContext context) => Container(
    width: double.infinity,
    color: const Color(0xFFF1F5F9),
    child: _section(
      context,
      sectionKey: _missionKey,
      title: 'Una comunidad conectada',
      subtitle: 'Cartagena Segura facilita la comunicación entre la ciudadanía y las autoridades, con herramientas accesibles desde el teléfono o el computador.',
      child: const SizedBox.shrink(),
    ),
  );

  Widget _howItWorks(BuildContext context) => _section(
    context,
    title: '¿Cómo empezar?',
    subtitle: 'Tres pasos sencillos para participar.',
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: CircleAvatar(child: Text('1')),
          title: Text('Crea tu cuenta'),
          subtitle: Text('Regístrate con tus datos de contacto.'),
        ),
        ListTile(
          leading: CircleAvatar(child: Text('2')),
          title: Text('Consulta o reporta'),
          subtitle: Text('Describe la situación y su ubicación.'),
        ),
        ListTile(
          leading: CircleAvatar(child: Text('3')),
          title: Text('Sigue la información'),
          subtitle: Text('Consulta el estado de tus reportes.'),
        ),
      ],
    ),
  );

  Widget _faq(BuildContext context) => _section(
    context,
    title: 'Preguntas frecuentes',
    subtitle: 'Información para usar la plataforma.',
    child: const Column(
      children: [
        ExpansionTile(
          title: Text('¿Necesito permitir mi ubicación?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No. Puedes escribir una dirección o referencia; compartir GPS es opcional.',
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: Text('¿Qué hago ante una emergencia inmediata?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Comunícate directamente con los servicios de emergencia de tu zona.',
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _footer(BuildContext context) => Container(
    width: double.infinity,
    color: AppColors.navy,
    padding: const EdgeInsets.all(28),
    child: const Text(
      'Cartagena Segura · Participación ciudadana',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white70),
    ),
  );

  Widget _section(
    BuildContext context, {
    Key? sectionKey,
    required String title,
    required String subtitle,
    required Widget child,
  }) => Padding(
    key: sectionKey,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    ),
  );

  void _scrollTo(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = key.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }
}
