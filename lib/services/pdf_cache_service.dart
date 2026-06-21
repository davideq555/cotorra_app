import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class PdfCacheService {
  static const String _appFolder = 'cotorra';
  static const String _pdfFolder = 'pdfs';

  final Dio _dio;

  PdfCacheService({Dio? dio}) : _dio = dio ?? Dio();

  Future<Directory> _getPdfDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${appDir.path}/$_appFolder/$_pdfFolder');
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    return pdfDir;
  }

  String _getFileName(int docId) => '$docId.pdf';

  Future<String?> getLocalPdfPath(int docId) async {
    final pdfDir = await _getPdfDirectory();
    final file = File('${pdfDir.path}/${_getFileName(docId)}');
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }

  Future<bool> isPdfCached(int docId) async {
    final path = await getLocalPdfPath(docId);
    return path != null;
  }

  Future<String> downloadAndCachePdf(
    String url,
    int docId, {
    void Function(int received, int total)? onProgress,
  }) async {
    final pdfDir = await _getPdfDirectory();
    final filePath = '${pdfDir.path}/${_getFileName(docId)}';
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

  Future<void> deletePdf(int docId) async {
    final path = await getLocalPdfPath(docId);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> clearCache() async {
    final pdfDir = await _getPdfDirectory();
    if (await pdfDir.exists()) {
      await pdfDir.delete(recursive: true);
      await pdfDir.create(recursive: true);
    }
  }

  Future<int> getCacheSize() async {
    final pdfDir = await _getPdfDirectory();
    if (!await pdfDir.exists()) return 0;

    int totalSize = 0;
    await for (final entity in pdfDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }
}
