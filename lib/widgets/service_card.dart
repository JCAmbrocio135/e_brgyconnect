import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool highlighted;

  const ServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = highlighted ? Colors.white : AppColors.primary;

    return Material(
      color: highlighted ? AppColors.primary : Colors.white,
      elevation: highlighted ? 3 : 0,
      shadowColor: AppColors.primary.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: highlighted
            ? BorderSide.none
            : const BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 78,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: highlighted ? 26 : 22),
              const SizedBox(height: 7),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: highlighted ? 11 : 10,
                  fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
                  color: highlighted ? Colors.white : const Color(0xFF263238),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}