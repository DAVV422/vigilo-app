import '../../domain/repositories/media_repository.dart';
import '../datasources/remote/remote_media_datasource.dart';

class RemoteMediaRepositoryImpl implements MediaRepository {
  RemoteMediaRepositoryImpl(this._datasource);

  final RemoteMediaDatasource _datasource;

  @override
  Future<UploadedMedia> uploadImage(String filePath, {String folder = 'general'}) async {
    final json = await _datasource.upload(filePath, folder);
    return UploadedMedia(id: json['id'] as String, url: json['url'] as String);
  }
}
