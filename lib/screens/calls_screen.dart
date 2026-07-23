// lib/screens/calls_screen.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/call_record.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/call_list_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import 'call_detail_screen.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  final _fs = FirestoreService();
  String _filter = 'all'; // all | booked | failed | transferred

  static const _filters = [
    ('all', 'All'),
    ('booked', 'Booked'),
    ('failed', 'Failed'),
    ('transferred', 'Transferred'),
  ];

  List<CallRecord> _applyFilter(List<CallRecord> calls) {
    if (_filter == 'all') return calls;
    return calls.where((c) => c.outcome == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        title: const Text('Calls'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.circle,
                size: 9,
                color: AppTheme.booked.withValues(alpha: 0.85)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _FilterBar(
            selected: _filter,
            filters: _filters,
            onChanged: (f) => setState(() => _filter = f),
          ),
        ),
      ),
      body: StreamBuilder<List<CallRecord>>(
        stream: _fs.callsStream(),
        builder: (ctx, snap) {
          if (snap.hasError) {
            return ErrorState(message: snap.error.toString());
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const _ShimmerList();
          }
          final calls = _applyFilter(snap.data ?? []);
          if (calls.isEmpty) {
            return EmptyState(
              icon: Icons.phone_missed_rounded,
              title: _filter == 'all' ? 'No calls yet' : 'No $_filter calls',
              subtitle: _filter == 'all'
                  ? 'Call records will appear here once AVA handles calls.'
                  : 'No calls match this filter.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: calls.length,
            itemBuilder: (ctx, i) => CallListTile(
              call: calls[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CallDetailScreen(call: calls[i])),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String selected;
  final List<(String, String)> filters;
  final ValueChanged<String> onChanged;

  const _FilterBar({
    required this.selected,
    required this.filters,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (key, label) = filters[i];
          final isSelected = selected == key;
          return GestureDetector(
            key: ValueKey('filter_$key'),
            onTap: () => onChanged(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accent
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(6), // Clean flat corners
                border: Border.all(
                  color: isSelected ? AppTheme.accent : AppTheme.line,
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Shimmer.fromColors(
          baseColor: AppTheme.surfaceCard,
          highlightColor: AppTheme.surfaceElevated,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
