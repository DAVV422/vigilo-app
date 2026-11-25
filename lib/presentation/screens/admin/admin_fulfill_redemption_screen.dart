import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/redemption.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/confirm_action_dialog.dart';

const _log = AppLogger('AdminCanjes');

/// Mostrador: buscar un canje por su código y entregarlo.
///
/// Es la única pantalla de gestión que alguien va a usar varias veces por
/// día, de pie y con una persona esperando enfrente. Todo lo que sigue está
/// pensado alrededor de eso: el campo arranca con el foco puesto, el
/// teclado va en mayúsculas, y al entregar se vuelve solo al estado de
/// búsqueda en vez de obligar a navegar hacia atrás.
class AdminFulfillRedemptionScreen extends ConsumerStatefulWidget {
  const AdminFulfillRedemptionScreen({super.key});

  @override
  ConsumerState<AdminFulfillRedemptionScreen> createState() =>
      _AdminFulfillRedemptionScreenState();
}

class _AdminFulfillRedemptionScreenState
    extends ConsumerState<AdminFulfillRedemptionScreen> {
  final _codeController = TextEditingController();
  final _focus = FocusNode();

  Redemption? _found;
  bool _searching = false;
  bool _fulfilling = false;
  String? _notFoundCode;

  @override
  void dispose() {
    _codeController.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _searching = true;
      _found = null;
      _notFoundCode = null;
    });

    try {
      final redemption =
          await ref.read(storeRepositoryProvider).findRedemptionByCode(code);
      if (!mounted) return;
      setState(() {
        _found = redemption;
        _searching = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        // Un código que no existe no es un error del sistema: es lo que
        // pasa cuando alguien se equivoca al tipear. Se muestra como un
        // estado de la pantalla, no como un fallo.
        if (e.statusCode == 404) {
          _notFoundCode = code.toUpperCase();
        }
      });
      if (e.statusCode != 404) _snack(e.message, isError: true);
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _searching = false);
      _snack(
        describeError(e, st, log: _log, operation: 'buscar el canje'),
        isError: true,
      );
    }
  }

  Future<void> _fulfill(Redemption redemption) async {
    final ok = await confirmAction(
      context,
      title: 'Entregar el canje',
      consequence:
          'Vas a marcar "${redemption.productName ?? 'el producto'}" como '
          'entregado a ${redemption.userName ?? 'esta persona'}. '
          'No se puede deshacer.',
      confirmLabel: 'Entregar',
    );
    if (!ok || !mounted) return;

    setState(() => _fulfilling = true);
    try {
      await ref.read(storeRepositoryProvider).fulfillRedemption(redemption.id);
      if (!mounted) return;
      setState(() {
        _fulfilling = false;
        _found = null;
        _codeController.clear();
      });
      _focus.requestFocus();
      _snack('Canje entregado.');
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _fulfilling = false);
      _snack(
        describeError(
          e,
          st,
          log: _log,
          operation: 'registrar la entrega',
          // Lo más probable en un mostrador es quedarse sin señal. Si no se
          // pudo registrar, el producto no se entrega.
          whereToCheck: 'el canje buscándolo de nuevo por su código',
        ),
        isError: true,
      );
    }
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Entrega de canjes',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _codeController,
            focusNode: _focus,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              letterSpacing: 1.2,
            ),
            decoration: InputDecoration(
              labelText: 'Código del canje',
              hintText: 'VIG-XXXXXXX-XXXX',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _searching ? null : _search,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pedile el código a la persona. No distingue mayúsculas.',
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          if (_searching)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (_notFoundCode != null)
            _buildNotFound()
          else if (_found != null)
            _buildFound(_found!),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return Column(
      children: [
        const Icon(Icons.search_off, size: 40, color: AppColors.outline),
        const SizedBox(height: 10),
        Text(
          'No existe ningún canje con el código $_notFoundCode',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 6),
        const Text(
          'Revisá que esté completo y volvé a intentar.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildFound(Redemption r) {
    final delivered = r.status == 'FULFILLED';
    final cancelled = r.status == 'CANCELLED';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(
          color: delivered ? AppColors.outlineVariant : AppColors.primary,
          width: delivered ? 1 : 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (r.productImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    r.productImageUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(width: 52, height: 52),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.productName ?? 'Producto no disponible',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r.pointsSpent} puntos',
                      style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _row('Entregar a', r.userName ?? 'Desconocido'),
          _row('Código', r.code),
          _row('Canjeado el', _formatDate(r.createdAt)),
          if (delivered) _row('Entregado el', _formatDate(r.fulfilledAt!)),
          const SizedBox(height: 16),
          if (delivered)
            _banner(
              Icons.check_circle_outline,
              'Este canje ya fue entregado.',
              AppColors.primary,
            )
          else if (cancelled)
            _banner(Icons.block, 'Este canje fue cancelado.', AppColors.error)
          else
            ElevatedButton.icon(
              onPressed: _fulfilling ? null : () => _fulfill(r),
              icon: _fulfilling
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Marcar como entregado'),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
          if (label == 'Código')
            InkWell(
              onTap: () => Clipboard.setData(ClipboardData(text: value)),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.copy_rounded, size: 15, color: AppColors.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  Widget _banner(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: color)),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
