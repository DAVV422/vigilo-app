import 'package:flutter/material.dart';
import '../domain/entities/incident.dart';
import '../theme/app_colors.dart';

class FilterBottomSheet extends StatefulWidget {
  final Set<IncidentType> initialTypes;
  final Set<String> initialSeverities;
  final Set<String> initialStatuses;
  final Function(Set<IncidentType> types, Set<String> severities, Set<String> statuses) onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialTypes,
    required this.initialSeverities,
    required this.initialStatuses,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Set<IncidentType> _selectedTypes;
  late Set<String> _selectedSeverities;
  late Set<String> _selectedStatuses;

  @override
  void initState() {
    super.initState();
    _selectedTypes = Set.from(widget.initialTypes);
    _selectedSeverities = Set.from(widget.initialSeverities);
    _selectedStatuses = Set.from(widget.initialStatuses);
  }

  void _clearFilters() {
    setState(() {
      // By user spec, they don't want a "Select All" button but asked to initially select all.
      // A "Clear" might mean deselect all, or reset to all. Let's reset to all as "clear filters" means "show everything".
      _selectedTypes = {IncidentType.insecurity, IncidentType.trash, IncidentType.weeds, IncidentType.recycling};
      _selectedSeverities = {'Baja', 'Media', 'Alta', 'Crítica'};
      _selectedStatuses = {'Recibido', 'En revisión', 'En gestión', 'Rechazado', 'Vencido'};
    });
  }

  void _applyFilters() {
    widget.onApply(_selectedTypes, _selectedSeverities, _selectedStatuses);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12.0, bottom: 16.0),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            
            // 2. Cabecera del Modal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtrar reportes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.grey.shade600, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nueva Sección: TIPO DE REPORTE
                    _buildSectionLabel('TIPO DE REPORTE'),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 3.5,
                      children: [
                        _buildTypeButton(IncidentType.insecurity, 'Inseguridad', Icons.security),
                        _buildTypeButton(IncidentType.trash, 'Basura', Icons.delete_outline),
                        _buildTypeButton(IncidentType.weeds, 'Maleza', Icons.grass),
                        _buildTypeButton(IncidentType.recycling, 'Reciclaje', Icons.recycling),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 3. Sección 1: Filtro de SEVERIDAD
                    _buildSectionLabel('SEVERIDAD'),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 3.5,
                      children: [
                        _buildSeverityButton('Baja', const Color(0xFF4CAF50)),
                        _buildSeverityButton('Media', Colors.orange),
                        _buildSeverityButton('Alta', const Color(0xFFE57373)),
                        _buildSeverityButton('Crítica', const Color(0xFFD32F2F)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 4. Sección 2: Filtro de ESTADO
                    _buildSectionLabel('ESTADO'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        _buildStatusChip('Recibido'),
                        _buildStatusChip('En revisión'),
                        _buildStatusChip('En gestión'),
                        _buildStatusChip('Rechazado'),
                        _buildStatusChip('Vencido'),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // 5. Sección de Botones de Acción (Footer)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _clearFilters,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Limpiar filtros',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, // Verde esmeralda en el tema original
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Ver reportes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTypeButton(IncidentType type, String label, IconData icon) {
    final isSelected = _selectedTypes.contains(type);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedTypes.remove(type);
          } else {
            _selectedTypes.add(type);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                size: 16, 
                color: isSelected ? AppColors.primary : Colors.grey.shade800
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.grey.shade800,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityButton(String severity, Color dotColor) {
    final isSelected = _selectedSeverities.contains(severity);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedSeverities.remove(severity);
          } else {
            _selectedSeverities.add(severity);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isSelected) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              severity,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey.shade800,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final isSelected = _selectedStatuses.contains(status);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedStatuses.remove(status);
          } else {
            _selectedStatuses.add(status);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(30.0),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
