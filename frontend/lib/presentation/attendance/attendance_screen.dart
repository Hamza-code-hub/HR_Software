import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../data/attendance_repository.dart';
import '../../data/employees_repository.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});
  @override
  ConsumerState<AttendanceScreen> createState() => _State();
}

class _State extends ConsumerState<AttendanceScreen> {
  int _month = DateTime.now().month;
  int _year  = DateTime.now().year;
  bool    _loading  = false;
  String? _error;
  List<AttendanceRecord> _records   = [];
  List<Employee>         _employees = [];

  @override
  void initState() {
    super.initState();
    _load();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      _employees = await ref.read(employeesRepositoryProvider).list();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _records = await ref.read(attendanceRepositoryProvider).list(_month, _year);
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _empName(String id) =>
      _employees.where((e) => e.id == id).map((e) => e.name).firstOrNull ?? id;

  @override
  Widget build(BuildContext context) {
    // Summary stats
    final present = _records.where((r) => r.checkIn != null).length;
    final absent  = _employees.length - present;
    final onLeave = _records.where((r) => r.status == 'leave').length;

    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            children: [
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Attendance', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  SizedBox(height: 2),
                  Text('Track daily check-in and check-out', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ]),
              ),
              // Month / Year picker
              _MonthPicker(
                month: _month, year: _year,
                onChanged: (m, y) => setState(() { _month = m; _year = y; _load(); }),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _load,
              ),
            ],
          ),
        ),

        // ── Stats ────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Row(
            children: [
              _StatCard(label: 'Present',   value: present.toString(), color: const Color(0xFF10B981), icon: Icons.check_circle_rounded),
              const SizedBox(width: 12),
              _StatCard(label: 'Absent',    value: absent < 0 ? '0' : absent.toString(), color: const Color(0xFFEF4444), icon: Icons.cancel_rounded),
              const SizedBox(width: 12),
              _StatCard(label: 'On Leave',  value: onLeave.toString(), color: const Color(0xFFF59E0B), icon: Icons.event_busy_rounded),
              const SizedBox(width: 12),
              _StatCard(label: 'Total Records', value: _records.length.toString(), color: const Color(0xFF3B82F6), icon: Icons.people_rounded),
            ],
          ),
        ),

        // ── Table ─────────────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                      const SizedBox(height: 12),
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ]))
                  : _records.isEmpty
                      ? const Center(child: Text('No attendance records for this period.', style: TextStyle(color: Color(0xFF64748B))))
                      : Column(
                          children: [
                            // Table header
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(flex: 3, child: Text('Employee', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 12))),
                                  Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 12))),
                                  Expanded(flex: 2, child: Text('Check In', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 12))),
                                  Expanded(flex: 2, child: Text('Check Out', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 12))),
                                  Expanded(flex: 1, child: Text('Hours', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 12))),
                                  Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 12))),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                itemCount: _records.length,
                                itemBuilder: (_, i) {
                                  final r = _records[i];
                                  final hasCheckIn  = r.checkIn  != null;
                                  final hasCheckOut = r.checkOut != null;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 4)],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 3, child: Row(children: [
                                          CircleAvatar(radius: 14, backgroundColor: const Color(0xFF3B82F6).withAlpha(25),
                                            child: Text(_empName(r.employeeId).isNotEmpty ? _empName(r.employeeId)[0].toUpperCase() : '?',
                                              style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 11, fontWeight: FontWeight.bold))),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(_empName(r.employeeId), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis)),
                                        ])),
                                        Expanded(flex: 2, child: Text(r.date, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                                        Expanded(flex: 2, child: Text(hasCheckIn  ? r.checkIn!  : '—', style: TextStyle(color: hasCheckIn  ? const Color(0xFF10B981) : const Color(0xFF94A3B8), fontSize: 12))),
                                        Expanded(flex: 2, child: Text(hasCheckOut ? r.checkOut! : '—', style: TextStyle(color: hasCheckOut ? const Color(0xFFEF4444)  : const Color(0xFF94A3B8), fontSize: 12))),
                                        Expanded(flex: 1, child: Text(r.totalHours != null ? '${r.totalHours!.toStringAsFixed(1)}h' : '—', style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.w500))),
                                        Expanded(flex: 2, child: _StatusBadge(status: r.status ?? (hasCheckIn ? 'present' : 'absent'))),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
        ),
      ],
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({required this.month, required this.year, required this.onChanged});
  final int month, year;
  final void Function(int, int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: month,
              isDense: true,
              items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text(_monthName(m), style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) { if (v != null) onChanged(v, year); },
            ),
          ),
          const SizedBox(width: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: year,
              isDense: true,
              items: [2024, 2025, 2026].map((y) => DropdownMenuItem(value: y, child: Text(y.toString(), style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) { if (v != null) onChanged(month, v); },
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) => ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});
  final String label, value;
  final Color    color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: color.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final colours = {
      'present': const Color(0xFF10B981),
      'absent':  const Color(0xFFEF4444),
      'leave':   const Color(0xFFF59E0B),
      'late':    const Color(0xFFEF4444),
    };
    final color = colours[status] ?? const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
