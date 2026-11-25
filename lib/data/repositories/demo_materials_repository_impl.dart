import '../../core/network/api_exception.dart';
import '../../domain/entities/material_type.dart';
import '../../domain/repositories/materials_repository.dart';
import '../demo/demo_state.dart';

/// Materiales en modo demo.
///
/// Escribe sobre `DemoState.materials`, que es la misma lista que lee el
/// formulario de publicación: cambiar los puntos por kilo acá se ve en el
/// siguiente recojo, igual que contra el servidor.
class DemoMaterialsRepositoryImpl implements MaterialsRepository {
  DemoMaterialsRepositoryImpl(this._state);

  final DemoState _state;

  /// Histórico simulado. El modo demo no persiste nada entre arranques, así
  /// que el histórico vive acá y se reinicia con la app.
  final Map<String, List<MaterialPrice>> _history = {};

  int _indexOf(String id) {
    final i = _state.materials.indexWhere((m) => m.id == id);
    if (i < 0) {
      throw ApiException(statusCode: 404, message: 'Material no encontrado.');
    }
    return i;
  }

  @override
  Future<List<MaterialType>> getAll({bool includeInactive = false}) async {
    return _state.materials.where((m) => includeInactive || m.isActive).toList();
  }

  @override
  Future<MaterialType> getById(String id) async {
    final m = _state.materials[_indexOf(id)];
    return m.copyWith(priceHistory: _history[id] ?? const []);
  }

  @override
  Future<MaterialType> update(String id, MaterialTypeInput input) async {
    final i = _indexOf(id);
    final updated = _state.materials[i].copyWith(
      pointsPerKg: input.pointsPerKg,
      minPayoutThreshold: input.minPayoutThreshold,
      co2FactorPerKg: input.co2FactorPerKg,
      isActive: input.isActive,
    );
    _state.materials[i] = updated;
    return updated.copyWith(priceHistory: _history[id] ?? const []);
  }

  @override
  Future<void> setPrice({
    required String materialId,
    required double pricePerKg,
    required DateTime effectiveDate,
    String? companyId,
  }) async {
    final i = _indexOf(materialId);

    // Igual que el backend: el anterior deja de ser vigente, no se pisa.
    final previos = [
      for (final p in _history[materialId] ?? const <MaterialPrice>[])
        MaterialPrice(
          id: p.id,
          pricePerKg: p.pricePerKg,
          effectiveDate: p.effectiveDate,
          isCurrent: false,
          companyId: p.companyId,
          createdAt: p.createdAt,
        ),
    ];

    final anterior = _state.materials[i].currentPricePerKg;
    if (previos.isEmpty && anterior > 0) {
      previos.add(
        MaterialPrice(
          id: 'demo-precio-$materialId-0',
          pricePerKg: anterior,
          effectiveDate: effectiveDate.subtract(const Duration(days: 30)),
          isCurrent: false,
          createdAt: effectiveDate.subtract(const Duration(days: 30)),
        ),
      );
    }

    _history[materialId] = [
      MaterialPrice(
        id: 'demo-precio-$materialId-${previos.length + 1}',
        pricePerKg: pricePerKg,
        effectiveDate: effectiveDate,
        isCurrent: true,
        companyId: companyId,
        createdAt: DateTime.now(),
      ),
      ...previos,
    ];

    _state.materials[i] =
        _state.materials[i].copyWith(currentPricePerKg: pricePerKg);
  }
}
