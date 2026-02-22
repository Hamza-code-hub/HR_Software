import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../data/auth_repository.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final _myEmployeeProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ref.watch(apiClientProvider).get('/api/employees/me');
  return res as Map<String, dynamic>;
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});
  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session   = ref.watch(sessionProvider);
    final empAsync  = ref.watch(_myEmployeeProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: empAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(e is AppException ? e.message : e.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => ref.refresh(_myEmployeeProvider), child: const Text('Retry')),
          ]),
        ),
        data: (emp) {
          final nameFromEmp = emp['name'] as String? ?? '';
          final nameFromEmail = session?.email.split('@')[0] ?? 'Employee';
          final rawName = nameFromEmp.isNotEmpty ? nameFromEmp : nameFromEmail;
          final displayName = rawName.isNotEmpty
              ? rawName[0].toUpperCase() + rawName.substring(1)
              : 'Employee';

          return SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(displayName, emp, session),
                const SizedBox(height: 32),
                _buildProfileContent(displayName, emp, session, isDesktop),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String displayName, Map<String, dynamic> emp, AuthTokens? session) {
    final designation = emp['designation'] as String? ?? session?.role ?? 'Employee';
    final email       = emp['email'] as String? ?? session?.email ?? '';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9)),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(displayName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text(designation, style: const TextStyle(fontSize: 16, color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              Wrap(spacing: 12, children: [
                if (emp['department_id'] != null)
                  _buildChip(Icons.business_center, 'Department'),
                _buildChip(Icons.email_rounded, email.isNotEmpty ? email : 'Not set'),
                if (emp['status'] != null)
                  _buildChip(Icons.circle, (emp['status'] as String).toUpperCase()),
              ]),
            ]),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: const Color(0xFF64748B)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
    ]),
  );

  Widget _buildProfileContent(String displayName, Map<String, dynamic> emp, AuthTokens? session, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF0EA5E9),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF0EA5E9),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [Tab(text: 'Personal Info'), Tab(text: 'Professional Details'), Tab(text: 'Documents')],
          ),
          const Divider(height: 1),
          // Fix: Ensure TabBarView has a bounded height even if parent is scrollable
          SizedBox(
            height: isDesktop ? 600 : 800, 
            child: TabBarView(
              controller: _tabController,
              children: [
                _personalInfoTab(displayName, emp, session),
                _professionalTab(emp, session),
                _documentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _personalInfoTab(String displayName, Map<String, dynamic> emp, AuthTokens? session) {
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    final fields = [
      _InfoItem('Full Name',        displayName),
      _InfoItem('Email Address',    emp['email'] as String? ?? session?.email ?? 'N/A'),
      _InfoItem('Phone Number',     emp['phone'] as String? ?? 'Not set'),
      _InfoItem('CNIC',             emp['cnic'] as String? ?? 'Not set'),
      _InfoItem('Status',           (emp['status'] as String? ?? 'active').toUpperCase()),
      _InfoItem('Employee Code',    emp['employee_code'] as String? ?? 'Not assigned'),
      _InfoItem('Joining Date',     emp['joining_date'] as String? ?? 'Not set'),
      _InfoItem('Employment Type',  emp['employment_type'] as String? ?? 'Full-time'),
    ];
    return _infoGrid(isDesktop, fields);
  }

  Widget _professionalTab(Map<String, dynamic> emp, AuthTokens? session) {
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    final salary    = emp['basic_salary'];
    final fields = [
      _InfoItem('Employee ID',      emp['id'] as String? ?? 'N/A'),
      _InfoItem('Role / Access',    session?.role.toUpperCase() ?? 'Employee'),
      _InfoItem('Designation',      emp['designation'] as String? ?? 'Not set'),
      _InfoItem('Basic Salary',     salary != null ? 'PKR ${salary.toString()}' : 'Confidential'),
      _InfoItem('Joining Date',     emp['joining_date'] as String? ?? 'Not set'),
      _InfoItem('Employment Type',  'Full-time'),
      _InfoItem('Work Location',    'On-site'),
      _InfoItem('Reporting Manager','To be assigned'),
    ];
    return _infoGrid(isDesktop, fields);
  }

  Widget _infoGrid(bool isDesktop, List<_InfoItem> items) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: isDesktop
          ? GridView.count(
              crossAxisCount: 2, childAspectRatio: 4, crossAxisSpacing: 32, mainAxisSpacing: 24,
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              children: items.map(_buildInfoField).toList(),
            )
          : Column(children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: SizedBox(width: double.infinity, child: _buildInfoField(item)),
            )).toList()),
    );
  }

  Widget _buildInfoField(_InfoItem item) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(item.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
      const SizedBox(height: 4),
      Text(item.value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
    ],
  );

  Widget _documentsTab() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Official Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 24),
          _buildDocumentRow('Identity Proof (ID)', 'Uploaded on Feb 10, 2024', true),
          _buildDocumentRow('Passport', 'Uploaded on Feb 12, 2024', true),
          _buildDocumentRow('Education Certificates', 'Not Uploaded', false),
          _buildDocumentRow('Previous Experience Letter', 'Uploaded on Feb 15, 2024', true),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(String title, String status, bool isUploaded) {
    final color = isUploaded ? const Color(0xFF10B981) : const Color(0xFF64748B);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(isUploaded ? Icons.description : Icons.upload_file, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
            Text(status, style: TextStyle(fontSize: 12, color: color)),
          ])),
          if (isUploaded) IconButton(onPressed: () {}, icon: const Icon(Icons.download_rounded, color: Color(0xFF0EA5E9)))
          else TextButton(onPressed: () {}, child: const Text('Upload Now')),
        ],
      ),
    );
  }
}

class _InfoItem {
  final String label, value;
  const _InfoItem(this.label, this.value);
}
