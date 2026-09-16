import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../screens/report/new_report_screen.dart';
import '../../screens/report/recycle_form_screen.dart';
import '../../screens/alerts/confirm_alerts_screen.dart';

class ReportModalDialog extends StatelessWidget {
  const ReportModalDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Qué quieres reportar?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona el tipo de incidencia en tu zona',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildOption(
              context: context,
              title: 'Reporte Urbano',
              subtitle: 'Bache, basura, alumbrado, inseguridad...',
              icon: Icons.warning_rounded,
              iconBackgroundColor: AppColors.tertiary,
              iconColor: AppColors.onTertiary,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NewReportScreen()));
              },
            ),
            const SizedBox(height: 12),
            _buildOption(
              context: context,
              title: 'Material Reciclable',
              subtitle: 'Plástico, cartón, vidrio, electrónicos...',
              icon: Icons.recycling, // Changed to recycling icon
              iconBackgroundColor: AppColors.primary,
              iconColor: AppColors.onPrimary,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RecycleFormScreen()));
              },
            ),
            const SizedBox(height: 12),
            _buildOption(
              context: context,
              title: 'Confirmar Alertas',
              subtitle: '2 reportes pendientes de verificación en tu área',
              icon: Icons.fact_check, // Changed to fact_check to match the image
              iconBackgroundColor: AppColors.surfaceContainerHighest,
              iconColor: AppColors.outline,
              badgeCount: 2,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfirmAlertsScreen()));
              },
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBackgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: const TextStyle(
                          color: AppColors.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
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
}
