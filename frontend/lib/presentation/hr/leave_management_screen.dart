import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../data/auth_repository.dart';

// ── Models ────────────────────────────────────────────────────────────────────
class LeaveType {
  final String id, name;
  final bool isPaid;
  final int maxDays;
  LeaveType({required this.id, required this.name, required this.isPaid, required this.maxDays});
  factory LeaveType.fromJson(Map<String, dynamic> j) => LeaveType(
    id: j['id'] as String, name: j['name'] as String,
    isPaid: j['is_paid'] as bool? ?? true, maxDays: j['max_days'] as int? ?? 0,
  );
}

class LeaveRequest {
  final String  id, employeeId, status;
  final String? employeeName, leaveTypeName, reason, rejectionReason;
  final String  startDate, endDate;
  final int     days;
  LeaveRequest({required this.id, required this.employeeId, required this.status, this.employeeName, this.leaveTypeName, this.reason, this.rejectionReason, required this.startDate, required this.endDate, required this.days});
  factory LeaveRequest.fromJson(Map<String, dynamic> j) => LeaveRequest(
    id: j['id'] as String, employeeId: j['employee_id'] as String,
    status: j['status'] as String? ?? 'pending',
    employeeName: j['employee_name'] as String?,
    leaveTypeName: j['leave_type_name'] as String?,
    reason: j['reason'] as String?,
    rejectionReason: j['rejection_reason'] as String?,
    startDate: j['start_date'] as String? ?? '', endDate: j['end_date'] as String? ?? '',
    days: j['days'] as int? ?? 0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class LeaveManagementScreen extends ConsumerStatefulWidget {
  const LeaveManagementScreen({super.key});
  @override
  ConsumerState<LeaveManagementScreen> createState() => _State();
}

class _State extends ConsumerState<LeaveManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<LeaveRequest> _requests  = [];
  List<LeaveType>    _types     = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final client = ref.read(apiClientProvider);
      final [rawReqs, rawTypes] = await Future.wait([
        client.get('/api/leave-requests'),
        client.get('/api/leave-types'),
      ]);
      _requests = (rawReqs as List).map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>)).toList();
      _types    = (rawTypes as List).map((e) => LeaveType.fromJson(e as Map<String, dynamic>)).toList();
      setState(() => _loading = false);
    } on AppException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String get _role => ref.read(sessionProvider)?.role ?? 'employee';
  bool get _isManager => _role == 'admin' || _role == 'hr';

  @override
  Widget build(BuildContext context) {
    final pending  = _requests.where((r) => r.status == 'pending').length;
    final approved = _requests.where((r) => r.status == 'approved').length;

    return Column(
      children: [
        // ── Header ───────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Leave Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  RichText(text: TextSpan(style: const TextStyle(color: Color(0xFF64748B), fontSize: 13), children: [
                    TextSpan(text: '$pending pending  •  '),
                    TextSpan(text: '$approved approved', style: const TextStyle(color: Color(0xFF10B981))),
                  ])),
                ]),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Apply for Leave'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: _showApplyDialog,
              ),
              if (_isManager) ...[
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_business_rounded, size: 16),
                  label: const Text('Add Leave Type'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF06B6D4),
                    side: const BorderSide(color: Color(0xFF06B6D4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () => _showAddTypeDialog(),
                ),
              ],
            ],
          ),
        ),

        // ── Tabs ──────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            labelColor: const Color(0xFF06B6D4),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF06B6D4),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: 'Leave Requests (${_requests.length})'),
              Tab(text: 'Leave Types (${_types.length})'),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                      const SizedBox(height: 12),
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadAll, child: const Text('Retry')),
                    ]))
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        // Requests
                        _requests.isEmpty
                            ? const Center(child: Text('No leave requests found.', style: TextStyle(color: Color(0xFF64748B))))
                            : ListView.separated(
                                padding: const EdgeInsets.all(24),
                                itemCount: _requests.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, i) => _LeaveRequestCard(
                                  request: _requests[i],
                                  isManager: _isManager,
                                  onApprove: () => _approve(_requests[i].id),
                                  onReject:  () => _reject(_requests[i].id),
                                ),
                              ),

                        // Types
                        _types.isEmpty
                            ? const Center(child: Text('No leave types configured.', style: TextStyle(color: Color(0xFF64748B))))
                            : ListView.separated(
                                padding: const EdgeInsets.all(24),
                                itemCount: _types.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, i) => _LeaveTypeCard(type: _types[i]),
                              ),
                      ],
                    ),
        ),
      ],
    );
  }

  Future<void> _approve(String id) async {
    try {
      await ref.read(apiClientProvider).put('/api/leave-requests/$id/approve', body: {});
      _loadAll();
      if (mounted) _snack('Request approved!', success: true);
    } on AppException catch (e) { if (mounted) _snack(e.message); }
  }

  Future<void> _reject(String id) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Leave Request'),
        content: TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason (optional)', border: OutlineInputBorder()), maxLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, true), child: const Text('Reject')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(apiClientProvider).put('/api/leave-requests/$id/reject', body: {'reason': reasonCtrl.text.trim()});
      _loadAll();
      if (mounted) _snack('Request rejected');
    } on AppException catch (e) { if (mounted) _snack(e.message); }
  }

  void _showApplyDialog() {
    if (_types.isEmpty) { _snack('No leave types configured.'); return; }
    String  typeId = _types.first.id;
    final   startCtrl  = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final   endCtrl    = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final   reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Apply for Leave', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: typeId, decoration: const InputDecoration(labelText: 'Leave Type', border: OutlineInputBorder()),
              items: _types.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
              onChanged: (v) => setState(() => typeId = v ?? typeId),
            ),
            const SizedBox(height: 10),
            TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: endCtrl,   decoration: const InputDecoration(labelText: 'End Date (YYYY-MM-DD)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()), maxLines: 2),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(apiClientProvider).post('/api/leave-requests', body: {
                    'leave_type_id': typeId, 'start_date': startCtrl.text, 'end_date': endCtrl.text, 'reason': reasonCtrl.text.trim(),
                  });
                  _loadAll();
                  if (mounted) _snack('Leave request submitted!', success: true);
                } on AppException catch (e) { if (mounted) _snack(e.message); }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTypeDialog() {
    final nameCtrl = TextEditingController();
    int   maxDays  = 14;
    bool  isPaid   = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('New Leave Type', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Type Name (e.g. Annual Leave)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max Days', border: OutlineInputBorder()),
                onChanged: (v) => maxDays = int.tryParse(v) ?? maxDays,
                controller: TextEditingController(text: maxDays.toString()),
              )),
              const SizedBox(width: 12),
              Row(children: [
                const Text('Paid'), Switch(value: isPaid, onChanged: (v) => setState(() => isPaid = v)),
              ]),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.white),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ref.read(apiClientProvider).post('/api/leave-types', body: {'name': nameCtrl.text.trim(), 'is_paid': isPaid, 'max_days': maxDays});
                  _loadAll();
                  if (mounted) _snack('Leave type created!', success: true);
                } on AppException catch (e) { if (mounted) _snack(e.message); }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg, {bool success = false}) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
  );
}

