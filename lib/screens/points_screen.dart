import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/network/api_exception.dart';
import '../domain/entities/citizen_summary.dart';
import '../domain/entities/points_transaction.dart';
import '../theme/app_colors.dart';
import '../presentation/providers/providers.dart';
import '../widgets/main_app_bar.dart';

/// Reescrito para mostrar solo datos reales del ledger (`PointsRepository`)
/// y del resumen agregado (`AnalyticsRepository`). Antes el ranking ("#7"),
/// el "Total ganado +130" y el historial de 3 movimientos eran constantes
/// locales que no reflejaban al usuario real — ni siquiera coincidían con
/// `userPoints`, que sí era real.
class PointsScreen extends ConsumerStatefulWidget {
  const PointsScreen({super.key});

  @override
  ConsumerState<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends ConsumerState<PointsScreen> {
  CitizenSummary? _summary;
  List<PointsTransactionEntry> _history = [];
  bool _isLoading = true;
  String? _error;

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
      final results = await Future.wait([
        ref.read(analyticsRepositoryProvider).getCitizenSummary(),
        ref.read(pointsRepositoryProvider).getHistory(limit: 30),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as CitizenSummary;
        _history = results[1] as List<PointsTransactionEntry>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'No se pudo cargar tu historial de puntos.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userPoints = ref.watch(authProvider)?.points ?? 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const MainAppBar(title: 'Mis puntos'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? _buildError(_error!)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    children: [
                      _buildBalanceCard(userPoints),
                      const SizedBox(height: 16),
                      _buildHowToEarnCard(),
                      const SizedBox(height: 16),
                      _buildHistoryCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: AppColors.outline, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(int userPoints) {
    final summary = _summary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SALDO ACTUAL', style: TextStyle(color: AppColors.primaryFixed, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$userPoints', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text('puntos', style: TextStyle(color: AppColors.primaryFixed, fontSize: 15)),
            ],
          ),
          if (summary != null) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total ganado', style: TextStyle(color: AppColors.primaryFixed, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('+${summary.pointsEarned}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total canjeado', style: TextStyle(color: AppColors.primaryFixed, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('-${summary.pointsRedeemed}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHowToEarnCard() {
    const actions = [
      ('Validar un reporte de otro ciudadano', '+2 pts', Icons.thumb_up_outlined),
      ('Que tu reporte sea resuelto', '+15 pts', Icons.task_alt_outlined),
      ('Entregar material reciclable', 'Según el peso', Icons.recycling_outlined),
    ];
    return _card(
      title: 'Cómo ganar puntos',
      child: Column(
        children: actions
            .map(
              (a) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(a.$3, size: 18, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(child: Text(a.$1, style: const TextStyle(fontSize: 13, color: AppColors.onSurface))),
                    Text(a.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildHistoryCard() {
    if (_history.isEmpty) {
      return _card(
        title: 'Historial de movimientos',
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Todavía no tienes movimientos de puntos.', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
        ),
      );
    }
    return _card(
      title: 'Historial de movimientos',
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _history.length,
        separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.outlineVariant),
        itemBuilder: (context, index) {
          final tx = _history[index];
          final isPositive = tx.delta >= 0;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPositive ? AppColors.primaryFixed.withValues(alpha: 0.3) : AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? AppColors.onPrimaryFixedVariant : AppColors.onErrorContainer,
                size: 16,
              ),
            ),
            title: Text(_reasonLabel(tx.reason), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(DateFormat('d MMM yyyy, HH:mm').format(tx.createdAt.toLocal()), style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
            trailing: Text(
              '${isPositive ? '+' : ''}${tx.delta}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isPositive ? AppColors.primary : AppColors.error,
              ),
            ),
          );
        },
      ),
    );
  }

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'REPORT_INCIDENT':
        return 'Reporte de incidente';
      case 'VALIDATE_INCIDENT':
        return 'Validación de reporte';
      case 'RESOLVE_INCIDENT':
        return 'Reporte resuelto';
      case 'RECYCLING_PICKUP':
        return 'Recojo de reciclaje confirmado';
      case 'REDEMPTION':
        return 'Canje en tienda';
      case 'PENALTY':
        return 'Penalización';
      case 'ADMIN_ADJUSTMENT':
        return 'Ajuste administrativo';
      default:
        return reason;
    }
  }

  Widget _card({required String title, required Widget child, EdgeInsets? padding}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: padding != null ? const EdgeInsets.fromLTRB(16, 16, 16, 0) : EdgeInsets.zero,
              child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
            ),
            SizedBox(height: padding != null ? 8 : 12),
            child,
          ],
        ),
      ),
    );
  }
}
