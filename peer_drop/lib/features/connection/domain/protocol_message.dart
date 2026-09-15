import 'dart:convert';
import 'dart:typed_data';
import '../../../core/constants/app_constants.dart';

class MessageType {
  MessageType._();

  static const int hello = 0x01;
  static const int helloAck = 0x02;

  static const int fileTransferRequest = 0x10;
  static const int fileTransferAccept = 0x11;
  static const int fileTransferReject = 0x12;
  static const int fileTransferStart = 0x13;
  static const int fileTransferData = 0x14;
  static const int fileTransferComplete = 0x15;
  static const int fileTransferCancel = 0x16;
  static const int fileTransferError = 0x17;
  static const int fileTransferCompleteAck = 0x18;

  static String nameOf(int type) {
    return switch (type) {
      hello => 'HELLO',
      helloAck => 'HELLO_ACK',
      fileTransferRequest => 'FILE_TRANSFER_REQUEST',
      fileTransferAccept => 'FILE_TRANSFER_ACCEPT',
      fileTransferReject => 'FILE_TRANSFER_REJECT',
      fileTransferStart => 'FILE_TRANSFER_START',
      fileTransferData => 'FILE_TRANSFER_DATA',
      fileTransferComplete => 'FILE_TRANSFER_COMPLETE',
      fileTransferCancel => 'FILE_TRANSFER_CANCEL',
      fileTransferError => 'FILE_TRANSFER_ERROR',
      fileTransferCompleteAck => 'FILE_TRANSFER_COMPLETE_ACK',
      _ => 'UNKNOWN(0x${type.toRadixString(16)})',
    };
  }
}

class RawProtocolMessage {
  final int type;
  final Uint8List payload;

  const RawProtocolMessage({
    required this.type,
    required this.payload,
  });

  String get payloadAsUtf8 => utf8.decode(payload, allowMalformed: true);

  Map<String, dynamic>? get payloadAsJson {
    try {
      return jsonDecode(payloadAsUtf8) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => 'RawProtocolMessage(type: ${MessageType.nameOf(type)}, length: ${payload.length})';
}

/// Handshake message
class HandshakeMessage {
  final int version;
  final String deviceId;
  final String deviceName;
  final String platform;

  const HandshakeMessage({
    this.version = AppConstants.protocolVersion,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'platform': platform,
  };

  static HandshakeMessage? fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int?;
    final deviceId = json['deviceId'] as String?;
    final deviceName = json['deviceName'] as String?;
    final platform = json['platform'] as String? ?? 'unknown';

    if (version == null || deviceId == null || deviceName == null) return null;
    return HandshakeMessage(
      version: version,
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform,
    );
  }
}

/// File Transfer Request message
class FileTransferRequestPayload {
  final String transferId;
  final String filename;
  final int fileSize;
  final String mimeType;
  final String sha256;
  final String senderDeviceId;
  final String senderDeviceName;

  const FileTransferRequestPayload({
    required this.transferId,
    required this.filename,
    required this.fileSize,
    required this.mimeType,
    required this.sha256,
    required this.senderDeviceId,
    required this.senderDeviceName,
  });

  Map<String, dynamic> toJson() => {
    'transferId': transferId,
    'filename': filename,
    'fileSize': fileSize,
    'mimeType': mimeType,
    'sha256': sha256,
    'senderDeviceId': senderDeviceId,
    'senderDeviceName': senderDeviceName,
  };

  static FileTransferRequestPayload? fromJson(Map<String, dynamic> json) {
    try {
      final transferId = json['transferId'] as String?;
      final filename = json['filename'] as String?;
      final fileSize = json['fileSize'] as int?;
      final mimeType = json['mimeType'] as String? ?? 'application/octet-stream';
      final sha256 = json['sha256'] as String?;
      final senderDeviceId = json['senderDeviceId'] as String?;
      final senderDeviceName = json['senderDeviceName'] as String?;

      if (transferId == null || filename == null || fileSize == null || sha256 == null) {
        return null;
      }

      return FileTransferRequestPayload(
        transferId: transferId,
        filename: filename,
        fileSize: fileSize,
        mimeType: mimeType,
        sha256: sha256,
        senderDeviceId: senderDeviceId ?? '',
        senderDeviceName: senderDeviceName ?? 'Unknown Sender',
      );
    } catch (_) {
      return null;
    }
  }
}

/// File Chunk Data
class FileChunkData {
  final String transferId;
  final int sequenceNumber;
  final Uint8List data;

  const FileChunkData({
    required this.transferId,
    required this.sequenceNumber,
    required this.data,
  });

  /// Encodes to binary:
  /// [2 bytes transferIdLength] [transferId utf8] [8 bytes sequenceNumber] [4 bytes dataLength] [data bytes]
  Uint8List encode() {
    final idBytes = utf8.encode(transferId);
    final totalSize = 2 + idBytes.length + 8 + 4 + data.length;
    final buffer = Uint8List(totalSize);
    final byteData = ByteData.sublistView(buffer);

    int offset = 0;
    // Transfer ID length (2 bytes)
    byteData.setUint16(offset, idBytes.length, Endian.big);
    offset += 2;

    // Transfer ID bytes
    buffer.setRange(offset, offset + idBytes.length, idBytes);
    offset += idBytes.length;

    // Sequence number (8 bytes)
    byteData.setUint64(offset, sequenceNumber, Endian.big);
    offset += 8;

    // Data length (4 bytes)
    byteData.setUint32(offset, data.length, Endian.big);
    offset += 4;

    // Chunk payload
    buffer.setRange(offset, offset + data.length, data);

    return buffer;
  }

  static FileChunkData? decode(Uint8List payload) {
    try {
      if (payload.length < 14) return null; // Min header size: 2 + 0 + 8 + 4 = 14
      final byteData = ByteData.sublistView(payload);

      int offset = 0;
      final idLen = byteData.getUint16(offset, Endian.big);
      offset += 2;

      if (payload.length < offset + idLen + 12) return null;

      final transferId = utf8.decode(Uint8List.sublistView(payload, offset, offset + idLen));
      offset += idLen;

      final sequenceNumber = byteData.getUint64(offset, Endian.big);
      offset += 8;

      final dataLen = byteData.getUint32(offset, Endian.big);
      offset += 4;

      if (payload.length < offset + dataLen) return null;

      final chunkBytes = Uint8List.sublistView(payload, offset, offset + dataLen);

      return FileChunkData(
        transferId: transferId,
        sequenceNumber: sequenceNumber,
        data: chunkBytes,
      );
    } catch (_) {
      return null;
    }
  }
}
