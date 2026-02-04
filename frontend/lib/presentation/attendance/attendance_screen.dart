import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/attendance_repository.dart';
import '../../data/employees_repository.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  bool _loading = false;
  String? _error;
  List<AttendanceRecord> _records = [];
  List<Employee> _employees = [];

  @override
  void initState() {
    super.initState();
    _load();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final repo = ref.read(employeesRepositoryProvider);
      _employees = await repo.list();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(attendanceRepositoryProvider);
      final list = await repo.list(_month, _year);
      setState(() {
        _records = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _employeeName(String id) {
    return _employees.where((e) => e.id == id).map((e) => e.name).firstOrNull ?? id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                DropdownButton<int>(
                  value: _month,
                  items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text('$m'))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _month = v);
                      _load();
                    }
                  },
                ),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _year,
                  items: [2024, 2025, 2026].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _year = v);
                      _load();
                    }
                  },
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
              ],
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _records.length,
                itemBuilder: (_, i) {
                  final r = _records[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(_employeeName(r.employeeId)),
                      subtitle: Text('${r.date}  In: ${r.checkIn ?? "-"}  Out: ${r.checkOut ?? "-"}  ${r.totalHours?.toStringAsFixed(1) ?? "-"}h'),
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
