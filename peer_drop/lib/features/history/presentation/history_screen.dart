import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/file_utils.dart';
import '../../file_transfer/domain/transfer_state.dart';
import '../domain/transfer_record.dart';
import 'history_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer History'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear History',
              onPressed: () => _confirmClearHistory(context, ref),
            ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.history_rounded, size: 64, color: AppColors.textMuted),
                  SizedBox(height: 16),
                  Text(
                    'No Transfers Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Completed, rejected, and cancelled transfers will appear here.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final record = history[index];
                return _buildHistoryCard(context, ref, record);
              },
            ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, WidgetRef ref, TransferRecord record) {
    final isSend = record.direction == TransferDirection.send;
    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(record.timestamp);
    final (statusColor, statusBg, statusText) = _getStatusDetails(record.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSend ? AppColors.primaryLight : AppColors.accentLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSend ? Icons.upload_rounded : Icons.download_rounded,
                  color: isSend ? AppColors.primary : AppColors.accentDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.filename,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isSend ? "To" : "From"}: ${record.peerName} • ${FileUtils.formatBytes(record.fileSize)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (record.filePath != null) ...[
            const SizedBox(height: 6),
            Text(
              'Location: ${record.filePath!}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              Row(
                children: [
                  if (record.sha256 != null && record.sha256!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.shield_outlined, size: 18),
                      tooltip: 'Copy SHA-256 Hash',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: record.sha256!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('SHA-256 hash copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  if (record.filePath != null && File(record.filePath!).existsSync())
                    IconButton(
                      icon: const Icon(Icons.folder_open_rounded, size: 18),
                      tooltip: 'Open File',
                      onPressed: () async {
                        try {
                          await OpenFile.open(record.filePath!);
                        } catch (_) {}
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
                    tooltip: 'Delete Record',
                    onPressed: () {
                      ref.read(historyControllerProvider.notifier).deleteRecord(record.id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  (Color, Color, String) _getStatusDetails(TransferStatus status) {
    return switch (status) {
      TransferStatus.completed => (AppColors.success, AppColors.successLight, 'Completed'),
      TransferStatus.failed => (AppColors.error, AppColors.errorLight, 'Failed'),
      TransferStatus.cancelled => (AppColors.textMuted, AppColors.surfaceVariant, 'Cancelled'),
      TransferStatus.rejected => (AppColors.warning, AppColors.warningLight, 'Rejected'),
      _ => (AppColors.textMuted, AppColors.surfaceVariant, status.name.toUpperCase()),
    };
  }

  Future<void> _confirmClearHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Transfer History'),
        content: const Text('Are you sure you want to clear all transfer records? Downloaded files on disk will not be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(historyControllerProvider.notifier).clearHistory();
    }
  }
}
