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

    final isConfirmed = appt.status.toLowerCase() == 'confirmed';
    final statusColor = isConfirmed ? AppTheme.accent : AppTheme.alert;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), // Clean modern top corners
        border: Border.all(color: AppTheme.line, width: 1),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6), // Segmented corners
                      border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isConfirmed ? Icons.check_circle_outline_rounded : Icons.highlight_off_rounded,
                          size: 13,
                          color: statusColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          appt.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9,
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

              // Structured Info Container (Stripe-Style Soft Shadow Card)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.cardShadow,
                  border: Border.all(color: AppTheme.line.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    // Patient Name
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Patient Name',
                      value: patientName,
                    ),
                    const Divider(height: 1),

                    // Service / Purpose
                    _InfoRow(
                      icon: Icons.assignment_outlined,
                      label: 'Appointment',
                      value: serviceType,
                    ),
                    const Divider(height: 1),

                    // Date
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date',
                      value: dateStr,
                    ),
                    const Divider(height: 1),

                    // Time & Duration
                    _InfoRow(
                      icon: Icons.access_time_rounded,
                      label: 'Time',
                      value: '$timeStr (${appt.durationLabel})',
                    ),
                    const Divider(height: 1),

                    // Location
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: (appt.location != null && appt.location!.trim().isNotEmpty)
                          ? appt.location!
                          : 'Main Hospital Clinic / Desk',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Notes / Description Section
              const Text(
                'NOTES & DETAILS',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.cardShadow,
                  border: Border.all(color: AppTheme.line.withValues(alpha: 0.5)),
                ),
                child: Text(
                  (appt.description != null && appt.description!.trim().isNotEmpty)
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

              // Copy Details Action Button (Stripe Indigo Solid Styling)
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
                        content: const Text(
                          'Appointment details copied to clipboard',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: AppTheme.ink,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                      borderRadius: BorderRadius.circular(8), // Aligned to token corners
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
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant inline icon in Stripe style: neutral and quiet
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: AppTheme.textSecondary, size: 18),
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
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
