import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../domain/entities/company.dart';
import '../domain/entities/user.dart';
import '../domain/entities/incident.dart';
import '../presentation/providers/providers.dart';
import 'login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _achievementReported = false;
  bool _achievementValidated = false;
  bool _achievementResolved = false;
  bool _achievementWalked = false;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _achievementReported =
          prefs.getBool('vigilo_achievement_reported') ?? false;
      _achievementValidated =
          prefs.getBool('vigilo_achievement_validated') ?? false;
      _achievementResolved =
          prefs.getBool('vigilo_achievement_resolved') ?? false;
      _achievementWalked = prefs.getBool('vigilo_achievement_walked') ?? false;
    });
  }

  void _logout(BuildContext context) async {
    await ref.read(authProvider.notifier).logout();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  bool _isGerente(User? user) {
    return user?.companyRole == CompanyRole.director;
  }

  void _showEditCompanyDialog(BuildContext context, Company company) {
    final nameController = TextEditingController(text: company.name);
    final logoController = TextEditingController(text: company.logoUrl ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Empresa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la empresa',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: logoController,
                decoration: const InputDecoration(
                  labelText: 'URL del logo (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'https://ejemplo.com/logo.png',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El nombre no puede estar vacío'),
                  ),
                );
                return;
              }

              final updatedCompany = company.copyWith(
                name: newName,
                logoUrl: logoController.text.trim().isNotEmpty
                    ? logoController.text.trim()
                    : null,
              );

              await ref
                  .read(companiesProvider.notifier)
                  .updateCompany(updatedCompany);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Empresa actualizada correctamente'),
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Lógica para calcular tiempos de resolución dinámicos
  Map<IncidentType, Duration> _calculateAverages(List<Incident> incidents) {
    Map<IncidentType, List<Duration>> durations = {
      IncidentType.insecurity: [],
      IncidentType.trash: [],
      IncidentType.weeds: [],
      IncidentType.recycling: [],
    };

    for (var incident in incidents) {
      if (incident.status == IncidentStatus.resolved &&
          incident.resolvedAt != null) {
        final diff = incident.resolvedAt!.difference(incident.reportedAt);
        durations[incident.type]!.add(diff);
      }
    }

    Map<IncidentType, Duration> averages = {};
    durations.forEach((type, list) {
      if (list.isEmpty) {
        // Tiempos semilla por defecto realistas
        switch (type) {
          case IncidentType.insecurity:
            averages[type] = const Duration(minutes: 45);
            break;
          case IncidentType.trash:
            averages[type] = const Duration(hours: 24);
            break;
          case IncidentType.weeds:
            averages[type] = const Duration(days: 2);
            break;
          case IncidentType.recycling:
            averages[type] = const Duration(hours: 3);
            break;
        }
      } else {
        final totalMs = list.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
        averages[type] = Duration(
          milliseconds: (totalMs / list.length).round(),
        );
      }
    });

    return averages;
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes < 60) {
      return '${d.inMinutes} min';
    } else if (d.inHours < 24) {
      return '${(d.inMilliseconds / (1000 * 60 * 60)).toStringAsFixed(1)} horas';
    } else {
      return '${(d.inMilliseconds / (1000 * 60 * 60 * 24)).toStringAsFixed(1)} días';
    }
  }

  double _getDurationScore(IncidentType type, Duration d) {
    double maxMinutes;
    switch (type) {
      case IncidentType.insecurity:
        maxMinutes = 120.0;
        break;
      case IncidentType.trash:
        maxMinutes = 3 * 24 * 60.0;
        break;
      case IncidentType.weeds:
        maxMinutes = 5 * 24 * 60.0;
        break;
      case IncidentType.recycling:
        maxMinutes = 6 * 60.0;
        break;
    }
    return (d.inMinutes / maxMinutes).clamp(0.08, 1.0);
  }

  Color _getSpeedColor(IncidentType type, Duration d) {
    switch (type) {
      case IncidentType.insecurity:
        return d.inMinutes < 60 ? AppColors.success : AppColors.warning;
      case IncidentType.trash:
        return d.inHours < 24 ? AppColors.success : AppColors.warning;
      case IncidentType.weeds:
        return d.inHours < 48 ? AppColors.success : AppColors.warning;
      case IncidentType.recycling:
        return d.inMinutes < 180 ? AppColors.success : AppColors.warning;
    }
  }

  String _getSpeedLabel(IncidentType type, Duration d) {
    switch (type) {
      case IncidentType.insecurity:
        return d.inMinutes < 60 ? '⚡ Respuesta inmediata' : 'Normal';
      case IncidentType.trash:
        return d.inHours < 24 ? '⚡ Recolección ágil' : 'Estándar';
      case IncidentType.weeds:
        return d.inHours < 48 ? '⚡ Trabajo rápido' : 'Programado';
      case IncidentType.recycling:
        return d.inMinutes < 180 ? '⚡ Retiro express' : 'Coordinado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final companies = ref.watch(companiesProvider);
    final incidents = ref.watch(incidentsProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Inicia sesión')));
    }

    Company? userCompany;
    if (user.companyId != null) {
      userCompany = companies.where((c) => c.id == user.companyId).firstOrNull;
    }

    final isGerente = _isGerente(user);

    // Calcular estadísticas dinámicas de incidentes
    final resolvedIncidents = incidents
        .where((i) => i.status == IncidentStatus.resolved)
        .toList();
    final activeIncidents = incidents
        .where((i) => i.status == IncidentStatus.active)
        .toList();
    final resolutionRate = incidents.isEmpty
        ? 0.0
        : (resolvedIncidents.length / incidents.length) * 100;

    final averages = _calculateAverages(incidents);

    // Configuración visual de barra de nivel (XP)
    int xpCurrent = user.points;
    int xpMax = 100;
    String nextLevel = 'Ciudadano Activo';
    Color rankGlowColor = const Color(0xFFcd7f32); // Novato: Cobre

    if (user.points >= 100 && user.points < 500) {
      xpCurrent = user.points - 100;
      xpMax = 400;
      nextLevel = 'Héroe';
      rankGlowColor = const Color(0xFFc0c0c0); // Plata
    } else if (user.points >= 500) {
      xpCurrent = user.points - 500;
      xpMax = 500;
      nextLevel = 'Leyenda Urbana';
      rankGlowColor = const Color(0xFFFFd700); // Oro
    }

    final double xpPercentage = (xpCurrent / xpMax).clamp(0.0, 1.0);

    // Desbloqueo de medallas
    final bool hasVigilanteMedal = _achievementReported || user.points >= 100;
    final bool hasHawkMedal = _achievementValidated || user.points >= 120;
    final bool hasSolverMedal = _achievementResolved || user.points >= 500;
    final bool hasExplorerMedal = _achievementWalked;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Mi Perfil de Héroe',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // CABECERA CON WAVE GRADIENT TOTALMENTE INTEGRADA (SIN TRASLAPE BUGGY)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    // AVATAR CON ANILLO DE XP GLOWING
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            rankGlowColor,
                            rankGlowColor.withOpacity(0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: rankGlowColor.withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            user.avatarUrl.isNotEmpty
                                ? user.avatarUrl
                                : user.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 44,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${user.name} ${user.lastName}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.username.isNotEmpty ? user.username : '@usuario',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    if (user.isEmployee) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getCompanyRoleLabel(user.companyRole),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // CUERPO DE CONTENEDORES CON PADDING
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // TARJETA DE NIVEL Y BARRA DE XP (GAMIFICACIÓN)
                    _buildLevelProgressCard(
                      user,
                      rankGlowColor,
                      xpPercentage,
                      xpCurrent,
                      xpMax,
                      nextLevel,
                    ),
                    const SizedBox(height: 24),

                    // TOGGLE ROL RECICLAJE (para ciudadanos normales)
                    if (!user.isEmployee) ...[
                      _buildRecyclingToggleCard(user),
                      const SizedBox(height: 16),
                    ],

                    // SECCIÓN DE NUEVAS MÉTRICAS INDIVIDUALES (REQUERIDO)
                    _buildUserSpecificMetricsCard(user, incidents),
                    const SizedBox(height: 24),

                    // SECCIÓN DE MEDALLAS / LOGROS
                    _buildTrophySection(
                      hasVigilanteMedal,
                      hasHawkMedal,
                      hasSolverMedal,
                      hasExplorerMedal,
                    ),
                    const SizedBox(height: 24),

                    // SECCIÓN DE ESTADÍSTICAS DINÁMICAS Y TIEMPOS DE RESPUESTA
                    _buildResolutionStatsCard(
                      resolvedCount: resolvedIncidents.length,
                      activeCount: activeIncidents.length,
                      totalCount: incidents.length,
                      rate: resolutionRate,
                      averages: averages,
                    ),
                    const SizedBox(height: 24),

                    // INFORMACIÓN DE CONTACTO
                    _buildContactCard(user),
                    const SizedBox(height: 16),

                    // EMPRESA ASOCIADA (SI APLICA)
                    if (user.isEmployee && userCompany != null) ...[
                      _buildCompanyCard(context, userCompany, isGerente),
                      const SizedBox(height: 24),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tarjeta de gamificación de nivel
  Widget _buildLevelProgressCard(
    User user,
    Color glowColor,
    double progress,
    int current,
    int max,
    String nextRank,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RANGO ACTUAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.stars, color: glowColor, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        user.level.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: glowColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'TOTAL PUNTOS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.points} PTS',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: AppColors.onBackground,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Barra de progreso interactiva
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [glowColor, glowColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XP: $current / $max para el próximo nivel',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              Text(
                nextRank,
                style: TextStyle(
                  color: glowColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // NUEVO: TARJETA DE MÉTRICAS INDIVIDUALES DEL USUARIO
  Widget _buildUserSpecificMetricsCard(User user, List<Incident> incidents) {
    if (!user.isEmployee) {
      // CITADINO COMÚN: Reportes realizados, validados y cuántos fueron resueltos.
      final int reportedByMe = incidents
          .where((i) => i.reportedByUserId == user.id)
          .length;
      final int validatedByMe = incidents
          .where((i) => i.validatorsIds.contains(user.id))
          .length;
      final int myResolvedReports = incidents
          .where(
            (i) =>
                i.reportedByUserId == user.id &&
                i.status == IncidentStatus.resolved,
          )
          .length;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.dashboard_customize_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'MIS CONTRIBUCIONES CIUDADANAS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.onBackground,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCircularMetricBadge(
                  '📢',
                  '$reportedByMe',
                  'Reportados',
                  Colors.blue.shade700,
                ),
                _buildCircularMetricBadge(
                  '👍',
                  '$validatedByMe',
                  'Validados',
                  AppColors.primary,
                ),
                _buildCircularMetricBadge(
                  '✅',
                  '$myResolvedReports',
                  'Resueltos',
                  AppColors.success,
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // OPERARIO / EMPLEADO / GERENTE: Incidentes resueltos por él, especialidad, incidentes que puede atender.
      final int resolvedByMe = incidents
          .where((i) => i.resolvedByUserId == user.id)
          .length;

      // Filtrar especialidad y cobertura
      List<IncidentType> myAllowedTypes = [];
      String roleTitle = "Colaborador General";
      String specialtyEmoji = "💼";
      if (user.roles.contains(UserRole.security)) {
        myAllowedTypes.add(IncidentType.insecurity);
        roleTitle = "Seguridad Ciudadana";
        specialtyEmoji = "🛡️";
      }
      if (user.roles.contains(UserRole.cleaning)) {
        myAllowedTypes.add(IncidentType.trash);
        myAllowedTypes.add(IncidentType.weeds);
        roleTitle = "Limpieza & Saneamiento Urbano";
        specialtyEmoji = "🧹";
      }
      if (user.roles.contains(UserRole.recycling)) {
        myAllowedTypes.add(IncidentType.recycling);
        roleTitle = "Especialista en Reciclaje";
        specialtyEmoji = "♻️";
      }

      final allowedIncidents = incidents
          .where((i) => myAllowedTypes.contains(i.type))
          .toList();
      final resolvedAllowedCount = allowedIncidents
          .where((i) => i.status == IncidentStatus.resolved)
          .length;
      final activeAllowedCount = allowedIncidents
          .where((i) => i.status == IncidentStatus.active)
          .length;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.engineering_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'MÉTRICAS DE HÉROE OPERATIVO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.onBackground,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                Text(specialtyEmoji, style: const TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 14),

            // Especialidad badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Especialidad: $roleTitle',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Métricas numéricas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCircularMetricBadge(
                  '🛠️',
                  '$resolvedByMe',
                  'Resueltos por mí',
                  AppColors.success,
                ),
                _buildCircularMetricBadge(
                  '📦',
                  '$activeAllowedCount',
                  'Pendientes en Rol',
                  AppColors.secondary,
                ),
                _buildCircularMetricBadge(
                  '📈',
                  '$resolvedAllowedCount',
                  'Total de Rol Resueltos',
                  Colors.teal,
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cobertura en especialidad:',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$resolvedAllowedCount de ${allowedIncidents.length} resueltos',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCircularMetricBadge(
    String emoji,
    String count,
    String label,
    Color accentColor,
  ) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.07),
            shape: BoxShape.circle,
            border: Border.all(color: accentColor.withOpacity(0.2), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(height: 6),
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: accentColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Galería de medallas / Logros
  Widget _buildTrophySection(bool fit, bool hawk, bool solver, bool explorer) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.military_tech, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'GALERÍA DE MEDALLAS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.onBackground,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMedalItem('🛡️', 'Vigilante', 'Reportó 1 alerta', fit),
              _buildMedalItem('🔍', 'Halcón', 'Validó 1 alerta', hawk),
              _buildMedalItem(
                '🛠️',
                'Solucionador',
                'Resolvió 1 alerta',
                solver,
              ),
              _buildMedalItem('⚡', 'Explorador', 'Caminó en radar', explorer),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedalItem(
    String emoji,
    String title,
    String subtitle,
    bool isUnlocked,
  ) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isUnlocked ? const Color(0xFFFFF9E6) : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(
              color: isUnlocked
                  ? const Color(0xFFFFD700)
                  : Colors.grey.shade300,
              width: isUnlocked ? 2.5 : 1.5,
            ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: isUnlocked ? 1.0 : 0.35,
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
              if (!isUnlocked)
                const Icon(Icons.lock, size: 14, color: Colors.grey),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: isUnlocked ? AppColors.onBackground : Colors.grey.shade500,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  // Tarjeta de estadísticas de incidentes y tiempo promedio de respuesta
  Widget _buildResolutionStatsCard({
    required int resolvedCount,
    required int activeCount,
    required int totalCount,
    required double rate,
    required Map<IncidentType, Duration> averages,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'RENDIMIENTO DE RESOLUCIÓN GENERAL',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.onBackground,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Indicadores numéricos principales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatMetric(
                'Reportados',
                '$totalCount',
                Colors.blue.shade700,
              ),
              _buildStatMetric(
                'Resueltos',
                '$resolvedCount',
                AppColors.success,
              ),
              _buildStatMetric(
                'Eficiencia',
                '${rate.toStringAsFixed(0)}%',
                AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'TIEMPOS DE RESPUESTA PROMEDIO EN LA CIUDAD',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          // Barras horizontales comparativas de velocidad
          _buildAverageSpeedBar(
            type: IncidentType.insecurity,
            title: '🚨 Seguridad',
            duration: averages[IncidentType.insecurity]!,
          ),
          _buildAverageSpeedBar(
            type: IncidentType.trash,
            title: '🗑️ Basura',
            duration: averages[IncidentType.trash]!,
          ),
          _buildAverageSpeedBar(
            type: IncidentType.weeds,
            title: '🌿 Maleza',
            duration: averages[IncidentType.weeds]!,
          ),
          _buildAverageSpeedBar(
            type: IncidentType.recycling,
            title: '♻️ Reciclaje',
            duration: averages[IncidentType.recycling]!,
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // Barra horizontal comparativa de velocidad de resolución
  Widget _buildAverageSpeedBar({
    required IncidentType type,
    required String title,
    required Duration duration,
  }) {
    final double score = _getDurationScore(type, duration);
    final Color barColor = _getSpeedColor(type, duration);
    final String labelSpeed = _getSpeedLabel(type, duration);
    final String labelTime = _formatDuration(duration);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.onBackground,
                ),
              ),
              Row(
                children: [
                  Text(
                    labelTime,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: barColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: barColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      labelSpeed,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: barColor,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Barra de progreso estilizada
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: score,
                  child: Container(
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta de información de contacto estándar
  Widget _buildContactCard(User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.email, 'Correo Electrónico', user.email),
          const Divider(height: 30),
          _buildInfoRow(
            Icons.phone,
            'Celular',
            user.phone.isNotEmpty ? user.phone : 'No registrado',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.onBackground,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Tarjeta de toggle de rol reciclaje (para ciudadanos normales)
  Widget _buildRecyclingToggleCard(User user) {
    final hasRecycling = user.roles.contains(UserRole.recycling);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasRecycling
              ? AppColors.ecoGreen.withOpacity(0.3)
              : Colors.grey.shade200,
          width: hasRecycling ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasRecycling
                ? AppColors.ecoGreen.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasRecycling
                  ? AppColors.ecoGreen.withOpacity(0.1)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.recycling,
              color: hasRecycling ? AppColors.ecoGreen : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo Reciclaje',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: hasRecycling
                        ? AppColors.ecoGreen
                        : AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasRecycling
                      ? 'Puedes marcar incidentes de reciclaje como solucionados'
                      : 'Activa para poder resolver incidentes de reciclaje',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: hasRecycling,
            activeColor: AppColors.ecoGreen,
            onChanged: (value) async {
              List<UserRole> newRoles;
              if (value) {
                newRoles = [...user.roles, UserRole.recycling];
              } else {
                newRoles = user.roles
                    .where((r) => r != UserRole.recycling)
                    .toList();
              }
              final updatedUser = user.copyWith(roles: newRoles);
              await ref.read(userRepositoryProvider).updateUser(updatedUser);
              await ref.read(authProvider.notifier).reloadUser();
            },
          ),
        ],
      ),
    );
  }

  // Módulo de empresa asociada
  Widget _buildCompanyCard(
    BuildContext context,
    Company company,
    bool isGerente,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'EMPRESA AFILIADA',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              if (isGerente)
                TextButton.icon(
                  onPressed: () => _showEditCompanyDialog(context, company),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Editar', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (company.logoUrl != null && company.logoUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    company.logoUrl!,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildCompanyDefaultAvatar(),
                  ),
                ),
              ] else
                _buildCompanyDefaultAvatar(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.onBackground,
                      ),
                    ),
                    if (isGerente)
                      const Text(
                        'Puesto Administrativo: Director General',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyDefaultAvatar() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.business, color: AppColors.primary, size: 24),
    );
  }

  String _getCompanyRoleLabel(CompanyRole? role) {
    switch (role) {
      case CompanyRole.director:
        return 'DIRECTOR GENERAL DE OPERACIONES';
      case CompanyRole.manager:
        return 'GERENTE DE DEPARTAMENTO';
      case CompanyRole.employee:
        return 'COLABORADOR OPERATIVO';
      default:
        return '';
    }
  }
}
