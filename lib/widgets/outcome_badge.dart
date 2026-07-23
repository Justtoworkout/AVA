// lib/widgets/outcome_badge.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OutcomeBadge extends StatelessWidget {
  final String outcome;
  final bool compact;

  const OutcomeBadge({super.key, required this.outcome, this.compact = false});

  String get _label {
    switch (outcome) {
      case 'booked':
        return 'Booked';
      case 'failed':
        return 'Failed';
      case 'transferred':
        return 'Transferred';
      default:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.outcomeColor(outcome);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6), // Friendly rounded corners
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppTheme.outcomeIcon(outcome),
            size: compact ? 10 : 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
