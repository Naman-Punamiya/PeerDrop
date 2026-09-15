import 'package:flutter_test/flutter_test.dart';
import 'package:peerdrop/features/file_transfer/domain/transfer_state.dart';
import 'package:peerdrop/features/history/domain/transfer_record.dart';

void main() {
  group('TransferState & TransferRecord Tests', () {
    test('Calculates progress percentage accurately', () {
      const state = TransferState(
        fileSize: 1000,
        bytesTransferred: 500,
        status: TransferStatus.transferring,
      );

      expect(state.progress, 0.5);
      expect(state.isActive, true);
      expect(state.isCompleted, false);
    });

    test('Clamps progress to 1.0 when bytes match', () {
      const state = TransferState(
        fileSize: 1024,
        bytesTransferred: 1024,
        status: TransferStatus.completed,
      );

      expect(state.progress, 1.0);
      expect(state.isActive, false);
      expect(state.isCompleted, true);
    });

    test('Converts TransferState to TransferRecord and JSON', () {
      final now = DateTime.now();
      final state = TransferState(
        transferId: 't-123',
        filename: 'notes.pdf',
        fileSize: 2048,
        status: TransferStatus.completed,
        direction: TransferDirection.receive,
        peerDeviceId: 'peer-abc',
        peerDeviceName: 'Pixel 8',
        actualSha256: 'hash123',
        completedAt: now,
      );

      final record = TransferRecord.fromTransferState(state);
      expect(record.id, 't-123');
      expect(record.filename, 'notes.pdf');
      expect(record.fileSize, 2048);
      expect(record.status, TransferStatus.completed);
      expect(record.direction, TransferDirection.receive);
      expect(record.peerName, 'Pixel 8');
      expect(record.sha256, 'hash123');

      final json = record.toJson();
      final fromJson = TransferRecord.fromJson(json);
      expect(fromJson, isNotNull);
      expect(fromJson!.id, 't-123');
      expect(fromJson.filename, 'notes.pdf');
    });
  });
}
