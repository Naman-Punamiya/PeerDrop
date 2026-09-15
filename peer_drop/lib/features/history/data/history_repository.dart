import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/transfer_record.dart';

class HistoryRepository {
  final SharedPreferences _prefs;

  HistoryRepository(this._prefs);

  static const int _maxRecords = 500;

  List<TransferRecord> getRecords() {
    try {
      final rawList = _prefs.getStringList(AppConstants.prefTransferHistory) ?? [];
      final records = <TransferRecord>[];

      for (final item in rawList) {
        try {
          final map = jsonDecode(item) as Map<String, dynamic>;
          final record = TransferRecord.fromJson(map);
          if (record != null) {
            records.add(record);
          }
        } catch (_) {}
      }

      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    } catch (e) {
      AppLogger.error('Failed to load transfer history', tag: 'HistoryRepository', error: e);
      return [];
    }
  }

  Future<void> addRecord(TransferRecord record) async {
    try {
      final records = getRecords();
      // Avoid exact duplicate IDs
      records.removeWhere((r) => r.id == record.id);
      records.insert(0, record);

      if (records.length > _maxRecords) {
        records.removeRange(_maxRecords, records.length);
      }

      final encodedList = records.map((r) => jsonEncode(r.toJson())).toList();
      await _prefs.setStringList(AppConstants.prefTransferHistory, encodedList);
      AppLogger.info('Saved transfer record: ${record.filename} (${record.status.name})', tag: 'HistoryRepository');
    } catch (e) {
      AppLogger.error('Failed to save transfer record', tag: 'HistoryRepository', error: e);
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      final records = getRecords();
      records.removeWhere((r) => r.id == id);
      final encodedList = records.map((r) => jsonEncode(r.toJson())).toList();
      await _prefs.setStringList(AppConstants.prefTransferHistory, encodedList);
    } catch (e) {
      AppLogger.error('Failed to delete transfer record', tag: 'HistoryRepository', error: e);
    }
  }

  Future<void> clearHistory() async {
    try {
      await _prefs.remove(AppConstants.prefTransferHistory);
      AppLogger.info('Cleared transfer history', tag: 'HistoryRepository');
    } catch (e) {
      AppLogger.error('Failed to clear transfer history', tag: 'HistoryRepository', error: e);
    }
  }
}
