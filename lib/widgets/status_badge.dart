import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case 'Processing': // yellow
        bg = const Color(0xFFFFF1C7);
        fg = const Color(0xFF8A6500);
        break;

      case 'Ready for Pickup': // green
      case 'Released':
        bg = const Color(0xFFD9F5E1);
        fg = const Color(0xFF1E7A3C);
        break;

      case 'Rejected': // red
      case 'Cancelled':
        bg = const Color(0xFFFFE0E0);
        fg = const Color(0xFFB42318);
        break;

      default: // Pending: gray
        bg = const Color(0xFFE5E7EB);
        fg = const Color(0xFF4B5563);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}