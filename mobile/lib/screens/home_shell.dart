import 'package:flutter/material.dart';

import '../data/session_controller.dart';
import '../data/report_draft_store.dart';
import '../theme.dart';
import 'emergency_screen.dart';
import 'incidents_map_screen.dart';
import 'my_reports_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'welcome_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({required this.session, super.key});

  final SessionController session;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  final _incidentRefresh = ValueNotifier<int>(0);
  late final ReportDraftStore _drafts;

  @override
  void initState() {
    super.initState();
    _drafts = ReportDraftStore(
      storage: widget.session.storage,
      owner: widget.session.user!.username,
    );
  }

  @override
  void dispose() {
    _incidentRefresh.dispose();
    super.dispose();
  }

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final api = widget.session.api;
    final wideLayout = MediaQuery.sizeOf(context).width >= 700;
    final pages = [
      WelcomeScreen(
        session: widget.session,
        incidentRefresh: _incidentRefresh,
        onSelectTab: _selectTab,
      ),
      MyReportsScreen(
        api: api,
        drafts: _drafts,
        incidentRefresh: _incidentRefresh,
        onReportSubmitted: () => _incidentRefresh.value++,
      ),
      IncidentsMapScreen(api: api, incidentRefresh: _incidentRefresh),
      EmergencyScreen(api: api),
      ProfileScreen(session: widget.session),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.06),
                border: Border.all(
                  color: AppColors.blue.withValues(alpha: 0.1),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset('assets/brand/app-icon.png'),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cartagena Segura',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  Text(
                    'Ciudadano',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => NotificationsScreen(api: api),
              ),
            ),
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: 'Perfil',
            onPressed: () => _selectTab(4),
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.blue,
              child: Text(
                (widget.session.user?.username.isNotEmpty ?? false)
                    ? widget.session.user!.username[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: wideLayout
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectTab,
                  extended: MediaQuery.sizeOf(context).width >= 1000,
                  labelType: MediaQuery.sizeOf(context).width >= 1000
                      ? null
                      : NavigationRailLabelType.all,
                  destinations: _railDestinations,
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: pages,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: wideLayout
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectTab,
              destinations: _navigationDestinations,
            ),
    );
  }

  static const _navigationDestinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Inicio',
    ),
    NavigationDestination(
      icon: Icon(Icons.assignment_outlined),
      selectedIcon: Icon(Icons.assignment),
      label: 'Reportes',
    ),
    NavigationDestination(
      icon: Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map),
      label: 'Mapa',
    ),
    NavigationDestination(
      icon: Icon(Icons.phone_outlined),
      selectedIcon: Icon(Icons.phone),
      label: 'Emergencias',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Perfil',
    ),
  ];

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: Text('Inicio'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.assignment_outlined),
      selectedIcon: Icon(Icons.assignment),
      label: Text('Reportes'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map),
      label: Text('Mapa'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.phone_outlined),
      selectedIcon: Icon(Icons.phone),
      label: Text('Emergencias'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: Text('Perfil'),
    ),
  ];
}
