import 'package:flutter_test/flutter_test.dart';
import 'package:peerdrop/core/errors/app_exceptions.dart';

void main() {
  group('AppException Hierarchy Tests', () {
    test('AppException formats message with and without cause', () {
      const exNoCause = AppException('Error message');
      expect(exNoCause.toString(), 'Error message');
      expect(exNoCause.message, 'Error message');
      expect(exNoCause.cause, isNull);

      const exWithCause = AppException('Failed to connect', 'Socket closed');
      expect(exWithCause.toString(), 'Failed to connect: Socket closed');
      expect(exWithCause.cause, 'Socket closed');
    });

    test('DiscoveryException inheritance and string conversion', () {
      const ex = DiscoveryException('UDP port in use', 'Address already in use');
      expect(ex, isA<AppException>());
      expect(ex.toString(), 'UDP port in use: Address already in use');
    });

    test('ConnectionException inheritance and string conversion', () {
      const ex = ConnectionException('Connection refused');
      expect(ex, isA<AppException>());
      expect(ex.toString(), 'Connection refused');
    });

    test('HandshakeException inheritance and string conversion', () {
      const ex = HandshakeException('Protocol mismatch');
      expect(ex, isA<AppException>());
      expect(ex.toString(), 'Protocol mismatch');
    });

    test('FramingException inheritance and string conversion', () {
      const ex = FramingException('Invalid magic bytes');
      expect(ex, isA<AppException>());
      expect(ex.toString(), 'Invalid magic bytes');
    });

    test('TransferException inheritance and string conversion', () {
      const ex = TransferException('Transfer aborted by peer');
      expect(ex, isA<AppException>());
      expect(ex.toString(), 'Transfer aborted by peer');
    });

    test('ChecksumException inheritance and string conversion', () {
      const ex = ChecksumException('SHA-256 hash mismatch');
      expect(ex, isA<AppException>());
      expect(ex.toString(), 'SHA-256 hash mismatch');
    });

    test('StorageException inheritance and string conversion', () {
      const ex = StorageException('Permission denied');
      expect(ex, isA<AppException>());
      expect(ex.toString(), 'Permission denied');
    });
  });
}
