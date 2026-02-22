import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../data/talent_repository.dart';
import '../../data/models/talent.dart';
import '../../core/app_theme.dart';

class PerformanceAppraisalScreen extends ConsumerStatefulWidget {
  const PerformanceAppraisalScreen({super.key});

  @override
  ConsumerState<PerformanceAppraisalScreen> createState() => _PerformanceAppraisalScreenState();
}

class _PerformanceAppraisalScreenState extends ConsumerState<PerformanceAppraisalScreen> {
  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(performanceReviewsProvider);
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surfaceBg,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance Appraisals', style: TextStyle(color: colors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Manage performance cycles, review submissions, and employee scores.', style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 24),
            Expanded(
              child: reviewsAsync.when(
                data: (reviews) {
                  if (reviews.isEmpty) return _buildEmptyState();
                  return ListView.separated(
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _ReviewRow(review: reviews[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {}, // TODO: New appraisal cycle
        icon: const Icon(Icons.analytics_rounded),
        label: const Text('New Review'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.query_stats_rounded, size: 64, color: context.appColors.textTertiary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No performance reviews found.'),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.review});
  final PerformanceReview review;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final score = review.overallScore;
    final scoreColor = score >= 4.0 ? Colors.green : (score >= 3.0 ? Colors.blue : Colors.orange);

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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: scoreColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(score.toStringAsFixed(1), style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(review.employeeName ?? 'Employee', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Reviewed by: ${review.reviewerName ?? 'Manager'} • ${review.reviewDate.toString().substring(0, 10)}', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _badge(review.status.toUpperCase(), Colors.blue),
              Text('Overall Score', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
