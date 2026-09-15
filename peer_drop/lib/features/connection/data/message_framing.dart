import 'dart:convert';
import 'dart:typed_data';
import '../../../core/errors/app_exceptions.dart';
import '../domain/protocol_message.dart';

class MessageFramer {
  static const int headerSize = 5; // 4 bytes length + 1 byte type
  static const int maxPayloadSize = 50 * 1024 * 1024; // 50 MB guard limit

  Uint8List _currentBytes = Uint8List(0);
  int _readOffset = 0;

  /// Appends newly received bytes and extracts all fully arrived protocol messages.
  List<RawProtocolMessage> processBytes(Uint8List newBytes) {
    if (newBytes.isEmpty) return const [];

    // Retain only unread remainder from previous batch
    if (_readOffset > 0) {
      if (_readOffset < _currentBytes.length) {
        _currentBytes = _currentBytes.sublist(_readOffset);
      } else {
        _currentBytes = Uint8List(0);
      }
      _readOffset = 0;
    }

    if (_currentBytes.isEmpty) {
      _currentBytes = newBytes;
    } else {
      final combined = Uint8List(_currentBytes.length + newBytes.length);
      combined.setRange(0, _currentBytes.length, _currentBytes);
      combined.setRange(_currentBytes.length, combined.length, newBytes);
      _currentBytes = combined;
    }

    final messages = <RawProtocolMessage>[];

    while (_currentBytes.length - _readOffset >= headerSize) {
      final byteData = ByteData.sublistView(_currentBytes, _readOffset, _readOffset + headerSize);
      final payloadLength = byteData.getUint32(0, Endian.big);
      final messageType = byteData.getUint8(4);

      if (payloadLength > maxPayloadSize) {
        reset();
        throw FramingException('Frame payload length $payloadLength exceeds maximum allowed limit $maxPayloadSize');
      }

      final totalFrameSize = headerSize + payloadLength;
      if (_currentBytes.length - _readOffset < totalFrameSize) {
        // Incomplete message arrived, wait for more data from TCP stream
        break;
      }

      // Extract payload slice
      final payloadStart = _readOffset + headerSize;
      final payloadEnd = _readOffset + totalFrameSize;
      final payload = _currentBytes.sublist(payloadStart, payloadEnd);
      messages.add(RawProtocolMessage(type: messageType, payload: payload));

      _readOffset += totalFrameSize;
    }

    return messages;
  }

  void reset() {
    _currentBytes = Uint8List(0);
    _readOffset = 0;
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
