import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peerdrop/features/discovery/domain/peer_device.dart';
import 'package:peerdrop/features/file_transfer/domain/transfer_state.dart';
import 'package:peerdrop/features/file_transfer/presentation/transfer_controller.dart';
import 'package:peerdrop/features/home/presentation/widgets/peer_card.dart';
import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyAndroidPeer = PeerDevice(
    deviceId: 'peer-android-1',
    deviceName: 'Samsung Galaxy',
    platform: 'android',
    ipAddress: '192.168.1.100',
    tcpPort: 4040,
    lastSeen: DateTime.now(),
  );

  final dummyWindowsPeer = PeerDevice(
    deviceId: 'peer-win-1',
    deviceName: 'Windows Office PC',
    platform: 'windows',
    ipAddress: '192.168.1.105',
    tcpPort: 4040,
    lastSeen: DateTime.now(),
  );

  testWidgets('PeerCard renders Android peer details and platform badge', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          transferControllerProvider.overrideWith((ref) => TransferControllerNotifierMock(TransferState.idleState)),
        ],
        child: PeerCard(peer: dummyAndroidPeer),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Samsung Galaxy'), findsOneWidget);
    expect(find.text('ANDROID'), findsOneWidget);
    expect(find.text('192.168.1.100:4040'), findsOneWidget);
    expect(find.byIcon(Icons.android_rounded), findsOneWidget);

    final sendButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send'));
    expect(sendButton.onPressed, isNotNull);
  });

  testWidgets('PeerCard renders Windows peer details with appropriate icon', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          transferControllerProvider.overrideWith((ref) => TransferControllerNotifierMock(TransferState.idleState)),
        ],
        child: PeerCard(peer: dummyWindowsPeer),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Windows Office PC'), findsOneWidget);
    expect(find.text('WINDOWS'), findsOneWidget);
    expect(find.text('192.168.1.105:4040'), findsOneWidget);
    expect(find.byIcon(Icons.laptop_windows_rounded), findsOneWidget);
  });

  testWidgets('PeerCard disables Send button when another transfer is active', (tester) async {
    const activeTransfer = TransferState(
      filename: 'sample.zip',
      fileSize: 10000,
      status: TransferStatus.transferring,
    );

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          transferControllerProvider.overrideWith((ref) => TransferControllerNotifierMock(activeTransfer)),
        ],
        child: PeerCard(peer: dummyAndroidPeer),
      ),
    );

    await tester.pumpAndSettle();

    final sendButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send'));
    expect(sendButton.onPressed, isNull);
  });
}

class TransferControllerNotifierMock extends StateNotifier<TransferState> implements TransferController {
  TransferControllerNotifierMock(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
