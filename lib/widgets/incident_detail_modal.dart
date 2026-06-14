import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/entities/incident.dart';
import '../domain/entities/user.dart';
import '../presentation/providers/providers.dart';
import '../theme/app_colors.dart';

class IncidentDetailModal extends ConsumerWidget {
  final Incident incident;
  final bool isWithinRange;

  const IncidentDetailModal({
    super.key,
    required this.incident,
    this.isWithinRange = true,
  });

  bool _canResolveIncident(User? user) {
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

  void _showResolveDialog(BuildContext context, WidgetRef ref, User currentUser) {
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolver Incidente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresa un comentario sobre la solución:',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe cómo se resolvió el incidente...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final comment = commentController.text.trim();
              if (comment.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor ingresa un comentario')),
                );
                return;
              }

              final companyId = currentUser.companyId ?? 'citizen';
              final companyName = currentUser.isEmployee
                  ? (currentUser.companyId ?? 'Ciudadano')
                  : 'Ciudadano';

              await ref.read(incidentsProvider.notifier).resolveIncident(
                incidentId: incident.id,
                userId: currentUser.id,
                companyId: companyId,
                companyName: companyName,
                comment: comment,
              );

              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Incidente resuelto correctamente (+2 puntos)'),
                    backgroundColor: AppColors.success,
                  ),
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

    final usersAsync = ref.watch(allUsersProvider);
    final currentUser = ref.watch(authProvider);
    final canResolve = _canResolveIncident(currentUser);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(typeIcon, color: typeColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(incident.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(typeLabel, style: TextStyle(color: typeColor, fontSize: 12)),
                          ),
                        ],
                      ),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(incident.reportedAt),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(incident.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),

            // Información de resolución
            if (incident.status == IncidentStatus.resolved) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        const Text('RESUELTO', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (incident.resolvedAt != null)
                      Text(
                        'El ${DateFormat('dd MMM yyyy HH:mm').format(incident.resolvedAt!)}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    if (incident.resolvedByCompany != null)
                      Text(
                        'Por: ${incident.resolvedByCompany}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    if (incident.resolutionComment != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '"${incident.resolutionComment}"',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            usersAsync.when(
              data: (users) {
                final reporter = users.firstWhere((u) => u.id == incident.reportedByUserId, orElse: () => User(id: '', name: 'Desconocido', email: '', password: ''));
                final validators = users.where((u) => incident.validatorsIds.contains(u.id)).toList();
                
                final hasValidated = currentUser != null && incident.validatorsIds.contains(currentUser.id);
                final isOwner = currentUser != null && incident.reportedByUserId == currentUser.id;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    Text('Reportado por: ${reporter.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (validators.isNotEmpty)
                      Text('Validado por ${validators.length} persona(s): ${validators.map((e) => e.name).join(", ")}', 
                           style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                    const SizedBox(height: 20),
                    if (incident.status == IncidentStatus.active && !isWithinRange)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.secondary.withOpacity(0.25), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock, color: AppColors.secondary, size: 20),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                '🔒 Alerta fuera del rango de radar (200m). Acércate físicamente para poder Validar o Resolver.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (incident.status == IncidentStatus.active && currentUser != null)
                          OutlinedButton.icon(
                            onPressed: (hasValidated || isOwner || !isWithinRange) ? null : () async {
                              await ref.read(incidentsProvider.notifier).validateIncident(incident.id, currentUser.id);
                              if (context.mounted) Navigator.pop(context);
                            },
                            icon: const Icon(Icons.thumb_up),
                            label: Text(hasValidated ? 'Ya lo validaste' : 'Validar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: (hasValidated || isOwner || !isWithinRange) ? Colors.grey : AppColors.primary),
                            ),
                          ),
                        if (canResolve || (_canResolveIncident(currentUser) && !isWithinRange))
                          FilledButton.icon(
                            onPressed: !isWithinRange ? null : () => _showResolveDialog(context, ref, currentUser!),
                            icon: const Icon(Icons.check),
                            label: const Text('Resolver'),
                            style: FilledButton.styleFrom(
                              backgroundColor: !isWithinRange ? Colors.grey : AppColors.success,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error cargando usuarios'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}