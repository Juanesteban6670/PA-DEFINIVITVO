import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/models.dart';
import 'package:cartagena_segura/shared/skeleton_loader.dart';
import 'package:cartagena_segura/shared/theme.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({required this.api, super.key});

  final ApiClient api;

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  late Future<List<EmergencyContact>> _contacts;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'ALL';

  @override
  void initState() {
    super.initState();
    _contacts = _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<EmergencyContact>> _loadContacts() async {
    final response = await widget.api.get('EmergencyContacts');
    if (response is! List) {
      throw const FormatException(
        'La API devolvió una lista de contactos inválida',
      );
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(EmergencyContact.fromJson)
        .toList();
  }

  Future<void> _call(String phone) async {
    final uri = Uri(
      scheme: 'tel',
      path: phone.replaceAll(RegExp(r'[^\d+]'), ''),
    );
    try {
      if (!await launchUrl(uri)) {
        throw Exception('El dispositivo no pudo iniciar la llamada a $phone');
      }
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No fue posible llamar ($phone): $error'),
          action: SnackBarAction(
            label: 'Copiar',
            onPressed: () => _copyPhone(phone),
          ),
        ),
      );
    }
  }

  void _copyPhone(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Número $phone copiado al portapapeles'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<EmergencyContact>>(
      future: _contacts,
      builder: (context, snapshot) {
        final allContacts = snapshot.data ?? const <EmergencyContact>[];

        final filtered = allContacts.where((contact) {
          final matchesCategory =
              _selectedCategory == 'ALL' ||
              contact.type.toUpperCase() == _selectedCategory;
          if (!matchesCategory) return false;

          if (_searchQuery.isEmpty) return true;
          final query = _searchQuery.toLowerCase();
          return contact.name.toLowerCase().contains(query) ||
              contact.address.toLowerCase().contains(query) ||
              contact.notes.toLowerCase().contains(query) ||
              contact.phone.toLowerCase().contains(query);
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Banner de Alerta Inmediata 123
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF991B1B), Color(0xFFDC2626), AppColors.red],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.red.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emergency_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¿Peligro o Urgencia Inmediata?',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                  ),
                            ),
                            const Text(
                              'Línea Única Distrital y Nacional',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.red,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _call('123'),
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                    label: const Text(
                      'Llamar al 123',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Buscador en tiempo real
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Buscar por entidad, barrio o número...',
                prefixIcon: const Icon(Icons.search_rounded, size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkCard : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Chips de filtrado por categoría
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'Todos (${allContacts.length})',
                    selected: _selectedCategory == 'ALL',
                    onSelected: () => setState(() => _selectedCategory = 'ALL'),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Policía',
                    icon: Icons.local_police_rounded,
                    selected: _selectedCategory == 'POLICE',
                    onSelected: () =>
                        setState(() => _selectedCategory = 'POLICE'),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Bomberos',
                    icon: Icons.local_fire_department_rounded,
                    selected: _selectedCategory == 'FIRE_STATION',
                    onSelected: () =>
                        setState(() => _selectedCategory = 'FIRE_STATION'),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Ambulancias',
                    icon: Icons.medical_services_rounded,
                    selected: _selectedCategory == 'AMBULANCE',
                    onSelected: () =>
                        setState(() => _selectedCategory = 'AMBULANCE'),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Guardacostas',
                    icon: Icons.directions_boat_rounded,
                    selected: _selectedCategory == 'COAST_GUARD',
                    onSelected: () =>
                        setState(() => _selectedCategory = 'COAST_GUARD'),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Hospitales',
                    icon: Icons.local_hospital_rounded,
                    selected: _selectedCategory == 'HOSPITAL',
                    onSelected: () =>
                        setState(() => _selectedCategory = 'HOSPITAL'),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Defensa Civil / Cruz Roja',
                    icon: Icons.health_and_safety_rounded,
                    selected: _selectedCategory == 'CIVIL_DEFENSE',
                    onSelected: () =>
                        setState(() => _selectedCategory = 'CIVIL_DEFENSE'),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Distrital',
                    icon: Icons.account_balance_rounded,
                    selected: _selectedCategory == 'MUNICIPALITY',
                    onSelected: () =>
                        setState(() => _selectedCategory = 'MUNICIPALITY'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Contactos disponibles',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkText : AppColors.navy,
                    ),
                  ),
                ),
                Text(
                  '${filtered.length} disponibles',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (snapshot.connectionState == ConnectionState.waiting)
              const Column(
                children: [
                  SkeletonIncidentCard(),
                  SizedBox(height: 10),
                  SkeletonIncidentCard(),
                  SizedBox(height: 10),
                  SkeletonIncidentCard(),
                ],
              )
            else if (snapshot.hasError)
              _ContactsError(
                message: snapshot.error.toString(),
                onRetry: () => setState(() => _contacts = _loadContacts()),
              )
            else if (filtered.isEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 40,
                        color: isDark ? AppColors.darkTextMuted : Colors.grey,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No se encontraron entidades con ese criterio.',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filtered.map(
                (contact) => _ModernContactCard(
                  contact: contact,
                  isDark: isDark,
                  onCall: () => _call(contact.phone),
                  onCopy: () => _copyPhone(contact.phone),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FilterChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      avatar: icon != null
          ? Icon(
              icon,
              size: 16,
              color: selected
                  ? Colors.white
                  : (isDark ? AppColors.sky : AppColors.brightBlue),
            )
          : null,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected
            ? Colors.white
            : (isDark ? AppColors.darkText : AppColors.navy),
      ),
      selectedColor: AppColors.brightBlue,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected
              ? AppColors.brightBlue
              : (isDark ? AppColors.darkBorder : AppColors.border),
        ),
      ),
    );
  }
}

