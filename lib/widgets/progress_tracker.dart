import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class ProgressTracker extends StatelessWidget {
  final List<String> steps;
  final int current; // index of the current step
  final Color color; // circle, dots and filled lines
  final Color? textColor; // current step label (defaults to color)

  const ProgressTracker({
    super.key,
    required this.steps,
    required this.current,
    this.color = AppColors.green,
    this.textColor,
  });

  static const _lineOff = Color(0xFFD9E2EC);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) Expanded(child: _step(i)),
      ],
    );
  }

  Widget _line(bool active, bool visible) => Expanded(
        child: Container(
          height: 5,
          decoration: BoxDecoration(
            color: !visible
                ? Colors.transparent
                : (active ? color : _lineOff),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );

  Widget _step(int i) {
    final isCurrent = i == current;
    final isDone = i < current;

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
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                )
              else
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDone ? color : _lineOff,
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
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? (textColor ?? color) : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}