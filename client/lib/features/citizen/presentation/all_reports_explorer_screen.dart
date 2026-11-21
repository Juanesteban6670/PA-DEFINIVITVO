import 'package:flutter/material.dart';
import 'package:cartagena_segura/core/data/incident_repository.dart';
import 'package:cartagena_segura/core/data/models.dart';
import 'package:cartagena_segura/core/data/session_controller.dart';
import 'package:cartagena_segura/features/citizen/presentation/widgets/incident_compact_card.dart';
import 'package:cartagena_segura/shared/responsive_layout.dart';
import 'package:cartagena_segura/shared/theme.dart';

/// Pantalla independiente para la exploración y consulta exhaustiva del historial de incidentes.
class AllReportsExplorerScreen extends StatefulWidget {
  const AllReportsExplorerScreen({
    required this.session,
    this.initialSector,
    super.key,
  });

  final SessionController session;
  final String? initialSector;

  @override
  State<AllReportsExplorerScreen> createState() => _AllReportsExplorerScreenState();
}

class _AllReportsExplorerScreenState extends State<AllReportsExplorerScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Incident>> _futureIncidents;

  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  String _selectedStatus = 'Todos';
  late String _selectedSector = widget.initialSector ?? 'Todos';
  DateTimeRange? _selectedDateRange;

  final List<String> _categories = const [
    'Todos',
    'Seguridad',
    'Tráfico',
    'Servicios',
    'Otros',
  ];

  final List<String> _statuses = const [
    'Todos',
    'En revisión',
    'En atención',
    'Resueltos',
  ];

  final List<String> _sectors = const [
    'Todos',
    'Centro Histórico',
    'Bocagrande',
    'Manga',
    'Getsemaní',
    'Bazurto',
    'Olaya Herrera',
    'Pie de la Popa',
    'Crespo',
    'El Cabrero',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    _futureIncidents = loadIncidents(widget.session.api, mine: false);
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _loadData();
    });
    await _futureIncidents;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: _selectedDateRange,
      helpText: 'Filtrar por rango de fechas',
      confirmText: 'Aplicar',
      cancelText: 'Cancelar',
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _clearDateRange() {
    setState(() => _selectedDateRange = null);
  }

  List<Incident> _applyFilters(List<Incident> incidents) {
    return incidents.where((inc) {
      // 1. Filtro de búsqueda por texto
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchDesc = inc.description.toLowerCase().contains(q);
        final matchType = inc.type.toLowerCase().contains(q);
        final matchLoc = inc.location.toLowerCase().contains(q);
        if (!matchDesc && !matchType && !matchLoc) return false;
      }

      // 2. Filtro de categoría
      if (_selectedCategory != 'Todos') {
        final (catName, _, _, _) = IncidentCompactCard.getCategoryMeta(inc.type, false);
        if (catName != _selectedCategory) {
          if (_selectedCategory == 'Otros' && (catName == 'Seguridad' || catName == 'Tráfico' || catName == 'Servicios')) {
            return false;
          } else if (_selectedCategory != 'Otros') {
            return false;
          }
        }
      }

      // 3. Filtro de estado
      if (_selectedStatus != 'Todos') {
        final st = inc.status.toUpperCase();
        if (_selectedStatus == 'En revisión' && st != 'PENDING') return false;
        if (_selectedStatus == 'En atención' && st != 'IN_PROGRESS') return false;
        if (_selectedStatus == 'Resueltos' && st != 'RESOLVED') return false;
      }

      // 4. Filtro de sector
      if (_selectedSector != 'Todos') {
        final loc = inc.location.toLowerCase();
        final desc = inc.description.toLowerCase();
        final sec = _selectedSector.toLowerCase();
        if (!loc.contains(sec) && !desc.contains(sec)) return false;
      }

      // 5. Filtro de fechas
      if (_selectedDateRange != null) {
        final date = inc.createdAt;
        if (date == null) return false;
        final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
        if (date.isBefore(start) || date.isAfter(end)) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCanvas : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? AppColors.darkText : AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Historial de Reportes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkText : AppColors.navy,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: Breakpoints.maxContentWidth,
          padding: EdgeInsets.symmetric(
            horizontal: context.responsiveValue(mobile: 16.0, tablet: 24.0, desktop: 32.0),
            vertical: 14.0,
          ),
          child: FutureBuilder<List<Incident>>(
            future: _futureIncidents,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allIncidents = snapshot.data ?? const <Incident>[];
              final filtered = _applyFilters(allIncidents);

              return RefreshIndicator(
                color: isDark ? AppColors.brightBlue : AppColors.blue,
                backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                onRefresh: _handleRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    // Campo de búsqueda en vivo
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        style: TextStyle(
                          color: isDark ? AppColors.darkText : AppColors.navy,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar por tipo, descripción o barrio...',
                          hintStyle: TextStyle(
                            color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: isDark ? AppColors.brightBlue : AppColors.blue,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filtros por Categoría
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final cat in _categories) ...[
                            _buildChoiceChip(
                              label: cat,
                              isSelected: _selectedCategory == cat,
                              onSelected: () => setState(() => _selectedCategory = cat),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filtros por Estado y Selector de Sector / Fechas
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Selector de Sector
                          _buildSectorDropdown(isDark),
                          const SizedBox(width: 8),

                          // Botón de Rango de Fechas
                          _buildDateFilterChip(isDark),
                          const SizedBox(width: 8),

                          // Chips de Estado
                          for (final st in _statuses) ...[
                            _buildChoiceChip(
                              label: st,
                              isSelected: _selectedStatus == st,
                              onSelected: () => setState(() => _selectedStatus = st),
                              isDark: isDark,
                              dense: true,
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Resumen de conteo y botón limpiar filtros
                    Row(
                      children: [
                        Text(
                          'Mostrando ${filtered.length} de ${allIncidents.length} reportes',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                          ),
                        ),
                        const Spacer(),
                        if (_searchQuery.isNotEmpty ||
                            _selectedCategory != 'Todos' ||
                            _selectedStatus != 'Todos' ||
                            _selectedSector != 'Todos' ||
                            _selectedDateRange != null)
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedCategory = 'Todos';
                                _selectedStatus = 'Todos';
                                _selectedSector = 'Todos';
                                _selectedDateRange = null;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Limpiar filtros',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.brightBlue : AppColors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Lista de tarjetas compactas o estado vacío
                    if (filtered.isEmpty)
                      _buildEmptyState(isDark)
                    else
                      for (final inc in filtered)
                        IncidentCompactCard(
                          incident: inc,
                          isDark: isDark,
                          onTap: () => IncidentCompactCard.showDetail(
                            context,
                            inc,
                            api: widget.session.api,
                          ),
                        ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required bool isDark,
    bool dense = false,
  }) {
    final activeBg = isDark ? AppColors.brightBlue : AppColors.blue;
    final inactiveBg = isDark ? AppColors.darkCard : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onSelected,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 12, vertical: dense ? 5 : 7),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? activeBg
                : (isDark ? AppColors.darkBorder : AppColors.border),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: dense ? 11 : 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.navy),
          ),
        ),
      ),
    );
  }

  Widget _buildSectorDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: _selectedSector != 'Todos'
            ? (isDark ? AppColors.brightBlue.withValues(alpha: 0.15) : AppColors.blue.withValues(alpha: 0.1))
            : (isDark ? AppColors.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _selectedSector != 'Todos'
              ? (isDark ? AppColors.brightBlue : AppColors.blue)
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: 0.8,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSector,
          isDense: true,
          dropdownColor: isDark ? AppColors.darkCard : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: isDark ? AppColors.darkText : AppColors.navy,
          ),
          items: _sectors.map((s) {
            return DropdownMenuItem<String>(
              value: s,
              child: Text(
                s == 'Todos' ? 'Barrio: Todos' : s,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.navy,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedSector = val);
          },
        ),
      ),
    );
  }

  Widget _buildDateFilterChip(bool isDark) {
    final hasRange = _selectedDateRange != null;
    final label = hasRange
        ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}'
        : 'Fecha';

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: _pickDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: hasRange
              ? (isDark ? AppColors.brightBlue.withValues(alpha: 0.15) : AppColors.blue.withValues(alpha: 0.1))
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: hasRange
                ? (isDark ? AppColors.brightBlue : AppColors.blue)
                : (isDark ? AppColors.darkBorder : AppColors.border),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 13,
              color: hasRange
                  ? (isDark ? AppColors.brightBlue : AppColors.blue)
                  : (isDark ? AppColors.darkTextMuted : AppColors.muted),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: hasRange ? FontWeight.w700 : FontWeight.w500,
                color: hasRange
                    ? (isDark ? AppColors.brightBlue : AppColors.blue)
                    : (isDark ? AppColors.darkText : AppColors.navy),
              ),
            ),
            if (hasRange) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _clearDateRange,
                child: const Icon(Icons.close_rounded, size: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 40,
            color: isDark ? AppColors.darkTextMuted : AppColors.muted,
          ),
          const SizedBox(height: 12),
          Text(
            'No se encontraron reportes',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Intenta ajustando los términos de búsqueda o los filtros aplicados.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