// ── Card widgets ─────────────────────────────────────────────────────────────

class _LeaveRequestCard extends StatelessWidget {
  const _LeaveRequestCard({required this.request, required this.isManager, required this.onApprove, required this.onReject});
  final LeaveRequest request;
  final bool         isManager;
  final VoidCallback onApprove, onReject;

  @override
  Widget build(BuildContext context) {
    final color = switch (request.status) {
      'approved' => const Color(0xFF10B981),
      'rejected' => const Color(0xFFEF4444),
      _          => const Color(0xFFF59E0B),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.event_note_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(request.employeeName ?? request.employeeId, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
              Text('${request.leaveTypeName ?? "Leave"}  •  ${request.startDate} → ${request.endDate}  •  ${request.days} day(s)',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              if (request.reason != null && request.reason!.isNotEmpty)
                Text('Reason: ${request.reason}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(20)),
            child: Text(request.status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          if (isManager && request.status == 'pending') ...[
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)), onPressed: onApprove, tooltip: 'Approve'),
            IconButton(icon: const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444)), onPressed: onReject, tooltip: 'Reject'),
          ],
        ],
      ),
    );
  }
}

class _LeaveTypeCard extends StatelessWidget {
  const _LeaveTypeCard({required this.type});
  final LeaveType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF06B6D4).withAlpha(25), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.category_rounded, color: Color(0xFF06B6D4), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(type.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
              Text('Max ${type.maxDays} days', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (type.isPaid ? const Color(0xFF10B981) : const Color(0xFF64748B)).withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              type.isPaid ? 'PAID' : 'UNPAID',
              style: TextStyle(color: type.isPaid ? const Color(0xFF10B981) : const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
