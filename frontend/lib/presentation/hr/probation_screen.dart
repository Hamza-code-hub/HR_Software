import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../data/employee_central_repository.dart';
import '../../data/models/employee_central.dart';
import 'package:intl/intl.dart';

class ProbationScreen extends ConsumerStatefulWidget {
  const ProbationScreen({super.key});

  @override
  ConsumerState<ProbationScreen> createState() => _ProbationScreenState();
}

class _ProbationScreenState extends ConsumerState<ProbationScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final probationAsync = ref.watch(probationRecordsProvider);
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
            _buildStatSummary(probationAsync.valueOrNull ?? []),
            const SizedBox(height: 24),
            _buildControls(context),
            const SizedBox(height: 16),
            Expanded(
              child: probationAsync.when(
                data: (records) {
                  final filtered = records.where((r) => 
                    (r.employeeName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
                  ).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _ProbationCard(record: filtered[index]),
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
          'Probation Tracking',
          style: TextStyle(
            color: context.appColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Monitor employee trial periods, performance reviews, and completion status.',
          style: TextStyle(color: context.appColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStatSummary(List<ProbationRecord> records) {
    final activeCount = records.where((r) => r.status == 'active').length;
    final soonCount = records.where((r) => r.status == 'active' && 
      r.endDate.difference(DateTime.now()).inDays < 30).length;

    return Row(
      children: [
        _StatChip(label: 'Total on Probation', count: records.length, color: const Color(0xFF6366F1)),
        const SizedBox(width: 12),
        _StatChip(label: 'Active Trials', count: activeCount, color: const Color(0xFF10B981)),
        const SizedBox(width: 12),
        _StatChip(label: 'Ending Soon', count: soonCount, color: const Color(0xFFEF4444)),
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
                      hintText: 'Search by employee name...',
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
        _buildFilterBtn(context, Icons.filter_list_rounded, 'Filter'),
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
          Icon(Icons.timer_outlined, size: 64, color: context.appColors.textTertiary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No probation records found',
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

class _ProbationCard extends StatelessWidget {
  const _ProbationCard({required this.record});
  final ProbationRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusColor = _getStatusColor(record.status);
    final progress = _calculateProgress();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _ProgressCircle(progress: progress, color: statusColor),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      record.employeeName ?? 'Employee',
                      style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    _badge(record.status.toUpperCase(), statusColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Started: ${DateFormat('MMM dd, yyyy').format(record.startDate)} • Ends: ${DateFormat('MMM dd, yyyy').format(record.endDate)}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
                if (record.reviewDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.rate_review_rounded, size: 14, color: colors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        'Next Review: ${DateFormat('MMM dd, yyyy').format(record.reviewDate!)}',
                        style: TextStyle(color: colors.textTertiary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              _actionBtn(Icons.assignment_turned_in_rounded, Colors.green, 'Confirm'),
              const SizedBox(height: 8),
              _actionBtn(Icons.more_time_rounded, Colors.orange, 'Extend'),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateProgress() {
    final now = DateTime.now();
    if (now.isAfter(record.endDate)) return 1.0;
    if (now.isBefore(record.startDate)) return 0.0;
    final total = record.endDate.difference(record.startDate).inDays;
    final elapsed = now.difference(record.startDate).inDays;
    return elapsed / total;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return const Color(0xFF10B981);
      case 'extended': return const Color(0xFFF59E0B);
      case 'completed': return const Color(0xFF8B5CF6);
      case 'terminated': return const Color(0xFFEF4444);
      default: return const Color(0xFF64748B);
    }
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

  Widget _actionBtn(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ProgressCircle extends StatelessWidget {
  const _ProgressCircle({required this.progress, required this.color});
  final double progress;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 48, height: 48,
          child: CircularProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeWidth: 4,
          ),
        ),
        Text(
          '${(progress * 100).toInt()}%',
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
