// ignore_for_file: avoid_print

import 'dart:io';

class NetworkUtils {
  static const List<String> _virtualOrCellularKeywords = [
    'vethernet',
    'vbox',
    'virtual',
    'docker',
    'vmnet',
    'wsl',
    'tun',
    'tap',
    'host-only',
    'rmnet',
    'ccmni',
    'p2p',
    'dummy',
    'sit',
    'cellular',
  ];

  static bool _isVirtualOrCellularInterface(String interfaceName) {
    final lowerName = interfaceName.toLowerCase();
    return _virtualOrCellularKeywords.any((keyword) => lowerName.contains(keyword));
  }

  static bool _isWifiOrLanInterface(String interfaceName) {
    final lower = interfaceName.toLowerCase();
    return lower.contains('wlan') ||
        lower.contains('eth') ||
        lower.contains('en') ||
        lower.contains('wifi') ||
        lower.contains('wi-fi');
  }

  /// Gets the primary local IPv4 address of the device.
  static Future<String> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
        includeLoopback: false,
      );

      // 1. Highest priority: Preferred Wi-Fi/Ethernet non-cellular interface
      for (final interface in interfaces) {
        if (_isVirtualOrCellularInterface(interface.name)) continue;
        if (_isWifiOrLanInterface(interface.name)) {
          for (final addr in interface.addresses) {
            if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
              return addr.address;
            }
          }
        }
      }

      // 2. Second pass: any non-virtual, non-cellular IPv4 interface
      for (final interface in interfaces) {
        if (_isVirtualOrCellularInterface(interface.name)) continue;
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }

      // 3. Fallback pass: any non-loopback IPv4 address
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('[DISCOVERY] Error retrieving local IP: $e');
    }
    return '127.0.0.1';
  }

  /// Calculates potential IPv4 broadcast addresses for active network interfaces.
  static Future<List<InternetAddress>> getBroadcastAddresses() async {
    final addressesSet = <String>{'255.255.255.255'};

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
        includeLoopback: false,
      );

      for (final interface in interfaces) {
        if (_isVirtualOrCellularInterface(interface.name)) continue;
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final broadcastIp = '${parts[0]}.${parts[1]}.${parts[2]}.255';
              addressesSet.add(broadcastIp);
            }
          }
        }
      }
    } catch (e) {
      print('[DISCOVERY] Error computing broadcast addresses: $e');
    }

    return addressesSet.map((ip) => InternetAddress(ip)).toList();
  }
}

