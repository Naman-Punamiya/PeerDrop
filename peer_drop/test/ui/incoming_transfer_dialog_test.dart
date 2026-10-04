import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peerdrop/core/utils/file_utils.dart';
import 'package:peerdrop/features/connection/domain/protocol_message.dart';
import 'package:peerdrop/features/file_transfer/domain/transfer_state.dart';
import 'package:peerdrop/features/file_transfer/presentation/transfer_controller.dart';
import 'package:peerdrop/features/file_transfer/presentation/widgets/incoming_transfer_dialog.dart';
import '../helpers/test_helpers.dart';

class MockDialogTransferController extends StateNotifier<TransferState> implements TransferController {
  MockDialogTransferController() : super(TransferState.idleState);

  int acceptCount = 0;
  int rejectCount = 0;

  @override
  Future<void> acceptIncomingTransfer() async {
    acceptCount++;
  }

  @override
  void rejectIncomingTransfer([String? reason]) {
    rejectCount++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const dummyRequest = FileTransferRequestPayload(
    transferId: 'req-123',
    filename: 'design_spec.pdf',
    fileSize: 1024 * 1024 * 3, // 3MB
    mimeType: 'application/pdf',
    sha256: 'hash-abc',
    senderDeviceId: 'peer-sender',
    senderDeviceName: 'Pixel 8 Pro',
  );

  const dummyPeer = HandshakeMessage(
    deviceId: 'peer-sender',
    deviceName: 'Pixel 8 Pro',
    platform: 'android',
  );

  testWidgets('IncomingTransferDialog displays sender and file details', (tester) async {
    final mockController = MockDialogTransferController();

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          incomingRequestProvider.overrideWith((ref) => dummyRequest),
          incomingPeerProvider.overrideWith((ref) => dummyPeer),
          transferControllerProvider.overrideWith((ref) => mockController),
        ],
        child: const IncomingTransferDialog(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Incoming File Request'), findsOneWidget);
    expect(find.text('Pixel 8 Pro'), findsOneWidget);
    expect(find.text('design_spec.pdf'), findsOneWidget);
    expect(find.text(FileUtils.formatBytes(dummyRequest.fileSize)), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
  });

  testWidgets('Clicking Accept on IncomingTransferDialog triggers controller', (tester) async {
    final mockController = MockDialogTransferController();

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          incomingRequestProvider.overrideWith((ref) => dummyRequest),
          incomingPeerProvider.overrideWith((ref) => dummyPeer),
          transferControllerProvider.overrideWith((ref) => mockController),
        ],
        child: const IncomingTransferDialog(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(mockController.acceptCount, 1);
  });

  testWidgets('Clicking Reject on IncomingTransferDialog triggers controller', (tester) async {
    final mockController = MockDialogTransferController();

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          incomingRequestProvider.overrideWith((ref) => dummyRequest),
          incomingPeerProvider.overrideWith((ref) => dummyPeer),
          transferControllerProvider.overrideWith((ref) => mockController),
        ],
        child: const IncomingTransferDialog(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();

    expect(mockController.rejectCount, 1);
  });
}
