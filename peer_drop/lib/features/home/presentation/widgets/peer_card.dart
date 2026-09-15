import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../discovery/domain/peer_device.dart';
import '../../../file_transfer/domain/transfer_metadata.dart';
import '../../../file_transfer/presentation/transfer_controller.dart';

class PeerCard extends ConsumerWidget {
  final PeerDevice peer;

  const PeerCard({super.key, required this.peer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAndroid = peer.platform.toLowerCase() == 'android';
    final isWindows = peer.platform.toLowerCase() == 'windows';

    final platformIcon = isAndroid
        ? Icons.android_rounded
        : (isWindows ? Icons.laptop_windows_rounded : Icons.devices_rounded);

    final transfer = ref.watch(transferControllerProvider);
    final isBusy = transfer.isActive;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAndroid ? const Color(0xFFE8F5E9) : const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              platformIcon,
              color: isAndroid ? const Color(0xFF2E7D32) : AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        peer.deviceName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        peer.platform.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${peer.ipAddress}:${peer.tcpPort}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: isBusy
                ? null
                : () => _pickAndSendFile(context, ref),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Send'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSendFile(BuildContext context, WidgetRef ref) async {
    try {
      // Pick exactly ONE single file (no multiple files, no folders)
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final path = file.path;

      if (path == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not access selected file path')),
          );
        }
        return;
      }

      final ioFile = File(path);
      if (!await ioFile.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File does not exist')),
          );
        }
        return;
      }

      final size = await ioFile.length();
      if (size == 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot send empty 0-byte file')),
          );
        }
        return;
      }

      final metadata = TransferFileMetadata(
        path: path,
        name: file.name,
        extension: file.extension ?? '',
        size: size,
        mimeType: FileUtils.getMimeType(path),
      );

      await ref.read(transferControllerProvider.notifier).sendFile(
        peer: peer,
        metadata: metadata,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
