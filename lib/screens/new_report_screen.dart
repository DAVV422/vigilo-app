import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../domain/entities/incident.dart';
import '../presentation/providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';

class NewReportScreen extends ConsumerStatefulWidget {
  const NewReportScreen({super.key});

  @override
  ConsumerState<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends ConsumerState<NewReportScreen> {
  int _selectedCategoryIndex = -1;
  String? _selectedEntity;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Baches y vías', 'icon': Icons.edit_road},
    {'title': 'Basura acumulada', 'icon': Icons.delete_outline},
    {'title': 'Luminarias dañadas', 'icon': Icons.lightbulb_outline, 'type': IncidentType.insecurity},
    {'title': 'Alcantarillas', 'icon': Icons.water_damage, 'type': IncidentType.insecurity},
    {'title': 'Áreas verdes', 'icon': Icons.park, 'type': IncidentType.weeds},
    {'title': 'Señales dañadas', 'icon': Icons.traffic, 'type': IncidentType.insecurity},
    {'title': 'Espacios inseguros', 'icon': Icons.gpp_bad, 'type': IncidentType.insecurity},
    {'title': 'Grafiti/Vandalismo', 'icon': Icons.format_paint, 'type': IncidentType.insecurity},
  ];

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              '¡Reporte enviado con éxito!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tu reporte ha sido registrado en tu ubicación actual exacta. Gracias por mejorar la ciudad.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                ),
                onPressed: () {
                  // Volver hasta la pantalla principal (mapa)
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Volver al inicio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_selectedCategoryIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecciona un tipo de problema')));
      return;
    }
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, completa los campos obligatorios (*)')));
      return;
    }

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final user = ref.read(authProvider);

      final newIncident = Incident(
        id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text,
        description: _descriptionController.text,
        location: LatLng(position.latitude, position.longitude),
        type: _categories[_selectedCategoryIndex]['type'] as IncidentType? ?? IncidentType.insecurity,
        reportedAt: DateTime.now(),
        reportedByUserId: user?.id ?? 'user1',
        validatorsIds: [],
        status: IncidentStatus.active,
      );

      await ref.read(incidentsProvider.notifier).addIncident(newIncident);
      
      // Ocultar carga
      if (mounted) Navigator.pop(context);
      _showSuccessDialog();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Nuevo reporte',
        subtitle: 'Ayuda a mejorar tu ciudad',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aviso de ubicación exacta
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.my_location, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Se utilizará automáticamente tu ubicación exacta actual para este reporte.',
                      style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('¿Qué problema reportas? *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategoryIndex == index;
                final cat = _categories[index];
                return InkWell(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                      border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300, width: isSelected ? 2 : 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Icon(cat['icon'] as IconData, size: 20, color: isSelected ? AppColors.primary : Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cat['title'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            _buildLabel('Título *'),
            _buildTextField(controller: _titleController, hint: 'Ej: Bache peligroso en Av. Banzer y 3er Anillo'),
            const SizedBox(height: 16),

            _buildLabel('Descripción *'),
            _buildTextField(controller: _descriptionController, hint: 'Describe el problema: tamaño, riesgo, hace cuánto está...', maxLines: 4),
            const SizedBox(height: 16),

            _buildLabel('Entidad responsable'),
            _buildDropdown(
              hint: 'Asignar automáticamente', 
              value: _selectedEntity,
              items: ['Asignar automáticamente', 'Alcaldía', 'CRE', 'SAGUAPAC'],
              onChanged: (val) => setState(() => _selectedEntity = val),
            ),
            const SizedBox(height: 24),

            _buildLabel('Foto de evidencia (Opcional)'),
            const SizedBox(height: 8),
            // Custom dashed-like container (since we might not have dotted_border installed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid), // using solid as fallback
              ),
              child: Column(
                children: [
                  Icon(Icons.camera_alt, color: Colors.grey.shade400, size: 40),
                  const SizedBox(height: 8),
                  Text('Tomar o subir foto', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tarjeta de recompensas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.redeem, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text('Ganas puntos', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRewardItem('Enviar reporte', '+25 pts'),
                  _buildRewardItem('Reporte validado por vecinos', '+25 pts'),
                  _buildRewardItem('Reporte resuelto', '+50 pts'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitReport,
                child: const Text('Enviar reporte', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildTextField({required String hint, int maxLines = 1, TextEditingController? controller}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildDropdown({required String hint, required List<String> items, String? value, void Function(String?)? onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildRewardItem(String text, String points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: Colors.green.shade900, fontSize: 13))),
          Text(points, style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
