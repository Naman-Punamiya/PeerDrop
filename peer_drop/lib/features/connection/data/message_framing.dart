import 'dart:convert';
import 'dart:typed_data';
import '../../../core/errors/app_exceptions.dart';
import '../domain/protocol_message.dart';

class MessageFramer {
  static const int headerSize = 5; // 4 bytes length + 1 byte type
  static const int maxPayloadSize = 50 * 1024 * 1024; // 50 MB guard limit

  final BytesBuilder _builder = BytesBuilder(copy: false);

  /// Appends newly received bytes and extracts all fully arrived protocol messages.
  List<RawProtocolMessage> processBytes(Uint8List newBytes) {
    if (newBytes.isEmpty) return const [];

    _builder.add(newBytes);
    final buffer = _builder.takeBytes();
    int offset = 0;
    final messages = <RawProtocolMessage>[];

    while (buffer.length - offset >= headerSize) {
      final byteData = ByteData.sublistView(buffer, offset, offset + headerSize);
      final payloadLength = byteData.getUint32(0, Endian.big);
      final messageType = byteData.getUint8(4);

      if (payloadLength > maxPayloadSize) {
        reset();
        throw FramingException('Frame payload length $payloadLength exceeds maximum allowed limit $maxPayloadSize');
      }

      final totalFrameSize = headerSize + payloadLength;
      if (buffer.length - offset < totalFrameSize) {
        // Incomplete message arrived, put unread remainder back
        break;
      }

      // Zero-copy view of payload
      final payloadStart = offset + headerSize;
      final payloadEnd = offset + totalFrameSize;
      final payload = Uint8List.sublistView(buffer, payloadStart, payloadEnd);
      messages.add(RawProtocolMessage(type: messageType, payload: payload));

      offset += totalFrameSize;
    }

    if (offset < buffer.length) {
      _builder.add(Uint8List.sublistView(buffer, offset));
    }

    return messages;
  }

  void reset() {
    _builder.clear();
  }
}

class MessageSerializer {
  MessageSerializer._();

  /// Frames a raw payload with 4-byte length and 1-byte type header.
  static Uint8List frame(int messageType, Uint8List payload) {
    final frameLength = MessageFramer.headerSize + payload.length;
    final buffer = Uint8List(frameLength);
    final byteData = ByteData.sublistView(buffer);

    byteData.setUint32(0, payload.length, Endian.big);
    byteData.setUint8(4, messageType);
    buffer.setRange(MessageFramer.headerSize, frameLength, payload);

    return buffer;
  }

  /// Convenience method to frame a JSON payload.
  static Uint8List frameJson(int messageType, Map<String, dynamic> json) {
    final jsonStr = jsonEncode(json);
    final payloadBytes = utf8.encode(jsonStr);
    return frame(messageType, Uint8List.fromList(payloadBytes));
  }

  /// Convenience method to frame an empty payload.
  static Uint8List frameEmpty(int messageType) {
    return frame(messageType, Uint8List(0));
  }
}
