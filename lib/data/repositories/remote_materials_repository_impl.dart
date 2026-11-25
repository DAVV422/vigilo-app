import '../../domain/entities/material_type.dart';
import '../../domain/repositories/materials_repository.dart';
import '../datasources/remote/remote_materials_datasource.dart';

class RemoteMaterialsRepositoryImpl implements MaterialsRepository {
  RemoteMaterialsRepositoryImpl(this._datasource);

  final RemoteMaterialsDatasource _datasource;

  @override
  Future<List<MaterialType>> getAll({bool includeInactive = false}) async {
    final raw = await _datasource.getAll(includeInactive: includeInactive);
    return raw
        .map((m) => MaterialType.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MaterialType> getById(String id) async {
    return MaterialType.fromJson(await _datasource.getById(id));
  }

  @override
  Future<MaterialType> update(String id, MaterialTypeInput input) async {
    return MaterialType.fromJson(await _datasource.update(id, input.toJson()));
  }

  @override
  Future<void> setPrice({
    required String materialId,
    required double pricePerKg,
    required DateTime effectiveDate,
    String? companyId,
  }) {
    final d = effectiveDate;
    final fecha = '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    return _datasource.createPrice(materialId, {
      'pricePerKg': pricePerKg,
      'effectiveDate': fecha,
      'companyId': ?companyId,
    });
  }
}
