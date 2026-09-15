import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdrop/core/utils/file_utils.dart';
import 'package:peerdrop/features/connection/data/tcp_client.dart';
import 'package:peerdrop/features/connection/data/tcp_server.dart';
import 'package:peerdrop/features/connection/domain/protocol_message.dart';
import 'package:peerdrop/features/file_transfer/data/file_receiver.dart';
import 'package:peerdrop/features/file_transfer/data/file_sender.dart';
import 'package:peerdrop/features/file_transfer/data/filesystem_service.dart';
import 'package:peerdrop/features/file_transfer/domain/transfer_metadata.dart';
import 'package:peerdrop/features/file_transfer/domain/transfer_state.dart';

void main() {
  group('End-to-End File Transfer over TCP', () {
    late Directory tempSenderDir;
    late Directory tempReceiverDir;
    late TcpServer server;
    late TcpClient client;

    const testPort = 4055;

    setUp(() async {
      tempSenderDir = await Directory.systemTemp.createTemp('peerdrop_sender_');
      tempReceiverDir = await Directory.systemTemp.createTemp('peerdrop_receiver_');
    });

    tearDown(() async {
      client.dispose();
      await server.stop();
      if (await tempSenderDir.exists()) await tempSenderDir.delete(recursive: true);
      if (await tempReceiverDir.exists()) await tempReceiverDir.delete(recursive: true);
    });

    test('Full file transfer flow with handshake, chunks and SHA-256 verification', () async {
      // 1. Create a 250 KB dummy file to test multiple 64 KB chunks
      final senderFile = File('${tempSenderDir.path}/sample_document.dat');
      final sampleData = List<int>.generate(250 * 1024, (i) => i % 256);
      await senderFile.writeAsBytes(sampleData);

      final originalSha256 = await FileUtils.calculateSha256(senderFile);

      // 2. Setup Receiver Server
      final filesystemService = FilesystemService(downloadDirectory: tempReceiverDir.path);
      FileReceiver? receiver;
      TransferState? receiverFinalState;

      server = TcpServer(
        port: testPort,
        localDeviceId: 'receiver-dev-id',
        localDeviceName: 'Receiver PC',
        platform: 'windows',
        onPeerConnected: (socket, peerInfo) {
          receiver = FileReceiver(
            socket: socket,
            peerInfo: peerInfo,
            filesystemService: filesystemService,
            onStateChange: (state) {
              if (state.isCompleted || state.isFailed) {
                receiverFinalState = state;
              }
            },
          );
        },
        onMessageReceived: (socket, peerInfo, message) async {
          if (message.type == MessageType.fileTransferRequest) {
            final request = FileTransferRequestPayload.fromJson(message.payloadAsJson!);
            if (request != null && receiver != null) {
              // Automatically accept for test
              await receiver!.acceptTransfer(request);
            }
            return;
          }
          await receiver?.handleMessage(message);
        },
      );

      await server.start();

      // 3. Setup Sender Client
      client = TcpClient(
        remoteIp: '127.0.0.1',
        remotePort: testPort,
        localDeviceId: 'sender-dev-id',
        localDeviceName: 'Sender Android',
        platform: 'android',
      );

      final handshake = await client.connect();
      expect(handshake.deviceId, 'receiver-dev-id');
      expect(handshake.deviceName, 'Receiver PC');

      // 4. Start FileSender
      TransferState? senderFinalState;
      final metadata = TransferFileMetadata(
        path: senderFile.path,
        name: 'sample_document.dat',
        extension: '.dat',
        size: await senderFile.length(),
        mimeType: 'application/octet-stream',
      );

      final sender = FileSender(
        client: client,
        metadata: metadata,
        localDeviceId: 'sender-dev-id',
        localDeviceName: 'Sender Android',
        onStateChange: (state) {
          if (state.isCompleted || state.isFailed) {
            senderFinalState = state;
          }
        },
      );

      await sender.startTransfer();

      // Wait a moment for server to verify SHA-256 and complete
      await Future.delayed(const Duration(milliseconds: 500));

      expect(senderFinalState, isNotNull);
      expect(senderFinalState!.status, TransferStatus.completed);

      expect(receiverFinalState, isNotNull);
      expect(receiverFinalState!.status, TransferStatus.completed);
      expect(receiverFinalState!.actualSha256, originalSha256);

      // Verify file on disk
      final receivedFile = File(receiverFinalState!.filePath!);
      expect(await receivedFile.exists(), true);
      expect(await receivedFile.length(), 250 * 1024);

      final receivedHash = await FileUtils.calculateSha256(receivedFile);
      expect(receivedHash, originalSha256);
    });
  });
}
