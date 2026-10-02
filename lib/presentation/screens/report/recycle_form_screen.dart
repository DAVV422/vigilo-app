import 'dart:io';
import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_exception.dart';
import '../../../theme/app_colors.dart';
import '../../../domain/entities/material_type.dart';
import '../../../domain/entities/recycling_listing.dart';
import '../../../domain/repositories/recycling_repository.dart';
import '../../providers/providers.dart';

/// Publica una [RecyclingListing] real contra el backend. Reemplaza la
/// versión anterior, que construía un `Incident` genérico de tipo
/// `recycling` — el reciclaje ya no vive ahí (ver docs/decisiones.md #005):
/// es su propio recurso, con catálogo de materiales real, peso en gramos y
/// ventanas de disponibilidad por día de la semana.
class RecycleFormScreen extends ConsumerStatefulWidget {
  const RecycleFormScreen({super.key});

  @override
  ConsumerState<RecycleFormScreen> createState() => _RecycleFormScreenState();
}

class _WeekDay {
  final int index; // 0=domingo .. 6=sábado, como lo espera el backend
  final String label;
  const _WeekDay(this.index, this.label);
}

class _TimeSlot {
  final String label;
  final IconData icon;
  final String start;
  final String end;
  const _TimeSlot(this.label, this.icon, this.start, this.end);
}

class _RecycleFormScreenState extends ConsumerState<RecycleFormScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  XFile? _selectedImage;
  bool _isSubmitting = false;

  List<MaterialType> _materials = [];
  bool _loadingMaterials = true;
  String? _materialsError;
  MaterialType? _selectedMaterial;

  static const _weekDays = [
    _WeekDay(1, 'Lun'),
    _WeekDay(2, 'Mar'),
    _WeekDay(3, 'Mié'),
    _WeekDay(4, 'Jue'),
    _WeekDay(5, 'Vie'),
    _WeekDay(6, 'Sáb'),
    _WeekDay(0, 'Dom'),
  ];
  int _selectedDay = DateTime.now().weekday % 7;

  static const _timeSlots = [
    _TimeSlot('Mañana', Icons.light_mode_outlined, '07:00:00', '12:00:00'),
    _TimeSlot('Tarde', Icons.wb_twilight_outlined, '12:00:00', '18:00:00'),
    _TimeSlot('Noche', Icons.dark_mode_outlined, '18:00:00', '21:00:00'),
  ];
  _TimeSlot _selectedSlot = _timeSlots.first;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    try {
      final materials = await ref.read(recyclingRepositoryProvider).getMaterials();
      if (!mounted) return;
      setState(() {
        _materials = materials;
        _selectedMaterial = materials.isNotEmpty ? materials.first : null;
        _loadingMaterials = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _materialsError = e is ApiException
            ? e.message
            : 'No se pudo cargar el catálogo de materiales.';
        _loadingMaterials = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _selectedImage = picked);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Icon(Icons.check_circle, color: AppColors.primary, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Publicación creada',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Un reciclador cercano podrá verla y coordinar el recojo contigo.',
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Volver al inicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_addressController.text.trim().isEmpty) {
      _showError('Indica la dirección del punto de recojo.');
      return;
    }
    final weightKg = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (weightKg == null || weightKg <= 0) {
      _showError('Ingresa un peso estimado válido en kilogramos.');
      return;
    }
    if (_selectedMaterial == null) {
      _showError('Selecciona un tipo de material.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      double latitude = -17.7833;
      double longitude = -63.1821;
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        latitude = position.latitude;
        longitude = position.longitude;
      } catch (_) {
        // Sin permiso de ubicación: se publica con el centro por defecto.
      }

      String? photoMediaId;
      if (_selectedImage != null) {
        final uploaded = await ref
            .read(mediaRepositoryProvider)
            .uploadImage(_selectedImage!.path, folder: 'listings');
        photoMediaId = uploaded.id;
      }

      await ref.read(recyclingRepositoryProvider).createListing(
        address: _addressController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        photoMediaId: photoMediaId,
        materials: [
          MaterialWeightInput(
            materialTypeId: _selectedMaterial!.id,
            estimatedWeightGrams: weightKg * 1000,
          ),
        ],
        availabilityWindows: [
          RecyclingAvailabilityWindow(
            dayOfWeek: _selectedDay,
            startTime: _selectedSlot.start,
            endTime: _selectedSlot.end,
          ),
        ],
      );

      if (mounted) _showSuccessDialog();
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : 'No se pudo publicar. Revisa tu conexión e intenta de nuevo.';
      _showError(message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar material reciclable')),
      body: _loadingMaterials
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _materialsError != null
              ? _buildError(_materialsError!)
              : _buildForm(),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: AppColors.outline, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _loadingMaterials = true;
                  _materialsError = null;
                });
                _loadMaterials();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Evidencia (opcional)'),
          _buildPhotoPicker(),
          const SizedBox(height: 24),

          _sectionLabel('Dirección de recojo'),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(hintText: 'Ej. Av. Las Begonias 450, Dpto 302'),
          ),
          const SizedBox(height: 20),

          _sectionLabel('Notas adicionales (opcional)'),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Describe el estado del material, referencias de acceso...'),
          ),
          const SizedBox(height: 20),

          _sectionLabel('Tipo de material'),
          _buildMaterialSelector(),
          const SizedBox(height: 20),

          _sectionLabel('Peso estimado'),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'Ej. 3.5', suffixText: 'kg'),
          ),
          const SizedBox(height: 20),

          _sectionLabel('Disponibilidad de recojo'),
          _buildDayPicker(),
          const SizedBox(height: 12),
          _buildTimeSlotPicker(),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitForm,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_outlined, size: 18),
              label: Text(_isSubmitting ? 'Publicando...' : 'Publicar'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.onSurface,
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    if (_selectedImage == null) {
      return InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: const Column(
            children: [
              Icon(Icons.add_a_photo_outlined, color: AppColors.onSurfaceVariant, size: 28),
              SizedBox(height: 8),
              Text('Agregar una foto', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(File(_selectedImage!.path), width: double.infinity, height: 160, fit: BoxFit.cover),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: () => setState(() => _selectedImage = null),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _materials.map((material) {
        final isSelected = _selectedMaterial?.id == material.id;
        return ChoiceChip(
          label: Text(material.name),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedMaterial = material),
        );
      }).toList(),
    );
  }

  Widget _buildDayPicker() {
    return Row(
      children: _weekDays.map((day) {
        final isSelected = _selectedDay == day.index;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => setState(() => _selectedDay = day.index),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.outlineVariant),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  day.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeSlotPicker() {
    return Row(
      children: _timeSlots.map((slot) {
        final isSelected = _selectedSlot.label == slot.label;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: slot == _timeSlots.last ? 0 : 8.0),
            child: InkWell(
              onTap: () => setState(() => _selectedSlot = slot),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.outlineVariant),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Icon(slot.icon, size: 20, color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant),
                    const SizedBox(height: 4),
                    Text(
                      slot.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
