import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:cartagena_segura/core/data/safe_route_service.dart';
import 'package:cartagena_segura/shared/theme.dart';

/// Modal para seleccionar o buscar un destino hacia el cual calcular la Ruta Segura.
class DestinationSearchDialog extends StatefulWidget {
  const DestinationSearchDialog({required this.currentLocation, super.key});

  final LatLng? currentLocation;

  @override
  State<DestinationSearchDialog> createState() =>
      _DestinationSearchDialogState();
}

class _DestinationSearchDialogState extends State<DestinationSearchDialog> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<DestinationPreset> _searchResults = const [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    if (text.trim().length < 2) {
      setState(() {
        _searchResults = const [];
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearching = true);
      final results = await SafeRouteService.searchDestinations(text);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brightBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.navigation_outlined,
                      color: AppColors.brightBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Trazar Ruta Segura',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkText : AppColors.navy,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Campo de búsqueda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  color: isDark ? AppColors.darkText : AppColors.navy,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar calle, barrio o destino en Cartagena…',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                  ),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : (_searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface
                      : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Opción para seleccionar en el mapa
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop('CHOOSE_ON_MAP'),
                icon: const Icon(Icons.touch_app_outlined, size: 20),
                label: const Text('Elegir destino tocando el mapa'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            Divider(
              height: 16,
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),

            // Lista de resultados o Destinos Frecuentes
            Expanded(
              child: _searchResults.isNotEmpty
                  ? ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.place,
                            color: AppColors.brightBlue,
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkText
                                  : AppColors.navy,
                            ),
                          ),
                          subtitle: Text(
                            item.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                          child: Text(
                            'Destinos frecuentes en Cartagena',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        for (final preset in SafeRouteService.cartagenaPresets)
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurface
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _categoryIcon(preset.category),
                                color: isDark
                                    ? AppColors.darkText
                                    : const Color(0xFF334155),
                                size: 18,
                              ),
                            ),
                            title: Text(
                              preset.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkText
                                    : AppColors.navy,
                              ),
                            ),
                            subtitle: Text(
                              preset.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            onTap: () => Navigator.of(context).pop(preset),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    return switch (category) {
      'Salud' => Icons.local_hospital_outlined,
      'Educación' => Icons.school_outlined,
      'Transporte' => Icons.directions_bus_outlined,
      'Turismo' => Icons.beach_access_outlined,
      'Comercio' => Icons.shopping_bag_outlined,
      _ => Icons.place_outlined,
    };
  }
}
