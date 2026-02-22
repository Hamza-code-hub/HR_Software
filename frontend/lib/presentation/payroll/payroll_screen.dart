import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../data/payroll_repository.dart';

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});
  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  List<PayrollRun> _runs      = [];
  List<Payslip>    _payslips  = [];
  bool    _loading       = true;
  bool    _loadingSlips  = false;
  String? _error;
  String? _selectedRunId;

  @override
  void initState() {
    super.initState();
    _loadRuns();
  }

  Future<void> _loadRuns() async {
    setState(() { _loading = true; _error = null; });
    try {
      _runs = await ref.read(payrollRepositoryProvider).listRuns();
      setState(() => _loading = false);
    } on AppException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _selectRun(String id) async {
    setState(() { _selectedRunId = id; _loadingSlips = true; });
    try {
      _payslips = await ref.read(payrollRepositoryProvider).listPayslips(id);
      setState(() => _loadingSlips = false);
    } catch (e) {
      setState(() => _loadingSlips = false);
      if (mounted) _snack(e.toString());
    }
  }

  Future<void> _createRun() async {
    final now = DateTime.now();
    try {
      await ref.read(payrollRepositoryProvider).createRun(now.month, now.year);
      if (mounted) _snack('Payroll run created!', success: true);
      _loadRuns();
    } on AppException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _lockRun(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lock Payroll Run'),
        content: const Text('Locking will finalize this run. Payslips cannot be changed afterward.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, true), child: const Text('Lock')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(payrollRepositoryProvider).lockRun(id);
      if (mounted) _snack('Payroll locked!', success: true);
      _loadRuns();
    } on AppException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── LEFT: Payroll Runs ────────────────────────────────────────────────
        Container(
          width: 280,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payroll', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    const Text('Run & manage payroll cycles', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_circle_rounded, size: 16),
                        label: const Text('New Run'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _loading ? null : _createRun,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (_loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                )
              else
                Expanded(
                  child: _runs.isEmpty
                      ? const Center(child: Text('No payroll runs yet.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)))
                      : ListView.builder(
                          itemCount: _runs.length,
                          itemBuilder: (_, i) {
                            final run = _runs[i];
                            final selected = run.id == _selectedRunId;
                            return InkWell(
                              onTap: () => _selectRun(run.id),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFF3B82F6).withAlpha(15) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: selected ? Border.all(color: const Color(0xFF3B82F6).withAlpha(60)) : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: (run.isLocked ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withAlpha(25),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        run.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                                        color: run.isLocked ? const Color(0xFF10B981) : const Color(0xFFF59E0B), size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text('${_monthName(run.month)} ${run.year}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                        Text(run.status.toUpperCase(), style: TextStyle(
                                          fontSize: 10, fontWeight: FontWeight.bold,
                                          color: run.isLocked ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                        )),
                                      ]),
                                    ),
                                    if (!run.isLocked)
                                      IconButton(
                                        icon: const Icon(Icons.lock_rounded, size: 16, color: Color(0xFF64748B)),
                                        tooltip: 'Lock run',
                                        onPressed: () => _lockRun(run.id),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
            ],
          ),
        ),

        // ── RIGHT: Payslips ───────────────────────────────────────────────────
        Expanded(
          child: _selectedRunId == null
              ? const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.payments_outlined, size: 64, color: Color(0xFFCBD5E1)),
                    SizedBox(height: 16),
                    Text('Select a payroll run to view payslips', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15)),
                  ]),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Payslips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              Text('${_payslips.length} records', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            ]),
                          ),
                          // Summary
                          if (_payslips.isNotEmpty) ...[
                            _SmallStat(label: 'Total Net', value: 'PKR ${_payslips.fold(0.0, (s, p) => s + p.netSalary).toStringAsFixed(0)}', color: const Color(0xFF10B981)),
                            const SizedBox(width: 12),
                            _SmallStat(label: 'Total Tax', value: 'PKR ${_payslips.fold(0.0, (s, p) => s + p.tax).toStringAsFixed(0)}', color: const Color(0xFFEF4444)),
                          ],
                        ],
                      ),
                    ),
                    if (_loadingSlips)
                      const Expanded(child: Center(child: CircularProgressIndicator()))
                    else if (_payslips.isEmpty)
                      const Expanded(child: Center(child: Text('No payslips in this run.', style: TextStyle(color: Color(0xFF64748B)))))
                    else
                      Expanded(
                        child: Column(
                          children: [
                            // Table header
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                              child: const Row(children: [
                                Expanded(flex: 3, child: Text('Employee', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 12))),
                                Expanded(flex: 2, child: Text('Basic', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 12))),
                                Expanded(flex: 2, child: Text('Gross', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 12))),
                                Expanded(flex: 2, child: Text('Tax', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 12))),
                                Expanded(flex: 2, child: Text('Net Pay', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 12))),
                                SizedBox(width: 40),
                              ]),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                itemCount: _payslips.length,
                                itemBuilder: (_, i) {
                                  final p = _payslips[i];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white, borderRadius: BorderRadius.circular(8),
                                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 4)],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 3, child: Text(p.employeeName ?? p.employeeId, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                                        Expanded(flex: 2, child: Text('PKR ${p.basicSalary.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                                        Expanded(flex: 2, child: Text('PKR ${p.grossSalary.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                                        Expanded(flex: 2, child: Text('PKR ${p.tax.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)))),
                                        Expanded(flex: 2, child: Text('PKR ${p.netSalary.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w600))),
                                        SizedBox(
                                          width: 40,
                                          child: IconButton(
                                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFF64748B)),
                                            tooltip: 'Download PDF',
                                            onPressed: () => _downloadPdf(p.id),
                                          ),
                                        ),
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
                ),
        ),
      ],
    );
  }

  Future<void> _downloadPdf(String id) async {
    try {
      await ref.read(payrollRepositoryProvider).getPayslipPdf(id);
      if (mounted) _snack('PDF ready', success: true);
    } on AppException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack(e.toString());
    }
  }

  void _snack(String msg, {bool success = false}) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
  );

  String _monthName(int m) => ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][m];
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({required this.label, required this.value, required this.color});
  final String label, value;
  final Color  color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withAlpha(50))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}
