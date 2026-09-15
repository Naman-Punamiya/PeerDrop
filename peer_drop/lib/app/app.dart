import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/connection/presentation/connection_controller.dart';
import '../features/file_transfer/presentation/transfer_controller.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class PeerDropApp extends ConsumerWidget {
  const PeerDropApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep TCP server and transfer controller active in background
    ref.watch(tcpServerProvider);
    ref.watch(transferControllerProvider);

    return MaterialApp.router(
      title: 'PeerDrop',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
