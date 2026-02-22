import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/app_theme.dart';

class DepartmentAttendanceScreen extends ConsumerStatefulWidget {
  const DepartmentAttendanceScreen({super.key});

  @override
  ConsumerState<DepartmentAttendanceScreen> createState() => _DepartmentAttendanceScreenState();
}

class _DepartmentAttendanceScreenState extends ConsumerState<DepartmentAttendanceScreen> {
  bool _loading = true;
  List<dynamic> _deptData = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(apiClientProvider).get('/api/analytics/hr/leave-balance');
      _deptData = res['data'];
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
            Text('Department Attendance', style: TextStyle(color: colors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Monitor leave utilization and presence trends across departments.', style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 24),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _deptData.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          itemCount: _deptData.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) => _DeptAttendanceCard(data: _deptData[index]),
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
          Icon(Icons.corporate_fare_rounded, size: 64, color: context.appColors.textTertiary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No departmental data available.'),
        ],
      ),
    );
  }
}

class _DeptAttendanceCard extends StatelessWidget {
  const _DeptAttendanceCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final annualTaken = data['annual_taken'] as int;
    final annualLeft = data['annual_left'] as int;
    final total = annualTaken + annualLeft;
    final progress = total > 0 ? annualTaken / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['department'] ?? 'Department', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(Icons.more_horiz, color: colors.textTertiary),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _miniStat('Annual Leave', annualTaken, 'taken')),
              Expanded(child: _miniStat('Sick Leave', data['sick_taken'] as int, 'taken')),
              Expanded(child: _miniStat('Casual Leave', data['casual_taken'] as int, 'taken')),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(progress > 0.8 ? Colors.orange : const Color(0xFF0EA5E9)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(1)}% leave utilization for the current period',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int value, String suffix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
