import 'package:flutter/material.dart';

import '../data/session_controller.dart';
import 'emergency_screen.dart';
import 'incidents_map_screen.dart';
import 'report_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({required this.session, super.key});

  final SessionController session;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  final _incidentRefresh = ValueNotifier<int>(0);

  @override
  void dispose() {
    _incidentRefresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session.user!;
    final pages = [
      _WelcomePage(
        name: user.fullName.isEmpty ? user.username : user.fullName,
        onSelectTab: (index) => setState(() => _selectedIndex = index),
      ),
      IncidentsMapScreen(
        api: widget.session.api,
        incidentRefresh: _incidentRefresh,
      ),
      ReportScreen(
        api: widget.session.api,
        onReportSubmitted: () => _incidentRefresh.value++,
      ),
      EmergencyScreen(api: widget.session.api),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cartagena Segura'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: widget.session.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Mapa'),
          NavigationDestination(
            icon: Icon(Icons.add_location_alt_outlined),
            label: 'Reportar',
          ),
          NavigationDestination(
            icon: Icon(Icons.sos_outlined),
            label: 'Emergencias',
          ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.name, required this.onSelectTab});

  final String name;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Hola, $name',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu comunidad, más segura y conectada.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        _ActionCard(
          icon: Icons.add_location_alt,
          title: 'Reportar un incidente',
          subtitle: 'Comparte qué ocurrió y dónde.',
          color: const Color(0xFFB42318),
          onTap: () => onSelectTab(2),
        ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.map,
          title: 'Ver mapa ciudadano',
          subtitle: 'Consulta los incidentes reportados.',
          color: const Color(0xFF155EEF),
          onTap: () => onSelectTab(1),
        ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.call,
          title: 'Contactos de emergencia',
          subtitle: 'Encuentra teléfonos de ayuda.',
          color: const Color(0xFF067647),
          onTap: () => onSelectTab(3),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Si existe un peligro inmediato, comunícate directamente '
                    'con la línea de emergencias 123.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
