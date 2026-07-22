// lib/screens/call_detail_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import '../models/call_record.dart';
import '../theme/app_theme.dart';
import '../widgets/outcome_badge.dart';

class CallDetailScreen extends StatefulWidget {
  final CallRecord call;

  const CallDetailScreen({super.key, required this.call});

  @override
  State<CallDetailScreen> createState() => _CallDetailScreenState();
}

class _CallDetailScreenState extends State<CallDetailScreen> {
  late final AudioPlayer _player;
  bool _playerReady = false;
  bool _playerLoading = false;
  String? _playerError;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    if (widget.call.recordingUrl != null) {
      _initPlayer();
    }
  }

  Future<void> _initPlayer() async {
    setState(() => _playerLoading = true);
    try {
      await _player.setUrl(widget.call.recordingUrl!);
      _durationSub = _player.durationStream.listen((d) {
        if (mounted) setState(() => _duration = d ?? Duration.zero);
      });
      _positionSub = _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _stateSub = _player.playingStream.listen((playing) {
        if (mounted) setState(() => _playing = playing);
      });
      if (mounted) setState(() => _playerReady = true);
    } catch (e) {
      if (mounted) setState(() => _playerError = e.toString());
    } finally {
      if (mounted) setState(() => _playerLoading = false);
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatCallDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(call.patientNumber),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Header card ---
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.outcomeColor(call.outcome)
                            .withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: AppTheme.outcomeColor(call.outcome),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            call.patientNumber,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 4),
                          OutcomeBadge(outcome: call.outcome),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _MetaRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: DateFormat('EEEE, MMM d yyyy').format(call.timestamp),
                ),
                _MetaRow(
                  icon: Icons.access_time_rounded,
                  label: 'Time',
                  value: DateFormat('h:mm a').format(call.timestamp),
                ),
                _MetaRow(
                  icon: Icons.timer_rounded,
                  label: 'Duration',
                  value: _formatCallDuration(call.durationSeconds),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --- AI Summary ---
          if (call.summary != null && call.summary!.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.auto_awesome_rounded,
              title: 'AI Summary',
            ),
            _SectionCard(
              child: Text(
                call.summary!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // --- Recording Player ---
          if (call.recordingUrl != null) ...[
            _SectionHeader(
              icon: Icons.mic_rounded,
              title: 'Recording',
            ),
            _SectionCard(child: _buildPlayer()),
            const SizedBox(height: 12),
          ],

          // --- Transcript ---
          _SectionHeader(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Transcript',
            trailing: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16,
                  color: AppTheme.textMuted),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: call.transcript));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transcript copied'),
                    duration: Duration(seconds: 2),
                    backgroundColor: AppTheme.surfaceElevated,
                  ),
                );
              },
            ),
          ),
          _SectionCard(
            child: call.transcript.isEmpty
                ? const Text(
                    'No transcript available.',
                    style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        fontFamily: 'Inter'),
                  )
                : _TranscriptView(transcript: call.transcript),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    if (_playerLoading) {
      return const SizedBox(
        height: 56,
        child: Center(
            child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.primary))),
      );
    }
    if (_playerError != null) {
      return const Text('Could not load recording.',
          style: TextStyle(
              color: AppTheme.textMuted, fontSize: 12, fontFamily: 'Inter'));
    }
    if (!_playerReady) {
      return const SizedBox.shrink();
    }

    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Column(
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () =>
                  _playing ? _player.pause() : _player.play(),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: AppTheme.border,
                      thumbColor: AppTheme.primary,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: (v) {
                        final ms = (v * _duration.inMilliseconds).round();
                        _player.seek(Duration(milliseconds: ms));
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_position),
                          style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 10,
                              fontFamily: 'Inter')),
                      Text(_formatDuration(_duration),
                          style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 10,
                              fontFamily: 'Inter')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Renders transcript lines, bolding speaker prefixes like "AI:" / "Patient:"
class _TranscriptView extends StatelessWidget {
  final String transcript;
  const _TranscriptView({required this.transcript});

  @override
  Widget build(BuildContext context) {
    final lines = transcript.split('\n').where((l) => l.trim().isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final colonIdx = line.indexOf(':');
        if (colonIdx > 0 && colonIdx < 20) {
          final speaker = line.substring(0, colonIdx + 1);
          final rest = line.substring(colonIdx + 1);
          final isAi = speaker.toLowerCase().contains('ai') ||
              speaker.toLowerCase().contains('ava');
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$speaker ',
                    style: TextStyle(
                      color: isAi ? AppTheme.primary : AppTheme.completed,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  TextSpan(
                    text: rest.trim(),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontFamily: 'Inter',
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontFamily: 'Inter',
              height: 1.5,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontFamily: 'Inter',
            ),
          ),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
