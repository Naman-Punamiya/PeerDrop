import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdrop/features/connection/domain/protocol_message.dart';

void main() {
  group('ProtocolMessage & FileChunkData Tests', () {
    test('Handshake message serialization and deserialization', () {
      const original = HandshakeMessage(
        version: 1,
        deviceId: 'dev-abc-123',
        deviceName: 'Pixel 8 Pro',
        platform: 'android',
      );

      final json = original.toJson();
      final decoded = HandshakeMessage.fromJson(json);

      expect(decoded, isNotNull);
      expect(decoded!.version, 1);
      expect(decoded.deviceId, 'dev-abc-123');
      expect(decoded.deviceName, 'Pixel 8 Pro');
      expect(decoded.platform, 'android');
    });

    test('FileTransferRequestPayload serialization and deserialization', () {
      const request = FileTransferRequestPayload(
        transferId: 't-uuid-99',
        filename: 'presentation.key',
        fileSize: 10485760,
        mimeType: 'application/octet-stream',
        sha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        senderDeviceId: 'dev-1',
        senderDeviceName: 'Laptop',
      );

      final json = request.toJson();
      final decoded = FileTransferRequestPayload.fromJson(json);

      expect(decoded, isNotNull);
      expect(decoded!.transferId, 't-uuid-99');
      expect(decoded.filename, 'presentation.key');
      expect(decoded.fileSize, 10485760);
      expect(decoded.sha256, request.sha256);
    });

    test('FileChunkData binary encode and decode', () {
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      final chunk = FileChunkData(
        transferId: 'transfer-456',
        sequenceNumber: 42,
        data: sampleBytes,
      );

      final encoded = chunk.encode();
      final decoded = FileChunkData.decode(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.transferId, 'transfer-456');
      expect(decoded.sequenceNumber, 42);
      expect(decoded.data, equals(sampleBytes));
    });
  });
}
