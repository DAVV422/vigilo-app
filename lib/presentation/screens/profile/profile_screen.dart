import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/user.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_icons.dart';
import '../../providers/providers.dart';
import '../../../widgets/main_app_bar.dart';
import '../../../../core/errors/describe_error.dart';
import '../../../../core/logging/app_logger.dart';

/// Reescrito para dejar de mostrar datos inventados (galería de medallas y
/// tiempos de respuesta por categoría eran 100% hardcodeados, sin relación
/// con datos reales) y un lenguaje de gamificación tipo videojuego
/// ("Héroe", "Leyenda", medallas con nombres como "Halcón") que no encaja
/// con el tono profesional que se busca para el producto. Todo lo que se
/// muestra ahora sale de `authProvider`/`incidentsProvider` (backend real).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _log = AppLogger('Perfil');
  bool _requestingRecyclerRole = false;

  // Nombres de nivel neutros en vez de "Novato/Héroe/Leyenda".
  static const _levelTiers = [
    (min: 0, name: 'Nivel 1'),
    (min: 100, name: 'Nivel 2'),
    (min: 500, name: 'Nivel 3'),
  ];

  Future<void> _requestRecyclerRole() async {
    final dniController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activar rol de reciclador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa tu número de documento (DNI) para verificar tu identidad.',
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dniController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Ej. 12345678'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Activar')),
        ],
      ),
    );
    if (confirmed != true || dniController.text.trim().isEmpty) return;

    setState(() => _requestingRecyclerRole = true);
    try {
      final result = await ref.read(authRepositoryProvider).requestRole(
            role: 'RECYCLER_INDIVIDUAL',
            idDocumentType: 'DNI',
            idDocumentNumber: dniController.text.trim(),
          );
      await ref.read(authProvider.notifier).reloadUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    } catch (e, st) {
      if (!mounted) return;
      final message = describeError(e, st, log: _log, operation: 'activar el rol', whereToCheck: 'Perfil');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _requestingRecyclerRole = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final incidents = ref.watch(incidentsProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    var currentTier = _levelTiers.first;
    var nextTierMin = _levelTiers[1].min;
    for (var i = 0; i < _levelTiers.length; i++) {
      if (user.points >= _levelTiers[i].min) {
        currentTier = _levelTiers[i];
        nextTierMin = i + 1 < _levelTiers.length ? _levelTiers[i + 1].min : _levelTiers[i].min;
      }
    }
    final isMaxTier = currentTier.min == _levelTiers.last.min;
    final pointsInTier = user.points - currentTier.min;
    final pointsForNextTier = (nextTierMin - currentTier.min).clamp(1, 1 << 30);
    final progress = isMaxTier ? 1.0 : (pointsInTier / pointsForNextTier).clamp(0.0, 1.0);

    final reportadosCount = incidents.where((i) => i.reportedByUserId == user.id).length;
    final isRecycler = user.roles.contains(UserRole.recycling);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const MainAppBar(title: 'Perfil'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(user),
            const SizedBox(height: 16),
            _buildLevelCard(user, currentTier.name, pointsInTier, pointsForNextTier, isMaxTier, progress),
            const SizedBox(height: 16),
            _buildTrustScoreCard(user),
            const SizedBox(height: 16),
            _buildRecyclerRoleCard(isRecycler),
            const SizedBox(height: 16),
            _buildActivityCard(reportadosCount),
            const SizedBox(height: 16),
            _buildContactCard(Icons.email_outlined, 'Correo electrónico', user.email),
            const SizedBox(height: 12),
            if (user.phone.isNotEmpty)
              _buildContactCard(Icons.phone_outlined, 'Celular', user.phone),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Cerrar sesión'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: ClipOval(
              child: user.avatarUrl.toString().startsWith('http')
                  ? Image.network(
                      user.avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(AppIcons.person, size: 40, color: AppColors.primary),
                    )
                  : const Icon(AppIcons.person, size: 40, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${user.name} ${user.lastName}'.trim(),
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            '@${user.username}',
            style: TextStyle(color: AppColors.primaryFixed, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(
    dynamic user,
    String tierName,
    int pointsInTier,
    int pointsForNextTier,
    bool isMaxTier,
    double progress,
  ) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label('NIVEL'),
              _label('PUNTOS'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tierName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              Text('${user.points}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            ],
          ),
          const SizedBox(height: 14),
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
            isMaxTier
                ? 'Nivel máximo alcanzado'
                : '$pointsInTier / $pointsForNextTier puntos para el siguiente nivel',
            style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustScoreCard(dynamic user) {
    return _card(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.verified_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reputación', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                const SizedBox(height: 2),
                Text(
                  user.ratingsCount > 0
                      ? 'Calificación de ${user.trustScore.toStringAsFixed(1)} / 5 (${user.ratingsCount} reseñas)'
                      : 'Todavía no tienes calificaciones',
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecyclerRoleCard(bool isRecycler) {
    return _card(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
            child: const Icon(AppIcons.recycling, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rol de reciclador', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                const SizedBox(height: 2),
                Text(
                  isRecycler
                      ? 'Activo — puedes reclamar publicaciones de reciclaje'
                      : 'Actívalo para poder recoger material publicado por otros usuarios',
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (!isRecycler)
            _requestingRecyclerRole
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : TextButton(onPressed: _requestRecyclerRole, child: const Text('Activar')),
        ],
      ),
    );
  }

  Widget _buildActivityCard(int reportadosCount) {
    return _card(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.campaign_outlined, color: AppColors.onSurfaceVariant, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reportes cercanos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                const SizedBox(height: 2),
                Text(
                  '$reportadosCount reporte(s) tuyos en tu zona',
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(IconData icon, String label, String value) {
    return _card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurfaceVariant,
        letterSpacing: 0.6,
      ),
    );
  }
}
