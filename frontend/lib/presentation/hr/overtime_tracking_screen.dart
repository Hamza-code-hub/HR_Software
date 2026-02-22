import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../data/operations_repository.dart';
import '../../data/models/operations.dart';
import '../../core/app_theme.dart';

class OvertimeTrackingScreen extends ConsumerStatefulWidget {
  const OvertimeTrackingScreen({super.key});

  @override
  ConsumerState<OvertimeTrackingScreen> createState() => _OvertimeTrackingScreenState();
}

class _OvertimeTrackingScreenState extends ConsumerState<OvertimeTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    final overtimeAsync = ref.watch(overtimeRequestsProvider);
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surfaceBg,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overtime Tracking', style: TextStyle(color: colors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Monitor and approve extra working hours for payroll processing.', style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 24),
            Expanded(
              child: overtimeAsync.when(
                data: (requests) {
                  if (requests.isEmpty) return _buildEmptyState();
                  return ListView.separated(
                    itemCount: requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _OvertimeRow(request: requests[index]),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 64, color: context.appColors.textTertiary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No overtime requests found.'),
        ],
      ),
    );
  }
}

class _OvertimeRow extends StatelessWidget {
  const _OvertimeRow({required this.request});
  final OvertimeRequest request;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusColor = switch (request.status.toLowerCase()) {
      'approved' => const Color(0xFF10B981),
      'rejected' => const Color(0xFFEF4444),
      _          => const Color(0xFFF59E0B),
    };

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
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.more_time_rounded, color: statusColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.employeeName ?? 'Employee', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
                Text('${request.hoursRequested} hours • ${request.date.toString().substring(0, 10)}', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _badge(request.status.toUpperCase(), statusColor),
              if (request.status == 'pending')
                TextButton(onPressed: () {}, child: const Text('Take Action', style: TextStyle(fontSize: 12))),
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
