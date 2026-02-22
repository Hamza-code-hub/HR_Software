import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../data/onboarding_repository.dart';
import '../../data/models/onboarding.dart';
import 'package:intl/intl.dart';

class EmployeeContractsScreen extends ConsumerStatefulWidget {
  const EmployeeContractsScreen({super.key});

  @override
  ConsumerState<EmployeeContractsScreen> createState() => _EmployeeContractsScreenState();
}

class _EmployeeContractsScreenState extends ConsumerState<EmployeeContractsScreen> {
  @override
  Widget build(BuildContext context) {
    final contractsAsync = ref.watch(employeeContractsProvider);
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
            Expanded(
              child: contractsAsync.when(
                data: (list) {
                  if (list.isEmpty) return _buildEmptyState();
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _ContractCard(contract: list[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {}, // TODO: Create Contract dialog
        icon: const Icon(Icons.history_edu_rounded),
        label: const Text('New Contract'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Employee Contracts',
          style: context.appColors.textPrimary == Colors.white 
            ? const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
            : TextStyle(color: context.appColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Track employment terms, renewals, and legal agreements across the workforce.',
          style: TextStyle(color: context.appColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_ind_rounded, size: 64, color: context.appColors.textTertiary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No employment contracts recorded.'),
        ],
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({required this.contract});
  final EmployeeContract contract;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusColor = contract.status == 'active' ? const Color(0xFF10B981) : const Color(0xFFEF4444);

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
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified_user_rounded, color: Color(0xFF8B5CF6), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contract.employeeName ?? 'Employee',
                  style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${contract.contractType.toUpperCase()} • Since ${DateFormat('MMM yyyy').format(contract.startDate)}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
                if (contract.endDate != null)
                  Text(
                    'Expires: ${DateFormat('MMM dd, yyyy').format(contract.endDate!)}',
                    style: TextStyle(color: const Color(0xFFEF4444).withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _badge(contract.status.toUpperCase(), statusColor),
              const SizedBox(height: 8),
              Row(
                children: [
                  _actionIcon(Icons.file_download_rounded, Colors.blue),
                  const SizedBox(width: 8),
                  _actionIcon(Icons.refresh_rounded, Colors.orange),
                ],
              ),
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

  Widget _actionIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 16),
    );
  }
}
