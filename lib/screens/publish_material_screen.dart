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
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Publicar material',
        subtitle: 'Conecta con recolectores locales',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aviso de ubicación
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
                      'Los recolectores verán esta alerta en tu ubicación exacta actual.',
                      style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Tipo de material *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green.shade50 : Colors.white,
                      border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300, width: isSelected ? 2 : 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(mat['icon'] as IconData, size: 24, color: isSelected ? Colors.green : Colors.grey.shade600),
                        const SizedBox(width: 8),
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
                                  color: isSelected ? Colors.green.shade800 : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                mat['price'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.green.shade700 : Colors.grey.shade500,
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
            const SizedBox(height: 16),

            _buildLabel('Kg estimados (aproximado)'),
            _buildTextField(controller: _kgController, hint: 'Ej: 5', keyboardType: TextInputType.number),
            const SizedBox(height: 24),

            const Text('Horario disponible para recoger *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  selectedColor: Colors.green.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.green.shade800 : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? Colors.green : Colors.grey.shade300),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            _buildTextField(controller: _extraController, hint: 'O escribe un horario específico...'),
            const SizedBox(height: 24),

            _buildLabel('Descripción adicional'),
            _buildTextField(hint: 'Ej: Material limpio y seco, separado por tipo...', maxLines: 3),
            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('¿Qué pasa después?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 16),
                  _buildProcessStep('1', 'Tu alerta aparece en el mapa para los recolectores.'),
                  _buildProcessStep('2', 'Un recolector acepta "Yo lo recojo".'),
                  _buildProcessStep('3', 'El recolector pasa por tu ubicación indicada.'),
                  _buildProcessStep('4', 'Confirmas la entrega y ambos ganan puntos.'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submitPublish,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.inventory_2, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Publicar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number, style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
