// lib/presentation/widgets/profile/performance_chart.dart
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class PerformanceChart extends StatelessWidget {
  const PerformanceChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Métricas Resumen
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                label: 'Reportados',
                value: '24',
                valueColor: AppColors.secondary,
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
              _buildMetricItem(
                label: 'Resueltos',
                value: '18',
                valueColor: AppColors.primary,
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
              _buildMetricItem(
                label: 'Eficiencia',
                value: '75%',
                valueColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: 16),

          // Título de sección interna
          const Text(
            'Tiempo de Respuesta Promedio',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Barras de Progreso por Categoría
          _buildCategoryBar(
            title: 'Seguridad',
            time: '45 min',
            progress: 0.75,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 12),
          _buildCategoryBar(
            title: 'Reciclaje',
            time: '20 min',
            progress: 0.90,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildCategoryBar(
            title: 'Maleza',
            time: '1h 15m',
            progress: 0.50,
            color: AppColors.tertiary,
          ),
          const SizedBox(height: 12),
          _buildCategoryBar(
            title: 'Basura',
            time: '35 min',
            progress: 0.65,
            color: AppColors.neutralTrash,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBar({
    required String title,
    required String time,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
