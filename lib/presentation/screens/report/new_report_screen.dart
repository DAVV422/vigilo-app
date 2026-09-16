import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../domain/entities/incident.dart';
import '../../providers/providers.dart';
import '../../../theme/app_colors.dart';
import '../map/new_report_map_screen.dart';

class NewReportScreen extends ConsumerStatefulWidget {
  const NewReportScreen({super.key});

  @override
  ConsumerState<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends ConsumerState<NewReportScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  LatLng? _selectedLocation;
  String _locationText = 'Av. Insurgentes Sur 123'; // Default to match image
  List<XFile> _selectedImages = [];

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles);
        if (_selectedImages.length > 5) {
          _selectedImages = _selectedImages.sublist(0, 5);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Puedes subir hasta 5 fotos como máximo.')),
          );
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchInitialLocation();
  }

  Future<void> _fetchInitialLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Ignore
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.check_circle, color: AppColors.primary, size: 64),
            const SizedBox(height: 16),
            const Text(
              '¡Reporte enviado con éxito!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Volver al inicio', style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa los campos obligatorios (*)'), backgroundColor: AppColors.error),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );

      final user = ref.read(authProvider);

      final newIncident = Incident(
        id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text,
        description: _descriptionController.text,
        location: _selectedLocation ?? const LatLng(-17.7833, -63.1821),
        type: IncidentType.weeds, // Or whatever maps to Urbano
        reportedAt: DateTime.now(),
        reportedByUserId: user?.id ?? 'user1',
        validatorsIds: [],
        status: IncidentStatus.active,
      );

      await ref.read(incidentsProvider.notifier).addIncident(newIncident);
      
      if (mounted) Navigator.pop(context);
      _showSuccessDialog();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar: $e')));
    }
  }

  void _openMapPicker() async {
    final initialLocation = _selectedLocation ?? const LatLng(-17.783327, -63.182141);
    final location = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewReportMapScreen(initialLocation: initialLocation),
      ),
    );

    if (location != null && location is LatLng && mounted) {
      setState(() {
        _selectedLocation = location;
        _locationText = '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nuevo Reporte Urbano',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Evidencia
            _buildLabel('EVIDENCIA (OPCIONAL)'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceContainerHigh),
              ),
              child: _selectedImages.isEmpty
                  ? Column(
                      children: [
                        InkWell(
                          onTap: _pickImages,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.add_a_photo_outlined,
                              color: AppColors.onPrimary,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Subir Foto/Video',
                          style: TextStyle(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Añade una foto o video del incidente (Máx 5)',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ..._selectedImages.map((file) => Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(file.path),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedImages.remove(file);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                          if (_selectedImages.length < 5)
                            InkWell(
                              onTap: _pickImages,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.outlineVariant),
                                ),
                                child: const Icon(Icons.add, color: AppColors.onSurfaceVariant, size: 32),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // Inputs
            _buildLabel('TÍTULO DEL REPORTE *'),
            _buildTextField(
              controller: _titleController,
              hint: 'Ej. Bache profundo en Av. Principal',
            ),
            const SizedBox(height: 20),

            _buildLabel('DESCRIPCIÓN *'),
            _buildTextField(
              controller: _descriptionController,
              hint: 'Describe brevemente la situación, el\nimpacto o cualquier detalle relevante...',
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            // Indicador de Ubicación
            _buildLabel('UBICACIÓN *'),
            InkWell(
              onTap: _openMapPicker,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AbsorbPointer(
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: _selectedLocation ?? const LatLng(-17.783327, -63.182141),
                            initialZoom: 15.0,
                            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.vigilo',
                            ),
                            if (_selectedLocation != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _selectedLocation!,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_on, color: AppColors.error, size: 40),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Container(color: Colors.black.withValues(alpha: 0.1)),
                      // Centered pill
                      Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.my_location, color: AppColors.primary, size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'Usar mi ubicación actual',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Address bar at bottom
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: AppColors.onSurfaceVariant, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _locationText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

            // Botón de Acción (Submit)
            SizedBox(
              width: double.infinity,
              height: 54, // Tap target
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                ),
                onPressed: _submitReport,
                icon: const Icon(Icons.send, size: 18),
                label: const Text(
                  'ENVIAR REPORTE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: AppColors.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    int maxLines = 1,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.outline, fontSize: 14),
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant.withOpacity(0.3)
      ..strokeWidth = 1;
    
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
