import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class ImageCacheService {
  static const String _appFolder = 'cotorra';
  static const String _imageFolder = 'images';

  final Dio _dio;

  ImageCacheService({Dio? dio}) : _dio = dio ?? Dio();

  Future<Directory> _getImageDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/$_appFolder/$_imageFolder');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir;
  }

  String _getFileName(int docId) {
    final ext = _getExtension(docId);
    return '$docId$ext';
  }

  String _getExtension(int docId) {
    return '.jpg';
  }

  Future<String?> getLocalImagePath(int docId) async {
    final imageDir = await _getImageDirectory();
    final file = File('${imageDir.path}/${_getFileName(docId)}');
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }

  Future<bool> isImageCached(int docId) async {
    final path = await getLocalImagePath(docId);
    return path != null;
  }

  Future<String> downloadAndCacheImage(
    String url,
    int docId, {
    void Function(int received, int total)? onProgress,
  }) async {
    final imageDir = await _getImageDirectory();
    final filePath = '${imageDir.path}/${_getFileName(docId)}';
    final file = File(filePath);

    if (await file.exists()) {
      return filePath;
    }

    await _dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1 && onProgress != null) {
          onProgress(received, total);
        }
      },
    );

    return filePath;
  }

  Future<void> deleteImage(int docId) async {
    final path = await getLocalImagePath(docId);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> clearCache() async {
    final imageDir = await _getImageDirectory();
    if (await imageDir.exists()) {
      await imageDir.delete(recursive: true);
      await imageDir.create(recursive: true);
    }
  }

  Future<int> getCacheSize() async {
    final imageDir = await _getImageDirectory();
    if (!await imageDir.exists()) return 0;

    int totalSize = 0;
    await for (final entity in imageDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }
}
