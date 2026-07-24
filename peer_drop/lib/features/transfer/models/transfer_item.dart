import 'package:flutter/material.dart';
import 'package:peer_drop/features/transfer/models/transfer_file.dart';

class TransferItem {
  final String deviceName;
  final String deviceType;
  final String fileName;
  final String size;
  final int progress;
  final String speed;
  final String eta;
  final IconData icon;
  final Color color;
  final bool completed;
  final List<TransferFile> files;

  TransferItem({
    required this.deviceName,
    required this.deviceType,
    required this.fileName,
    required this.size,
    required this.progress,
    required this.speed,
    required this.eta,
    required this.icon,
    required this.color,
    this.completed = false,
    required this.files,
  });
}
