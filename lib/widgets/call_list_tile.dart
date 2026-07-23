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

    return InkWell(
      key: ValueKey('call_tile_${call.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            // Avatar circle with outcome color
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.outcomeColor(call.outcome).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone_rounded,
                color: AppTheme.outcomeColor(call.outcome),
                size: 20,
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
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const Spacer(),
                      OutcomeBadge(outcome: call.outcome, compact: true),
                    ],
                  ),
                  const SizedBox(height: 5),
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
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.timer_outlined,
                          size: 11, color: AppTheme.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        _formatDuration(call.durationSeconds),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  if (call.summary != null && call.summary!.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      call.summary!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontFamily: 'Inter',
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
