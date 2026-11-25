import '../../domain/entities/redemption.dart';
import '../../domain/entities/store_product.dart';
import '../../domain/repositories/store_repository.dart';
import '../datasources/remote/remote_store_datasource.dart';
import '../../core/network/json_parsing.dart';

class RemoteStoreRepositoryImpl implements StoreRepository {
  RemoteStoreRepositoryImpl(this._datasource);

  final RemoteStoreDatasource _datasource;

  @override
  Future<List<StoreProduct>> getProducts() async {
    final raw = await _datasource.getProducts();
    return raw.map((json) => StoreProduct.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<({Redemption redemption, int remainingBalance})> redeem(String productId) async {
    final json = await _datasource.redeem(productId);
    final product = json['product'] as Map<String, dynamic>?;
    final redemption = Redemption(
      id: json['redemptionId'] as String,
      productId: product?['id'] as String? ?? productId,
      productName: product?['name'] as String?,
      productImageUrl: product?['imageUrl'] as String?,
      pointsSpent: toInt(json['pointsSpent'], field: 'pointsSpent'),
      code: json['code'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
    return (redemption: redemption, remainingBalance: toInt(json['remainingBalance'], field: 'remainingBalance'));
  }

  @override
  Future<List<Redemption>> getMyRedemptions() async {
    final raw = await _datasource.getMyRedemptions();
    return raw.map((json) => Redemption.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<StoreProduct>> getAllProducts() async {
    final raw = await _datasource.getAllProducts();
    return raw.map((j) => StoreProduct.fromJson(j as Map<String, dynamic>)).toList();
  }

  @override
  Future<StoreProduct> createProduct(ProductInput input) async {
    return StoreProduct.fromJson(await _datasource.createProduct(input.toJson()));
  }

  @override
  Future<StoreProduct> updateProduct(String id, ProductInput input) async {
    return StoreProduct.fromJson(await _datasource.updateProduct(id, input.toJson()));
  }
}
