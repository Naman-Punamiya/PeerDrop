import 'package:flutter/material.dart';
import 'package:peer_drop/core/widgets/navigation_bar.dart';
import 'package:peer_drop/features/transfer/widgets/file_select.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PeerDrop', style: TextStyle(fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              // Navigate to settings page
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
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
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.android, size: 42, color: Colors.green),
                    SizedBox(width: 24),
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
                            'Visible to other devices as "Device Name"',
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
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Text(
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
                Text(
                  'Nearby Devices',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // Refresh nearby devices
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.only(
                right: 12.0,
                left: 12.0,
                top: 8.0,
                bottom: 8.0,
              ),
              height: MediaQuery.of(context).size.height * .5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return deviceCard(
                    'Device ${index + 1}',
                    'Type ${index + 1}',
                    '192.168.1.${index + 1}',
                    Icons.devices,
                    Colors.green,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavBar(context, 0),
    );
  }

  Widget deviceCard(
    String deviceName,
    String deviceType,
    String ipAddress,
    IconData iconData,
    Color iconColor,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FileSelectPage(
              deviceIcon: iconData,
              deviceName: deviceName,
              deviceType: deviceType,
              deviceIP: ipAddress,
            ),
          ),
        );
      },
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Device Icon
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: Colors.green, size: 30),
            ),

            const SizedBox(width: 24),

            // Device Information
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deviceName,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$deviceType • $ipAddress",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Signal Strength
            Icon(Icons.signal_cellular_alt, color: iconColor, size: 28),
          ],
        ),
      ),
    );
  }
}
