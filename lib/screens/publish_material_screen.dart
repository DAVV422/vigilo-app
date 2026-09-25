import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../domain/entities/incident.dart';
import '../presentation/providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';

class PublishMaterialScreen extends ConsumerStatefulWidget {
  const PublishMaterialScreen({super.key});

  @override
  ConsumerState<PublishMaterialScreen> createState() => _PublishMaterialScreenState();
}

class _PublishMaterialScreenState extends ConsumerState<PublishMaterialScreen> {
  int _selectedCategoryIndex = -1;
  String _selectedTime = '';
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _kgController = TextEditingController();
  final TextEditingController _extraController = TextEditingController();

  final List<Map<String, dynamic>> _materials = [
    {'title': 'Plástico PET', 'price': '~Bs.2/kg', 'icon': Icons.local_drink},
    {'title': 'Cartón/Papel', 'price': '~Bs.0.5/kg', 'icon': Icons.inventory_2},
    {'title': 'Vidrio', 'price': '~Bs.0.2/kg', 'icon': Icons.wine_bar},
    {'title': 'Metal/Alum', 'price': '~Bs.5/kg', 'icon': Icons.delete_outline},
    {'title': 'Ropa/Textiles', 'price': 'Donación', 'icon': Icons.checkroom},
    {'title': 'Electrodom.', 'price': 'Variable', 'icon': Icons.tv},
    {'title': 'Muebles', 'price': 'Variable', 'icon': Icons.chair},
    {'title': 'Botellas', 'price': '~Bs.1/kg', 'icon': Icons.liquor},
  ];

  final List<String> _times = ['Mañana 7-12hs', 'Tarde 13-18hs', 'Flexible', 'Fines de semana', 'Con cita previa'];

  @override
  void dispose() {
    _descController.dispose();
    _kgController.dispose();
    _extraController.dispose();
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
              '¡Material publicado con éxito!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tu alerta ya es visible para los recolectores de la zona en tu ubicación actual.',
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

  Future<void> _submitPublish() async {
    if (_selectedCategoryIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecciona un tipo de material')));
      return;
    }
    if (_descController.text.isEmpty || _selectedTime.isEmpty) {
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

      final matTitle = _materials[_selectedCategoryIndex]['title'];
      final kgText = _kgController.text.isNotEmpty ? '${_kgController.text}kg - ' : '';

      final newIncident = Incident(
        id: 'mat_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Recolección: $matTitle',
        description: '$kgText${_descController.text}\nHorario: $_selectedTime\nExtra: ${_extraController.text}',
        location: LatLng(position.latitude, position.longitude),
        type: IncidentType.recycling,
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
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Publicar material',
        subtitle: 'Conecta con recolectores locales',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aviso de ubicación
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.6),
                border: Border.all(color: Colors.blue.shade100, width: 1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.my_location_rounded, color: Colors.blue.shade600, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Los recolectores verán esta alerta en tu ubicación exacta actual.',
                      style: TextStyle(color: Colors.blue.shade800, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Tipo de material *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onBackground),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _materials.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategoryIndex == index;
                final mat = _materials[index];
                return InkWell(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.white,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.shade200,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected ? AppColors.primary.withOpacity(0.04) : Colors.black.withOpacity(0.015),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            mat['icon'] as IconData,
                            size: 20,
                            color: isSelected ? AppColors.primary : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                mat['title'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.primary : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mat['price'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? AppColors.primary.withOpacity(0.8) : Colors.grey.shade500,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            _buildLabel('Descripción de cantidad *'),
            _buildTextField(controller: _descController, hint: 'Ej: 3 bolsas grandes, 8 cajas...'),
            const SizedBox(height: 20),

            _buildLabel('Kg estimados (aproximado)'),
            _buildTextField(controller: _kgController, hint: 'Ej: 5', keyboardType: TextInputType.number),
            const SizedBox(height: 24),

            const Text(
              'Horario disponible para recoger *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onBackground),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _times.map((t) {
                final isSelected = _selectedTime == t;
                return ChoiceChip(
                  label: Text(t),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedTime = selected ? t : '';
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primary.withOpacity(0.08),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            _buildTextField(controller: _extraController, hint: 'O escribe un horario específico...'),
            const SizedBox(height: 24),

            _buildLabel('Descripción adicional'),
            _buildTextField(hint: 'Ej: Material limpio y seco, separado por tipo...', maxLines: 3),
            const SizedBox(height: 28),

            // Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Qué pasa después?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onBackground),
                  ),
                  const SizedBox(height: 18),
                  _buildProcessStep('1', 'Tu alerta aparece en el mapa para los recolectores.'),
                  _buildProcessStep('2', 'Un recolector acepta "Yo lo recojo".'),
                  _buildProcessStep('3', 'El recolector pasa por tu ubicación indicada.'),
                  _buildProcessStep('4', 'Confirmas la entrega y ambos ganan puntos.'),
                ],
              ),
            ),
            const SizedBox(height: 36),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                    ),
                    onPressed: _submitPublish,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.inventory_2_outlined, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Publicar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
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
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onBackground),
      ),
    );
  }

  Widget _buildTextField({required String hint, int maxLines = 1, TextInputType? keyboardType, TextEditingController? controller}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown({required String hint, required List<String> items, String? value, void Function(String?)? onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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

  Widget _buildProcessStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
