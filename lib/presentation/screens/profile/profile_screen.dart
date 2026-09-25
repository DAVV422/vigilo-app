import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_icons.dart';
import '../../../domain/entities/incident.dart';
import '../../providers/providers.dart';
import '../../../widgets/main_app_bar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isRecycleModeActive = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final incidents = ref.watch(incidentsProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    // Cálculos de XP y Rango
    int currentLevelMin = 0;
    int nextLevelMin = 100;
    String nextLevelName = 'Ciudadano Activo';

    if (user.points >= 500) {
      currentLevelMin = 500;
      nextLevelMin = 1000;
      nextLevelName = 'Leyenda';
    } else if (user.points >= 100) {
      currentLevelMin = 100;
      nextLevelMin = 500;
      nextLevelName = 'Héroe';
    }

    final pointsInCurrentLevel = user.points - currentLevelMin;
    final pointsNeededForNext = nextLevelMin - currentLevelMin;
    final progress = (pointsInCurrentLevel / pointsNeededForNext).clamp(0.0, 1.0);

    // Cálculos dinámicos reales de contribuciones
    final reportadosCount = incidents.where((i) => i.reportedByUserId == user.id).length;
    final validadosCount = incidents.where((i) => i.validatorsIds.contains(user.id)).length;
    final resueltosCount = incidents.where((i) => i.resolvedByUserId == user.id).length;

    // Rendimiento Global 
    final globalReportados = incidents.length;
    final globalResueltos = incidents.where((i) => i.status == IncidentStatus.resolved).length;
    final globalEficiencia = globalReportados > 0 ? (globalResueltos / globalReportados * 100).round() : 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const MainAppBar(title: 'Perfil'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Tarjeta Principal (Verde)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: user.avatarUrl.startsWith('http')
                          ? Image.network(
                              user.avatarUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(AppIcons.person, size: 70, color: Colors.white),
                            )
                          : const SizedBox(
                              width: 70,
                              height: 70,
                              child: Icon(AppIcons.person, size: 50, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${user.name} ${user.lastName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(
                      color: AppColors.primaryFixed,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Rango y Puntos
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'RANGO ACTUAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Text(
                        'TOTAL PUNTOS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stars, color: Colors.orange, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            user.level.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${user.points} PTS',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'XP: $pointsInCurrentLevel / $pointsNeededForNext para el próximo nivel $nextLevelName',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Modo Reciclaje
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.surfaceVariant,
                    radius: 20,
                    child: const Icon(AppIcons.recycling, color: AppColors.onSurfaceVariant, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modo Reciclaje',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Activa para poder resolver\nincidentes de reciclaje',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isRecycleModeActive,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.outline,
                    inactiveThumbColor: AppColors.outline,
                    inactiveTrackColor: AppColors.surfaceVariant,
                    onChanged: (val) {
                      setState(() {
                        _isRecycleModeActive = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Mis Contribuciones Ciudadanas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.grid_view_rounded, size: 16, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 8),
                      const Text(
                        'MIS CONTRIBUCIONES CIUDADANAS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildContributionItem(
                        icon: Icons.campaign_outlined,
                        iconColor: AppColors.error,
                        boxColor: AppColors.errorContainer.withValues(alpha: 0.5),
                        value: reportadosCount,
                        label: 'REPORTADOS',
                      ),
                      _buildContributionItem(
                        icon: AppIcons.thumbUp,
                        iconColor: AppColors.warning,
                        boxColor: AppColors.tertiaryFixed,
                        value: validadosCount,
                        label: 'VALIDADOS',
                      ),
                      _buildContributionItem(
                        icon: Icons.domain_verification,
                        iconColor: AppColors.primary,
                        boxColor: AppColors.primaryFixed.withValues(alpha: 0.3),
                        value: resueltosCount,
                        label: 'RESUELTOS',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Galería de Medallas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'GALERÍA DE MEDALLAS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildMedalItem(
                          icon: AppIcons.securityShield,
                          iconColor: AppColors.primary,
                          title: 'Vigilante',
                          subtitle: 'Reportó 1\nalerta',
                          borderColor: AppColors.primaryFixedDim,
                        ),
                        _buildMedalItem(
                          icon: AppIcons.search,
                          iconColor: AppColors.onSurface,
                          title: 'Halcón',
                          subtitle: 'Validó 1\nalerta',
                          borderColor: AppColors.tertiaryFixedDim,
                        ),
                        _buildMedalItem(
                          icon: Icons.build,
                          iconColor: AppColors.outlineVariant,
                          title: 'Solucionador',
                          subtitle: 'Resolvió 1\nalerta',
                          borderColor: AppColors.surfaceVariant,
                          isInactive: true,
                        ),
                        _buildMedalItem(
                          icon: Icons.bolt,
                          iconColor: AppColors.warning,
                          title: 'Explorador',
                          subtitle: 'Caminó en\nradar',
                          borderColor: AppColors.tertiaryFixedDim,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 6. Rendimiento de resolución general
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bar_chart, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'RENDIMIENTO DE RESOLUCIÓN\nGENERAL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPerformanceStat(
                        value: globalReportados.toString(),
                        label: 'REPORTADOS',
                        valueColor: AppColors.error,
                      ),
                      _buildPerformanceStat(
                        value: globalResueltos.toString(),
                        label: 'RESUELTOS',
                        valueColor: AppColors.primary,
                      ),
                      _buildPerformanceStat(
                        value: '$globalEficiencia%',
                        label: 'EFICIENCIA',
                        valueColor: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.surfaceVariant),
                  const SizedBox(height: 16),
                  const Text(
                    'TIEMPOS DE RESPUESTA PROMEDIO EN LA CIUDAD',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildResponseTimeItem(
                    icon: AppIcons.security,
                    iconColor: AppColors.error,
                    title: 'Seguridad',
                    time: '45 min',
                    badgeText: 'Respuesta inmediata',
                    badgeColor: AppColors.primaryFixedDim,
                    badgeTextColor: AppColors.onPrimaryFixedVariant,
                    progress: 0.2, // short
                    barColor: AppColors.primary,
                  ),
                  _buildResponseTimeItem(
                    icon: Icons.delete_outline,
                    iconColor: AppColors.secondary, // blueish in mockup? Let's use blue or app color
                    title: 'Basura',
                    time: '1.0 días',
                    badgeText: 'Estándar',
                    badgeColor: AppColors.tertiaryFixed,
                    badgeTextColor: AppColors.onTertiaryFixedVariant,
                    progress: 0.5,
                    barColor: AppColors.tertiary,
                  ),
                  _buildResponseTimeItem(
                    icon: AppIcons.weeds,
                    iconColor: AppColors.primary,
                    title: 'Maleza',
                    time: '2.0 días',
                    badgeText: 'Programado',
                    badgeColor: AppColors.tertiaryFixed,
                    badgeTextColor: AppColors.onTertiaryFixedVariant,
                    progress: 0.7,
                    barColor: AppColors.tertiary,
                  ),
                  _buildResponseTimeItem(
                    icon: AppIcons.recycling,
                    iconColor: AppColors.primary,
                    title: 'Reciclaje',
                    time: '3.0 horas',
                    badgeText: 'Coordinado',
                    badgeColor: AppColors.tertiaryFixed,
                    badgeTextColor: AppColors.onTertiaryFixedVariant,
                    progress: 0.4,
                    barColor: AppColors.tertiary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 7. Contacto
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Correo Electrónico', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(user.email, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Celular', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(user.phone, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionItem({
    required IconData icon,
    required Color iconColor,
    required Color boxColor,
    required int value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: iconColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMedalItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color borderColor,
    bool isInactive = false,
  }) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isInactive ? AppColors.surfaceVariant : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isInactive ? AppColors.outlineVariant : AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: isInactive ? AppColors.outlineVariant : AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceStat({
    required String value,
    required String label,
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
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildResponseTimeItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required double progress,
    required Color barColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface),
              ),
              const Spacer(),
              Text(
                time,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    if (badgeText == 'Respuesta inmediata')
                       Icon(Icons.bolt, color: badgeTextColor, size: 10),
                    Text(
                      badgeText,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}
