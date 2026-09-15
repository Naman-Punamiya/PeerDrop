import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdrop/core/errors/app_exceptions.dart';
import 'package:peerdrop/features/connection/data/message_framing.dart';
import 'package:peerdrop/features/connection/domain/protocol_message.dart';

void main() {
  group('MessageFramer Tests', () {
    late MessageFramer framer;

    setUp(() {
      framer = MessageFramer();
    });

    test('Frames and decodes a single complete message', () {
      final json = {'status': 'ok', 'message': 'hello'};
      final framed = MessageSerializer.frameJson(MessageType.hello, json);

      final messages = framer.processBytes(framed);
      expect(messages.length, 1);
      expect(messages[0].type, MessageType.hello);
      expect(messages[0].payloadAsJson?['status'], 'ok');
    });

    test('Handles TCP byte fragmentation (partial reads)', () {
      final json = {'transferId': '12345', 'filename': 'document.pdf'};
      final framed = MessageSerializer.frameJson(MessageType.fileTransferRequest, json);

      // Split framed bytes in half to simulate 2 TCP packets
      final part1 = framed.sublist(0, framed.length ~/ 2);
      final part2 = framed.sublist(framed.length ~/ 2);

      // First partial read should return no complete messages
      final msgs1 = framer.processBytes(part1);
      expect(msgs1.isEmpty, true);

      // Second partial read should complete the frame
      final msgs2 = framer.processBytes(part2);
      expect(msgs2.length, 1);
      expect(msgs2[0].type, MessageType.fileTransferRequest);
      expect(msgs2[0].payloadAsJson?['filename'], 'document.pdf');
    });

    test('Handles TCP byte coalescing (multiple messages in one read)', () {
      final msg1 = MessageSerializer.frameJson(MessageType.hello, {'from': 'device1'});
      final msg2 = MessageSerializer.frameJson(MessageType.fileTransferAccept, {'transferId': 't1'});
      final msg3 = MessageSerializer.frameEmpty(MessageType.fileTransferCancel);

      final combined = Uint8List(msg1.length + msg2.length + msg3.length);
      int offset = 0;
      combined.setRange(offset, offset + msg1.length, msg1);
      offset += msg1.length;
      combined.setRange(offset, offset + msg2.length, msg2);
      offset += msg2.length;
      combined.setRange(offset, offset + msg3.length, msg3);

      final messages = framer.processBytes(combined);
      expect(messages.length, 3);
      expect(messages[0].type, MessageType.hello);
      expect(messages[0].payloadAsJson?['from'], 'device1');
      expect(messages[1].type, MessageType.fileTransferAccept);
      expect(messages[2].type, MessageType.fileTransferCancel);
    });

    test('Throws FramingException on corrupt oversized length header', () {
      final corruptBuffer = Uint8List(10);
      final byteData = ByteData.sublistView(corruptBuffer);
      byteData.setUint32(0, 100 * 1024 * 1024, Endian.big); // 100 MB > maxPayloadSize
      byteData.setUint8(4, MessageType.fileTransferData);

      expect(() => framer.processBytes(corruptBuffer), throwsA(isA<FramingException>()));
    });
  });
}
