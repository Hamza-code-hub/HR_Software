import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../data/recruitment_repository.dart';
import '../../data/models/recruitment.dart';
import 'package:intl/intl.dart';

class InterviewsScreen extends ConsumerStatefulWidget {
  const InterviewsScreen({super.key});

  @override
  ConsumerState<InterviewsScreen> createState() => _InterviewsScreenState();
}

class _InterviewsScreenState extends ConsumerState<InterviewsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final interviewsAsync = ref.watch(interviewsProvider);
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surfaceBg,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildStatSummary(interviewsAsync.valueOrNull ?? []),
            const SizedBox(height: 24),
            _buildControls(context),
            const SizedBox(height: 16),
            Expanded(
              child: interviewsAsync.when(
                data: (interviews) {
                  final filtered = interviews.where((i) => 
                    (i.candidateName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                    (i.interviewerName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
                  ).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _InterviewCard(interview: filtered[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interviews',
          style: TextStyle(
            color: context.appColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Schedule and collect feedback for candidate interviews.',
          style: TextStyle(color: context.appColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStatSummary(List<Interview> interviews) {
    final scheduledCount = interviews.where((i) => i.status == 'scheduled').length;
    final completedCount = interviews.where((i) => i.status == 'completed').length;

    return Row(
      children: [
        _StatChip(label: 'Total Interviews', count: interviews.length, color: const Color(0xFF6366F1)),
        const SizedBox(width: 12),
        _StatChip(label: 'Upcoming', count: scheduledCount, color: const Color(0xFF10B981)),
        const SizedBox(width: 12),
        _StatChip(label: 'Completed', count: completedCount, color: const Color(0xFF0EA5E9)),
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: colors.textSecondary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by candidate or interviewer...',
                      hintStyle: TextStyle(color: colors.textTertiary, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildFilterBtn(context, Icons.calendar_today_rounded, 'Month'),
      ],
    );
  }

  Widget _buildFilterBtn(BuildContext context, IconData icon, String label) {
    final colors = context.appColors;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.textSecondary, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_rounded, size: 64, color: context.appColors.textTertiary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No interviews scheduled',
            style: TextStyle(color: context.appColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.count, required this.color});
  final String label;
  final int    count;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Text(
            count.toString(),
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _InterviewCard extends StatelessWidget {
  const _InterviewCard({required this.interview});
  final Interview interview;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusColor = interview.status == 'scheduled' ? const Color(0xFF10B981) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('MMM').format(interview.scheduledAt).toUpperCase(),
                  style: const TextStyle(color: Color(0xFF0EA5E9), fontSize: 10, fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('dd').format(interview.scheduledAt),
                  style: const TextStyle(color: Color(0xFF0EA5E9), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      interview.candidateName ?? 'Candidate',
                      style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    _badge(interview.status.toUpperCase(), statusColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Interviewer: ${interview.interviewerName ?? 'TBD'} • ${DateFormat('hh:mm a').format(interview.scheduledAt)}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Location: ${interview.location}',
                  style: TextStyle(color: colors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
          _actionIcon(Icons.rate_review_rounded, Colors.blue, 'Feedback'),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
