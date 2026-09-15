import 'dart:io';
import '../logging/app_logger.dart';

class NetworkUtils {
  NetworkUtils._();

  /// Gets the primary local IPv4 address.
  static Future<String> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      // First pass: Prioritize Wi-Fi and physical LAN adapters (wlan, wifi, ap, p2p, eth)
      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('wlan') ||
            name.contains('wifi') ||
            name.contains('wi-fi') ||
            name.contains('ap') ||
            name.contains('p2p') ||
            name.contains('eth') ||
            name.contains('en')) {
          for (final addr in interface.addresses) {
            if (!addr.isLoopback && !addr.isLinkLocal) {
              return addr.address;
            }
          }
        }
      }

      for (final interface in interfaces) {
        // Exclude virtual/docker/host-only adapters if possible
        final name = interface.name.toLowerCase();
        if (name.contains('vethernet') ||
            name.contains('docker') ||
            name.contains('vmware') ||
            name.contains('virtualbox')) {
          continue;
        }

        for (final addr in interface.addresses) {
          if (!addr.isLoopback && !addr.isLinkLocal) {
            return addr.address;
          }
        }
      }

      // Fallback: check any non-loopback
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e, st) {
      AppLogger.warning('Failed to determine local IP address', tag: 'NetworkUtils', error: e, stackTrace: st);
    }
    return '127.0.0.1';
  }

  /// Returns all available local IPv4 broadcast addresses.
  static Future<List<InternetAddress>> getBroadcastAddresses() async {
    final list = <InternetAddress>[];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            // Compute standard /24 subnet broadcast address as a heuristic if netmask not available
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final broadcastIp = '${parts[0]}.${parts[1]}.${parts[2]}.255';
              try {
                list.add(InternetAddress(broadcastIp));
              } catch (_) {}
            }
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Error computing subnet broadcast addresses', tag: 'NetworkUtils', error: e);
    }

    // Always include global broadcast address
    list.add(InternetAddress('255.255.255.255'));
    return list;
  }

  /// Platform string representation
  static String getPlatformName() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}
