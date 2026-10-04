import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peerdrop/features/file_transfer/domain/transfer_state.dart';
import 'package:peerdrop/features/file_transfer/presentation/transfer_controller.dart';
import 'package:peerdrop/features/home/presentation/widgets/active_transfer_card.dart';
import '../helpers/test_helpers.dart';

class MockTransferController extends StateNotifier<TransferState> implements TransferController {
  MockTransferController(super.state);

  int cancelCallCount = 0;
  int acceptCallCount = 0;
  int rejectCallCount = 0;
  int resetCallCount = 0;

  @override
  void cancelCurrentTransfer() {
    cancelCallCount++;
  }

  @override
  Future<void> acceptIncomingTransfer() async {
    acceptCallCount++;
  }

  @override
  void rejectIncomingTransfer([String? reason]) {
    rejectCallCount++;
  }

  @override
  void resetToIdle() {
    resetCallCount++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ActiveTransferCard is hidden when status is idle', (tester) async {
    final mockController = MockTransferController(TransferState.idleState);

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          transferControllerProvider.overrideWith((ref) => mockController),
        ],
        child: const ActiveTransferCard(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(ActiveTransferCard), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('ActiveTransferCard shows progress, speed and Cancel button during transferring', (tester) async {
    final transferringState = TransferState(
      filename: 'video.mp4',
      fileSize: 10 * 1024 * 1024,
      bytesTransferred: 5 * 1024 * 1024,
      speedBytesPerSecond: 2 * 1024 * 1024,
      status: TransferStatus.transferring,
      direction: TransferDirection.send,
      peerDeviceName: 'Pixel 8',
    );

    final mockController = MockTransferController(transferringState);

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          transferControllerProvider.overrideWith((ref) => mockController),
        ],
        child: const ActiveTransferCard(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('video.mp4'), findsOneWidget);
    expect(find.textContaining('Pixel 8'), findsOneWidget);
    expect(find.text('Transferring'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('50%'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap cancel button
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(mockController.cancelCallCount, 1);
  });

  testWidgets('ActiveTransferCard shows Completed status and Dismiss button', (tester) async {
    final completedState = TransferState(
      filename: 'document.pdf',
      fileSize: 500000,
      bytesTransferred: 500000,
      status: TransferStatus.completed,
      direction: TransferDirection.receive,
      peerDeviceName: 'MacBook',
      filePath: '/downloads/document.pdf',
    );

    final mockController = MockTransferController(completedState);

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          transferControllerProvider.overrideWith((ref) => mockController),
        ],
        child: const ActiveTransferCard(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Saved Location:'), findsOneWidget);
    expect(find.text('/downloads/document.pdf'), findsOneWidget);
    expect(find.text('Open File'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);

    await tester.tap(find.text('Dismiss'));
    await tester.pump();
    expect(mockController.resetCallCount, 1);
  });

  testWidgets('ActiveTransferCard shows Accept and Reject buttons for incoming request', (tester) async {
    final waitingState = TransferState(
      filename: 'archive.tar.gz',
      fileSize: 1000000,
      status: TransferStatus.waitingForAcceptance,
      direction: TransferDirection.receive,
      peerDeviceName: 'Linux Box',
    );

    final mockController = MockTransferController(waitingState);

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          transferControllerProvider.overrideWith((ref) => mockController),
        ],
        child: const ActiveTransferCard(),
      ),
    );

    await tester.pump();

    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pump();
    expect(mockController.acceptCallCount, 1);

    await tester.tap(find.text('Reject'));
    await tester.pump();
    expect(mockController.rejectCallCount, 1);
  });
}
