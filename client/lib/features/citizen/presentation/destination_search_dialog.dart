import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:cartagena_segura/core/data/safe_route_service.dart';

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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.navigation_outlined,
                      color: Color(0xFF1D4ED8),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Trazar Ruta Segura',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
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
                decoration: InputDecoration(
                  hintText: 'Buscar calle, barrio o destino en Cartagena…',
                  prefixIcon: const Icon(Icons.search),
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
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
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
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const Divider(height: 16),

            // Lista de resultados o Destinos Frecuentes
            Expanded(
              child: _searchResults.isNotEmpty
                  ? ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.place,
                            color: Color(0xFF1D4ED8),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            item.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
                          child: Text(
                            'Destinos frecuentes en Cartagena',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        for (final preset in SafeRouteService.cartagenaPresets)
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _categoryIcon(preset.category),
                                color: const Color(0xFF334155),
                                size: 18,
                              ),
                            ),
                            title: Text(
                              preset.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              preset.description,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
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

  IconData _categoryIcon(String category) => switch (category) {
    'Turismo' => Icons.beach_access_outlined,
    'Cultural' => Icons.museum_outlined,
    'Monumento' => Icons.fort_outlined,
    'Residencial' => Icons.location_city_outlined,
    'Transporte' => Icons.flight_takeoff_outlined,
    _ => Icons.place_outlined,
  };
}
