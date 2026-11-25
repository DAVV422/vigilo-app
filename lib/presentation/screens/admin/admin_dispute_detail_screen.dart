import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/dispute.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../widgets/admin/resolve_dispute_sheet.dart';
import '../../widgets/ratings/rating_stars.dart';
import '../profile/user_ratings_screen.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admin_scaffold.dart';

const _log = AppLogger('AdminDisputas');

/// Detalle de una disputa y su resolución.
///
/// El orden de la pantalla no es casual: arriba el reclamo completo, que es
/// lo que se está juzgando; después las dos partes con su reputación, que
/// es el contexto para creerle a una o a otra; recién entonces el pesaje y
/// la plata; y las acciones al final, cuando ya se leyó todo.
class AdminDisputeDetailScreen extends ConsumerStatefulWidget {
  const AdminDisputeDetailScreen({super.key, required this.disputeId});

  final String disputeId;

  @override
  ConsumerState<AdminDisputeDetailScreen> createState() =>
      _AdminDisputeDetailScreenState();
}

class _AdminDisputeDetailScreenState extends ConsumerState<AdminDisputeDetailScreen> {
  Dispute? _dispute;
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final d = await ref.read(disputesRepositoryProvider).getById(widget.disputeId);
      if (!mounted) return;
      setState(() {
        _dispute = d;
        _isLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      describeError(e, st, log: _log, operation: 'cargar la disputa');
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _resolve(Dispute d) async {
    final resolved = await showResolveDisputeSheet(context, dispute: d);
    if (resolved == true && mounted) Navigator.pop(context, true);
  }

  void _openReputation(DisputeParty party) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserRatingsScreen(userId: party.id, displayName: party.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _dispute;

    return AdminScaffold(
      title: 'Disputa',
      onRefresh: _load,
      body: AdminAsyncView(
        isLoading: _isLoading,
        error: _error,
        onRetry: _load,
        child: d == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.all(16),
                physics:
                    const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                children: [
                  _buildClaim(d),
                  const SizedBox(height: 16),
                  if (d.pickup != null) ...[
                    _buildParties(d.pickup!),
                    const SizedBox(height: 16),
                    _buildWeighIn(d.pickup!),
                    const SizedBox(height: 16),
                  ],
                  if (d.resolution != null)
                    _buildResolution(d.resolution!)
                  else if (d.isOpen)
                    ElevatedButton.icon(
                      onPressed: () => _resolve(d),
                      icon: const Icon(Icons.gavel),
                      label: const Text('Resolver la disputa'),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  Widget _card({required Widget child, String? title}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildClaim(Dispute d) {
    return _card(
      title: 'EL RECLAMO',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Completo y sin recortar: es exactamente lo que se está juzgando.
          Text(d.reason, style: const TextStyle(fontSize: 14, height: 1.4)),
          const SizedBox(height: 10),
          Text(
            'Abierta por ${d.openedBy?.name ?? 'un usuario'} · '
            '${_formatDate(d.createdAt)}',
            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildParties(DisputePickup p) {
    return _card(
      title: 'LAS PARTES',
      child: Column(
        children: [
          if (p.citizen != null) _partyRow('Ciudadano', p.citizen!),
          if (p.citizen != null && p.recycler != null) const Divider(height: 20),
          if (p.recycler != null) _partyRow('Recolector', p.recycler!),
        ],
      ),
    );
  }

  Widget _partyRow(String role, DisputeParty party) {
    return InkWell(
      onTap: () => _openReputation(party),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    party.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (party.trustScore != null)
              RatingScoreBadge(score: party.trustScore!, count: party.ratingsCount),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildWeighIn(DisputePickup p) {
    return _card(
      title: 'PESAJE REGISTRADO',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.results.isEmpty)
            const Text(
              'El recojo no tiene pesaje registrado.',
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            )
          else
            for (final r in p.results)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.materialName ?? 'Material',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      // En kilos para leerlo; el sistema trabaja en gramos.
                      '${(r.actualWeightGrams / 1000).toStringAsFixed(2)} kg',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${r.pointsAwarded} pts',
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
          if (p.compensation != null) ...[
            const Divider(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text('Compensación', style: TextStyle(fontSize: 13)),
                ),
                Text(
                  'Bs ${p.compensation!.grossAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Text(
                  p.compensation!.status,
                  style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResolution(DisputeResolution r) {
    return _card(
      title: 'RESOLUCIÓN',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _actionLabel(r.action),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          if (r.notes != null) ...[
            const SizedBox(height: 8),
            Text(r.notes!, style: const TextStyle(fontSize: 13, height: 1.4)),
          ],
          const SizedBox(height: 10),
          Text(
            '${r.resolvedBy ?? 'Un moderador'} · '
            '${r.resolvedAt != null ? _formatDate(r.resolvedAt!) : ''}',
            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _actionLabel(String? wire) => switch (wire) {
        'ADJUST_WEIGHT' => 'Se corrigió el pesaje',
        'CREDIT_POINTS' => 'Se acreditaron puntos',
        'PENALIZE_RECYCLER' => 'Se penalizó al recolector',
        'DISMISS' => 'Se desestimó el reclamo',
        _ => wire ?? 'Resuelta',
      };

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
