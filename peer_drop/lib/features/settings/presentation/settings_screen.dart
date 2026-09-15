import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/network_utils.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading settings: $err')),
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _buildSectionHeader('Device Identity'),
              _buildSettingCard(
                children: [
                  ListTile(
                    leading: const Icon(Icons.badge_outlined, color: AppColors.primary),
                    title: const Text('Device Name'),
                    subtitle: Text(settings.deviceName),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () => _editDeviceName(context, ref, settings.deviceName),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                    title: const Text('Device ID'),
                    subtitle: Text(
                      settings.deviceId,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                    trailing: const Icon(Icons.copy_rounded, size: 20),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: settings.deviceId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Device ID copied to clipboard')),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.devices_rounded, color: AppColors.primary),
                    title: const Text('Platform'),
                    subtitle: Text(NetworkUtils.getPlatformName().toUpperCase()),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionHeader('Storage & Downloads'),
              _buildSettingCard(
                children: [
                  ListTile(
                    leading: const Icon(Icons.folder_outlined, color: AppColors.accent),
                    title: const Text('Download Directory'),
                    subtitle: Text(
                      settings.downloadDirectory,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.folder_open_rounded, size: 20),
                          tooltip: 'Open Directory',
                          onPressed: () async {
                            try {
                              await OpenFile.open(settings.downloadDirectory);
                            } catch (_) {}
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.drive_file_move_outlined, size: 20),
                          tooltip: 'Change Directory',
                          onPressed: () => _changeDownloadDirectory(context, ref, settings.downloadDirectory),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionHeader('Networking'),
              _buildSettingCard(
                children: [
                  SwitchListTile.adaptive(
                    secondary: const Icon(Icons.radar_rounded, color: AppColors.primary),
                    title: const Text('Auto-start Discovery'),
                    subtitle: const Text('Automatically discover nearby peers on launch'),
                    value: settings.autoDiscover,
                    activeTrackColor: AppColors.accent,
                    onChanged: (val) {
                      ref.read(settingsControllerProvider.notifier).updateAutoDiscover(val);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings_input_antenna_rounded, color: AppColors.primary),
                    title: const Text('TCP Transfer Port'),
                    subtitle: Text('${settings.tcpPort} (Default: ${AppConstants.defaultTcpPort})'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.cell_tower_rounded, color: AppColors.primary),
                    title: const Text('UDP Discovery Port'),
                    subtitle: Text('${settings.discoveryPort} (Default: ${AppConstants.defaultDiscoveryPort})'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionHeader('About'),
              _buildSettingCard(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                    title: const Text('PeerDrop'),
                    subtitle: const Text('P2P Local File Sharing • Version 1.0.0'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Future<void> _editDeviceName(BuildContext context, WidgetRef ref, String currentName) async {
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Device Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Device Name',
            hintText: 'e.g. Naman PC, Pixel 8',
          ),
          maxLength: 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await ref.read(settingsControllerProvider.notifier).updateDeviceName(newName);
    }
  }

  Future<void> _changeDownloadDirectory(BuildContext context, WidgetRef ref, String currentDir) async {
    try {
      final selectedPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select PeerDrop Download Folder',
        initialDirectory: currentDir,
      );

      if (selectedPath != null && selectedPath.isNotEmpty) {
        await ref.read(settingsControllerProvider.notifier).updateDownloadDirectory(selectedPath);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download directory updated to: $selectedPath')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select directory: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
