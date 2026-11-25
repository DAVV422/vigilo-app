import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/admin_user.dart';
import '../../../domain/entities/system_config.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/confirm_action_dialog.dart';

const _log = AppLogger('AdminConfig');

/// Los parámetros que gobiernan el marketplace.
///
/// Dos secciones y no dos pantallas: son tres campos en total y repartirlos
/// sería peor. Arriba lo global, que afecta a todos a la vez; abajo el
/// límite de una persona concreta, que es la única parte que necesita
/// buscar a alguien.
class AdminSystemConfigScreen extends ConsumerStatefulWidget {
  const AdminSystemConfigScreen({super.key});

  @override
  ConsumerState<AdminSystemConfigScreen> createState() =>
      _AdminSystemConfigScreenState();
}

class _AdminSystemConfigScreenState
    extends ConsumerState<AdminSystemConfigScreen> {
  List<SystemConfig> _configs = [];
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;
  Object? _error;
  String? _saving;

  // --- Límite por recolector ---
  final _search = TextEditingController();
  final _limit = TextEditingController();
  List<AdminUser> _results = [];
  AdminUser? _selected;
  bool _searching = false;
  String? _searchMessage;
  bool _savingLimit = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _search.dispose();
    _limit.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await ref.read(systemConfigRepositoryProvider).getAll();
      if (!mounted) return;
      setState(() {
        _configs = list;
        for (final c in list) {
          _controllers.putIfAbsent(c.key, () => TextEditingController());
          _controllers[c.key]!.text = c.value;
        }
        _isLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      describeError(e, st, log: _log, operation: 'cargar la configuración');
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _save(SystemConfig config) async {
    final texto = _controllers[config.key]!.text.trim();
    final spec = SystemConfigSpec.of(config.key);

    if (texto.isEmpty) {
      _snack('El valor no puede quedar vacío.', isError: true);
      return;
    }

    // El servidor acepta cualquier texto; esta es la única validación que
    // existe para una clave que el código lee como entero.
    if (spec != null) {
      final n = int.tryParse(texto);
      if (n == null) {
        _snack('${spec.label} tiene que ser un número entero.', isError: true);
        return;
      }
      if (n < spec.min || n > spec.max) {
        _snack(
          '${spec.label}: tiene que estar entre ${spec.min} y ${spec.max} '
          '${spec.unit}.',
          isError: true,
        );
        return;
      }
      if (spec.confirmBelow != null && n < spec.confirmBelow!) {
        final ok = await confirmAction(
          context,
          title: 'Bajar a $n ${spec.unit}',
          consequence: spec.consequence,
          confirmLabel: 'Guardar igual',
        );
        if (!ok || !mounted) return;
      }
    }

    setState(() => _saving = config.key);
    try {
      await ref.read(systemConfigRepositoryProvider).update(config.key, texto);
      if (!mounted) return;
      setState(() => _saving = null);
      _snack('${spec?.label ?? config.key} actualizado.');
      await _load();
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _saving = null);
      _snack(
        describeError(e, st,
            log: _log,
            operation: 'guardar la configuración',
            whereToCheck: 'la configuración del sistema'),
        isError: true,
      );
    }
  }

  Future<void> _doSearch() async {
    final q = _search.text.trim();
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
        _searchMessage = list.isNotEmpty
            ? null
            : AppConfig.demoMode
                ? 'El modo demo no tiene un padrón de usuarios para buscar.'
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

  Future<void> _saveLimit({required bool restablecer}) async {
    final u = _selected!;
    int? valor;

    if (!restablecer) {
      valor = int.tryParse(_limit.text.trim());
      if (valor == null || valor < 1) {
        _snack('El límite tiene que ser 1 o más.', isError: true);
        return;
      }
    }

    setState(() => _savingLimit = true);
    try {
      await ref
          .read(systemConfigRepositoryProvider)
          .setRecyclerPickupLimit(u.id, valor);
      if (!mounted) return;
      setState(() => _savingLimit = false);
      _snack(
        restablecer
            ? '${u.firstName} vuelve al límite estándar de la plataforma.'
            : '${u.firstName} queda con $valor recojos activos como máximo.',
      );
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _savingLimit = false);
      _snack(
        describeError(e, st,
            log: _log,
            operation: 'ajustar el límite',
            whereToCheck: 'la configuración del sistema'),
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
      title: 'Configuración del sistema',
      onRefresh: _load,
      body: AdminAsyncView(
        isLoading: _isLoading,
        error: _error,
        onRetry: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics:
              const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
            _header('PARÁMETROS GLOBALES'),
            for (final c in _configs) _buildConfig(c),
            const SizedBox(height: 22),
            _header('LÍMITE DE UN RECOLECTOR'),
            _buildRecyclerLimit(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      );

  Widget _buildConfig(SystemConfig c) {
    final spec = SystemConfigSpec.of(c.key);
    final guardando = _saving == c.key;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controllers[c.key],
            enabled: !guardando,
            keyboardType:
                spec == null ? TextInputType.text : TextInputType.number,
            decoration: InputDecoration(
              labelText: spec?.label ?? c.key,
              // La unidad siempre al lado: un número suelto no dice nada.
              suffixText: spec?.unit,
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            // La consecuencia, no la definición. La descripción del
            // servidor está escrita para quien programó el sistema.
            spec?.consequence ?? c.description ?? 'Clave sin documentar.',
            style: const TextStyle(
                fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          if (spec == null) ...[
            const SizedBox(height: 6),
            const Text(
              'El sistema no conoce esta clave: se guarda tal cual, sin '
              'validar.',
              style: TextStyle(fontSize: 11, color: AppColors.tertiary),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: guardando ? null : () => _save(c),
              child: guardando
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecyclerLimit() {
    final u = _selected;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sobreescribe el límite estándar para una persona concreta. '
            'Solo funciona con recolectores.',
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          if (u == null) ...[
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _doSearch(),
              decoration: InputDecoration(
                labelText: 'Buscar al recolector',
                isDense: true,
                suffixIcon: IconButton(
                  onPressed: _doSearch,
                  icon: const Icon(Icons.search),
                ),
              ),
            ),
            if (_searching)
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child:
                    Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (_searchMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _searchMessage!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              )
            else
              for (final r in _results)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onTap: () => setState(() {
                    _selected = r;
                    _results = [];
                    _search.clear();
                  }),
                  title: Text(r.fullName, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(
                    r.isRecycler ? '@${r.username} · recolector' : '@${r.username}',
                    style: TextStyle(
                      fontSize: 12,
                      // Se muestra igual, pero avisando: el servidor va a
                      // rechazarlo y es mejor saberlo antes de tocar nada.
                      color: r.isRecycler
                          ? AppColors.onSurfaceVariant
                          : AppColors.error,
                    ),
                  ),
                ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.fullName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        u.isRecycler
                            ? '@${u.username} · recolector'
                            : '@${u.username} · no es recolector',
                        style: TextStyle(
                          fontSize: 12,
                          color: u.isRecycler
                              ? AppColors.onSurfaceVariant
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _savingLimit
                      ? null
                      : () => setState(() {
                            _selected = null;
                            _limit.clear();
                          }),
                  child: const Text('Cambiar'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _limit,
              enabled: !_savingLimit,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Recojos activos como máximo',
                suffixText: 'recojos',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _savingLimit
                        ? null
                        : () => _saveLimit(restablecer: false),
                    child: const Text('Fijar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _savingLimit ? null : () => _saveLimit(restablecer: true),
                    child: const Text('Estándar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              // `null` es «volver al estándar», no cero. Si no se dice, se
              // deduce mal.
              '«Estándar» devuelve a esta persona al límite global de la '
              'plataforma. No es lo mismo que poner cero.',
              style:
                  TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
