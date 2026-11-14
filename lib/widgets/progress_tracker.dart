
import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class ProgressTracker extends StatelessWidget {
  final List<String> steps;
  final int current;

  const ProgressTracker({
    super.key,
    required this.steps,
    required this.current,
  });

  static const _lineOff = Color(0xFFD9E2EC);

  // Status colors
  static const _pendingColor = Color(0xFF808080);
  static const _processingColor = Color(0xFFE6B422);
  static const _completedColor = Color(0xFF2E9D50);
  static const _cancelledColor = Color(0xFFD93636);

  Color _getStatusColor(String status, bool isDone, bool isCurrent) {
    final normalized = status
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('-', '');

    switch (normalized) {
      case 'pending':
        return _pendingColor;

      case 'processing':
        return _processingColor;

      case 'readyforpickup':
      case 'released':
        return _completedColor;

      case 'cancelled':
      case 'canceled':
      case 'rejected':
        return _cancelledColor;

      default:
        // Preserve the original behavior for unrecognized statuses.
        if (isDone || isCurrent) {
          return AppColors.green;
        }
        return _lineOff;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(child: _step(i)),
      ],
    );
  }

  Widget _line(bool active, bool visible) => Expanded(
        child: Container(
          height: 5,
          decoration: BoxDecoration(
            color: !visible
                ? Colors.transparent
                : (active ? AppColors.green : _lineOff),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );

  Widget _step(int i) {
    final isCurrent = i == current;
    final isDone = i < current;

    final statusColor = isCurrent
    ? _getStatusColor(steps[i], isDone, isCurrent)
    : _lineOff;
    return Column(
      children: [
        SizedBox(
          height: 30,
          child: Row(
            children: [
              _line(i <= current, i != 0),

              if (isCurrent)
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  ),
                )
              else
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),

              _line(i < current, i != steps.length - 1),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            steps[i],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.2,
              fontWeight:
                  isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent
                  ? statusColor
                  : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}
