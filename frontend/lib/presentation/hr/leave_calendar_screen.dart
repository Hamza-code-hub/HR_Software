import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/app_theme.dart';

class LeaveCalendarScreen extends ConsumerStatefulWidget {
  const LeaveCalendarScreen({super.key});

  @override
  ConsumerState<LeaveCalendarScreen> createState() => _LeaveCalendarScreenState();
}

class _LeaveCalendarScreenState extends ConsumerState<LeaveCalendarScreen> {
  bool _loading = true;
  List<dynamic> _leaves = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(apiClientProvider).get('/api/leave-requests');
      // Only show approved leaves in calendar
      _leaves = (res as List).where((e) => e['status'] == 'approved').toList();
    } catch (e) {
      // Error
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
            Text('Leave Calendar', style: TextStyle(color: colors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('A unified view of employee availability and scheduled leaves.', style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 24),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _leaves.isEmpty
                      ? _buildEmptyState()
                      : _buildCalendarList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarList() {
    final colors = context.appColors;
    return ListView.separated(
      itemCount: _leaves.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final leaf = _leaves[index];
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
                height: 50,
                decoration: BoxDecoration(color: const Color(0xFF0EA5E9).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text(
                    leaf['employee_name']?[0] ?? 'E',
                    style: const TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(leaf['employee_name'] ?? 'Employee', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
                    Text('${leaf['leave_type_name']} policy', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(leaf['start_date'], style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('to ${leaf['end_date']}', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_month_rounded, size: 64, color: context.appColors.textTertiary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No approved leaves for the current period.'),
        ],
      ),
    );
  }
}
