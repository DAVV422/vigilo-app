import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
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

class _HomeMapScreenState extends ConsumerState<HomeMapScreen> {
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(
    -17.783327,
    -63.182141,
  ); // Default Santa Cruz
  bool _isLocating = true;

  // Flujo de creación de reporte
  bool _isSelectingLocation = false;
  IncidentType? _selectedTypeForReport;

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
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _isLocating = false;
    });

    _mapController.move(_currentLocation, 16.0);
  }

  void _showIncidentDetail(Incident incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncidentDetailModal(incident: incident),
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

    // Solo procedemos si el usuario no cerró el modal y sí ingresó texto
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

      setState(() {
        _isSelectingLocation = false;
        _selectedTypeForReport = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte creado exitosamente.')),
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

    List<Marker> markers = incidents.map((incident) {
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

      return Marker(
        point: incident.location,
        width: 40,
        height: 40,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: _isSelectingLocation
              ? null
              : () => _showIncidentDetail(incident),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
        ),
      );
    }).toList();

    if (!_isLocating) {
      markers.add(
        Marker(
          point: _currentLocation,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 6, 49, 239),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vigilo.app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),

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

          if (!_isSelectingLocation)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Inseguridad', AppColors.secondary),
                      const SizedBox(width: 8),
                      _buildFilterChip('Basura', AppColors.neutralTrash),
                      const SizedBox(width: 8),
                      _buildFilterChip('Maleza', AppColors.warning),
                      const SizedBox(width: 8),
                      _buildFilterChip('Reciclaje', AppColors.ecoGreen),
                    ],
                  ),
                ),
              ),
            ),
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

  Widget _buildFilterChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Widget auxiliar para el BottomSheet de descripción
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
    // Permite que el modal suba junto con el teclado usando ViewInsets
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
              hintText:
                  'Ej. Calle sin iluminación, dos personas sospechosas...',
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
            onPressed: _hasText
                ? () => widget.onSubmitted(_controller.text)
                : null,
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
