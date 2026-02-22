import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/data/hr_ops_repository.dart';
import 'package:frontend/data/models/hr_ops.dart';
import 'package:intl/intl.dart';

class ResignationManagementScreen extends ConsumerStatefulWidget {
  const ResignationManagementScreen({super.key});

  @override
  ConsumerState<ResignationManagementScreen> createState() => _ResignationManagementScreenState();
}

class _ResignationManagementScreenState extends ConsumerState<ResignationManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final resignationsAsync = ref.watch(resignationsProvider);
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Expanded(
            child: resignationsAsync.when(
              data: (list) => _buildContent(context, list),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exit Management',
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track resignations, accept exits, and manage clearance workflows',
            style: context.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Resignation> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.exit_to_app, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'No resignations recorded',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildResignationCard(context, item);
      },
    );
  }

  Widget _buildResignationCard(BuildContext context, Resignation item) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    switch (item.status.toLowerCase()) {
      case 'pending': statusColor = Colors.orange; break;
      case 'accepted': statusColor = Colors.blue; break;
      case 'rejected': statusColor = Colors.red; break;
      case 'completed': statusColor = Colors.green; break;
      default: statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Text(item.employeeName?[0] ?? 'E', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.employeeName ?? 'Unknown Employee',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Resigned: ${DateFormat('MMM dd, yyyy').format(item.resignationDate)}',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildBadge(item.status.toUpperCase(), statusColor),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoCol('Last Working Day', item.lastWorkingDay != null ? DateFormat('MMM dd, yyyy').format(item.lastWorkingDay!) : 'Not set'),
                _buildInfoCol('Clearance', item.exitClearanceStatus.replaceAll('_', ' ').toUpperCase(), 
                  color: item.exitClearanceStatus == 'cleared' ? Colors.green : Colors.orange),
              ],
            ),
            if (item.reason != null && item.reason!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Reason for Exit:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              ),
              const SizedBox(height: 4),
              Text(item.reason!),
            ],
            if (item.status.toLowerCase() == 'pending') ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _updateStatus(item.id, 'rejected'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _updateStatus(item.id, 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept Resignation'),
                  ),
                ],
              ),
            ] else if (item.status.toLowerCase() == 'accepted') ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   OutlinedButton.icon(
                    onPressed: () => context.go('/hr/resignations/${item.id}/interview'),
                    icon: const Icon(Icons.feedback_outlined, size: 18),
                    label: const Text('Exit Interview'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/hr/resignations/${item.id}/clearance'),
                    icon: const Icon(Icons.checklist_rtl_rounded),
                    label: const Text('Manage Clearance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.exitClearanceStatus == 'cleared' ? Colors.green : Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildInfoCol(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Future<void> _updateStatus(String id, String status, {String? clearance}) async {
    try {
      await ref.read(hrOpsRepositoryProvider).updateResignationStatus(id, status, clearanceStatus: clearance);
      ref.invalidate(resignationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
