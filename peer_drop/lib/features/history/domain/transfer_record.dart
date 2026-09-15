import '../../file_transfer/domain/transfer_state.dart';

class TransferRecord {
  final String id;
  final String filename;
  final String? filePath;
  final int fileSize;
  final String peerName;
  final String peerDeviceId;
  final String peerPlatform;
  final TransferDirection direction;
  final TransferStatus status;
  final String? sha256;
  final String? error;
  final DateTime timestamp;

  const TransferRecord({
    required this.id,
    required this.filename,
    this.filePath,
    required this.fileSize,
    required this.peerName,
    required this.peerDeviceId,
    required this.peerPlatform,
    required this.direction,
    required this.status,
    this.sha256,
    this.error,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'filename': filename,
    'filePath': filePath,
    'fileSize': fileSize,
    'peerName': peerName,
    'peerDeviceId': peerDeviceId,
    'peerPlatform': peerPlatform,
    'direction': direction.name,
    'status': status.name,
    'sha256': sha256,
    'error': error,
    'timestamp': timestamp.toIso8601String(),
  };

  static TransferRecord? fromJson(Map<String, dynamic> json) {
    try {
      return TransferRecord(
        id: json['id'] as String,
        filename: json['filename'] as String,
        filePath: json['filePath'] as String?,
        fileSize: json['fileSize'] as int,
        peerName: json['peerName'] as String,
        peerDeviceId: json['peerDeviceId'] as String? ?? '',
        peerPlatform: json['peerPlatform'] as String? ?? 'unknown',
        direction: TransferDirection.values.byName(json['direction'] as String),
        status: TransferStatus.values.byName(json['status'] as String),
        sha256: json['sha256'] as String?,
        error: json['error'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  static TransferRecord fromTransferState(TransferState state) {
    return TransferRecord(
      id: state.transferId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      filename: state.filename ?? 'Unknown file',
      filePath: state.filePath,
      fileSize: state.fileSize,
      peerName: state.peerDeviceName ?? 'Unknown Device',
      peerDeviceId: state.peerDeviceId ?? '',
      peerPlatform: state.peerPlatform ?? 'unknown',
      direction: state.direction ?? TransferDirection.send,
      status: state.status,
      sha256: state.actualSha256 ?? state.expectedSha256,
      error: state.errorMessage,
      timestamp: state.completedAt ?? DateTime.now(),
    );
  }
}
