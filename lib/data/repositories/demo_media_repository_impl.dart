import '../../domain/repositories/media_repository.dart';

/// No hay almacenamiento real en modo demo: se devuelve un id falso al
/// instante y una imagen de stock, igual de offline que los logos/íconos que
/// ya usaba el mock anterior ([LocalJsonDatasource._seedData]).
class DemoMediaRepositoryImpl implements MediaRepository {
  @override
  Future<UploadedMedia> uploadImage(String filePath, {String folder = 'general'}) async {
    return UploadedMedia(
      id: 'demo-media-${DateTime.now().microsecondsSinceEpoch}',
      url: 'https://cdn-icons-png.flaticon.com/512/3141/3141811.png',
    );
  }
}
