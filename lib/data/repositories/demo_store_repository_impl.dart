import 'dart:math';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_exception.dart';
import '../../domain/entities/redemption.dart';
import '../../domain/entities/store_product.dart';
import '../../domain/repositories/store_repository.dart';
import '../datasources/local_json_datasource.dart';
import '../demo/demo_state.dart';
import '../models/company_model.dart';
import '../models/incident_model.dart';
import '../models/store_product_model.dart';
import '../models/user_model.dart';

const _log = AppLogger('DemoStore');
final _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

String _generateCode() {
  final random = Random();
  return List.generate(6, (_) => _codeChars[random.nextInt(_codeChars.length)]).join();
}

/// Catálogo de tienda respaldado por el mismo archivo local que ya usaba el
/// mock anterior ([LocalJsonDatasource]) — así el stock de un canje persiste
/// entre sesiones de la demo igual que antes. Los canjes en sí ([Redemption])
/// viven solo en memoria ([DemoState]): no estaban modelados en ese archivo.
class DemoStoreRepositoryImpl implements StoreRepository {
  DemoStoreRepositoryImpl(this._datasource, this._state);

  final LocalJsonDatasource _datasource;
  final DemoState _state;

  @override
  Future<List<StoreProduct>> getProducts() async {
    final data = await _datasource.readData();
    final productsJson = data['products'] as List<dynamic>? ?? [];
    return productsJson.map((p) => StoreProductModel.fromJson(p as Map<String, dynamic>)).toList();
  }

  @override
  Future<({Redemption redemption, int remainingBalance})> redeem(String productId) async {
    final user = _state.currentUser;
    if (user == null) throw ApiException(statusCode: 401, message: 'No hay sesión activa.');

    final data = await _datasource.readData();
    final usersJson = data['users'] as List<dynamic>;
    final incidentsJson = data['incidents'] as List<dynamic>;
    final companiesJson = data['companies'] as List<dynamic>;
    final productsJson = data['products'] as List<dynamic>? ?? [];

    final users = usersJson.map((u) => UserModel.fromJson(u)).toList();
    final incidents = incidentsJson.map((i) => IncidentModel.fromJson(i)).toList();
    final companies = companiesJson.map((c) => CompanyModel.fromJson(c as Map<String, dynamic>)).toList();
    final products = productsJson.map((p) => StoreProductModel.fromJson(p as Map<String, dynamic>)).toList();

    final index = products.indexWhere((p) => p.id == productId);
    if (index == -1) throw ApiException(statusCode: 404, message: 'Producto no encontrado.');
    final product = products[index];

    if (!product.active || product.stock <= 0) {
      throw ApiException(statusCode: 409, message: 'Este producto ya no tiene stock disponible.');
    }
    if (user.points < product.pointsCost) {
      throw ApiException(statusCode: 409, message: 'No tienes suficientes puntos para este canje.');
    }

    products[index] = StoreProductModel.fromEntity(product.copyWith(stock: product.stock - 1));
    await _datasource.writeData(users, incidents, companies, products: products);

    _state.creditPoints(
      delta: -product.pointsCost,
      reason: 'Canje: ${product.name}',
      referenceType: 'STORE_REDEMPTION',
      referenceId: product.id,
    );

    final redemption = Redemption(
      id: _state.newId('demo-redemption'),
      productId: product.id,
      productName: product.name,
      productImageUrl: product.imageUrl,
      pointsSpent: product.pointsCost,
      code: _generateCode(),
      status: 'PENDING',
      createdAt: DateTime.now(),
    );
    _state.redemptions.insert(0, redemption);
    _log.info('Canje demo: ${product.name} por ${user.email}');

    return (redemption: redemption, remainingBalance: _state.currentUser?.points ?? 0);
  }

  @override
  Future<List<Redemption>> getMyRedemptions() async => _state.redemptions;

  // --- Administración ---
  //
  // Escriben en el mismo archivo local que el catálogo del ciudadano, igual
  // que hace `redeem` con el stock, para que un producto dado de alta en
  // modo demo siga ahí en la próxima sesión.

  Future<List<StoreProductModel>> _readProducts() async {
    final data = await _datasource.readData();
    final raw = data['products'] as List<dynamic>? ?? [];
    return raw.map((p) => StoreProductModel.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<void> _writeProducts(List<StoreProductModel> products) async {
    final data = await _datasource.readData();
    final users = (data['users'] as List<dynamic>).map((u) => UserModel.fromJson(u)).toList();
    final incidents =
        (data['incidents'] as List<dynamic>).map((i) => IncidentModel.fromJson(i)).toList();
    final companies = (data['companies'] as List<dynamic>)
        .map((c) => CompanyModel.fromJson(c as Map<String, dynamic>))
        .toList();
    await _datasource.writeData(users, incidents, companies, products: products);
  }

  @override
  Future<List<StoreProduct>> getAllProducts() async => _readProducts();

  @override
  Future<StoreProduct> createProduct(ProductInput input) async {
    final products = await _readProducts();
    final created = StoreProduct(
      id: _state.newId('demo-product'),
      name: input.name ?? '',
      description: input.description ?? '',
      imageUrl: input.imageUrl ?? '',
      pointsCost: input.pointsCost ?? 0,
      stock: input.stock ?? 0,
      // El backend normaliza la categoría a mayúsculas; replicarlo evita que
      // el modo demo acumule variantes que el real no tendría.
      category: (input.category ?? 'GENERAL').toUpperCase(),
      active: input.active ?? true,
    );
    products.add(StoreProductModel.fromEntity(created));
    await _writeProducts(products);
    _log.info('Producto demo creado: ${created.name}');
    return created;
  }

  @override
  Future<Redemption> findRedemptionByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    final match = _state.redemptions.where((r) => r.code == normalized);
    if (match.isEmpty) {
      throw ApiException(
        statusCode: 404,
        message: 'No existe ningún canje con el código $normalized',
      );
    }
    return match.first;
  }

  @override
  Future<void> fulfillRedemption(String id) async {
    final index = _state.redemptions.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw ApiException(statusCode: 404, message: 'Canje no encontrado.');
    }
    final current = _state.redemptions[index];
    if (current.status == 'FULFILLED') {
      throw ApiException(statusCode: 409, message: 'Este canje ya fue entregado.');
    }
    _state.redemptions[index] = Redemption(
      id: current.id,
      productId: current.productId,
      productName: current.productName,
      productImageUrl: current.productImageUrl,
      pointsSpent: current.pointsSpent,
      code: current.code,
      status: 'FULFILLED',
      createdAt: current.createdAt,
      fulfilledAt: DateTime.now(),
      userName: current.userName,
    );
    _log.info('Canje demo entregado: ${current.code}');
  }

  @override
  Future<StoreProduct> updateProduct(String id, ProductInput input) async {
    final products = await _readProducts();
    final index = products.indexWhere((p) => p.id == id);
    if (index == -1) {
      throw ApiException(statusCode: 404, message: 'Producto no encontrado.');
    }
    final updated = products[index].copyWith(
      name: input.name,
      description: input.description,
      imageUrl: input.imageUrl,
      pointsCost: input.pointsCost,
      stock: input.stock,
      category: input.category?.toUpperCase(),
      active: input.active,
    );
    products[index] = StoreProductModel.fromEntity(updated);
    await _writeProducts(products);
    return updated;
  }
}
