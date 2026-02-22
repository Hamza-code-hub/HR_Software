import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/app_theme.dart';

final _departmentsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final list = await ref.watch(apiClientProvider).get('/api/departments') as List;
  return list.cast<Map<String, dynamic>>();
});

class DepartmentManagementScreen extends ConsumerStatefulWidget {
  const DepartmentManagementScreen({super.key});
  @override
  ConsumerState<DepartmentManagementScreen> createState() => _State();
}

class _State extends ConsumerState<DepartmentManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final deptsAsync = ref.watch(_departmentsProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Row(
            children: [
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Departments', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  SizedBox(height: 4),
                  Text('Manage your organization\'s structure', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ]),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_business_rounded, size: 16),
                label: const Text('New Department'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showAddDialog(),
              ),
            ],
          ),
        ),
        Expanded(
          child: deptsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:   (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text(e is AppException ? e.message : e.toString()),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => ref.refresh(_departmentsProvider), child: const Text('Retry')),
            ])),
            data: (depts) {
              if (depts.isEmpty) {
                return const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.business_outlined, size: 64, color: Color(0xFFCBD5E1)),
                    SizedBox(height: 16),
                    Text('No departments yet. Create one!', style: TextStyle(color: Color(0xFF64748B))),
                  ]),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: depts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final d = depts[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withAlpha(25), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.business_rounded, color: Color(0xFF8B5CF6)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(d['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B), fontSize: 15)),
                            if (d['employee_count'] != null)
                              Text('${d['employee_count']} employees', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          ]),
                        ),
                        IconButton(icon: const Icon(Icons.edit_rounded, color: Color(0xFF64748B)), onPressed: () => _showEditDialog(d)),
                        IconButton(icon: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444)), onPressed: () => _delete(d['id'] as String)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Department', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white),
            onPressed: () async { Navigator.pop(context); await _create(ctrl.text.trim()); },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> dept) {
    final ctrl = TextEditingController(text: dept['name'] as String?);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Department', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white),
            onPressed: () async { Navigator.pop(context); await _update(dept['id'] as String, ctrl.text.trim()); },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _create(String name) async {
    if (name.isEmpty) return;
    try {
      await ref.read(apiClientProvider).post('/api/departments', body: {'name': name});
      ref.invalidate(_departmentsProvider);
    } on AppException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _update(String id, String name) async {
    if (name.isEmpty) return;
    try {
      await ref.read(apiClientProvider).put('/api/departments/$id', body: {'name': name});
      ref.invalidate(_departmentsProvider);
    } on AppException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Department'),
        content: const Text('Are you sure? Active employees will be unassigned.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(apiClientProvider).delete('/api/departments/$id');
      ref.invalidate(_departmentsProvider);
    } on AppException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
  );
}
