import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/entities/incident.dart';
import '../../../domain/entities/user.dart';
import '../../providers/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/widgets.dart';
import '../../widgets/report/report_modal_dialog.dart';
import '../report/new_report_screen.dart';
import '../../../screens/publish_material_screen.dart';
import '../../../widgets/report_bottom_sheet.dart';
import '../../../widgets/incident_detail_modal.dart';
import '../../../screens/store_screen.dart';
import '../../../screens/points_screen.dart';
import '../alerts/confirm_alerts_screen.dart';
import '../../../screens/kpi_screen.dart';
import '../../../screens/impact_screen.dart';
import '../../../screens/collections_screen.dart';
import '../../widgets/map/map_alert_summary_sheet.dart';
import '../../../widgets/main_app_bar.dart';
import '../../../theme/app_icons.dart';

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
  Set<IncidentType> _activeTypes = {
    IncidentType.insecurity,
    IncidentType.trash,
    IncidentType.weeds,
    IncidentType.recycling,
  };
  Set<String> _activeSeverities = {'Baja', 'Media', 'Alta', 'Crítica'};
  Set<String> _activeStatuses = {'Recibido', 'En revisión', 'En gestión', 'Rechazado', 'Vencido'};

  bool _isFilterViewActive = false;
  String _selectedMainFilter = 'Todos';
  String _selectedSubFilter = '';

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: Colors.grey.shade200),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

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
  }

  void _showIncidentDetail(Incident incident) {
    final distance = Geolocator.distanceBetween(
      _currentLocation.latitude,
      _currentLocation.longitude,
      incident.location.latitude,
      incident.location.longitude,
    );
    final distanceText = distance < 1000
        ? '${distance.toInt()} m'
        : '${(distance / 1000).toStringAsFixed(1)} km';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MapAlertSummarySheet(
        incident: incident,
        distanceText: distanceText,
      ),
    );
  }

  void _startReportFlow() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ReportModalDialog(),
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
    final user = ref.watch(authProvider);
    final proximityIncidents = ref.watch(proximityNotifierProvider);

    final incidents = ref.watch(incidentsProvider);
    final activeIncidents = incidents.where((i) => i.status == IncidentStatus.active).toList();

    // Marcadores de incidentes filtrados
    final filteredIncidents = incidents.where((incident) {
      if (!_activeTypes.contains(incident.type)) return false;

      String incidentSeverity;
      switch (incident.type) {
        case IncidentType.insecurity:
          incidentSeverity = 'Crítica';
          break;
        case IncidentType.trash:
          incidentSeverity = 'Alta';
          break;
        case IncidentType.weeds:
          incidentSeverity = 'Media';
          break;
        case IncidentType.recycling:
          incidentSeverity = 'Baja';
          break;
      }
      if (!_activeSeverities.contains(incidentSeverity)) return false;

      // Ocultar siempre los reportes resueltos
      if (incident.status == IncidentStatus.resolved) return false;

      bool hasActiveStatusSelected = _activeStatuses.contains('Recibido') ||
          _activeStatuses.contains('En revisión') ||
          _activeStatuses.contains('En gestión');
          
      if (!hasActiveStatusSelected) return false;

      return true;
    }).toList();

    List<Marker> markers = filteredIncidents.map((incident) {
      Color iconColor;
      IconData iconData;

      switch (incident.type) {
        case IncidentType.insecurity:
          iconColor = AppColors.error;
          iconData = Icons.warning;
          break;
        case IncidentType.trash:
          iconColor = AppColors.secondary;
          iconData = Icons.delete;
          break;
        case IncidentType.weeds:
          iconColor = AppColors.tertiary;
          iconData = Icons.grass;
          break;
        case IncidentType.recycling:
          iconColor = AppColors.primary;
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

    final userName = user?.name ?? 'Carlos Mendoza';
    final userInitials = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'C';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MainAppBar(title: 'Vigilo'),
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
              onMapReady: () {
                _mapController.move(_currentLocation, 16.0);
              },
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

          // OVERLAYS Y ESTADOS
          if (!_isSelectingLocation)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: !_isFilterViewActive
                  ? Stack(
                      key: const ValueKey('state1'),
                      children: [
                        Positioned(
                          left: 16,
                          top: 16,
                          child: FloatingActionButton(
                            mini: true,
                            heroTag: 'menu_sidebar_btn',
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onPressed: () {
                              setState(() {
                                _isSidebarOpen = true;
                              });
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(AppIcons.menu, size: 24),
                                if (activeIncidents.isNotEmpty)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${activeIncidents.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 16,
                          top: 16,
                          child: FloatingActionButton(
                            mini: true,
                            heroTag: 'filter_btn_state1',
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onPressed: () {
                              setState(() {
                                _isFilterViewActive = true;
                              });
                            },
                            child: const Icon(AppIcons.tune),
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      key: const ValueKey('state2'),
                      children: [
                        // State 2: Filter/Report View Overlays
                        Positioned(
                          top: 16,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              // Barra de búsqueda y botón de filtro
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            const SizedBox(width: 16),
                                            Icon(AppIcons.search, color: Colors.grey.shade600),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Buscar en el mapa...',
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      height: 52,
                                      width: 52,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(AppIcons.tune, color: AppColors.primary),
                                        onPressed: () {
                                          setState(() {
                                            _isFilterViewActive = false; // Volver al mapa
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Chips Row
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  children: [
                                    _buildFilterChip('Todos', _selectedMainFilter == 'Todos', () {
                                      setState(() {
                                        _selectedMainFilter = 'Todos';
                                      });
                                    }),
                                    const SizedBox(width: 12),
                                    _buildFilterChip('Reportes', _selectedMainFilter == 'Reportes', () {
                                      setState(() {
                                        _selectedMainFilter = 'Reportes';
                                      });
                                    }),
                                    const SizedBox(width: 12),
                                    _buildFilterChip('Reciclaje', _selectedMainFilter == 'Reciclaje', () {
                                      setState(() {
                                        _selectedMainFilter = 'Reciclaje';
                                      });
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
            
          // Proximity Alert Overlay (Placed after controls so it renders on top)
          if (proximityIncidents.isNotEmpty && !_isSelectingLocation)
            Positioned(
              bottom: 90, // Right above the REPORTAR FAB, covering the compass and walk controls
              left: 0,
              right: 0,
              child: ProximityAlertOverlay(
                key: ValueKey(proximityIncidents.first.id),
                incident: proximityIncidents.first,
                onDismiss: () {
                  ref.read(proximityNotifierProvider.notifier).dismissAlert(proximityIncidents.first.id);
                },
                onConfirm: () {
                  ref.read(incidentsProvider.notifier).validateIncident(proximityIncidents.first.id, user?.id ?? 'u1');
                  ref.read(proximityNotifierProvider.notifier).permanentlyDismissAlert(proximityIncidents.first.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gracias por confirmar')));
                },
                onReject: () {
                  ref.read(incidentsProvider.notifier).resolveIncident(
                    incidentId: proximityIncidents.first.id, 
                    userId: user?.id ?? 'u1', 
                    companyId: 'none', 
                    companyName: 'Usuario', 
                    comment: 'El usuario indicó que ya no está.'
                  );
                  ref.read(proximityNotifierProvider.notifier).permanentlyDismissAlert(proximityIncidents.first.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gracias por el reporte')));
                },
              ),
            ),

          // 6. OVERLAY OSCURO PARA CERRAR SIDEBAR
          if (_isSidebarOpen)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isSidebarOpen = false;
                });
              },
              child: Container(
                color: Colors.black54,
              ),
            ),

          // 7. LA BARRA LATERAL DESLIZANTE (GLASSMORPHIC SIDEBAR)
          _buildGlassmorphicSidebar(context, incidents, activeIncidents),
        ],
      ),
      floatingActionButton: _isSidebarOpen
          ? null
          : _isSelectingLocation
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                FloatingActionButton.extended(
                  heroTag: 'cancel_report_btn',
                  onPressed: () {
                    setState(() {
                      _isSelectingLocation = false;
                      _selectedTypeForReport = null;
                    });
                  },
                  backgroundColor: Colors.white,
                  icon: const Icon(Icons.close, color: Colors.grey),
                  label: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.extended(
                  heroTag: 'confirm_report_btn',
                  onPressed: _promptForDescription,
                  backgroundColor: AppColors.primaryContainer,
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    'Confirmar Ubicación',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            )
          : ElevatedButton.icon(
                  onPressed: _startReportFlow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D25), // Dark green as seen in first image
                    foregroundColor: Colors.white,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(AppIcons.addLocationAlt, color: Colors.white),
                  label: const Text(
                    'REPORTAR',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2),
                  ),
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }



  // Componente del Sidebar deslizable
  Widget _buildGlassmorphicSidebar(BuildContext context, List<Incident> allIncidents, List<Incident> activeIncidents) {
    final double sidebarWidth = MediaQuery.of(context).size.width * 0.75;
    final user = ref.watch(authProvider);
    final userName = user?.name ?? 'Carlos Mendoza';
    final userInitials = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'C';
    final userPoints = user?.points ?? 350;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      left: _isSidebarOpen ? 0 : -sidebarWidth,
      top: 0,
      bottom: 0,
      child: Container(
        width: sidebarWidth,
        decoration: BoxDecoration(
          color: Colors.white, // Modo Claro
          boxShadow: [
            if (_isSidebarOpen)
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(4, 0),
              ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 2. Cabecera (Header)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 16, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset('assets/app_icon.jpg', fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VIGILO',
                              style: TextStyle(
                                color: AppColors.onBackground,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'Tu ciudad, tu guardia',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isSidebarOpen = false;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.black87, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.grey.shade200, height: 1, thickness: 1),
              
              // 3. Cuerpo de Navegación (Opciones del Menú)
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    _buildDrawerItem(Icons.notifications_none, 'Notificaciones', () {
                      setState(() {
                        _isSidebarOpen = false;
                      });
                      Future.delayed(const Duration(milliseconds: 250), () {
                        if (mounted) {
                          ref.read(currentNavIndexProvider.notifier).setIndex(1);
                        }
                      });
                    }),
                    _buildDrawerItem(Icons.bar_chart, 'KPIs de Gestión', () {
                      setState(() {
                        _isSidebarOpen = false;
                      });
                      Future.delayed(const Duration(milliseconds: 250), () {
                        if (mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const KpiScreen()));
                        }
                      });
                    }),
                    _buildDrawerItem(Icons.trending_up, 'Impacto Ciudad', () {
                      setState(() {
                        _isSidebarOpen = false;
                      });
                      Future.delayed(const Duration(milliseconds: 250), () {
                        if (mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ImpactScreen()));
                        }
                      });
                    }),
                    _buildDrawerItem(Icons.shopping_bag_outlined, 'Marketplace', () {
                      setState(() {
                        _isSidebarOpen = false;
                      });
                      Future.delayed(const Duration(milliseconds: 250), () {
                        if (mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen()));
                        }
                      });
                    }),
                    _buildDrawerItem(Icons.star_border, 'Mis Puntos', () {
                      setState(() {
                        _isSidebarOpen = false;
                      });
                      Future.delayed(const Duration(milliseconds: 250), () {
                        if (mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsScreen()));
                        }
                      });
                    }),
                    _buildDrawerItem(Icons.recycling, 'Mis Recolecciones', () {
                      setState(() {
                        _isSidebarOpen = false;
                      });
                      Future.delayed(const Duration(milliseconds: 250), () {
                        if (mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectionsScreen()));
                        }
                      });
                    }),
                  ],
                ),
              ),

              // 4. Pie de página (Perfil de Usuario)
              Divider(color: Colors.grey.shade200, height: 1, thickness: 1),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        userInitials,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: AppColors.onBackground,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$userPoints puntos',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        leading: Icon(icon, color: Colors.grey.shade600, size: 24),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.onBackground,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
        onTap: onTap,
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
class PinPainter extends CustomPainter {
  final Color color;
  final Color fillColor;
  final bool hasShadow;
  final Color shadowColor;

  PinPainter({
    required this.color,
    required this.fillColor,
    this.hasShadow = true,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final path = Path();
    final radius = size.width / 2;
    final center = Offset(size.width / 2, radius);

    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
    );

    path.lineTo(size.width / 2, size.height);
    path.close();

    if (hasShadow) {
      canvas.drawShadow(path, shadowColor, 4.0, true);
    }
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant PinPainter oldDelegate) =>
      color != oldDelegate.color ||
      fillColor != oldDelegate.fillColor ||
      shadowColor != oldDelegate.shadowColor;
}

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
          child: SizedBox(
            width: 36,
            height: 48,
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: const Size(36, 48),
                  painter: PinPainter(
                    color: widget.isWithinRange ? widget.color : Colors.grey.shade400,
                    fillColor: widget.isWithinRange ? Colors.white : Colors.grey.shade200,
                    shadowColor: widget.isWithinRange ? widget.color : Colors.black,
                  ),
                ),
                Positioned(
                  top: 9,
                  child: Icon(
                    widget.iconData,
                    color: widget.isWithinRange ? widget.color : Colors.grey,
                    size: 18,
                  ),
                ),
                if (!widget.isWithinRange && widget.isActive)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
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
