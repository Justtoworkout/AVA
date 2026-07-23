// lib/widgets/appointment_detail_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../theme/app_theme.dart';

class AppointmentDetailSheet extends StatelessWidget {
  final Appointment appt;

  const AppointmentDetailSheet({
    super.key,
    required this.appt,
  });

  static void show(BuildContext context, Appointment appt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppointmentDetailSheet(appt: appt),
    );
  }

  /// Helper to extract patient name and service type from title if formatted like "Dental appointment for Kevin"
  Map<String, String> _parseTitle(String rawTitle) {
    final lower = rawTitle.trim();
    if (lower.toLowerCase().contains(' for ')) {
      final parts = lower.split(RegExp(r'\s+for\s+', caseSensitive: false));
      if (parts.length >= 2) {
        return {
          'service': parts[0].trim(),
          'patient': parts.sublist(1).join(' for ').trim(),
        };
      }
    }
    return {
      'service': rawTitle,
      'patient': 'Patient',
    };
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parseTitle(appt.title);
    final patientName = parsed['patient']!;
    final serviceType = parsed['service']!;

    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(appt.start);
    final timeStr = appt.isAllDay
        ? 'All day event'
        : '${DateFormat('h:mm a').format(appt.start)} – ${DateFormat('h:mm a').format(appt.end)}';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppTheme.border, width: 1),
          left: BorderSide(color: AppTheme.border, width: 1),
          right: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Row
              Row(
                children: [
                  const Text(
                    'Appointment Details',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.booked.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.booked.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: AppTheme.booked,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          appt.status.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.booked,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppTheme.textSecondary, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Structured Info Container
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    // Patient Name
                    _InfoRow(
                      icon: Icons.person_rounded,
                      iconColor: AppTheme.primary,
                      label: 'Patient Name',
                      value: patientName,
                      isFirst: true,
                    ),
                    const Divider(height: 1),

                    // Service / Purpose
                    _InfoRow(
                      icon: Icons.medical_services_rounded,
                      iconColor: const Color(0xFF60A5FA),
                      label: 'Appointment',
                      value: serviceType,
                    ),
                    const Divider(height: 1),

                    // Date
                    _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      iconColor: const Color(0xFFFBBF24),
                      label: 'Date',
                      value: dateStr,
                    ),
                    const Divider(height: 1),

                    // Time & Duration
                    _InfoRow(
                      icon: Icons.access_time_filled_rounded,
                      iconColor: const Color(0xFF4ADE80),
                      label: 'Time',
                      value: '$timeStr (${appt.durationLabel})',
                    ),
                    const Divider(height: 1),

                    // Location
                    _InfoRow(
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFFFF7A00),
                      label: 'Location',
                      value: (appt.location != null &&
                              appt.location!.trim().isNotEmpty)
                          ? appt.location!
                          : 'Main Hospital Clinic / Desk',
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Notes / Description Section
              const Text(
                'NOTES & DETAILS',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  (appt.description != null &&
                          appt.description!.trim().isNotEmpty)
                      ? appt.description!
                      : 'Booked via AVA Voice AI Companion. Synced directly with Google Calendar.',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Copy Details Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final text = '''
Patient Name: $patientName
Appointment: $serviceType
Date: $dateStr
Time: $timeStr (${appt.durationLabel})
Location: ${appt.location ?? 'Main Hospital Clinic'}
Status: ${appt.status}
''';
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            const Text('Appointment details copied to clipboard'),
                        backgroundColor: AppTheme.surfaceElevated,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy Appointment Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
