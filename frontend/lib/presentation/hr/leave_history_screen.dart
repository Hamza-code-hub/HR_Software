import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../data/auth_repository.dart';

class LeaveHistoryScreen extends ConsumerStatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  ConsumerState<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends ConsumerState<LeaveHistoryScreen> {
  bool _loading = true;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(apiClientProvider).get('/api/leave-requests');
      _requests = res as List;
    } catch (e) {
      // Error handling
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surfaceBg,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Leave History', style: TextStyle(color: colors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Track all leave requests and their current approval status.', style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 24),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _requests.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          itemCount: _requests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => _LeaveRequestCard(data: _requests[index], onRefresh: _load),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: context.appColors.textTertiary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No leave history found.'),
        ],
      ),
    );
  }
}

class _LeaveRequestCard extends ConsumerWidget {
  const _LeaveRequestCard({required this.data, required this.onRefresh});
  final Map<String, dynamic> data;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final status = data['status'] as String? ?? 'pending';
    final role = ref.watch(sessionProvider)?.role ?? 'employee';
    final isManager = role == 'admin' || role == 'hr';

    final statusColor = switch (status.toLowerCase()) {
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
            child: Icon(Icons.calendar_today_rounded, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['employee_name'] ?? 'Employee', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${data['leave_type_name']} • ${data['start_date']} to ${data['end_date']}', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                if (data['reason'] != null)
                  Text('Reason: ${data['reason']}', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _badge(status.toUpperCase(), statusColor),
              if (isManager && status == 'pending') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20),
                      onPressed: () => _handleAction(ref, context, 'approve'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.highlight_off_rounded, color: Color(0xFFEF4444), size: 20),
                      onPressed: () => _handleAction(ref, context, 'reject'),
                    ),
                  ],
                ),
              ],
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

  Future<void> _handleAction(WidgetRef ref, BuildContext context, String action) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.put('/api/leave-requests/${data['id']}/$action', body: {});
      onRefresh();
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
