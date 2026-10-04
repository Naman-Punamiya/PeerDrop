import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peerdrop/core/constants/app_constants.dart';
import 'package:peerdrop/features/file_transfer/domain/transfer_state.dart';
import 'package:peerdrop/features/history/data/history_repository.dart';
import 'package:peerdrop/features/history/domain/transfer_record.dart';
import 'package:peerdrop/features/history/presentation/history_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyRecord1 = TransferRecord(
    id: 'rec-1',
    filename: 'photo.jpg',
    fileSize: 1024 * 1024,
    status: TransferStatus.completed,
    direction: TransferDirection.send,
    peerName: 'Pixel 7',
    peerDeviceId: 'peer-id-1',
    peerPlatform: 'android',
    timestamp: DateTime(2026, 1, 1, 10, 0),
  );

  final dummyRecord2 = TransferRecord(
    id: 'rec-2',
    filename: 'document.pdf',
    fileSize: 512 * 1024,
    status: TransferStatus.failed,
    direction: TransferDirection.receive,
    peerName: 'MacBook Pro',
    peerDeviceId: 'peer-id-2',
    peerPlatform: 'macos',
    timestamp: DateTime(2026, 1, 1, 11, 0),
  );

  group('HistoryRepository Tests', () {
    test('getRecords returns empty list when no history is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = HistoryRepository(prefs);

      expect(repo.getRecords(), isEmpty);
    });

    test('getRecords ignores malformed json entries and sorts descending by timestamp', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefTransferHistory: [
          jsonEncode(dummyRecord1.toJson()),
          'invalid json string',
          jsonEncode(dummyRecord2.toJson()),
        ],
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = HistoryRepository(prefs);

      final records = repo.getRecords();
      expect(records.length, 2);
      expect(records.first.id, 'rec-2'); // Later timestamp first
      expect(records.last.id, 'rec-1');
    });

    test('addRecord inserts new record at top and prevents duplicate IDs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = HistoryRepository(prefs);

      await repo.addRecord(dummyRecord1);
      expect(repo.getRecords().length, 1);

      // Re-adding with same ID updates/repositions it without duplicates
      final updatedRecord1 = TransferRecord(
        id: dummyRecord1.id,
        filename: dummyRecord1.filename,
        fileSize: dummyRecord1.fileSize,
        status: TransferStatus.failed,
        direction: dummyRecord1.direction,
        peerName: dummyRecord1.peerName,
        peerDeviceId: dummyRecord1.peerDeviceId,
        peerPlatform: dummyRecord1.peerPlatform,
        timestamp: dummyRecord1.timestamp,
      );
      await repo.addRecord(updatedRecord1);

      final records = repo.getRecords();
      expect(records.length, 1);
      expect(records.first.status, TransferStatus.failed);
    });

    test('deleteRecord removes specific record by ID', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefTransferHistory: [
          jsonEncode(dummyRecord1.toJson()),
          jsonEncode(dummyRecord2.toJson()),
        ],
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = HistoryRepository(prefs);

      await repo.deleteRecord('rec-1');
      final records = repo.getRecords();
      expect(records.length, 1);
      expect(records.first.id, 'rec-2');
    });

    test('clearHistory removes all history from preferences', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefTransferHistory: [
          jsonEncode(dummyRecord1.toJson()),
        ],
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = HistoryRepository(prefs);

      await repo.clearHistory();
      expect(repo.getRecords(), isEmpty);
    });
  });

  group('HistoryController Tests', () {
    test('addRecord, deleteRecord, and clearHistory update state correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = HistoryRepository(prefs);
      final controller = HistoryController(repo);

      expect(controller.state, isEmpty);

      await controller.addRecord(dummyRecord1);
      expect(controller.state.length, 1);
      expect(controller.state.first.id, 'rec-1');

      await controller.addRecord(dummyRecord2);
      expect(controller.state.length, 2);

      await controller.deleteRecord('rec-1');
      expect(controller.state.length, 1);
      expect(controller.state.first.id, 'rec-2');

      await controller.clearHistory();
      expect(controller.state, isEmpty);
    });
  });
}
