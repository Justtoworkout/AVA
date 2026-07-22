// lib/widgets/alert_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert.dart';
import '../theme/app_theme.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onViewCall;

  const AlertCard({super.key, required this.alert, this.onViewCall});

  Color get _color {
    switch (alert.severity) {
      case AlertSeverity.high:
        return AppTheme.failed;
      case AlertSeverity.medium:
        return AppTheme.transferred;
      case AlertSeverity.low:
        return AppTheme.completed;
    }
  }

  IconData get _icon {
    switch (alert.severity) {
      case AlertSeverity.high:
        return Icons.error_rounded;
      case AlertSeverity.medium:
        return Icons.swap_calls_rounded;
      case AlertSeverity.low:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(alert.timestamp);
    final dateStr = _isToday(alert.timestamp)
        ? 'Today'
        : DateFormat('MMM d').format(alert.timestamp);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent strip
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_icon, size: 17, color: _color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: TextStyle(
                              color: _color,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '$dateStr · $timeStr',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  alert.body,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                if (onViewCall != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onViewCall,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new_rounded,
                            size: 13, color: _color),
                        const SizedBox(width: 5),
                        Text(
                          'View call details',
                          style: TextStyle(
                            color: _color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }
}
