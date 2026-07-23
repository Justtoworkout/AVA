// lib/widgets/call_list_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/call_record.dart';
import '../theme/app_theme.dart';
import 'outcome_badge.dart';

class CallListTile extends StatelessWidget {
  final CallRecord call;
  final VoidCallback? onTap;

  const CallListTile({super.key, required this.call, this.onTap});

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(call.timestamp);
    final dateStr = _isToday(call.timestamp)
        ? 'Today'
        : DateFormat('MMM d').format(call.timestamp);

    final showDuration = call.durationSeconds > 0;

    return InkWell(
      key: ValueKey('call_tile_${call.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12), // Clean modern curves
          boxShadow: AppTheme.cardShadow,          // High-end soft shadows
          border: Border.all(color: AppTheme.line.withValues(alpha: 0.5), width: 1),
        ),
        child: Row(
          children: [
            // Left margin line decoration using the outcome color
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.outcomeColor(call.outcome),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        call.patientNumber,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      OutcomeBadge(outcome: call.outcome, compact: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 11, color: AppTheme.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        '$dateStr · $timeStr',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      if (showDuration) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.timer_outlined,
                            size: 11, color: AppTheme.textMuted),
                        const SizedBox(width: 3),
                        Text(
                          _formatDuration(call.durationSeconds),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (call.summary != null && call.summary!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      call.summary!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }
}
