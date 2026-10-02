class UploadedMedia {
  final String id;
  final String url;
  UploadedMedia({required this.id, required this.url});
}

/// Sube un archivo a `/media/upload` y devuelve su `id` real (UUID), que es
/// lo que esperan photoMediaId/voucherMediaId/resolutionMediaId en el resto
/// de la API — no la URL pública del archivo.
abstract class MediaRepository {
  Future<UploadedMedia> uploadImage(String filePath, {String folder = 'general'});
}
