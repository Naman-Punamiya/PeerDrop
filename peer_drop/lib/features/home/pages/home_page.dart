import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:peer_drop/core/device/device_identity_service.dart';
import 'package:peer_drop/core/network/connection/connection_service.dart';
import 'package:peer_drop/core/network/discovery/device_discovery.dart';
import 'package:peer_drop/core/network/discovery/native_device_discovery.dart';
import 'package:peer_drop/core/network/discovery/udp_broadcaster.dart';
import 'package:peer_drop/core/network/discovery/udp_listener.dart';
import 'package:peer_drop/core/network/models/device_info.dart';
import 'package:peer_drop/core/network/transport/tcp_server.dart';
import 'package:peer_drop/core/widgets/navigation_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TcpServer? tcpServerInstance;
  DeviceDiscovery? deviceDiscoveryInstance;
  UdpBroadcaster? udpBroadcasterInstance;
  UdpListener? udpListenerInstance;

  StreamSubscription<List<DeviceInfo>>? _discoveredDevicesSubscription;
  List<DeviceInfo> listOfDiscoveredDevices = [];

  late final ConnectionService connectionService;

  String currentDeviceId = '';
  String currentDeviceName = '';
  String currentDevicePlatform = '';

  bool isSearchingForDevices = true;
  bool isInitializingNetwork = true;

  @override
  void initState() {
    super.initState();
    connectionService = ConnectionService();
    initializeNetwork();
  }

  Future<void> initializeNetwork() async {
    try {
      final identityService = DeviceIdentityService();

      currentDeviceId = await identityService.getDeviceId();
      currentDeviceName = await identityService.getDeviceName();
      currentDevicePlatform = identityService.getDeviceType();

      if (!mounted) return;

      final localDeviceInfo = DeviceInfo(
        id: currentDeviceId,
        name: currentDeviceName,
        platform: currentDevicePlatform,
        ip: '',
        discoveryPort: int.parse(dotenv.env['UDP_PORT']!),
        connectionPort: int.parse(dotenv.env['TCP_PORT']!),
      );

      udpBroadcasterInstance = UdpBroadcaster(deviceInfo: localDeviceInfo);
      udpListenerInstance = UdpListener();

      deviceDiscoveryInstance = NativeDeviceDiscovery(
        broadcaster: udpBroadcasterInstance!,
        listener: udpListenerInstance!,
        localDeviceInfo: localDeviceInfo,
      );

      _discoveredDevicesSubscription = deviceDiscoveryInstance!.devices.listen((updatedDevicesList) {
        if (!mounted) return;
        setState(() {
          listOfDiscoveredDevices = updatedDevicesList;
          if (listOfDiscoveredDevices.isNotEmpty) {
            isSearchingForDevices = false;
          }
        });
      });

      tcpServerInstance = TcpServer();

      await deviceDiscoveryInstance!.start();
      await tcpServerInstance!.start();

      if (!mounted) return;

      setState(() {
        isInitializingNetwork = false;
        isSearchingForDevices = true;
      });

      await Future.delayed(const Duration(seconds: 6));

      if (!mounted) return;

      if (listOfDiscoveredDevices.isEmpty) {
        setState(() {
          isSearchingForDevices = false;
        });
      }
    } catch (initializationError) {
      if (!mounted) return;

      setState(() {
        isInitializingNetwork = false;
        isSearchingForDevices = false;
      });
    }
  }

  @override
  void dispose() {
    _discoveredDevicesSubscription?.cancel();
    deviceDiscoveryInstance?.stop();
    tcpServerInstance?.stop();
    connectionService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isInitializingNetwork) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('PeerDrop', style: TextStyle(fontSize: 24)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PeerDrop', style: TextStyle(fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * .15,
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.android, size: 42, color: Colors.green),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'You are discoverable',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Visible to other devices as "$currentDeviceName"',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: const Text(
                          'Change',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nearby Devices',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    await udpBroadcasterInstance?.broadcastOnce();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(
                  right: 12,
                  left: 12,
                  top: 8,
                  bottom: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _buildDeviceList(listOfDiscoveredDevices),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavBar(context, 0),
    );
  }

  Widget _buildDeviceList(List<DeviceInfo> discoveredDevicesList) {
    if (isSearchingForDevices && discoveredDevicesList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching for nearby devices...',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (discoveredDevicesList.isEmpty) {
      return Center(
        child: Text(
          'No nearby devices',
          style: TextStyle(color: Colors.grey[600], fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      itemCount: discoveredDevicesList.length,
      itemBuilder: (context, index) {
        final targetDevice = discoveredDevicesList[index];

        return deviceCard(
          targetDevice.name,
          targetDevice.platform,
          targetDevice.ip,
          Icons.devices,
          Colors.green,
          () => _connectToTargetDevice(targetDevice),
        );
      },
    );
  }

  Future<void> _connectToTargetDevice(DeviceInfo targetDevice) async {
    try {
      await connectionService.connect(device: targetDevice);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${targetDevice.name}')),
      );
    } catch (connectionError) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $connectionError')),
      );
    }
  }

  Widget deviceCard(
    String deviceName,
    String deviceType,
    String ipAddress,
    IconData iconData,
    Color iconColor,
    VoidCallback onTapCallback,
  ) {
    return InkWell(
      onTap: onTapCallback,
      child: Container(
        height: MediaQuery.of(context).size.height * .1,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 30),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deviceName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$deviceType • $ipAddress',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.signal_cellular_alt, color: iconColor, size: 28),
          ],
        ),
      ),
    );
  }
}
