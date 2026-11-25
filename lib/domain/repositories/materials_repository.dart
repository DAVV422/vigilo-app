import '../entities/material_type.dart';

/// Los atributos editables de un material.
///
/// Todos opcionales porque el backend aplica solo lo que llega: mandar el
/// objeto entero sobreescribiría campos que nadie tocó.
class MaterialTypeInput {
  const MaterialTypeInput({
    this.pointsPerKg,
    this.minPayoutThreshold,
    this.co2FactorPerKg,
    this.isActive,
  });

  final double? pointsPerKg;
  final double? minPayoutThreshold;
  final double? co2FactorPerKg;
  final bool? isActive;

  bool get isEmpty =>
      pointsPerKg == null &&
      minPayoutThreshold == null &&
      co2FactorPerKg == null &&
      isActive == null;

  Map<String, dynamic> toJson() => {
        'pointsPerKg': ?pointsPerKg,
        'minPayoutThreshold': ?minPayoutThreshold,
        'co2FactorPerKg': ?co2FactorPerKg,
        'isActive': ?isActive,
      };
}

/// Gobierno de los materiales: cuánto vale cada kilo y cuántos puntos da.
///
/// Está separado de `RecyclingRepository` —que también lee materiales— porque
/// no es parte del flujo de reciclaje sino de su configuración: lo usa quien
/// administra la plataforma, no quien recicla.
abstract class MaterialsRepository {
  /// [includeInactive] es para la pantalla de administración. Sin eso, un
  /// material desactivado desaparecería de la única vista que permite
  /// volver a activarlo.
  Future<List<MaterialType>> getAll({bool includeInactive = false});

  /// Trae además el histórico de precios.
  Future<MaterialType> getById(String id);

  Future<MaterialType> update(String id, MaterialTypeInput input);

  /// Fija un precio nuevo. No actualiza el anterior: inserta una fila y
  /// marca la vigente como no vigente.
  Future<void> setPrice({
    required String materialId,
    required double pricePerKg,
    required DateTime effectiveDate,
    String? companyId,
  });
}
