import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/employees_repository.dart';
import '../../data/payroll_repository.dart';

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  bool _loading = false;
  String? _error;
  List<PayrollRun> _runs = [];
  List<Payslip> _payslips = [];
  String? _selectedRunId;
  List<Employee> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadRuns();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final repo = ref.read(employeesRepositoryProvider);
      _employees = await repo.list();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _loadRuns() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(payrollRepositoryProvider);
      final list = await repo.listRuns();
      setState(() {
        _runs = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _selectRun(String id) async {
    setState(() => _selectedRunId = id);
    try {
      final repo = ref.read(payrollRepositoryProvider);
      final list = await repo.listPayslips(id);
      setState(() => _payslips = list);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _createRun() async {
    final now = DateTime.now();
    final month = now.month;
    final year = now.year;
    try {
      final repo = ref.read(payrollRepositoryProvider);
      await repo.createRun(month, year);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payroll run created')));
        _loadRuns();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _lockRun(String id) async {
    try {
      final repo = ref.read(payrollRepositoryProvider);
      await repo.lockRun(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payroll locked')));
        _loadRuns();
        if (_selectedRunId == id) _selectedRunId = null;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _downloadPdf(String payslipId) async {
    try {
      final repo = ref.read(payrollRepositoryProvider);
      final bytes = await repo.getPayslipPdf(payslipId);
      // In a real app, use file_picker or save to downloads. For web show a snackbar.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF ready (${bytes.length} bytes). Use browser download for web.')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  String _employeeName(String id) {
    return _employees.where((e) => e.id == id).map((e) => e.name).firstOrNull ?? id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('New run'),
            onPressed: _loading ? null : _createRun,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _loadRuns, child: const Text('Retry')),
                    ],
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _runs.length,
                        itemBuilder: (_, i) {
                          final run = _runs[i];
                          final selected = run.id == _selectedRunId;
                          return Card(
                            color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
                            child: ListTile(
                              title: Text('${run.month}/${run.year}'),
                              subtitle: Text(run.status),
                              selected: selected,
                              onTap: () => _selectRun(run.id),
                              trailing: run.status == 'draft'
                                  ? IconButton(
                                      icon: const Icon(Icons.lock),
                                      onPressed: () => _lockRun(run.id),
                                      tooltip: 'Lock',
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _selectedRunId == null
                          ? const Center(child: Text('Select a payroll run'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _payslips.length,
                              itemBuilder: (_, i) {
                                final p = _payslips[i];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(_employeeName(p.employeeId)),
                                    subtitle: Text(
                                        'Basic: ${p.basicSalary.toStringAsFixed(0)}  Gross: ${p.grossSalary.toStringAsFixed(0)}  Tax: ${p.tax.toStringAsFixed(0)}  Net: ${p.netSalary.toStringAsFixed(0)}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.picture_as_pdf),
                                      onPressed: () => _downloadPdf(p.id),
                                      tooltip: 'Download PDF',
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
