enum TransferDirection {
  send,
  receive,
}

enum TransferStatus {
  idle,
  requesting,
  waitingForAcceptance,
  accepted,
  transferring,
  verifying,
  completed,
  rejected,
  cancelled,
  failed,
}

class TransferState {
  final String? transferId;
  final String? filename;
  final String? filePath;
  final int fileSize;
  final int bytesTransferred;
  final double speedBytesPerSecond;
  final TransferStatus status;
  final TransferDirection? direction;
  final String? peerDeviceId;
  final String? peerDeviceName;
  final String? peerPlatform;
  final String? expectedSha256;
  final String? actualSha256;
  final String? errorMessage;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const TransferState({
    this.transferId,
    this.filename,
    this.filePath,
    this.fileSize = 0,
    this.bytesTransferred = 0,
    this.speedBytesPerSecond = 0.0,
    this.status = TransferStatus.idle,
    this.direction,
    this.peerDeviceId,
    this.peerDeviceName,
    this.peerPlatform,
    this.expectedSha256,
    this.actualSha256,
    this.errorMessage,
    this.startedAt,
    this.completedAt,
  });

  double get progress => fileSize > 0 ? (bytesTransferred / fileSize).clamp(0.0, 1.0) : 0.0;
  bool get isActive =>
      status == TransferStatus.requesting ||
      status == TransferStatus.waitingForAcceptance ||
      status == TransferStatus.accepted ||
      status == TransferStatus.transferring ||
      status == TransferStatus.verifying;

  bool get isCompleted => status == TransferStatus.completed;
  bool get isFailed => status == TransferStatus.failed;
  bool get isCancelled => status == TransferStatus.cancelled;
  bool get isRejected => status == TransferStatus.rejected;

  TransferState copyWith({
    String? transferId,
    String? filename,
    String? filePath,
    int? fileSize,
    int? bytesTransferred,
    double? speedBytesPerSecond,
    TransferStatus? status,
    TransferDirection? direction,
    String? peerDeviceId,
    String? peerDeviceName,
    String? peerPlatform,
    String? expectedSha256,
    String? actualSha256,
    String? errorMessage,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return TransferState(
      transferId: transferId ?? this.transferId,
      filename: filename ?? this.filename,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      peerDeviceId: peerDeviceId ?? this.peerDeviceId,
      peerDeviceName: peerDeviceName ?? this.peerDeviceName,
      peerPlatform: peerPlatform ?? this.peerPlatform,
      expectedSha256: expectedSha256 ?? this.expectedSha256,
      actualSha256: actualSha256 ?? this.actualSha256,
      errorMessage: errorMessage ?? this.errorMessage,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  static const TransferState idleState = TransferState(status: TransferStatus.idle);

  @override
  String toString() {
    return 'TransferState(id: $transferId, file: $filename, status: $status, progress: ${(progress * 100).toStringAsFixed(1)}%)';
  }
}
