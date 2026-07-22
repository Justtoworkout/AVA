// lib/widgets/appointment_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../theme/app_theme.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appt;
  final bool isToday;

  const AppointmentCard({
    super.key,
    required this.appt,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = appt.isAllDay
        ? 'All day'
        : DateFormat('h:mm a').format(appt.start);
    final endStr = appt.isAllDay
        ? ''
        : ' – ${DateFormat('h:mm a').format(appt.end)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? AppTheme.primary.withValues(alpha: 0.4)
              : AppTheme.border,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left time strip
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isToday
                    ? AppTheme.primary.withValues(alpha: 0.08)
                    : AppTheme.surfaceElevated.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    appt.isAllDay
                        ? 'ALL'
                        : DateFormat('h:mm').format(appt.start),
                    style: TextStyle(
                      color: isToday ? AppTheme.primary : AppTheme.textPrimary,
                      fontSize: appt.isAllDay ? 10 : 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!appt.isAllDay)
                    Text(
                      DateFormat('a').format(appt.start),
                      style: TextStyle(
                        color: isToday
                            ? AppTheme.primary.withValues(alpha: 0.8)
                            : AppTheme.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            // Vertical divider
            Container(width: 1, color: AppTheme.border),
            // Content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            appt.title,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'Today',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 11, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '$timeStr$endStr',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.timer_outlined,
                            size: 11, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          appt.durationLabel,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (appt.location != null &&
                        appt.location!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 11, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              appt.location!,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (appt.description != null &&
                        appt.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        appt.description!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
