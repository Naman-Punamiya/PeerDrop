import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/history_repository.dart';
import '../domain/transfer_record.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  throw UnimplementedError('HistoryRepository must be initialized');
});

final historyControllerProvider = StateNotifierProvider<HistoryController, List<TransferRecord>>((ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return HistoryController(repository);
});

class HistoryController extends StateNotifier<List<TransferRecord>> {
  final HistoryRepository _repository;

  HistoryController(this._repository) : super(const []) {
    loadHistory();
  }

  void loadHistory() {
    state = _repository.getRecords();
  }

  Future<void> addRecord(TransferRecord record) async {
    await _repository.addRecord(record);
    loadHistory();
  }

  Future<void> deleteRecord(String id) async {
    await _repository.deleteRecord(id);
    loadHistory();
  }

  Future<void> clearHistory() async {
    await _repository.clearHistory();
    state = const [];
  }
}
