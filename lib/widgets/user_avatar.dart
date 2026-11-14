import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String? photoBase64;
  final String name;
  final double radius;

  const UserAvatar({
    super.key,
    required this.photoBase64,
    required this.name,
    this.radius = 40,
  });

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    final raw = photoBase64;
    if (raw != null && raw.isNotEmpty) {
      try {
        bytes = base64Decode(raw);
      } catch (_) {
        bytes = null; // corrupted data: fall back to the initial
      }
    }

    if (bytes != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary,
        backgroundImage: MemoryImage(bytes),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(
          fontSize: radius * 0.8,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}