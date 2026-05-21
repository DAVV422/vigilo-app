import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../domain/entities/incident.dart';

class ReportBottomSheet extends StatelessWidget {
  final Function(IncidentType) onTypeSelected;

  const ReportBottomSheet({super.key, required this.onTypeSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('¿Qué deseas reportar?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildReportOption(context, Icons.warning, 'Inseguridad', AppColors.secondary, IncidentType.insecurity),
              _buildReportOption(context, Icons.delete, 'Basura', AppColors.neutralTrash, IncidentType.trash),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildReportOption(context, Icons.grass, 'Maleza', AppColors.warning, IncidentType.weeds),
              _buildReportOption(context, Icons.recycling, 'Reciclaje', AppColors.ecoGreen, IncidentType.recycling),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildReportOption(BuildContext context, IconData icon, String label, Color color, IncidentType type) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTypeSelected(type);
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
