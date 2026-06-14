import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../domain/entities/incident.dart';
import '../domain/entities/user.dart';
import '../presentation/providers/providers.dart';
import '../theme/app_colors.dart';

class ProximityAlertDialog extends ConsumerWidget {
  final Incident incident;
  final VoidCallback onDismiss;

  const ProximityAlertDialog({
    super.key,
    required this.incident,
    required this.onDismiss,
  });

  bool _canResolve(User? user) {
    if (user == null) return false;
    if (incident.status == IncidentStatus.resolved) return false;
    switch (incident.type) {
      case IncidentType.insecurity:
        return user.isEmployee && user.roles.contains(UserRole.security);
      case IncidentType.trash:
      case IncidentType.weeds:
        return user.isEmployee && user.roles.contains(UserRole.cleaning);
      case IncidentType.recycling:
        return user.roles.contains(UserRole.recycling);
    }
  }

  void _validate(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authProvider);
    if (user == null) return;
    await ref.read(incidentsProvider.notifier).validateIncident(incident.id, user.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incidente validado como vigente (+1 punto)'), backgroundColor: AppColors.success),
      );
    }
    onDismiss();
  }

  void _resolve(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final user = ref.read(authProvider);
    if (user == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolver Incidente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Describe cómo se resolvió:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Comentario de la solución...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final comment = controller.text.trim();
              if (comment.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Por favor ingresa un comentario')),
                );
                return;
              }
              await ref.read(incidentsProvider.notifier).resolveIncident(
                incidentId: incident.id,
                userId: user.id,
                companyId: user.companyId ?? 'citizen',
                companyName: user.isEmployee ? (user.companyId ?? 'Ciudadano') : 'Ciudadano',
                comment: comment,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                onDismiss();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incidente resuelto (+2 puntos)'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);
    final location = ref.watch(currentLocationProvider);
    final canResolve = _canResolve(currentUser);
    final hasValidated = currentUser != null && incident.validatorsIds.contains(currentUser.id);
    final isOwner = currentUser != null && incident.reportedByUserId == currentUser.id;

    final distance = Geolocator.distanceBetween(
      location.latitude, location.longitude,
      incident.location.latitude, incident.location.longitude,
    );

    Color typeColor;
    IconData typeIcon;
    String typeLabel;
    switch (incident.type) {
      case IncidentType.insecurity:
        typeColor = AppColors.secondary;
        typeIcon = Icons.warning;
        typeLabel = 'Seguridad';
        break;
      case IncidentType.trash:
        typeColor = AppColors.neutralTrash;
        typeIcon = Icons.delete;
        typeLabel = 'Basura';
        break;
      case IncidentType.weeds:
        typeColor = AppColors.warning;
        typeIcon = Icons.grass;
        typeLabel = 'Maleza';
        break;
      case IncidentType.recycling:
        typeColor = AppColors.ecoGreen;
        typeIcon = Icons.recycling;
        typeLabel = 'Reciclaje';
        break;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
          const SizedBox(width: 10),
          const Expanded(child: Text('¡Incidente Cercano!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(typeLabel, style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('A ${distance.toInt()}m de ti', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(incident.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(incident.description, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          if (hasValidated)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text('Ya validaste este incidente', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          if (isOwner)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text('Reportaste este incidente', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13))),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: onDismiss, child: const Text('Ignorar')),
        if (!hasValidated && !isOwner)
          OutlinedButton.icon(
            onPressed: () => _validate(context, ref),
            icon: const Icon(Icons.thumb_up, size: 16),
            label: const Text('Validar como vigente'),
          ),
        if (canResolve)
          FilledButton.icon(
            onPressed: () => _resolve(context, ref),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Resolver ahora'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          ),
      ],
    );
  }
}
