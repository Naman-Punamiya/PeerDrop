import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../file_transfer/domain/transfer_state.dart';
import '../../../file_transfer/presentation/transfer_controller.dart';

class ActiveTransferCard extends ConsumerWidget {
  const ActiveTransferCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfer = ref.watch(transferControllerProvider);

    if (transfer.status == TransferStatus.idle) {
      return const SizedBox.shrink();
    }

    final isSending = transfer.direction == TransferDirection.send;
    final (statusColor, statusBg, statusText, statusIcon) = _getStatusConfig(transfer.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: transfer.isActive ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border,
          width: transfer.isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (transfer.isActive ? AppColors.primary : Colors.black).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSending ? AppColors.primaryLight : AppColors.accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSending ? Icons.upload_rounded : Icons.download_rounded,
                  color: isSending ? AppColors.primary : AppColors.accentDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transfer.filename ?? 'File Transfer',
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
                      '${isSending ? "To" : "From"}: ${transfer.peerDeviceName ?? "Peer"} • ${FileUtils.formatBytes(transfer.fileSize)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: transfer.status == TransferStatus.transferring
                  ? transfer.progress
                  : (transfer.isCompleted ? 1.0 : (transfer.isActive ? null : 0.0)),
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                transfer.isCompleted ? AppColors.success : (transfer.isFailed ? AppColors.error : AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Progress details & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                transfer.status == TransferStatus.transferring
                    ? '${FileUtils.formatBytes(transfer.bytesTransferred)} / ${FileUtils.formatBytes(transfer.fileSize)} (${(transfer.progress * 100).toStringAsFixed(0)}%)'
                    : (transfer.errorMessage != null ? transfer.errorMessage! : '${(transfer.progress * 100).toStringAsFixed(0)}%'),
                style: TextStyle(
                  fontSize: 12,
                  color: transfer.errorMessage != null ? AppColors.error : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (transfer.status == TransferStatus.transferring && transfer.speedBytesPerSecond > 0)
                Text(
                  FileUtils.formatSpeed(transfer.speedBytesPerSecond),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentDark,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // File path display on completion
          if (transfer.isCompleted && transfer.filePath != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_open_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saved Location:',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 1),
                        SelectableText(
                          transfer.filePath!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (transfer.status == TransferStatus.waitingForAcceptance && !isSending) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(transferControllerProvider.notifier).rejectIncomingTransfer();
                  },
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                  label: const Text('Reject', style: TextStyle(color: AppColors.error, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(transferControllerProvider.notifier).acceptIncomingTransfer();
                  },
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Accept', style: TextStyle(fontSize: 13)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    backgroundColor: AppColors.success,
                  ),
                ),
              ] else if (transfer.isActive) ...[
                TextButton.icon(
                  onPressed: () {
                    ref.read(transferControllerProvider.notifier).cancelCurrentTransfer();
                  },
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                  label: const Text('Cancel', style: TextStyle(color: AppColors.error, fontSize: 13)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
              if (transfer.isCompleted && transfer.filePath != null && transfer.filePath!.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await OpenFile.open(transfer.filePath!);
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.folder_open_rounded, size: 16),
                  label: const Text('Open File', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (!transfer.isActive)
                FilledButton.tonal(
                  onPressed: () {
                    ref.read(transferControllerProvider.notifier).resetToIdle();
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  ),
                  child: const Text('Dismiss', style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  (Color, Color, String, IconData) _getStatusConfig(TransferStatus status) {
    return switch (status) {
      TransferStatus.idle => (AppColors.textMuted, AppColors.surfaceVariant, 'Idle', Icons.hourglass_empty_rounded),
      TransferStatus.requesting => (AppColors.info, AppColors.primaryLight, 'Requesting...', Icons.sync_rounded),
      TransferStatus.waitingForAcceptance => (AppColors.warning, AppColors.warningLight, 'Waiting for Peer...', Icons.access_time_rounded),
      TransferStatus.accepted => (AppColors.accentDark, AppColors.accentLight, 'Accepted', Icons.check_circle_outline_rounded),
      TransferStatus.transferring => (AppColors.primary, AppColors.primaryLight, 'Transferring', Icons.arrow_downward_rounded),
      TransferStatus.verifying => (AppColors.info, AppColors.primaryLight, 'Verifying SHA-256...', Icons.security_rounded),
      TransferStatus.completed => (AppColors.success, AppColors.successLight, 'Completed', Icons.check_circle_rounded),
      TransferStatus.rejected => (AppColors.error, AppColors.errorLight, 'Rejected', Icons.cancel_outlined),
      TransferStatus.cancelled => (AppColors.textMuted, AppColors.surfaceVariant, 'Cancelled', Icons.block_rounded),
      TransferStatus.failed => (AppColors.error, AppColors.errorLight, 'Failed', Icons.error_outline_rounded),
    };
  }
}
