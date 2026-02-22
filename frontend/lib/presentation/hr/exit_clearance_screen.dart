import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../data/hr_ops_repository.dart';
import '../../data/models/hr_ops.dart';

class ExitClearanceScreen extends ConsumerStatefulWidget {
  const ExitClearanceScreen({super.key, required this.resignationId});
  final String resignationId;

  @override
  ConsumerState<ExitClearanceScreen> createState() => _ExitClearanceScreenState();
}

class _ExitClearanceScreenState extends ConsumerState<ExitClearanceScreen> {
  late Future<List<ExitClearanceItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _itemsFuture = ref.read(hrOpsRepositoryProvider).getClearanceItems(widget.resignationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surfaceBg,
      appBar: AppBar(
        title: const Text('Exit Clearance Checklist'),
        backgroundColor: colors.cardBg,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: FutureBuilder<List<ExitClearanceItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return _buildEmptyState();
          }

          // Group by department
          final grouped = <String, List<ExitClearanceItem>>{};
          for (var item in items) {
            grouped.putIfAbsent(item.department, () => []).add(item);
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: grouped.entries.map((e) => _buildDeptSection(e.key, e.value)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildDeptSection(String dept, List<ExitClearanceItem> items) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            dept.toUpperCase(),
            style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
        ),
        ...items.map((item) => _buildItemCard(item)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildItemCard(ExitClearanceItem item) {
    final colors = context.appColors;
    final isCleared = item.status == 'cleared';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCleared ? const Color(0xFF10B981).withValues(alpha: 0.3) : colors.border),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isCleared,
            activeColor: const Color(0xFF10B981),
            onChanged: (val) => _updateStatus(item, val == true ? 'cleared' : 'pending'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    decoration: isCleared ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (item.notes != null && item.notes!.isNotEmpty)
                  Text(item.notes!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (!isCleared)
            IconButton(
              icon: Icon(Icons.edit_note_rounded, color: colors.textTertiary, size: 20),
              onPressed: () => _showNotesDialog(item),
            ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(ExitClearanceItem item, String status) async {
    try {
      await ref.read(hrOpsRepositoryProvider).updateClearanceItem(item.id, status, item.notes ?? '');
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showNotesDialog(ExitClearanceItem item) {
    final controller = TextEditingController(text: item.notes);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Notes: ${item.itemName}'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Add remarks...'), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(hrOpsRepositoryProvider).updateClearanceItem(item.id, item.status, controller.text);
              if (mounted) Navigator.pop(ctx);
              _refresh();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist_rounded, size: 64, color: context.appColors.textTertiary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No clearance items found for this resignation.'),
        ],
      ),
    );
  }
}
