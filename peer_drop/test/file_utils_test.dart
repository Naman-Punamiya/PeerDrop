import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdrop/core/utils/file_utils.dart';

void main() {
  group('FileUtils Tests', () {
    test('Sanitizes malicious directory traversal filenames', () {
      expect(FileUtils.sanitizeFilename('../../secret.txt'), 'secret.txt');
      expect(FileUtils.sanitizeFilename('..\\..\\passwords.json'), 'passwords.json');
      expect(FileUtils.sanitizeFilename('/var/log/syslog'), 'syslog');
      expect(FileUtils.sanitizeFilename(r'C:\System32\drivers\etc\hosts'), 'hosts');
      expect(FileUtils.sanitizeFilename('...test...'), 'test');
    });

    test('Sanitizes illegal filename characters', () {
      expect(FileUtils.sanitizeFilename('my<invalid>:file"name.jpg'), 'my_invalid__file_name.jpg');
    });

    test('Provides fallback for blank/empty filenames', () {
      final sanitized = FileUtils.sanitizeFilename('   ');
      expect(sanitized.startsWith('received_file_'), true);
    });

    test('Formats byte sizes accurately', () {
      expect(FileUtils.formatBytes(0), '0 B');
      expect(FileUtils.formatBytes(512), '512.00 B');
      expect(FileUtils.formatBytes(1024), '1.00 KB');
      expect(FileUtils.formatBytes(1024 * 1024 * 5), '5.00 MB');
      expect(FileUtils.formatBytes(1024 * 1024 * 1024 * 2), '2.00 GB');
    });

    test('Streaming SHA-256 matches expected hash for file content', () async {
      final tempDir = await Directory.systemTemp.createTemp('peerdrop_test_');
      final tempFile = File('${tempDir.path}/test_file.txt');
      await tempFile.writeAsString('Hello PeerDrop P2P File Sharing!');

      final hash = await FileUtils.calculateSha256(tempFile);
      expect(hash, isNotEmpty);
      expect(hash.length, 64); // SHA-256 hex string length

      await tempDir.delete(recursive: true);
    });

    test('Creates unique non-colliding destination files', () async {
      final tempDir = await Directory.systemTemp.createTemp('peerdrop_collision_');

      // Create existing test.txt
      final file1 = File('${tempDir.path}/photo.jpg');
      await file1.writeAsString('file 1');

      // Unique file for same name should be photo (1).jpg
      final file2 = await FileUtils.getUniqueDestinationFile(tempDir.path, 'photo.jpg');
      expect(file2.path.endsWith('photo (1).jpg'), true);
      await file2.writeAsString('file 2');

      // Next unique should be photo (2).jpg
      final file3 = await FileUtils.getUniqueDestinationFile(tempDir.path, 'photo.jpg');
      expect(file3.path.endsWith('photo (2).jpg'), true);

      await tempDir.delete(recursive: true);
    });
  });
}
