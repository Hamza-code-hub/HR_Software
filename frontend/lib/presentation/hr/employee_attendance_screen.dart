import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../data/employees_repository.dart';

class EmployeeAttendanceScreen extends ConsumerStatefulWidget {
  const EmployeeAttendanceScreen({super.key});

  @override
  ConsumerState<EmployeeAttendanceScreen> createState() => _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState extends ConsumerState<EmployeeAttendanceScreen> {
  final _searchCtrl = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesListProvider);
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surfaceBg,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee Attendance', style: TextStyle(color: colors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Review detailed attendance logs for individual team members.', style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 24),
            
            // Search Bar
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by employee name or code...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: colors.cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Expanded(
              child: employeesAsync.when(
                data: (list) {
                  final filtered = list.where((e) => 
                    e.name.toLowerCase().contains(_searchCtrl.text.toLowerCase()) ||
                    (e.employeeCode?.toLowerCase().contains(_searchCtrl.text.toLowerCase()) ?? false)
                  ).toList();
                  
                  if (filtered.isEmpty) return _buildEmptyState();
                  
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _EmployeeAttendanceRow(employee: filtered[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No employees found matching your search.'));
  }
}

class _EmployeeAttendanceRow extends StatelessWidget {
  const _EmployeeAttendanceRow({required this.employee});
  final Employee employee;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
            child: Text(employee.name[0], style: const TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
                Text(employee.designation ?? 'Employee', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {}, // TODO: Navigate to this employee's detail attendance log
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
              foregroundColor: const Color(0xFF0EA5E9),
              elevation: 0,
            ),
            child: const Text('View Logs'),
          ),
        ],
      ),
    );
  }
}
