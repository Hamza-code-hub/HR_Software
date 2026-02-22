import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/app_theme.dart';

class AttendanceReportScreen extends ConsumerStatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  ConsumerState<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends ConsumerState<AttendanceReportScreen> {
  bool _loading = true;
  Map<String, dynamic>? _stats;
  List<dynamic> _heatmap = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final client = ref.read(apiClientProvider);
      final [statsRes, heatmapRes] = await Future.wait([
        client.get('/api/analytics/hr/dashboard-stats'),
        client.get('/api/analytics/hr/attendance-heatmap?days=30'),
      ]);
      _stats = statsRes['data'];
      _heatmap = heatmapRes['data'];
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Attendance Reports', style: TextStyle(color: colors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Visual insights into workforce presence and engagement.', style: TextStyle(color: colors.textSecondary)),
                  const SizedBox(height: 32),
                  
                  _buildSummaryGrid(),
                  const SizedBox(height: 32),
                  
                  _sectionHeader('Presence Heatmap (Last 30 Days)'),
                  const SizedBox(height: 16),
                  _buildHeatmap(),
                  
                  const SizedBox(height: 32),
                  _sectionHeader('Monthly Trends'),
                  const SizedBox(height: 16),
                  _buildTrendCard('Average Daily Attendance', '${_stats?['avg_attendance'] ?? 0}%', Icons.trending_up, Colors.green),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: TextStyle(color: context.appColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildSummaryGrid() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2,
      children: [
        _summaryCard('Present Today', _stats?['present_today']?.toString() ?? '0', Colors.green),
        _summaryCard('On Leave', _stats?['on_leave']?.toString() ?? '0', Colors.orange),
        _summaryCard('Late Today', _stats?['late_today']?.toString() ?? '0', Colors.red),
        _summaryCard('Remote', _stats?['remote_today']?.toString() ?? '0', Colors.blue),
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHeatmap() {
    final colors = context.appColors;
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _heatmap.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = _heatmap[index];
          final percentage = (day['percentage'] as num).toDouble();
          final color = _getHeatColor(percentage);
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 24,
                height: (percentage - 50) * 2, // Simple bar visualization
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 8),
              Text(day['date'].toString().substring(8), style: TextStyle(color: colors.textTertiary, fontSize: 10)),
            ],
          );
        },
      ),
    );
  }

  Color _getHeatColor(double percentage) {
    if (percentage > 95) return const Color(0xFF10B981);
    if (percentage > 90) return const Color(0xFF3B82F6);
    if (percentage > 80) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _buildTrendCard(String label, String value, IconData icon, Color color) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: colors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
