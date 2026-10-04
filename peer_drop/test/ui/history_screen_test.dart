import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peerdrop/features/file_transfer/domain/transfer_state.dart';
import 'package:peerdrop/features/history/data/history_repository.dart';
import 'package:peerdrop/features/history/domain/transfer_record.dart';
import 'package:peerdrop/features/history/presentation/history_controller.dart';
import 'package:peerdrop/features/history/presentation/history_screen.dart';
import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final record1 = TransferRecord(
    id: 'h-1',
    filename: 'document.pdf',
    fileSize: 1024 * 500,
    status: TransferStatus.completed,
    direction: TransferDirection.send,
    peerName: 'Pixel 8',
    peerDeviceId: 'peer-id-1',
    peerPlatform: 'android',
    timestamp: DateTime(2026, 3, 10, 14, 30),
    sha256: 'sha256-sample-hash',
  );

  final record2 = TransferRecord(
    id: 'h-2',
    filename: 'image.png',
    fileSize: 1024 * 1024 * 2,
    status: TransferStatus.failed,
    direction: TransferDirection.receive,
    peerName: 'iPad Air',
    peerDeviceId: 'peer-id-2',
    peerPlatform: 'ios',
    timestamp: DateTime(2026, 3, 10, 15, 0),
  );

  testWidgets('HistoryScreen shows empty state when no transfers exist', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final historyRepo = HistoryRepository(prefs);

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          historyRepositoryProvider.overrideWithValue(historyRepo),
        ],
        child: const HistoryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Transfer History'), findsOneWidget);
    expect(find.text('No Transfers Yet'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
  });

  testWidgets('HistoryScreen shows list of transfer cards with status and peer info', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final historyRepo = HistoryRepository(prefs);

    await historyRepo.addRecord(record1);
    await historyRepo.addRecord(record2);

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          historyRepositoryProvider.overrideWithValue(historyRepo),
        ],
        child: const HistoryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('document.pdf'), findsOneWidget);
    expect(find.textContaining('To: Pixel 8'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);

    expect(find.text('image.png'), findsOneWidget);
    expect(find.textContaining('From: iPad Air'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);

    // Delete single record
    final deleteButtons = find.byTooltip('Delete Record');
    expect(deleteButtons, findsNWidgets(2));

    await tester.tap(deleteButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('image.png'), findsNothing);
    expect(find.text('document.pdf'), findsOneWidget);
  });

  testWidgets('HistoryScreen clear history button shows confirmation dialog and clears list', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final historyRepo = HistoryRepository(prefs);

    await historyRepo.addRecord(record1);

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          historyRepositoryProvider.overrideWithValue(historyRepo),
        ],
        child: const HistoryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    final clearAllButton = find.byTooltip('Clear History');
    expect(clearAllButton, findsOneWidget);

    await tester.tap(clearAllButton);
    await tester.pumpAndSettle();

    expect(find.text('Clear Transfer History'), findsOneWidget);
    expect(find.text('Clear All'), findsOneWidget);

    await tester.tap(find.text('Clear All'));
    await tester.pumpAndSettle();

    expect(find.text('No Transfers Yet'), findsOneWidget);
  });
}
