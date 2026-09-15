import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_repository.dart';
import '../domain/app_settings.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('SettingsRepository must be initialized before use');
});

final settingsControllerProvider = StateNotifierProvider<SettingsController, AsyncValue<AppSettings>>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsController(repository);
});

class SettingsController extends StateNotifier<AsyncValue<AppSettings>> {
  final SettingsRepository _repository;

  SettingsController(this._repository) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      state = const AsyncValue.loading();
      final settings = await _repository.loadSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateDeviceName(String name) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(deviceName: name.trim());
    state = AsyncValue.data(updated);
    await _repository.saveDeviceName(name.trim());
  }

  Future<void> updateDownloadDirectory(String path) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(downloadDirectory: path);
    state = AsyncValue.data(updated);
    await _repository.saveDownloadDirectory(path);
  }

  Future<void> updateTcpPort(int port) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(tcpPort: port);
    state = AsyncValue.data(updated);
    await _repository.saveTcpPort(port);
  }

  Future<void> updateDiscoveryPort(int port) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(discoveryPort: port);
    state = AsyncValue.data(updated);
    await _repository.saveDiscoveryPort(port);
  }

  Future<void> updateAutoDiscover(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(autoDiscover: enabled);
    state = AsyncValue.data(updated);
    await _repository.saveAutoDiscover(enabled);
  }
}