class _ModernContactCard extends StatelessWidget {
  const _ModernContactCard({
    required this.contact,
    required this.isDark,
    required this.onCall,
    required this.onCopy,
  });

  final EmergencyContact contact;
  final bool isDark;
  final VoidCallback onCall;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final (icon, iconBg, typeName) = _meta(contact.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg.withValues(alpha: isDark ? 0.25 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconBg, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: iconBg.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: iconBg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (contact.phone.isNotEmpty)
                        Text(
                          contact.phone,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : const Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    contact.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : AppColors.navy,
                    ),
                  ),
                  if (contact.address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 13,
                          color: isDark ? AppColors.darkTextMuted : Colors.grey,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            contact.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (contact.notes.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      contact.notes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Copiar número',
                  visualDensity: VisualDensity.compact,
                  onPressed: onCopy,
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: isDark ? AppColors.sky : AppColors.brightBlue,
                  ),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  tooltip: 'Llamar a ${contact.name}',
                  onPressed: contact.phone.isEmpty ? null : onCall,
                  icon: const Icon(Icons.call_rounded, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, String) _meta(String type) => switch (type.toUpperCase()) {
    'POLICE' => (
      Icons.local_police_rounded,
      const Color(0xFF2563EB),
      'Policía',
    ),
    'FIRE_STATION' => (
      Icons.local_fire_department_rounded,
      const Color(0xFFEA580C),
      'Bomberos',
    ),
    'CIVIL_DEFENSE' => (
      Icons.health_and_safety_rounded,
      const Color(0xFFD97706),
      'Socorro',
    ),
    'HOSPITAL' => (
      Icons.local_hospital_rounded,
      const Color(0xFF059669),
      'Hospital',
    ),
    'AMBULANCE' => (
      Icons.medical_services_rounded,
      const Color(0xFFDC2626),
      'Ambulancia',
    ),
    'COAST_GUARD' => (
      Icons.directions_boat_rounded,
      const Color(0xFF0284C7),
      'Guardacostas',
    ),
    'MUNICIPALITY' => (
      Icons.account_balance_rounded,
      const Color(0xFF7C3AED),
      'Distrital',
    ),
    _ => (Icons.phone_in_talk_rounded, const Color(0xFF64748B), 'Servicio'),
  };
}

class _ContactsError extends StatelessWidget {
  const _ContactsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.red,
            size: 36,
          ),
          const SizedBox(height: 8),
          const Text(
            'No se pudieron cargar los contactos',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}
