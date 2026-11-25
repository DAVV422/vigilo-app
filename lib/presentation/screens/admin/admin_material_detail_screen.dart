import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/material_type.dart';
import '../../../domain/repositories/materials_repository.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/confirm_action_dialog.dart';

const _log = AppLogger('AdminMateriales');

/// Edición de un material y de su precio por kilo.
///
/// Dos secciones separadas a propósito, porque son dos operaciones
/// distintas: los atributos se corrigen (`PATCH`), el precio **no se edita**
/// sino que se fija uno nuevo que deja al anterior como histórico.
class AdminMaterialDetailScreen extends ConsumerStatefulWidget {
  const AdminMaterialDetailScreen({super.key, required this.materialId});

  final String materialId;

  @override
  ConsumerState<AdminMaterialDetailScreen> createState() =>
      _AdminMaterialDetailScreenState();
}

class _AdminMaterialDetailScreenState
    extends ConsumerState<AdminMaterialDetailScreen> {
  MaterialType? _material;
  bool _isLoading = true;
  Object? _error;

  /// Para avisarle a la lista que tiene que recargarse al volver.
  bool _changed = false;

  final _points = TextEditingController();
  final _threshold = TextEditingController();
  final _co2 = TextEditingController();
  bool _isActive = true;

  bool _savingAttrs = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _points.dispose();
    _threshold.dispose();
    _co2.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final m = await ref.read(materialsRepositoryProvider).getById(widget.materialId);
      if (!mounted) return;
      setState(() {
        _material = m;
        _points.text = _fmt(m.pointsPerKg);
        _threshold.text = _fmt(m.minPayoutThreshold);
        _co2.text = _fmt(m.co2FactorPerKg);
        _isActive = m.isActive;
        _isLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      describeError(e, st, log: _log, operation: 'cargar el material');
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> _saveAttributes() async {
    final m = _material!;
    final puntos = _parse(_points);
    final umbral = _parse(_threshold);
    final co2 = _parse(_co2);

    if (puntos == null || umbral == null || co2 == null) {
      _snack('Revisá los números: hay un valor inválido.', isError: true);
      return;
    }
    if (puntos < 0 || umbral < 0 || co2 < 0) {
      _snack('Los valores no pueden ser negativos.', isError: true);
      return;
    }

    // Desactivar es lo único de esta pantalla con efecto sobre otras
    // personas, así que es lo único que se confirma.
    if (m.isActive && !_isActive) {
      final ok = await confirmAction(
        context,
        title: 'Desactivar ${m.name}',
        consequence:
            'Deja de ofrecerse al publicar material nuevo. Las publicaciones '
            'y los recojos que ya lo usan siguen funcionando.',
        confirmLabel: 'Desactivar',
        isDestructive: true,
      );
      if (!ok || !mounted) return;
    }

    setState(() => _savingAttrs = true);
    try {
      final actualizado = await ref.read(materialsRepositoryProvider).update(
            m.id,
            MaterialTypeInput(
              pointsPerKg: puntos,
              minPayoutThreshold: umbral,
              co2FactorPerKg: co2,
              isActive: _isActive,
            ),
          );
      if (!mounted) return;
      setState(() {
        _material = actualizado;
        _savingAttrs = false;
        _changed = true;
      });
      _snack('Material actualizado.');
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _savingAttrs = false);
      _snack(
        describeError(e, st,
            log: _log,
            operation: 'guardar el material',
            whereToCheck: 'la lista de materiales'),
        isError: true,
      );
    }
  }

  Future<void> _setPrice() async {
    final m = _material!;
    final nuevo = await showDialog<double>(
      context: context,
      builder: (_) => _PriceDialog(material: m),
    );
    if (nuevo == null || !mounted) return;

    try {
      await ref.read(materialsRepositoryProvider).setPrice(
            materialId: m.id,
            pricePerKg: nuevo,
            // Vigencia de hoy y no editable: el servidor marca el precio
            // nuevo como vigente apenas se inserta, sin mirar la fecha. Un
            // campo de fecha futura prometería algo que no pasa.
            effectiveDate: DateTime.now(),
          );
      if (!mounted) return;
      _changed = true;
      await _load();
      if (!mounted) return;
      _snack('Precio fijado en Bs ${nuevo.toStringAsFixed(2)} por kilo.');
    } catch (e, st) {
      if (!mounted) return;
      _snack(
        describeError(e, st,
            log: _log,
            operation: 'fijar el precio',
            whereToCheck: 'el detalle del material'),
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
    final m = _material;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: AdminScaffold(
        title: m?.name ?? 'Material',
        onRefresh: _load,
        body: AdminAsyncView(
          isLoading: _isLoading,
          error: _error,
          onRetry: _load,
          child: m == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  children: [
                    _buildPriceCard(m),
                    const SizedBox(height: 16),
                    _buildAttributesCard(m),
                    const SizedBox(height: 16),
                    if (m.priceHistory.length > 1) _buildHistoryCard(m),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPriceCard(MaterialType m) {
    return _card(
      title: 'PRECIO VIGENTE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                m.currentPricePerKg > 0
                    ? 'Bs ${m.currentPricePerKg.toStringAsFixed(2)}'
                    : 'Sin precio',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              const Text(
                'por kilo',
                style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Es lo que el recolector le paga al ciudadano por cada kilo '
            'entregado de este material.',
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _setPrice,
            icon: const Icon(Icons.price_change_outlined, size: 18),
            label: const Text('Fijar un precio nuevo'),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributesCard(MaterialType m) {
    return _card(
      title: 'PARÁMETROS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _numberField(
            controller: _points,
            label: 'Puntos por kilo',
            suffix: 'pts / kg',
            help: 'Cuántos puntos gana el ciudadano por cada kilo.',
          ),
          const SizedBox(height: 14),
          _numberField(
            controller: _threshold,
            label: 'Umbral mínimo de pago',
            suffix: 'kg',
            help: 'Debajo de este peso no se liquida compensación.',
          ),
          const SizedBox(height: 14),
          _numberField(
            controller: _co2,
            label: 'Factor de CO₂',
            suffix: 'kg CO₂ / kg',
            help: 'Se usa para calcular el impacto ambiental evitado.',
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            value: _isActive,
            onChanged: _savingAttrs ? null : (v) => setState(() => _isActive = v),
            contentPadding: EdgeInsets.zero,
            title: const Text('Activo', style: TextStyle(fontSize: 14)),
            subtitle: Text(
              _isActive
                  ? 'Se ofrece al publicar material.'
                  : 'No se ofrece al publicar. Lo ya publicado sigue válido.',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savingAttrs ? null : _saveAttributes,
              child: _savingAttrs
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar parámetros'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required String help,
  }) {
    return TextField(
      controller: controller,
      enabled: !_savingAttrs,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        // La unidad siempre al lado del campo: el sistema pesa en gramos y
        // cobra por kilo, y un número sin unidad acá se presta a confusión.
        suffixText: suffix,
        helperText: help,
        helperMaxLines: 2,
      ),
    );
  }

  Widget _buildHistoryCard(MaterialType m) {
    return _card(
      title: 'HISTÓRICO DE PRECIOS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in m.priceHistory)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _date(p.effectiveDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: p.isCurrent
                            ? AppColors.onSurface
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    'Bs ${p.pricePerKg.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: p.isCurrent ? FontWeight.w700 : FontWeight.w400,
                      color: p.isCurrent
                          ? AppColors.onSurface
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (p.isCurrent) ...[
                    const SizedBox(width: 10),
                    const Text(
                      'vigente',
                      style: TextStyle(fontSize: 11, color: AppColors.primary),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// Pide el precio nuevo. Diálogo y no pantalla: es un solo número.
class _PriceDialog extends StatefulWidget {
  const _PriceDialog({required this.material});

  final MaterialType material;

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  final _controller = TextEditingController();
  String? _problema;

  @override
  void initState() {
    super.initState();
    if (widget.material.currentPricePerKg > 0) {
      _controller.text = widget.material.currentPricePerKg.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final v = double.tryParse(_controller.text.trim().replaceAll(',', '.'));
    if (v == null) {
      setState(() => _problema = 'No es un número válido.');
      return;
    }
    // El servidor exige > 0.01; frenarlo acá evita un 400 y explica mejor.
    if (v < 0.01) {
      setState(() => _problema = 'El precio tiene que ser mayor a cero.');
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Fijar precio'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.material.name,
            style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Precio por kilo',
              prefixText: 'Bs ',
              suffixText: '/ kg',
              errorText: _problema,
            ),
            onChanged: (_) {
              if (_problema != null) setState(() => _problema = null);
            },
          ),
          const SizedBox(height: 10),
          const Text(
            'Rige desde hoy. El precio anterior queda guardado en el '
            'histórico.',
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _confirm, child: const Text('Fijar')),
      ],
    );
  }
}

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
