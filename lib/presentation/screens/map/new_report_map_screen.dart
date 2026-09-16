import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../theme/app_colors.dart';
import '../../widgets/map/location_confirmation_sheet.dart';

class NewReportMapScreen extends StatefulWidget {
  final LatLng initialLocation;

  const NewReportMapScreen({super.key, required this.initialLocation});

  @override
  State<NewReportMapScreen> createState() => _NewReportMapScreenState();
}

class _NewReportMapScreenState extends State<NewReportMapScreen> {
  late final MapController _mapController;
  late LatLng _currentCenter;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentCenter = widget.initialLocation;
  }

  void _onMapPositionChanged(MapCamera position, bool hasGesture) {
    setState(() {
      _currentCenter = position.center;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Seleccionar ubicación',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. Mapa interactivo
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 16.0,
              onPositionChanged: _onMapPositionChanged,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vigilo.app',
              ),
            ],
          ),

          // 2. Pin estático en el centro (Drop Pin)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.0), // Ajuste visual para que la punta toque el centro
              child: Icon(
                Icons.location_on,
                size: 50,
                color: AppColors.primary,
              ),
            ),
          ),

          // 3. Panel Inferior
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LocationConfirmationSheet(
              addressText: 'Ubicación seleccionada en el mapa.\nCoordenadas: ${_currentCenter.latitude.toStringAsFixed(4)}, ${_currentCenter.longitude.toStringAsFixed(4)}',
              onConfirm: () {
                Navigator.pop(context, _currentCenter);
              },
            ),
          ),
        ],
      ),
    );
  }
}
