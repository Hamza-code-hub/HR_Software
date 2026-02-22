import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class _LeaveType {
  final String id, name;
  final int daysPerYear;
  final bool isPaid;
  _LeaveType({required this.id, required this.name, required this.daysPerYear, required this.isPaid});
  factory _LeaveType.fromJson(Map<String, dynamic> j) => _LeaveType(
    id:          j['id'] as String,
    name:        j['name'] as String,
    daysPerYear: j['days_per_year'] as int? ?? 0,
    isPaid:      j['is_paid'] as bool? ?? true,
  );
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ApplyLeaveScreen extends ConsumerStatefulWidget {
  const ApplyLeaveScreen({super.key});
  @override
  ConsumerState<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends ConsumerState<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  String?   _selectedTypeId;
  final _reasonController = TextEditingController();

  List<_LeaveType> _leaveTypes = [];
  String?          _employeeId;
  bool             _loadingTypes = true;
  bool             _submitting   = false;
  String?          _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final client = ref.read(apiClientProvider);
    try {
      // Load leave types and employee record in parallel
      final results = await Future.wait([
        client.get('/api/leave-types'),
        client.get('/api/employees/me'),
      ]);

      final types = (results[0] as List)
          .map((e) => _LeaveType.fromJson(e as Map<String, dynamic>))
          .toList();
      final emp = results[1] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _leaveTypes   = types;
          _employeeId   = emp['id'] as String?;
          if (_leaveTypes.isNotEmpty) _selectedTypeId = _leaveTypes.first.id;
          _loadingTypes = false;
        });
      }
    } on AppException catch (e) {
      if (mounted) setState(() { _error = e.message; _loadingTypes = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loadingTypes = false; });
    }
  }

  int get _dayCount {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? now : (_startDate ?? now),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0EA5E9), onPrimary: Colors.white, onSurface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) _endDate = null;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      _snack('Please select both start and end dates.', success: false);
      return;
    }
    if (_selectedTypeId == null || _employeeId == null) {
      _snack('Unable to resolve leave type or employee. Please try again.', success: false);
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(apiClientProvider).post('/api/leave-requests', body: {
        'employee_id':   _employeeId,
        'leave_type_id': _selectedTypeId,
        'start_date':    DateFormat('yyyy-MM-dd').format(_startDate!),
        'end_date':      DateFormat('yyyy-MM-dd').format(_endDate!),
        'reason':        _reasonController.text.trim(),
      });
      if (mounted) {
        setState(() => _submitting = false);
        _snack('Leave request submitted successfully! Pending approval.', success: true);
        // Reset form
        _reasonController.clear();
        setState(() { _startDate = null; _endDate = null; });
      }
    } on AppException catch (e) {
      if (mounted) { setState(() => _submitting = false); _snack(e.message); }
    } catch (e) {
      if (mounted) { setState(() => _submitting = false); _snack(e.toString()); }
    }
  }

  void _snack(String msg, {bool success = true}) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _loadingTypes
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                    const SizedBox(height: 12),
                    Text(_error!),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _loadInitialData, child: const Text('Retry')),
                  ]),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Apply for Leave', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 8),
                      const Text('Submit a leave request for approval by your manager.', style: TextStyle(color: Color(0xFF64748B))),
                      const SizedBox(height: 32),
                      Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 640),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 24, offset: const Offset(0, 8))],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Leave Type
                                _label('Leave Type'),
                                const SizedBox(height: 8),
                                if (_leaveTypes.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: _fieldBox(),
                                    child: const Text('No leave types configured. Contact HR.', style: TextStyle(color: Color(0xFF64748B))),
                                  )
                                else
                                  DropdownButtonFormField<String>(
                                    value: _selectedTypeId,
                                    decoration: _inputDeco(''),
                                    items: _leaveTypes.map((t) => DropdownMenuItem(
                                      value: t.id,
                                      child: Row(children: [
                                        Text(t.name),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (t.isPaid ? const Color(0xFF10B981) : const Color(0xFF64748B)).withAlpha(20),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(t.isPaid ? 'PAID' : 'UNPAID',
                                            style: TextStyle(fontSize: 10, color: t.isPaid ? const Color(0xFF10B981) : const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 6),
                                        Text('(${t.daysPerYear}d/yr)', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                      ]),
                                    )).toList(),
                                    onChanged: (v) => setState(() => _selectedTypeId = v),
                                    validator: (v) => v == null ? 'Select a leave type' : null,
                                  ),
                                const SizedBox(height: 24),

                                // Date pickers
                                Row(children: [
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    _label('Start Date'),
                                    const SizedBox(height: 8),
                                    _DatePickerField(
                                      date: _startDate,
                                      hint: 'Select date',
                                      onTap: () => _selectDate(context, true),
                                    ),
                                  ])),
                                  const SizedBox(width: 16),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    _label('End Date'),
                                    const SizedBox(height: 8),
                                    _DatePickerField(
                                      date: _endDate,
                                      hint: 'Select date',
                                      enabled: _startDate != null,
                                      onTap: () => _selectDate(context, false),
                                    ),
                                  ])),
                                ]),

                                // Day count preview
                                if (_dayCount > 0) ...[ 
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0EA5E9).withAlpha(15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(children: [
                                      const Icon(Icons.info_outline_rounded, color: Color(0xFF0EA5E9), size: 16),
                                      const SizedBox(width: 8),
                                      Text('$_dayCount day(s) leave requested', style: const TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.w600)),
                                    ]),
                                  ),
                                ],

                                const SizedBox(height: 24),
                                _label('Reason for Leave'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _reasonController,
                                  maxLines: 4,
                                  decoration: _inputDeco('Describe your reason here...'),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a reason' : null,
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _submitting ? null : _submitRequest,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0EA5E9), foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 0,
                                    ),
                                    child: _submitting
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)));

  BoxDecoration _fieldBox() => BoxDecoration(
    color: const Color(0xFFF1F5F9),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFE2E8F0)),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    filled: true, fillColor: const Color(0xFFF1F5F9),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2)),
    contentPadding: const EdgeInsets.all(16),
  );
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.date, required this.hint, required this.onTap, this.enabled = true});
  final DateTime? date;
  final String    hint;
  final VoidCallback onTap;
  final bool      enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF1F5F9) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded, size: 18, color: enabled ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
          const SizedBox(width: 12),
          Text(
            date == null ? hint : DateFormat('MMM dd, yyyy').format(date!),
            style: TextStyle(color: date == null ? const Color(0xFF94A3B8) : const Color(0xFF1E293B), fontSize: 14),
          ),
        ]),
      ),
    );
  }
}
