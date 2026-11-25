import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/admin_user.dart';
import '../../../domain/entities/penalty.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../widgets/ratings/rating_stars.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/confirm_action_dialog.dart';

const _log = AppLogger('AdminSanciones');

/// Aplicar una sanción a alguien.
///
/// Descuenta puntos del saldo de otra persona, puede revocarle el rol de
/// recolector y le manda una notificación. Es, junto con resolver una
/// disputa, lo que más consecuencias tiene de lo que hace un administrador.
class AdminApplyPenaltyScreen extends ConsumerStatefulWidget {
  const AdminApplyPenaltyScreen({super.key, this.preselected});

  /// Para llegar acá desde una pantalla que ya sabe a quién sancionar.
  final AdminUser? preselected;

  @override
  ConsumerState<AdminApplyPenaltyScreen> createState() =>
      _AdminApplyPenaltyScreenState();
}

class _AdminApplyPenaltyScreenState
    extends ConsumerState<AdminApplyPenaltyScreen> {
  final _search = TextEditingController();
  final _reason = TextEditingController();

  List<AdminUser> _results = [];
  bool _searching = false;
  String? _searchMessage;

  AdminUser? _selected;
  List<PenaltyRule> _rules = [];
  PenaltyRule? _rule;

  /// Sanciones previas de la persona elegida, para anticipar la escala.
  List<Penalty> _history = [];
  bool _loadingHistory = false;

  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.preselected;
    _loadRules();
    if (_selected != null) _loadHistory(_selected!.id);
  }

  @override
  void dispose() {
    _search.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _loadRules() async {
    try {
      final list = await ref.read(penaltiesRepositoryProvider).getRules();
      if (!mounted) return;
      setState(() {
        _rules = list.where((r) => r.active).toList();
        _rule ??= _rules.isEmpty ? null : _rules.first;
      });
    } catch (e, st) {
      if (!mounted) return;
      _snack(
        describeError(e, st, log: _log, operation: 'cargar las reglas'),
        isError: true,
      );
    }
  }

  Future<void> _doSearch() async {
    final q = _search.text.trim();
    // Mismo mínimo que el servidor, para no gastar una vuelta en un 400.
    if (q.length < 3) {
      setState(() => _searchMessage = 'Escribí al menos 3 letras.');
      return;
    }

    setState(() {
      _searching = true;
      _searchMessage = null;
    });
    try {
      final list = await ref.read(adminUsersRepositoryProvider).search(q);
      if (!mounted) return;
      setState(() {
        _results = list;
        _searching = false;
        // En modo demo no hay padrón que recorrer, así que nunca va a
        // coincidir nadie. Decir «nadie coincide» sugeriría que el nombre
        // está mal escrito.
        _searchMessage = list.isNotEmpty
            ? null
            : AppConfig.demoMode
                ? 'El modo demo no tiene un padrón de usuarios para buscar. '
                    'Esta pantalla funciona contra el servidor.'
                : 'Nadie coincide con «$q».';
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _searching = false);
      _snack(
        describeError(e, st, log: _log, operation: 'buscar a la persona'),
        isError: true,
      );
    }
  }

  Future<void> _select(AdminUser u) async {
    setState(() {
      _selected = u;
      _results = [];
      _search.clear();
      _searchMessage = null;
    });
    await _loadHistory(u.id);
  }

  Future<void> _loadHistory(String userId) async {
    setState(() => _loadingHistory = true);
    try {
      final list = await ref
          .read(penaltiesRepositoryProvider)
          .getPenalties(userId: userId);
      if (!mounted) return;
      setState(() {
        _history = list;
        _loadingHistory = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      describeError(e, st, log: _log, operation: 'cargar el historial');
      // Sin historial la pantalla sigue sirviendo; lo que se pierde es
      // poder anticipar cuántos puntos se van a descontar.
      setState(() {
        _history = [];
        _loadingHistory = false;
      });
    }
  }

  /// Qué número de falta sería esta, con el mismo criterio que el servidor:
  /// mismas infracciones, dentro de la ventana de la regla.
  int get _occurrence {
    final r = _rule;
    if (r == null) return 1;
    final desde = DateTime.now().subtract(Duration(days: r.evaluationWindowDays));
    final previas = _history.where((p) =>
        p.infractionCode == r.infractionCode && p.startsAt.isAfter(desde));
    return previas.length + 1;
  }

  Future<void> _apply() async {
    final u = _selected;
    final r = _rule;
    if (u == null) {
      _snack('Elegí a quién sancionar.', isError: true);
      return;
    }
    if (r == null) {
      _snack('No hay ninguna regla activa que aplicar.', isError: true);
      return;
    }
    if (_reason.text.trim().length < 10) {
      _snack(
        'Escribí el motivo: qué pasó, cuándo y dónde.',
        isError: true,
      );
      return;
    }

    final n = _occurrence;
    final puntos = r.pointsForOccurrence(n);
    final suspende = r.suspendsAt(n);

    final ok = await confirmAction(
      context,
      title: 'Sancionar a ${u.firstName}',
      consequence: [
        'Se le descuentan $puntos puntos de los ${u.pointsBalance} que tiene.',
        if (suspende && r.infractionCode == 'NO_SHOW_RECYCLER' && u.isRecycler)
          'Queda suspendida y pierde el rol de recolector.'
        else if (suspende)
          'Queda suspendida temporalmente.',
        'Le llega una notificación con el motivo que escribiste.',
      ].join(' '),
      confirmLabel: 'Sancionar',
      isDestructive: true,
    );
    if (!ok || !mounted) return;

    setState(() => _sending = true);
    try {
      final aplicada = await ref.read(penaltiesRepositoryProvider).apply(
            userId: u.id,
            infractionCode: r.infractionCode,
            reason: _reason.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
      _snack(
        'Sanción aplicada: −${aplicada.pointsDeducted} puntos. '
        'Le quedan ${aplicada.remainingBalance}.',
      );
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _sending = false);
      _snack(
        describeError(e, st,
            log: _log,
            operation: 'aplicar la sanción',
            whereToCheck: 'el historial de sanciones'),
        isError: true,
      );
    }
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Aplicar una sanción',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_selected == null) ..._buildSearch() else ..._buildForm(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _buildSearch() {
    return [
      TextField(
        controller: _search,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _doSearch(),
        decoration: InputDecoration(
          labelText: 'Buscar a la persona',
          hintText: 'Nombre, usuario o correo',
          helperText: 'Al menos 3 letras.',
          suffixIcon: IconButton(
            onPressed: _doSearch,
            icon: const Icon(Icons.search),
          ),
        ),
      ),
      const SizedBox(height: 14),
      if (_searching)
        const Center(child: CircularProgressIndicator(color: AppColors.primary))
      else if (_searchMessage != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            _searchMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
        )
      else
        for (final u in _results) _buildUserTile(u),
    ];
  }

  Widget _buildUserTile(AdminUser u) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () => _select(u),
        title: Text(u.fullName, style: const TextStyle(fontSize: 14)),
        subtitle: Text(
          '@${u.username} · ${u.pointsBalance} pts',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: u.ratingsCount > 0
            ? RatingScoreBadge(score: u.trustScore, count: u.ratingsCount)
            : null,
      ),
    );
  }

  List<Widget> _buildForm() {
    final u = _selected!;
    final r = _rule;
    final n = _occurrence;

    return [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.fullName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${u.pointsBalance} puntos · '
                    '${u.isRecycler ? "recolector" : "ciudadano"}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (widget.preselected == null)
              TextButton(
                onPressed: _sending
                    ? null
                    : () => setState(() {
                          _selected = null;
                          _history = [];
                        }),
                child: const Text('Cambiar'),
              ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        'INFRACCIÓN',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 4),
      RadioGroup<String>(
        groupValue: _rule?.infractionCode,
        onChanged: (v) {
          if (_sending || v == null) return;
          setState(() =>
              _rule = _rules.firstWhere((x) => x.infractionCode == v));
        },
        child: Column(
          children: [
            for (final regla in _rules)
              RadioListTile<String>(
                value: regla.infractionCode,
                title: Text(regla.label,
                    style: const TextStyle(fontSize: 14)),
                subtitle: Text(regla.description,
                    style: const TextStyle(fontSize: 12)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      if (r != null) _buildImpact(r, n, u),
      const SizedBox(height: 14),
      TextField(
        controller: _reason,
        enabled: !_sending,
        maxLines: 3,
        maxLength: 500,
        decoration: const InputDecoration(
          labelText: 'Motivo',
          // Es lo único que va a quedar para explicar el descuento.
          helperText: 'Qué pasó, cuándo y dónde. Dentro de seis meses es lo '
              'único que explica este descuento.',
          helperMaxLines: 3,
        ),
      ),
      const SizedBox(height: 8),
      ElevatedButton(
        onPressed: _sending ? null : _apply,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.onError,
        ),
        child: _sending
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Aplicar la sanción'),
      ),
    ];
  }

  Widget _buildImpact(PenaltyRule r, int n, AdminUser u) {
    if (_loadingHistory) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'Calculando el efecto…',
          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
        ),
      );
    }

    final puntos = r.pointsForOccurrence(n);
    final suspende = r.suspendsAt(n);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: suspende
            ? AppColors.errorContainer
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            n == 1
                ? 'Primera falta de este tipo.'
                : 'Sería la $n.ª falta de este tipo en '
                    '${r.evaluationWindowDays} días.',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '−$puntos puntos. Le quedarían '
            '${(u.pointsBalance - puntos).clamp(0, u.pointsBalance)}.',
            style: const TextStyle(fontSize: 13),
          ),
          if (suspende) ...[
            const SizedBox(height: 4),
            Text(
              r.infractionCode == 'NO_SHOW_RECYCLER' && u.isRecycler
                  ? 'Además queda suspendida y pierde el rol de recolector.'
                  : 'Además queda suspendida temporalmente.',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.onErrorContainer),
            ),
          ],
        ],
      ),
    );
  }
}
