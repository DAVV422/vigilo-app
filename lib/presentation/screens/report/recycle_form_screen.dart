import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_colors.dart';
import '../../../domain/entities/incident.dart';
import '../../providers/providers.dart';

class RecycleFormScreen extends ConsumerStatefulWidget {
  const RecycleFormScreen({super.key});

  @override
  ConsumerState<RecycleFormScreen> createState() => _RecycleFormScreenState();
}

class _RecycleFormScreenState extends ConsumerState<RecycleFormScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
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

  String _selectedMaterial = 'Plástico';
  String _selectedUnit = 'Bolsas';
  String _selectedTimeSlot = 'Mañana';

  final List<Map<String, dynamic>> _materials = const [
    {'name': 'Plástico', 'icon': Icons.recycling},
    {'name': 'Cartón', 'icon': Icons.inventory_2_outlined},
    {'name': 'Vidrio', 'icon': Icons.local_drink_outlined},
    {'name': 'Metal', 'icon': Icons.hardware_outlined},
  ];

  final List<String> _units = const ['Bolsas', 'Kg', 'Cajas'];

  final List<Map<String, dynamic>> _timeSlots = const [
    {'name': 'Mañana', 'icon': Icons.light_mode_outlined},
    {'name': 'Tarde', 'icon': Icons.wb_twilight_outlined},
    {'name': 'Noche', 'icon': Icons.dark_mode_outlined},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
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
              '¡Publicado con éxito!',
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

  Future<void> _submitForm() async {
    if (_descriptionController.text.isEmpty || _quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa los campos'), backgroundColor: AppColors.error),
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
      
      LatLng finalLocation = const LatLng(-17.7833, -63.1821);
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
        );
        finalLocation = LatLng(position.latitude, position.longitude);
      } catch (e) {
        // Ignore fallback
      }

      final newIncident = Incident(
        id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Reciclaje: $_selectedMaterial (${_quantityController.text} $_selectedUnit)',
        description: _descriptionController.text,
        location: finalLocation,
        type: IncidentType.recycling,
        reportedAt: DateTime.now(),
        reportedByUserId: user?.id ?? 'user1',
        validatorsIds: [],
        status: IncidentStatus.active,
      );

      await ref.read(incidentsProvider.notifier).addIncident(newIncident);
      
      if (mounted) Navigator.pop(context);
      _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
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
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.onSurface, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Publicar Reciclaje',
          style: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // EVIDENCIA
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
                          'Sube evidencia del material (Máx 5)',
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

            // DESCRIPCIÓN
            _buildLabel('Descripción'),
            _buildTextField(
              controller: _descriptionController,
              hint: 'Describe los materiales, estado, y detalles\nadicionales...',
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // TIPO DE MATERIAL
            _buildLabel('Tipo de Material'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _materials.length,
              itemBuilder: (context, index) {
                final material = _materials[index];
                final isSelected = _selectedMaterial == material['name'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedMaterial = material['name'];
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.surfaceContainerHighest,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          material['icon'],
                          color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          material['name'],
                          style: TextStyle(
                            color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // CANTIDAD ESTIMADA
            _buildLabel('Cantidad Estimada'),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _quantityController,
                    hint: 'Ej. 5',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      border: Border.all(color: AppColors.outlineVariant),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedUnit,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.onSurfaceVariant),
                        items: _units.map((String unit) {
                          return DropdownMenuItem<String>(
                            value: unit,
                            child: Text(
                              unit,
                              style: const TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedUnit = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // DISPONIBILIDAD DE RECOJO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('Disponibilidad de Recojo'),
                const Text(
                  'Hoy',
                  style: TextStyle(
                    color: Colors.blue, // Using a blue accent to match image
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Row(
              children: _timeSlots.map((slot) {
                final isSelected = _selectedTimeSlot == slot['name'];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: slot == _timeSlots.last ? 0 : 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedTimeSlot = slot['name'];
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.surfaceContainerHighest,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              slot['icon'],
                              color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              slot['name'],
                              style: TextStyle(
                                color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // BOTÓN DE ACCIÓN
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
                onPressed: _submitForm,
                icon: const Icon(Icons.send, size: 18),
                label: const Text(
                  'Publicar Reciclaje',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
          letterSpacing: 1.1,
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
