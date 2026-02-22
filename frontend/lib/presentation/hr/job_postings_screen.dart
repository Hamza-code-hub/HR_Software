import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../data/recruitment_repository.dart';
import '../../data/models/recruitment.dart';
import 'package:intl/intl.dart';

class JobPostingsScreen extends ConsumerStatefulWidget {
  const JobPostingsScreen({super.key});

  @override
  ConsumerState<JobPostingsScreen> createState() => _JobPostingsScreenState();
}

class _JobPostingsScreenState extends ConsumerState<JobPostingsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final postingsAsync = ref.watch(jobPostingsProvider);
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
            _buildStatSummary(postingsAsync.valueOrNull ?? []),
            const SizedBox(height: 24),
            _buildControls(context),
            const SizedBox(height: 16),
            Expanded(
              child: postingsAsync.when(
                data: (postings) {
                  final filtered = postings.where((p) => 
                    p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    p.department.toLowerCase().contains(_searchQuery.toLowerCase())
                  ).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _JobPostingCard(posting: filtered[index]),
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
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Posting'),
        backgroundColor: const Color(0xFF0EA5E9),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Job Postings',
          style: TextStyle(
            color: context.appColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage your company recruitment pipeline and open positions.',
          style: TextStyle(color: context.appColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStatSummary(List<JobPosting> postings) {
    final openCount = postings.where((p) => p.status == 'open').length;
    final closedCount = postings.where((p) => p.status == 'closed').length;
    final draftCount = postings.where((p) => p.status == 'draft').length;

    return Row(
      children: [
        _StatChip(label: 'Total', count: postings.length, color: const Color(0xFF6366F1)),
        const SizedBox(width: 12),
        _StatChip(label: 'Open', count: openCount, color: const Color(0xFF10B981)),
        const SizedBox(width: 12),
        _StatChip(label: 'Closed', count: closedCount, color: const Color(0xFFEF4444)),
        const SizedBox(width: 12),
        _StatChip(label: 'Draft', count: draftCount, color: const Color(0xFFF59E0B)),
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
                      hintText: 'Search by title or department...',
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
          Icon(Icons.work_off_rounded, size: 64, color: context.appColors.textTertiary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No job postings found',
            style: TextStyle(color: context.appColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final deptController = TextEditingController();
    final typeController = TextEditingController(text: 'Full-time');
    final locController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Job Posting'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Job Title')),
              TextField(controller: deptController, decoration: const InputDecoration(labelText: 'Department')),
              TextField(controller: locController, decoration: const InputDecoration(labelText: 'Location')),
              DropdownButtonFormField<String>(
                value: 'Full-time',
                items: ['Full-time', 'Part-time', 'Contract'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => typeController.text = val!,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(recruitmentRepositoryProvider).createJobPosting({
                'title': titleController.text,
                'department': deptController.text,
                'location': locController.text,
                'employment_type': typeController.text,
                'description': 'New opening for ${titleController.text}',
                'requirements': 'Bachelor degree or equivalent',
                'status': 'open',
              });
              ref.invalidate(jobPostingsProvider);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Create'),
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

class _JobPostingCard extends StatelessWidget {
  const _JobPostingCard({required this.posting});
  final JobPosting posting;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusColor = posting.status == 'open' ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.work_outline_rounded, color: Color(0xFF0EA5E9), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      posting.title,
                      style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    _badge(posting.status.toUpperCase(), statusColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${posting.department} • ${posting.location} • ${posting.employmentType}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('MMM dd, yyyy').format(posting.createdAt),
                style: TextStyle(color: colors.textTertiary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _actionIcon(Icons.edit_note_rounded, Colors.blue),
                  const SizedBox(width: 8),
                  _actionIcon(Icons.delete_outline_rounded, Colors.red),
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

  Widget _actionIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
