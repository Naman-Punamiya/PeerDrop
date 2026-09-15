import 'dart:async';
import 'dart:io';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/file_utils.dart';

class IncomingFileSession {
  final File file;
  final RandomAccessFile raf;
  final String originalFilename;
  int bytesWritten = 0;
  bool isClosed = false;
  Future<void> _writeQueue = Future.value();

  IncomingFileSession({
    required this.file,
    required this.raf,
    required this.originalFilename,
  });

  Future<void> writeChunk(List<int> chunk) {
    if (isClosed) return Future.value();
    
    // Chain writes sequentially to prevent 'An async operation is currently pending' on raf
    final op = _writeQueue.then((_) async {
      if (isClosed) return;
      await raf.writeFrom(chunk);
      bytesWritten += chunk.length;
    });

    _writeQueue = op;
    return op;
  }

  Future<void> close() async {
    if (isClosed) return;
    isClosed = true;
    
    // Await all queued chunk writes to finish before closing
    await _writeQueue;
    await raf.flush();
    await raf.close();
  }

  Future<void> abortAndCleanup() async {
    try {
      if (!isClosed) {
        isClosed = true;
        try {
          await _writeQueue;
        } catch (_) {}
        await raf.close();
      }
      if (await file.exists()) {
        await file.delete();
        AppLogger.info('Cleaned up incomplete file: ${file.path}', tag: 'FilesystemService');
      }
    } catch (e) {
      AppLogger.warning('Error cleaning up file ${file.path}: $e', tag: 'FilesystemService');
    }
  }
}

class FilesystemService {
  final String downloadDirectory;

  FilesystemService({required this.downloadDirectory});

  Future<void> ensureDownloadDirectoryExists() async {
    final dir = Directory(downloadDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Prepares an incoming file session for writing chunks.
  Future<IncomingFileSession> prepareIncomingFile(String proposedFilename) async {
    try {
      await ensureDownloadDirectoryExists();

      final destinationFile = await FileUtils.getUniqueDestinationFile(
        downloadDirectory,
        proposedFilename,
      );

      final raf = await destinationFile.open(mode: FileMode.writeOnly);

      return IncomingFileSession(
        file: destinationFile,
        raf: raf,
        originalFilename: proposedFilename,
      );
    } catch (e, st) {
      AppLogger.error('Failed to prepare destination file for $proposedFilename', tag: 'FilesystemService', error: e, stackTrace: st);
      throw StorageException('Failed to prepare destination file: $e', e);
    }
  }

  /// Computes SHA-256 hash of a file on disk.
  Future<String> verifyFileHash(File file) async {
    try {
      if (!await file.exists()) {
        throw const StorageException('File does not exist for SHA-256 verification');
      }
      return await FileUtils.calculateSha256(file);
    } catch (e, st) {
      AppLogger.error('Failed to verify SHA-256 for ${file.path}', tag: 'FilesystemService', error: e, stackTrace: st);
      if (e is AppException) rethrow;
      throw ChecksumException('Failed to calculate SHA-256: $e', e);
    }
  }
}
