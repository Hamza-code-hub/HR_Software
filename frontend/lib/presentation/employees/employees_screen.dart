import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../data/employees_repository.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});
  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  List<Employee> _all = [];
  List<Employee> _filtered = [];
  bool  _loading = true;
  String? _error;
  String  _search  = '';
  String  _filter  = 'all'; // all / active / inactive

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ref.read(employeesRepositoryProvider).list();
      _all = list;
      _applyFilter();
      setState(() => _loading = false);
    } on AppException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _applyFilter() {
    var result = _all;
    if (_filter != 'all') result = result.where((e) => e.status == _filter).toList();
    if (_search.isNotEmpty) {
      result = result.where((e) =>
        e.name.toLowerCase().contains(_search.toLowerCase()) ||
        (e.email ?? '').toLowerCase().contains(_search.toLowerCase()) ||
        (e.designation ?? '').toLowerCase().contains(_search.toLowerCase())
      ).toList();
    }
    _filtered = result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ───────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            children: [
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Employees', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  SizedBox(height: 2),
                  Text('Manage all employee profiles', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ]),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('Add Employee'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showAddDialog(),
              ),
            ],
          ),
        ),

        // ── Search & filter bar ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, email or designation...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (v) => setState(() { _search = v; _applyFilter(); }),
                ),
              ),
              const SizedBox(width: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all',      label: Text('All')),
                  ButtonSegment(value: 'active',   label: Text('Active')),
                  ButtonSegment(value: 'inactive', label: Text('Inactive')),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => setState(() { _filter = s.first; _applyFilter(); }),
              ),
            ],
          ),
        ),

        // ── Stats row ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Row(
            children: [
              _StatBadge(label: 'Total', value: _all.length.toString(), color: const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              _StatBadge(label: 'Active', value: _all.where((e) => e.status == 'active').length.toString(), color: const Color(0xFF10B981)),
              const SizedBox(width: 8),
              _StatBadge(label: 'Inactive', value: _all.where((e) => e.status == 'inactive').length.toString(), color: const Color(0xFF64748B)),
            ],
          ),
        ),

        // ── List ──────────────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ]))
                  : _filtered.isEmpty
                      ? const Center(child: Text('No employees found.', style: TextStyle(color: Color(0xFF64748B))))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _EmployeeCard(
                            employee: _filtered[i],
                            onEdit: () => _showEditDialog(_filtered[i]),
                            onDelete: () => _delete(_filtered[i].id),
                          ),
                        ),
        ),
      ],
    );
  }

  void _showAddDialog() {
    final nameCtrl  = TextEditingController();
    final emailCtrl = TextEditingController();
    final codeCtrl  = TextEditingController();
    final desigCtrl = TextEditingController();
    final salCtrl   = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Employee', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _field(nameCtrl,  'Full Name *'),
            const SizedBox(height: 10),
            _field(emailCtrl, 'Email', keyboard: TextInputType.emailAddress),
            const SizedBox(height: 10),
            _field(codeCtrl,  'Employee Code'),
            const SizedBox(height: 10),
            _field(desigCtrl, 'Designation'),
            const SizedBox(height: 10),
            _field(salCtrl,   'Basic Salary', keyboard: TextInputType.number),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref.read(employeesRepositoryProvider).create(Employee(
                  id: '', tenantId: '', name: nameCtrl.text.trim(),
                  email:        emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                  employeeCode: codeCtrl.text.trim().isEmpty  ? null : codeCtrl.text.trim(),
                  designation:  desigCtrl.text.trim().isEmpty ? null : desigCtrl.text.trim(),
                  basicSalary:  double.tryParse(salCtrl.text),
                  status: 'active', createdAt: '',
                ));
                _load();
              } on AppException catch (e) {
                if (mounted) _snack(e.message);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Employee emp) {
    final nameCtrl  = TextEditingController(text: emp.name);
    final emailCtrl = TextEditingController(text: emp.email ?? '');
    final desigCtrl = TextEditingController(text: emp.designation ?? '');
    final salCtrl   = TextEditingController(text: emp.basicSalary?.toStringAsFixed(0) ?? '');
    String status   = emp.status;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit Employee', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(nameCtrl,  'Full Name *'),
              const SizedBox(height: 10),
              _field(emailCtrl, 'Email'),
              const SizedBox(height: 10),
              _field(desigCtrl, 'Designation'),
              const SizedBox(height: 10),
              _field(salCtrl,   'Basic Salary', keyboard: TextInputType.number),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: ['active', 'inactive'].map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                onChanged: (v) => setState(() => status = v ?? status),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(employeesRepositoryProvider).update(emp.id, Employee(
                    id: emp.id, tenantId: emp.tenantId, name: nameCtrl.text.trim(),
                    email:       emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    designation: desigCtrl.text.trim().isEmpty ? null : desigCtrl.text.trim(),
                    basicSalary: double.tryParse(salCtrl.text),
                    status: status, createdAt: emp.createdAt,
                  ));
                  _load();
                } on AppException catch (e) {
                  if (mounted) _snack(e.message);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Employee'),
        content: const Text('Are you sure you want to delete this employee? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(employeesRepositoryProvider).delete(id);
      _load();
    } on AppException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Widget _field(TextEditingController c, String label, {TextInputType? keyboard}) =>
      TextField(controller: c, keyboardType: keyboard, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()));

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
  );
}

// ── Employee card ─────────────────────────────────────────────────────────────

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.employee, required this.onEdit, required this.onDelete});
  final Employee     employee;
  final VoidCallback onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = employee.status == 'active';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF10B981).withAlpha(25),
            radius: 22,
            child: Text(
              employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(employee.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF10B981).withAlpha(25) : const Color(0xFF64748B).withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(employee.status.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF10B981) : const Color(0xFF64748B))),
                ),
              ]),
              const SizedBox(height: 2),
              Text(
                [if (employee.designation != null) employee.designation!, if (employee.email != null) employee.email!].join('  •  '),
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              if (employee.basicSalary != null)
                Text('PKR ${employee.basicSalary!.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
          if (employee.employeeCode != null)
            Text(employee.employeeCode!, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.edit_rounded, color: Color(0xFF64748B), size: 18), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 18), onPressed: onDelete),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.label, required this.value, required this.color});
  final String label, value;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withAlpha(60))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ]),
    );
  }
}
