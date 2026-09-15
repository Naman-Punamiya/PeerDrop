import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../discovery/presentation/discovery_controller.dart';
import '../../discovery/presentation/discovery_state.dart';
import '../../file_transfer/presentation/transfer_controller.dart';
import '../../file_transfer/presentation/widgets/incoming_transfer_dialog.dart';
import 'widgets/active_transfer_card.dart';
import 'widgets/device_card.dart';
import 'widgets/peer_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discovery = ref.watch(discoveryControllerProvider);

    // Show incoming request dialog if present
    ref.listen(incomingRequestProvider, (previous, next) {
      if (next != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const IncomingTransferDialog(),
        );
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopLayout = screenWidth >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.wifi_tethering_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'PeerDrop',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/history'),
            tooltip: 'Transfer History',
            icon: const Icon(Icons.history_rounded, color: AppColors.textPrimary),
          ),
          IconButton(
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: isDesktopLayout
            ? _buildDesktopLayout(context, ref, discovery)
            : _buildMobileLayout(context, ref, discovery),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    DiscoveryState discovery,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const DeviceCard(),
        const ActiveTransferCard(),
        _buildPeersSectionHeader(context, ref, discovery),
        _buildPeersList(discovery),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    DiscoveryState discovery,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column: Device details and active transfer
        SizedBox(
          width: 380,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: const [
              DeviceCard(),
              ActiveTransferCard(),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Right column: Discovered peers list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildPeersSectionHeader(context, ref, discovery),
              _buildPeersList(discovery),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeersSectionHeader(
    BuildContext context,
    WidgetRef ref,
    DiscoveryState discovery,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'Nearby Devices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: discovery.peers.isNotEmpty ? AppColors.accentLight : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${discovery.peers.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: discovery.peers.isNotEmpty ? AppColors.accentDark : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          Switch.adaptive(
            value: discovery.isDiscovering,
            activeTrackColor: AppColors.accent,
            onChanged: (val) {
              if (val) {
                ref.read(discoveryControllerProvider.notifier).startDiscovery();
              } else {
                ref.read(discoveryControllerProvider.notifier).stopDiscovery();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeersList(DiscoveryState discovery) {
    if (discovery.hasError) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                discovery.errorMessage ?? 'UDP discovery encounter an error',
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    if (!discovery.isDiscovering && discovery.peers.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          children: const [
            Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'Discovery is Paused',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Turn on the switch above to search for nearby devices',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (discovery.peers.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: const [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Searching for Nearby Peers...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Make sure both devices are on the same Wi-Fi network and have PeerDrop open.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: discovery.peers.length,
      itemBuilder: (context, index) {
        final peer = discovery.peers[index];
        return PeerCard(peer: peer);
      },
    );
  }
}
