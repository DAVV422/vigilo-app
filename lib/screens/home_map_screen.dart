import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../domain/entities/incident.dart';
import '../presentation/providers/providers.dart';
import '../widgets/report_bottom_sheet.dart';
import '../widgets/incident_detail_modal.dart';

class HomeMapScreen extends ConsumerStatefulWidget {
  final Incident? incidentToShow;

  const HomeMapScreen({super.key, this.incidentToShow});

  @override
  ConsumerState<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends ConsumerState<HomeMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(
    -17.783327,
    -63.182141,
  ); // Default Santa Cruz
  bool _isLocating = true;

  // Filtros activos
  final Set<IncidentType> _activeFilters = {
    IncidentType.insecurity,
    IncidentType.trash,
    IncidentType.weeds,
    IncidentType.recycling,
  };

  // Flujo de creación de reporte
  bool _isSelectingLocation = false;
  IncidentType? _selectedTypeForReport;

  // Pokemon Go Simulación & Interactividad
  bool _isSimulationMode = false;
  double _mapRotation = 0.0;
  bool _isSidebarOpen = false;

  // Animaciones de Caminata
  AnimationController? _movementController;
  LatLng? _startLocation;

  // Animaciones de Radar
  AnimationController? _radarSweepController;
  double _radarPulseRadius = 0.0;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.incidentToShow != null) {
        final incident = widget.incidentToShow!;
        _mapController.move(incident.location, 17.0);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showIncidentDetail(incident);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _movementController?.dispose();
    _radarSweepController?.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLocating = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLocating = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLocating = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    final newPos = LatLng(position.latitude, position.longitude);
    setState(() {
      _currentLocation = newPos;
      _isLocating = false;
    });
    ref.read(currentLocationProvider.notifier).state = newPos;

    _mapController.move(_currentLocation, 16.0);
    _triggerRadarPulse();
  }

  void _simulateWalkTo(LatLng target) {
    _movementController?.dispose();

    _startLocation = _currentLocation;

    // Calcular velocidad constante basada en la distancia (aprox. 100m por segundo)
    final distance = Geolocator.distanceBetween(
      _startLocation!.latitude,
      _startLocation!.longitude,
      target.latitude,
      target.longitude,
    );

    // Duración entre 1 y 4 segundos
    final durationMs = (distance * 10).clamp(1000.0, 4000.0).toInt();

    _movementController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );

    final Animation<double> curve = CurvedAnimation(
      parent: _movementController!,
      curve: Curves.easeInOutCubic,
    );

    _movementController!.addListener(() {
      final value = curve.value;
      final lat = _startLocation!.latitude + (target.latitude - _startLocation!.latitude) * value;
      final lng = _startLocation!.longitude + (target.longitude - _startLocation!.longitude) * value;
      final newPos = LatLng(lat, lng);
      setState(() {
        _currentLocation = newPos;
      });
      ref.read(currentLocationProvider.notifier).state = newPos;
      _mapController.move(_currentLocation, _mapController.camera.zoom);
    });

    _movementController!.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        _triggerRadarPulse();
        ref.read(proximityNotifierProvider.notifier).checkNow();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('vigilo_achievement_walked', true);
      }
    });

    _movementController!.forward();
  }

  void _triggerRadarPulse() {
    setState(() {
      _radarPulseRadius = 0.0;
    });

    _radarSweepController?.dispose();
    _radarSweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    final Animation<double> radarAnimation = Tween<double>(begin: 0.0, end: 200.0).animate(
      CurvedAnimation(parent: _radarSweepController!, curve: Curves.easeOutQuad),
    );

    _radarSweepController!.addListener(() {
      setState(() {
        _radarPulseRadius = radarAnimation.value;
      });
    });

    _radarSweepController!.forward();

    // Contar reportes cercanos detectados en rango
    final incidents = ref.read(incidentsProvider);
    int nearbyCount = 0;
    for (var incident in incidents) {
      if (incident.status == IncidentStatus.active) {
        final dist = Geolocator.distanceBetween(
          _currentLocation.latitude,
          _currentLocation.longitude,
          incident.location.latitude,
          incident.location.longitude,
        );
        if (dist <= 200) {
          nearbyCount++;
        }
      }
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.radar, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                nearbyCount > 0
                    ? '¡Radar activo! Detectados $nearbyCount reportes en tu rango de 200m.'
                    : 'Radar escaneado. No hay reportes activos en tu rango inmediato.',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryContainer,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showIncidentDetail(Incident incident) {
    final distance = Geolocator.distanceBetween(
      _currentLocation.latitude,
      _currentLocation.longitude,
      incident.location.latitude,
      incident.location.longitude,
    );
    final bool isWithinRange = distance <= 200 || incident.status == IncidentStatus.resolved;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncidentDetailModal(
        incident: incident,
        isWithinRange: isWithinRange,
      ),
    );
  }

  void _startReportFlow() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportBottomSheet(
        onTypeSelected: (type) {
          setState(() {
            _selectedTypeForReport = type;
            _isSelectingLocation = true;
          });
        },
      ),
    );
  }

  Future<void> _promptForDescription() async {
    final user = ref.read(authProvider);
    if (user == null) return;

    final centerPosition = _mapController.camera.center;
    String? enteredDescription;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DescriptionInputSheet(
        onSubmitted: (text) {
          enteredDescription = text;
          Navigator.pop(context);
        },
      ),
    );

    if (enteredDescription != null && enteredDescription!.trim().isNotEmpty) {
      final String incidentTitle = _getTitleForType(_selectedTypeForReport!);

      final newIncident = Incident(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: incidentTitle,
        description: enteredDescription!.trim(),
        location: centerPosition,
        type: _selectedTypeForReport!,
        reportedAt: DateTime.now(),
        reportedByUserId: user.id,
        validatorsIds: [],
      );

      await ref.read(incidentsProvider.notifier).addIncident(newIncident);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('vigilo_achievement_reported', true);

      setState(() {
        _isSelectingLocation = false;
        _selectedTypeForReport = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte creado exitosamente (+3 puntos).'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getTitleForType(IncidentType type) {
    switch (type) {
      case IncidentType.insecurity:
        return 'Inseguridad Reportada';
      case IncidentType.trash:
        return 'Basura Reportada';
      case IncidentType.weeds:
        return 'Maleza Reportada';
      case IncidentType.recycling:
        return 'Reciclaje Disponible';
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(incidentsProvider);
    final activeIncidents = incidents.where((i) => i.status == IncidentStatus.active).toList();

    // Marcadores de incidentes filtrados (solo incidentes activos)
    final filteredIncidents = incidents.where((incident) {
      return _activeFilters.contains(incident.type) && incident.status == IncidentStatus.active;
    }).toList();

    List<Marker> markers = filteredIncidents.map((incident) {
      Color iconColor;
      IconData iconData;

      switch (incident.type) {
        case IncidentType.insecurity:
          iconColor = AppColors.secondary;
          iconData = Icons.warning;
          break;
        case IncidentType.trash:
          iconColor = AppColors.neutralTrash;
          iconData = Icons.delete;
          break;
        case IncidentType.weeds:
          iconColor = AppColors.warning;
          iconData = Icons.grass;
          break;
        case IncidentType.recycling:
          iconColor = AppColors.ecoGreen;
          iconData = Icons.recycling;
          break;
      }

      final double distance = Geolocator.distanceBetween(
        _currentLocation.latitude,
        _currentLocation.longitude,
        incident.location.latitude,
        incident.location.longitude,
      );

      final bool isWithinRange = distance <= 200 || incident.status == IncidentStatus.resolved;

      return Marker(
        point: incident.location,
        width: 60,
        height: 60,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: _isSelectingLocation
              ? null
              : () => _showIncidentDetail(incident),
          child: PulsingMarkerWidget(
            color: iconColor,
            iconData: iconData,
            isWithinRange: isWithinRange,
            isActive: incident.status == IncidentStatus.active,
          ),
        ),
      );
    }).toList();

    // Añadir el Pin de Héroe del Jugador
    if (!_isLocating) {
      markers.add(
        Marker(
          point: _currentLocation,
          width: 70,
          height: 70,
          child: HeroLocationMarkerWidget(rotation: _mapRotation),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. EL MAPA FLUTTER_MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 16.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all, // Permitir rotación completa
              ),
              onMapEvent: (event) {
                setState(() {
                  _mapRotation = _mapController.camera.rotation;
                });
              },
              onTap: (tapPosition, point) {
                if (_isSimulationMode) {
                  _simulateWalkTo(point);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vigilo.app',
              ),
              // Círculos de Radar de Rango de Escaneo (Pokemon Go)
              if (!_isLocating)
                CircleLayer(
                  circles: [
                    // Círculo límite de 200 metros
                    CircleMarker(
                      point: _currentLocation,
                      radius: 200,
                      useRadiusInMeter: true,
                      color: AppColors.primary.withOpacity(0.06),
                      borderColor: AppColors.primary.withOpacity(0.3),
                      borderStrokeWidth: 2,
                    ),
                    // Onda pulsante expansiva temporal
                    if (_radarPulseRadius > 0.0)
                      CircleMarker(
                        point: _currentLocation,
                        radius: _radarPulseRadius,
                        useRadiusInMeter: true,
                        color: AppColors.primary.withOpacity(0.18 * (1.0 - _radarPulseRadius / 200.0)),
                        borderColor: AppColors.primary.withOpacity(0.45 * (1.0 - _radarPulseRadius / 200.0)),
                        borderStrokeWidth: 1.5,
                      ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),

          // 2. PUNTO DE MIRA EN MODO CREACIÓN
          if (_isSelectingLocation)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40.0),
                child: Icon(
                  Icons.location_on,
                  size: 50,
                  color: AppColors.secondary,
                ),
              ),
            ),

          // 3. BARRA DE FILTROS SUPERIOR (INTERACTIVOS)
          if (!_isSelectingLocation)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.only(left: 56), // Dejar espacio al menú sidebar
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(IncidentType.insecurity, 'Inseguridad', AppColors.secondary),
                          const SizedBox(width: 8),
                          _buildFilterChip(IncidentType.trash, 'Basura', AppColors.neutralTrash),
                          const SizedBox(width: 8),
                          _buildFilterChip(IncidentType.weeds, 'Maleza', AppColors.warning),
                          const SizedBox(width: 8),
                          _buildFilterChip(IncidentType.recycling, 'Reciclaje', AppColors.ecoGreen),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 4. BOTÓN FLOTANTE PARA ABRIR LA BARRA LATERAL (SIDEBAR)
          if (!_isSelectingLocation)
            Positioned(
              left: 16,
              top: MediaQuery.of(context).padding.top + 8,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'menu_sidebar_btn',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                elevation: 4,
                onPressed: () {
                  setState(() {
                    _isSidebarOpen = true;
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.menu, size: 24),
                    if (activeIncidents.isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${activeIncidents.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // 5. CONTROLES FLOTANTES LATERALES DERECHOS (BRÚJULA Y MODO CAMINATA)
          if (!_isSelectingLocation)
            Positioned(
              right: 16,
              bottom: 100,
              child: Column(
                children: [
                  // Brújula inteligente
                  CompassWidget(
                    rotation: _mapRotation,
                    onTap: () {
                      _mapController.rotate(0.0);
                      setState(() {
                        _mapRotation = 0.0;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Botón caminata Pokemon Go
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'sim_walk_btn',
                    backgroundColor: _isSimulationMode ? AppColors.primary : Colors.white,
                    foregroundColor: _isSimulationMode ? Colors.white : AppColors.primary,
                    elevation: 4,
                    onPressed: () {
                      setState(() {
                        _isSimulationMode = !_isSimulationMode;
                      });
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.directions_walk, color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isSimulationMode
                                      ? 'Modo Simulación Activo. Toca el mapa para que tu héroe camine hacia allí.'
                                      : 'Modo Simulación Desactivado.',
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Icon(Icons.directions_walk),
                  ),
                ],
              ),
            ),

          // 6. LA BARRA LATERAL DESLIZANTE (GLASSMORPHIC SIDEBAR)
          _buildGlassmorphicSidebar(context, incidents, activeIncidents),
        ],
      ),
      floatingActionButton: _isSelectingLocation
          ? FloatingActionButton.extended(
              onPressed: _promptForDescription,
              backgroundColor: AppColors.primaryContainer,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Confirmar Ubicación',
                style: TextStyle(color: Colors.white),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: _startReportFlow,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_alert, color: Colors.white),
              label: const Text(
                'Reportar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Widget de barra de filtros interactiva
  Widget _buildFilterChip(IncidentType type, String label, Color color) {
    final bool isActive = _activeFilters.contains(type);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isActive) {
            _activeFilters.remove(type);
          } else {
            _activeFilters.add(type);
          }
        });
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isActive ? 1.0 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isActive ? Border.all(color: color, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isActive ? Colors.black : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Componente del Sidebar deslizable
  Widget _buildGlassmorphicSidebar(BuildContext context, List<Incident> allIncidents, List<Incident> activeIncidents) {
    final double sidebarWidth = 290.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      left: _isSidebarOpen ? 0 : -sidebarWidth,
      top: 0,
      bottom: 0,
      child: Container(
        width: sidebarWidth,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 15,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera del Sidebar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.analytics, color: AppColors.primary, size: 24),
                            const SizedBox(width: 8),
                            const Text(
                              'Estado de Zona',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onBackground,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _isSidebarOpen = false;
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 6),
                    // Resumen y contadores
                    _buildSidebarCounters(activeIncidents),
                    const SizedBox(height: 12),
                    const Text(
                      'LISTADO DE REPORTES ACTIVOS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Lista de incidentes
                    Expanded(
                      child: activeIncidents.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay reportes activos en la ciudad.',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: activeIncidents.length,
                              itemBuilder: (context, index) {
                                final incident = activeIncidents[index];
                                final double distance = Geolocator.distanceBetween(
                                  _currentLocation.latitude,
                                  _currentLocation.longitude,
                                  incident.location.latitude,
                                  incident.location.longitude,
                                );
                                return _buildSidebarCard(incident, distance);
                              },
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

  // Sub-componente de contadores por categoría
  Widget _buildSidebarCounters(List<Incident> activeIncidents) {
    int insecurity = activeIncidents.where((i) => i.type == IncidentType.insecurity).length;
    int trash = activeIncidents.where((i) => i.type == IncidentType.trash).length;
    int weeds = activeIncidents.where((i) => i.type == IncidentType.weeds).length;
    int recycling = activeIncidents.where((i) => i.type == IncidentType.recycling).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Reportes Activos:', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${activeIncidents.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCounterItem('🚨', insecurity, AppColors.secondary),
              _buildCounterItem('🗑️', trash, AppColors.neutralTrash),
              _buildCounterItem('🌿', weeds, AppColors.warning),
              _buildCounterItem('♻️', recycling, AppColors.ecoGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterItem(String emoji, int count, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count',
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 10),
          ),
        ),
      ],
    );
  }

  // Tarjeta de cada incidente en el sidebar
  Widget _buildSidebarCard(Incident incident, double distance) {
    Color color;
    String emoji;
    switch (incident.type) {
      case IncidentType.insecurity:
        color = AppColors.secondary;
        emoji = '🚨';
        break;
      case IncidentType.trash:
        color = AppColors.neutralTrash;
        emoji = '🗑️';
        break;
      case IncidentType.weeds:
        color = AppColors.warning;
        emoji = '🌿';
        break;
      case IncidentType.recycling:
        color = AppColors.ecoGreen;
        emoji = '♻️';
        break;
    }

    final bool inRange = distance <= 200;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: inRange ? color.withOpacity(0.5) : Colors.transparent, width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        dense: true,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 16)),
        ),
        title: Text(
          incident.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Row(
          children: [
            Icon(
              inRange ? Icons.radar : Icons.lock,
              size: 11,
              color: inRange ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              '${distance.toInt()}m ${inRange ? "¡Cerca!" : "Lejos"}',
              style: TextStyle(
                fontSize: 10,
                color: inRange ? AppColors.primary : Colors.grey,
                fontWeight: inRange ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            _isSidebarOpen = false;
          });
          _mapController.move(incident.location, 16.5);
          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted) {
              _showIncidentDetail(incident);
            }
          });
        },
      ),
    );
  }
}

// ==========================================
// WIDGETS AUXILIARES DENTRO DE ESTE ARCHIVO
// ==========================================

// 1. PIN DE HÉROE / UBICACIÓN DEL JUGADOR
class HeroLocationMarkerWidget extends StatefulWidget {
  final double rotation;

  const HeroLocationMarkerWidget({super.key, required this.rotation});

  @override
  State<HeroLocationMarkerWidget> createState() => _HeroLocationMarkerWidgetState();
}

class _HeroLocationMarkerWidgetState extends State<HeroLocationMarkerWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Onda de radar local del héroe
            Container(
              width: 30 + (30 * _controller.value),
              height: 30 + (30 * _controller.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.3 * (1.0 - _controller.value)),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.5 * (1.0 - _controller.value)),
                  width: 1.5,
                ),
              ),
            ),
            // Pin de Héroe (Glow Shield)
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Transform.rotate(
                angle: -widget.rotation * (math.pi / 180),
                child: const Icon(
                  Icons.shield,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            // Puntero de dirección (estilo brújula)
            Transform.rotate(
              angle: -widget.rotation * (math.pi / 180),
              child: Align(
                alignment: const Alignment(0, -1.8),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// 2. PIN DE INCIDENTES (FLOTACIÓN Y PULSACIÓN)
class PulsingMarkerWidget extends StatefulWidget {
  final Color color;
  final IconData iconData;
  final bool isWithinRange;
  final bool isActive;

  const PulsingMarkerWidget({
    super.key,
    required this.color,
    required this.iconData,
    required this.isWithinRange,
    required this.isActive,
  });

  @override
  State<PulsingMarkerWidget> createState() => _PulsingMarkerWidgetState();
}

class _PulsingMarkerWidgetState extends State<PulsingMarkerWidget> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _floatController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200 + math.Random().nextInt(800)), // flotación asíncrona!
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _floatAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    if (widget.isActive && widget.isWithinRange) {
      _pulseController.repeat();
    }
    _floatController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant PulsingMarkerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && widget.isWithinRange && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if ((!widget.isActive || !widget.isWithinRange) && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Sombra de radar pulsante de fondo
        if (widget.isActive && widget.isWithinRange)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 32 + (28 * _pulseAnimation.value),
                height: 32 + (28 * _pulseAnimation.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.35 * (1.0 - _pulseAnimation.value)),
                  border: Border.all(
                    color: widget.color.withOpacity(0.5 * (1.0 - _pulseAnimation.value)),
                    width: 1.5,
                  ),
                ),
              );
            },
          ),
        // Cuerpo flotante del marcador
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: child,
            );
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.isWithinRange ? Colors.white : Colors.grey.shade200,
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isWithinRange ? widget.color : Colors.grey.shade400,
                width: widget.isWithinRange ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.isWithinRange ? widget.color : Colors.black).withOpacity(widget.isWithinRange ? 0.35 : 0.15),
                  blurRadius: widget.isWithinRange ? 8 : 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  widget.iconData,
                  color: widget.isWithinRange ? widget.color : Colors.grey,
                  size: 20,
                ),
                if (!widget.isWithinRange && widget.isActive)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock,
                        size: 10,
                        color: Colors.grey,
                      ),
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

// 3. WIDGET DE BRÚJULA
class CompassWidget extends StatelessWidget {
  final double rotation;
  final VoidCallback onTap;

  const CompassWidget({super.key, required this.rotation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Transform.rotate(
          angle: -rotation * (math.pi / 180), // convertir grados a radianes
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.navigation, color: AppColors.secondary, size: 24),
              Positioned(
                top: 4,
                child: Text(
                  'N',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget auxiliar para el BottomSheet de descripción (sin cambios estructurales, solo estilos pulidos)
class _DescriptionInputSheet extends StatefulWidget {
  final Function(String) onSubmitted;

  const _DescriptionInputSheet({required this.onSubmitted});

  @override
  State<_DescriptionInputSheet> createState() => _DescriptionInputSheetState();
}

class _DescriptionInputSheetState extends State<_DescriptionInputSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Añade una descripción',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            maxLength: 150,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Ej. Calle sin iluminación, dos personas sospechosas...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _hasText = val.trim().isNotEmpty;
              });
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _hasText ? () => widget.onSubmitted(_controller.text) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Enviar Reporte',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
