import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../../data/employees_repository.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  late final PlutoGridStateManager _stateManager;
  bool _loading = true;
  String? _error;
  List<Employee> _list = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(employeesRepositoryProvider);
      final list = await repo.list();
      setState(() {
        _list = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<PlutoColumn> _columns() {
    return [
      PlutoColumn(title: 'Name', field: 'name', type: PlutoColumnType.text(), width: 150),
      PlutoColumn(title: 'Code', field: 'employee_code', type: PlutoColumnType.text(), width: 100),
      PlutoColumn(title: 'Email', field: 'email', type: PlutoColumnType.text(), width: 180),
      PlutoColumn(title: 'Designation', field: 'designation', type: PlutoColumnType.text(), width: 120),
      PlutoColumn(title: 'Status', field: 'status', type: PlutoColumnType.text(), width: 80),
      PlutoColumn(title: 'Basic Salary', field: 'basic_salary', type: PlutoColumnType.number(), width: 100),
    ];
  }

  List<PlutoRow> _rows() {
    return _list.map((e) {
      return PlutoRow(
        cells: {
          'name': PlutoCell(value: e.name),
          'employee_code': PlutoCell(value: e.employeeCode),
          'email': PlutoCell(value: e.email),
          'designation': PlutoCell(value: e.designation),
          'status': PlutoCell(value: e.status),
          'basic_salary': PlutoCell(value: e.basicSalary),
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Employees'), leading: BackButton(onPressed: () => context.pop())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Employees'), leading: BackButton(onPressed: () => context.pop())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddDialog(context)),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: PlutoGrid(
        columns: _columns(),
        rows: _rows(),
        onLoaded: (event) {
          _stateManager = event.stateManager;
        },
        configuration: const PlutoGridConfiguration(),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final emailController = TextEditingController();
    final designationController = TextEditingController();
    final salaryController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add employee'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Employee code', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: designationController,
                  decoration: const InputDecoration(labelText: 'Designation', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: salaryController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Basic salary', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    final salaryStr = salaryController.text.trim();
    final basicSalary = salaryStr.isEmpty ? null : double.tryParse(salaryStr);

    try {
      final repo = ref.read(employeesRepositoryProvider);
      await repo.create(Employee(
        id: '',
        tenantId: '',
        name: name,
        employeeCode: codeController.text.trim().isEmpty ? null : codeController.text.trim(),
        email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
        designation: designationController.text.trim().isEmpty ? null : designationController.text.trim(),
        status: 'active',
        basicSalary: basicSalary,
        createdAt: '',
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee added')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }
}
