import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

class FileUtils {
  FileUtils._();

  /// Sanitizes a filename from an external peer:
  /// - Strips directory traversal (.. / \ ~ etc.)
  /// - Removes reserved / invalid filesystem characters (< > : " / \ | ? *)
  /// - Trims whitespace and trailing periods
  /// - Provides a safe fallback name if empty
  static String sanitizeFilename(String filename) {
    // Extract base name only (strip any directory path components)
    String name = p.basename(filename);

    // Remove null bytes and control chars
    name = name.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '');

    // Replace invalid characters on Windows and POSIX
    name = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    // Remove leading/trailing dots and spaces
    name = name.trim();
    while (name.startsWith('.')) {
      name = name.substring(1).trim();
    }
    while (name.endsWith('.')) {
      name = name.substring(0, name.length - 1).trim();
    }

    if (name.isEmpty) {
      name = 'received_file_${DateTime.now().millisecondsSinceEpoch}';
    }

    return name;
  }

  /// Finds a non-colliding destination file path by appending (1), (2), etc.
  static Future<File> getUniqueDestinationFile(String directoryPath, String filename) async {
    final cleanName = sanitizeFilename(filename);
    final ext = p.extension(cleanName);
    final baseWithoutExt = p.basenameWithoutExtension(cleanName);

    var candidatePath = p.join(directoryPath, cleanName);
    var candidateFile = File(candidatePath);

    int counter = 1;
    while (await candidateFile.exists()) {
      final numberedName = '$baseWithoutExt ($counter)$ext';
      candidatePath = p.join(directoryPath, numberedName);
      candidateFile = File(candidatePath);
      counter++;
    }

    return candidateFile;
  }

  /// Calculates SHA-256 for a file using streaming file reading in a background isolate.
  static Future<String> calculateSha256(File file) async {
    final path = file.path;
    return await Isolate.run(() async {
      final f = File(path);
      final stream = f.openRead();
      final digest = await sha256.bind(stream).first;
      return digest.toString();
    });
  }

  /// Formats byte size to human readable string.
  static String formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    final i = (log(bytes) / log(1024)).floor();
    final clampedI = i.clamp(0, suffixes.length - 1);
    final size = bytes / pow(1024, clampedI);
    return '${size.toStringAsFixed(decimals)} ${suffixes[clampedI]}';
  }

  /// Formats transfer speed (bytes per second).
  static String formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return '0 B/s';
    return '${formatBytes(bytesPerSecond.toInt())}/s';
  }

  /// Guesses MIME type from filename or path.
  static String getMimeType(String filePath) {
    return lookupMimeType(filePath) ?? 'application/octet-stream';
  }
}
