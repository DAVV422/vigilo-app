// lib/presentation/widgets/alerts/create_alert_sheet.dart
import 'package:flutter/material.dart';
import '../../../domain/enums/alert_category.dart';
import '../../../theme/app_colors.dart';
import 'package:latlong2/latlong.dart';
import '../../screens/map/new_report_map_screen.dart';

class CreateAlertSheet extends StatefulWidget {
  final void Function(String title, String description, AlertCategory category) onPublish;

  const CreateAlertSheet({
    Key? key,
    required this.onPublish,
  }) : super(key: key);

  @override
  State<CreateAlertSheet> createState() => _CreateAlertSheetState();
}

class _CreateAlertSheetState extends State<CreateAlertSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  AlertCategory _selectedCategory = AlertCategory.seguridad;
  LatLng? _selectedLocation;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    widget.onPublish(title, description, _selectedCategory);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador superior
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            // Título del Modal
            const Text(
              'Reportar Nueva Alerta',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 20),

            // Selector de Categoría
            const Text(
              'Categoría',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: AlertCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                    avatar: Icon(
                      category.icon,
                      size: 16,
                      color: isSelected
                          ? category.textColor
                          : AppColors.onSurfaceVariant,
                    ),
                    selectedColor: category.backgroundColor,
                    backgroundColor: AppColors.surfaceVariant,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? category.textColor
                          : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Input: Título
            const Text(
              'Título',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Ej. Fuga de agua en la avenida principal',
                hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Input: Descripción
            const Text(
              'Descripción',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Describe con detalle lo que está sucediendo...',
                hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Selector de Ubicación
            const Text(
              'Ubicación',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                // Navigates to NewReportMapScreen and waits for the result
                final location = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewReportMapScreen(
                      initialLocation: LatLng(-17.783327, -63.182141), // Santa Cruz default
                    ),
                  ),
                );
                if (location != null && location is LatLng) {
                  setState(() {
                    _selectedLocation = location;
                  });
                }
              },
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: _selectedLocation != null ? AppColors.primary : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedLocation != null
                            ? '${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}'
                            : 'Seleccionar en el mapa',
                        style: TextStyle(
                          color: _selectedLocation != null ? AppColors.onSurface : AppColors.onSurfaceVariant,
                          fontWeight: _selectedLocation != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón Publicar Alerta
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  'Publicar Alerta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
