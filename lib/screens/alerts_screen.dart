// lib/screens/alerts_screen.dart

import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../models/call_record.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/alert_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import 'call_detail_screen.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _AlertCount(),
          ),
        ],
      ),
      body: StreamBuilder<List<CallRecord>>(
        stream: FirestoreService().alertCallsStream(),
        builder: (ctx, snap) {
          if (snap.hasError) {
            return ErrorState(message: snap.error.toString());
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const _ShimmerAlerts();
          }

          final calls = snap.data ?? [];
          final alerts =
              calls.map(Alert.fromCallRecord).toList();

          if (alerts.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'All clear',
              subtitle:
                  'No failed or transferred calls. AVA is handling everything smoothly.',
            );
          }

          // Group by severity
          final high = alerts
              .where((a) => a.severity == AlertSeverity.high)
              .toList();
          final medium = alerts
              .where((a) => a.severity == AlertSeverity.medium)
              .toList();

          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            children: [
              if (high.isNotEmpty) ...[
                _SectionHeader(
                  label: 'FAILED CALLS',
                  count: high.length,
                  color: AppTheme.failed,
                ),
                ...high.map((a) => AlertCard(
                      alert: a,
                      onViewCall: a.relatedCall != null
                          ? () => _openCall(context, a.relatedCall!)
                          : null,
                    )),
                const SizedBox(height: 8),
              ],
              if (medium.isNotEmpty) ...[
                _SectionHeader(
                  label: 'TRANSFERRED',
                  count: medium.length,
                  color: AppTheme.transferred,
                ),
                ...medium.map((a) => AlertCard(
                      alert: a,
                      onViewCall: a.relatedCall != null
                          ? () => _openCall(context, a.relatedCall!)
                          : null,
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  void _openCall(BuildContext context, CallRecord call) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CallDetailScreen(call: call)),
    );
  }
}

// ─── Section header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated alert count badge in AppBar ─────────────────────────────────

class _AlertCount extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CallRecord>>(
      stream: FirestoreService().alertCallsStream(),
      builder: (ctx, snap) {
        final count = snap.data?.length ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.failed.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.failed.withValues(alpha: 0.4)),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppTheme.failed,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

// ─── Shimmer ───────────────────────────────────────────────────────────────

class _ShimmerAlerts extends StatelessWidget {
  const _ShimmerAlerts();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        height: 110,
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
      ),
    );
  }
}
