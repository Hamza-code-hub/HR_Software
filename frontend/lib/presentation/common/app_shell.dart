import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../core/theme_provider.dart';
import '../../data/auth_repository.dart';

final selectedShellMenuProvider = StateProvider<String>((ref) => 'dashboard');
final expandedShellMenuProvider = StateProvider<Set<String>>((ref) => {});

// ─────────────────────────────────────────────────────────────────────────────
// AppShell — dual-rail persistent sidebar + themed content area
// Layout: [MiniRail 60px] [NavPanel 240px] [Content ∞]
// ─────────────────────────────────────────────────────────────────────────────

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child, required this.currentRoute});
  final Widget child;
  final String currentRoute;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRoute(widget.currentRoute));
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentRoute != oldWidget.currentRoute) {
      Future.microtask(() => _syncRoute(widget.currentRoute));
    }
  }

  void _syncRoute(String route) {
    String menu = 'dashboard';
    // Simplified sync for new 44 items
    if (route.startsWith('/admin/users'))            menu = 'settings_users';
    else if (route.startsWith('/admin/departments'))  menu = 'settings_company';
    else if (route.startsWith('/admin'))             menu = 'dashboard';
    else if (route.startsWith('/dashboard'))         menu = 'hr_dashboard';
    else if (route.startsWith('/employees'))         menu = 'emp_list';
    else if (route.startsWith('/attendance'))        menu = 'att_daily';
    else if (route.startsWith('/hr/leave'))          menu = 'leave_approve';
    else if (route.startsWith('/payroll'))           menu = 'payroll_process';
    else if (route.startsWith('/hr/hiring-requests')) menu = 'req_view';
    else if (route.startsWith('/hr/resignations'))    menu = 'resignation_pending';
    else if (route.startsWith('/hr/recruitment'))   menu = 'recruit_postings';
    else if (route.startsWith('/employee/dashboard')) menu = 'employee_dashboard';
    else if (route.startsWith('/employee/profile'))   menu = 'profile';
    else if (route.startsWith('/employee/apply-leave')) menu = 'leave_apply';
    else if (route.startsWith('/employee/log-time'))  menu = 'time_log';
    else if (route.startsWith('/feature/')) {
      menu = route.split('/').last;
    }
    ref.read(selectedShellMenuProvider.notifier).state = menu;
  }

  void _go(String key) {
    final role = ref.read(sessionProvider)?.role ?? 'employee';
    ref.read(selectedShellMenuProvider.notifier).state = key;
    final map = {
      'dashboard':           role == 'admin' ? '/admin' : '/dashboard',
      'hr_dashboard':        '/dashboard',
      'employee_dashboard':  '/employee/dashboard',
      'profile':             '/employee/profile',
      'my_profile':          '/employee/profile',
      'settings':            role == 'admin' ? '/admin/users' : '/feature/settings',
      'employee_settings':   '/feature/settings',

      // Requirement Raising
      'req_create':          '/feature/req_create',
      'req_view':            '/hr/resource-requirements',
      'req_approve':         '/feature/req_approve',

      // Recruitment
      'recruit_postings':    '/hr/recruitment/postings',
      'recruit_candidates':  '/hr/recruitment/candidates',
      'recruit_schedule':    '/hr/recruitment/interviews',
      'recruit_feedback':    '/hr/recruitment/interviews',

      // Employee
      'emp_add':             '/hr/employee/add',
      'emp_list':            '/employees',
      'emp_probation':       '/hr/employee/probation',
      'emp_profile':         '/employee/profile',
      'emp_contracts':       '/hr/employee/contracts',
      'emp_offers':          '/hr/recruitment/offers',
      'emp_docs':            '/hr/employee/documents',
      'emp_promo':           '/hr/employee/promotions',

      // Attendance
      'att_daily':           '/attendance',
      'att_employee':        '/hr/attendance/employee',
      'att_dept':            '/hr/attendance/department',
      'att_report':          '/hr/attendance/report',
      'att_shifts':          '/hr/operations/shifts',

      // Leave Tracker
      'leave_apply':         '/employee/apply-leave',
      'leave_approve':       '/hr/leave',
      'leave_history':       '/hr/leave/history',
      'leave_types':         '/hr/leave/types',
      'leave_calendar':      '/hr/leave/calendar',

      // Time Tracker
      'time_log':            '/hr/operations/timesheets',
      'time_sheets':         '/hr/operations/timesheets',
      'time_project':        '/hr/operations/projects',
      'time_overtime':       '/hr/operations/overtime',

      // Appraisal
      'appraisal_review':    '/hr/talent/performance',
      'appraisal_goals':     '/hr/talent/performance',
      'appraisal_360':       '/hr/talent/performance',
      'appraisal_reports':   '/hr/talent/performance',
      'perf_review':         '/hr/talent/performance',
      'perf_setup':          '/hr/talent/performance',

      // Payroll
      'payroll_process':     '/payroll',
      'payroll_payslips':    '/feature/payroll_payslips',
      'payroll_structure':   '/accounting/rules',
      'payroll_tax':         '/accounting/reports',

      // Announcement
      'announcement_create': '/hr/communication/announcements',
      'announcement_view':   '/hr/communication/announcements',

      // Resignation
      'resignation_submit':  '/feature/resignation_submit',
      'resignation_pending': '/hr/resignations',
      'resignation_exit':    '/feature/resignation_exit',
      'resignation_clearance':'/feature/resignation_clearance',

      // Assets
      'asset_inventory':     '/hr/operations/assets',
      'asset_assignments':   '/hr/operations/assets',
      'asset_requests':      '/hr/operations/assets',

      // Talent
      'talent_training':     '/hr/talent/trainings',
      'talent_performance':  '/hr/talent/performance',

      // Settings
      'settings_company':    '/admin/departments',
    };
    final path = map[key];
    if (path != null) context.go(path);
    else context.go('/feature/$key');
  }

  void _toggleMenu(String id) {
    final curr = Set<String>.from(ref.read(expandedShellMenuProvider));
    if (curr.contains(id)) curr.remove(id); else curr.add(id);
    ref.read(expandedShellMenuProvider.notifier).state = curr;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final role    = session?.role ?? 'employee';
    final colors  = context.appColors;

    return Scaffold(
      backgroundColor: colors.surfaceBg,
      body: Row(
        children: [
          // ── 1. Mini Rail (far left, icon-only) ─────────────────────────────
          _MiniRail(
            session: session,
            onSettings: () => _go(role == 'employee' ? 'employee_settings' : 'settings'),
            onProfile:  () => _go('profile'),
            onLogout:   () => _showLogout(context),
          ),

          // ── 2. Nav Panel (main sidebar with labels) ─────────────────────────
          _NavPanel(
            role: role,
            session: session,
            selectedMenu: ref.watch(selectedShellMenuProvider),
            expandedMenus: ref.watch(expandedShellMenuProvider),
            onTap: _go,
            onToggle: _toggleMenu,
            onLogout: () => _showLogout(context),
          ),

          // ── 3. Main content area (uses theme bg) ───────────────────────────
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  void _showLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await (ref.read(authStateProvider.notifier) as dynamic).logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Rail ────────────────────────────────────────────────────────────────
// Far-left icon-only strip: Logo | ... | Avatar · Settings · Theme

class _MiniRail extends ConsumerWidget {
  const _MiniRail({
    required this.session,
    required this.onSettings,
    required this.onProfile,
    required this.onLogout,
  });
  final AuthTokens? session;
  final VoidCallback onSettings;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark    = themeMode == ThemeMode.dark;
    final initials  = _initials(session?.email ?? '?');

    return Container(
      width: 60,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF020617)],
        ),
        border: Border(right: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Column(
        children: [
          // Logo icon
          const SizedBox(height: 16),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF1E293B), thickness: 1, height: 1),
          const Spacer(),

          // ── Bottom icons ───────────────────────────────────────
          const Divider(color: Color(0xFF1E293B), thickness: 1, height: 1),
          const SizedBox(height: 8),

          // Theme toggle
          Tooltip(
            message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            preferBelow: false,
            child: InkWell(
              onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDark ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF94A3B8),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Settings
          Tooltip(
            message: 'Settings',
            preferBelow: false,
            child: InkWell(
              onTap: onSettings,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.settings_rounded, color: Color(0xFF94A3B8), size: 20),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Avatar / Profile
          Tooltip(
            message: session?.email ?? 'Profile',
            preferBelow: false,
            child: InkWell(
              onTap: onProfile,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                ),
                child: Center(
                  child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _initials(String email) {
    final parts = email.split('@').first.split('.');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }
}

// ─── Nav Panel ────────────────────────────────────────────────────────────────
// Main sidebar: logo + brand + scrollable nav + user card at bottom

class _NavPanel extends ConsumerWidget {
  const _NavPanel({
    required this.role,
    required this.session,
    required this.selectedMenu,
    required this.expandedMenus,
    required this.onTap,
    required this.onToggle,
    required this.onLogout,
  });
  final String     role;
  final AuthTokens? session;
  final String     selectedMenu;
  final Set<String> expandedMenus;
  final void Function(String) onTap;
  final void Function(String) onToggle;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        border: Border(right: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: Column(
        children: [
          // ── Brand header ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: const Color(0xFF0EA5E9).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.groups_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('HR Suite', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('CyberZeus', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                ]),
              ],
            ),
          ),
          const Divider(color: Color(0xFF334155), height: 1),

          // ── Scrollable nav items ─────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _buildNavItems(context),
            ),
          ),

          // ── User card at bottom ──────────────────────────────────────────
          _buildUserCard(context),
        ],
      ),
    );
  }

  // ── Nav item builders ─────────────────────────────────────────────────────

  List<Widget> _buildNavItems(BuildContext context) {
    if (role == 'employee') return _buildEmployeeNavItems(context);
    
    // Comprehensive HR/Admin sidebar (44+ items)
    return [
      // 1. DASHBOARD
      _item(context, Icons.dashboard_rounded, role == 'admin' ? 'Admin Dashboard' : 'HR Dashboard', 'dashboard'),

      // 2. PROFILE
      _item(context, Icons.person_pin_rounded, 'Profile', 'profile'),

      // 3. RESOURCE REQUIREMENTS
      _category('OPERATIONS'),
      _item(context, Icons.inventory_rounded, 'Resource Requirements', 'resource_reqs', sub: true),
      if (expandedMenus.contains('resource_reqs')) ...[
        _sub(context, Icons.add_circle_outline, 'Request Resource', 'res_create'),
        _sub(context, Icons.visibility_rounded, 'View Requests', 'res_view'),
        _sub(context, Icons.how_to_reg_rounded, 'Approve Requests', 'res_approve'),
      ],

      // 4. RECRUITMENT
      _item(context, Icons.work_rounded, 'Recruitment', 'recruitment_menu', sub: true),
      if (expandedMenus.contains('recruitment_menu')) ...[
        _sub(context, Icons.post_add_rounded, 'Job Postings', 'recruit_postings'),
        _sub(context, Icons.people_outline_rounded, 'Candidates', 'recruit_candidates'),
        _sub(context, Icons.calendar_today_rounded, 'Schedule Interview', 'recruit_schedule'),
        _sub(context, Icons.assessment_rounded, 'Interview Feedback', 'recruit_feedback'),
      ],

      // 5. EMPLOYEE
      _category('EMPLOYEE SERVICES'),
      _item(context, Icons.people_rounded, 'Employee Management', 'employee_menu', sub: true),
      if (expandedMenus.contains('employee_menu')) ...[
        _sub(context, Icons.person_add_rounded, 'Add Employee', 'emp_add'),
        _sub(context, Icons.list_alt_rounded, 'Employee List', 'emp_list'),
        _sub(context, Icons.timer_outlined, 'Probation Tracking', 'emp_probation'),
        _sub(context, Icons.badge_rounded, 'My Profile', 'emp_profile'),
        _sub(context, Icons.description_rounded, 'Contracts', 'emp_contracts'),
        _sub(context, Icons.drafts_rounded, 'Offer Letters', 'emp_offers'),
        _sub(context, Icons.folder_shared_rounded, 'Documents', 'emp_docs'),
        _sub(context, Icons.swap_horiz_rounded, 'Promotion & Transfer', 'emp_promo'),
      ],

      // 6. ATTENDANCE
      _category('OPERATIONS'),
      _item(context, Icons.access_time_filled_rounded, 'Attendance', 'attendance_menu', sub: true),
      if (expandedMenus.contains('attendance_menu')) ...[
        _sub(context, Icons.today_rounded, 'Daily Attendance', 'att_daily'),
        _sub(context, Icons.person_search_rounded, 'Employee Attendance', 'att_employee'),
        _sub(context, Icons.business_rounded, 'Department Wise', 'att_dept'),
        _sub(context, Icons.analytics_rounded, 'Attendance Report', 'att_report'),
        _sub(context, Icons.published_with_changes_rounded, 'Shift Management', 'att_shifts'),
      ],

      // 7. LEAVE TRACKER
      _item(context, Icons.event_busy_rounded, 'Leave Tracker', 'leave_menu', sub: true),
      if (expandedMenus.contains('leave_menu')) ...[
        _sub(context, Icons.add_task_rounded, 'Apply Leave', 'leave_apply'),
        _sub(context, Icons.fact_check_rounded, 'Approve Leaves', 'leave_approve'),
        _sub(context, Icons.history_rounded, 'Leave History', 'leave_history'),
        _sub(context, Icons.category_rounded, 'Leave Types', 'leave_types'),
        _sub(context, Icons.calendar_month_rounded, 'Leave Calendar', 'leave_calendar'),
      ],

      // 8. TIME TRACKER
      _item(context, Icons.timer_rounded, 'Time Tracker', 'time_menu', sub: true),
      if (expandedMenus.contains('time_menu')) ...[
        _sub(context, Icons.edit_calendar_rounded, 'Log Time', 'time_log'),
        _sub(context, Icons.table_chart_rounded, 'Timesheets', 'time_sheets'),
        _sub(context, Icons.assignment_rounded, 'Project Time', 'time_project'),
        _sub(context, Icons.more_time_rounded, 'Overtime', 'time_overtime'),
      ],

      // 9. ASSET MANAGEMENT
      _item(context, Icons.inventory_2_rounded, 'Asset Management', 'asset_menu', sub: true),
      if (expandedMenus.contains('asset_menu')) ...[
        _sub(context, Icons.devices_rounded, 'Inventory', 'asset_inventory'),
        _sub(context, Icons.assignment_returned_rounded, 'Assignments', 'asset_assignments'),
        _sub(context, Icons.request_quote_rounded, 'Asset Requests', 'asset_requests'),
      ],




      // 10. PAYROLL
      _category('FINANCE'),
      _item(context, Icons.payments_rounded, 'Payroll', 'payroll_menu', sub: true),
      if (expandedMenus.contains('payroll_menu')) ...[
        _sub(context, Icons.account_balance_rounded, 'Process Payroll', 'payroll_process'),
        _sub(context, Icons.receipt_long_rounded, 'My Payslips', 'payroll_payslips'),
        _sub(context, Icons.schema_rounded, 'Salary Structure', 'payroll_structure'),
        _sub(context, Icons.calculate_rounded, 'Tax Calculation', 'payroll_tax'),
      ],

      // 11. ANNOUNCEMENT
      _category('COMMUNICATION'),
      _item(context, Icons.campaign_rounded, 'Announcement', 'ann_menu', sub: true),
      if (expandedMenus.contains('ann_menu')) ...[
        _sub(context, Icons.add_comment_rounded, 'Create Announcement', 'announcement_create'),
        _sub(context, Icons.feed_rounded, 'View Announcements', 'announcement_view'),
      ],

      // 12. RESIGNATION
      _category('EXIT MANAGEMENT'),
      _item(context, Icons.exit_to_app_rounded, 'Resignation', 'exit_menu', sub: true),
      if (expandedMenus.contains('exit_menu')) ...[
        _sub(context, Icons.outbox_rounded, 'Submit Resignation', 'resignation_submit'),
        _sub(context, Icons.pending_actions_rounded, 'Pending Resignations', 'resignation_pending'),
        _sub(context, Icons.meeting_room_rounded, 'Exit Process', 'resignation_exit'),
        _sub(context, Icons.checklist_rtl_rounded, 'Clearance Checklist', 'resignation_clearance'),
      ],

      // 13. SETTINGS
      _category('SYSTEM'),
      _item(context, Icons.settings_rounded, 'Settings', 'settings_menu', sub: true),
      if (expandedMenus.contains('settings_menu')) ...[
        _sub(context, Icons.business_rounded, 'Company Settings', 'settings_company'),
      ],

      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildEmployeeNavItems(BuildContext context) {
    return [
      _item(context, Icons.dashboard_rounded, 'My Dashboard', 'employee_dashboard'),
      _category('SELF SERVICE'),
      _item(context, Icons.person_rounded, 'My Profile', 'profile'),
      _item(context, Icons.mail_rounded, 'Apply Leave', 'leave_apply'),
      _item(context, Icons.timer_rounded, 'Log Time', 'time_log'),
      
      _category('ATTENDANCE'),
      _item(context, Icons.fingerprint_rounded, 'My Attendance', 'att_daily'),
      
      _category('PAY'),
      _item(context, Icons.receipt_long_rounded, 'My Payslips', 'payroll_payslips'),
      
      _category('COMMUNICATION'),
      _item(context, Icons.campaign_rounded, 'Announcements', 'announcement_view'),
      
      const SizedBox(height: 16),
    ];
  }

  Widget _category(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
    child: Text(
      label,
      style: const TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2),
    ),
  );

  Widget _item(BuildContext ctx, IconData icon, String label, String key, {bool sub = false}) {
    final isActive = selectedMenu == key;
    return GestureDetector(
      onTap: sub ? () => onToggle(key) : () => onTap(key),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          gradient: isActive ? const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]) : null,
          color:     isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: isActive ? Colors.white : const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFFCBD5E1),
            fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ))),
          if (sub)
            Icon(
              expandedMenus.contains(key) ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
              color: isActive ? Colors.white : const Color(0xFF64748B), size: 16,
            ),
        ]),
      ),
    );
  }

  Widget _sub(BuildContext ctx, IconData icon, String label, String key) => GestureDetector(
    onTap: () => onTap(key),
    child: Container(
      margin: const EdgeInsets.only(left: 24, right: 8, top: 1, bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: selectedMenu == key ? const Color(0xFF0EA5E9).withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(icon, size: 15, color: selectedMenu == key ? const Color(0xFF38BDF8) : const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(
          color: selectedMenu == key ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
          fontSize: 12, fontWeight: FontWeight.w500,
        )),
      ]),
    ),
  );

  // ── User card ────────────────────────────────────────────────────────────

  Widget _buildUserCard(BuildContext context) {
    final email    = session?.email ?? 'user@example.com';
    final role_    = session?.role ?? 'employee';
    final name_    = email.split('@').first.replaceAll('.', ' ');
    final initials = name_.isNotEmpty ? name_.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join('').toUpperCase() : '?';

    final roleColor = switch (role_) {
      'admin'      => const Color(0xFF3B82F6),
      'hr'         => const Color(0xFF8B5CF6),
      'accounting' => const Color(0xFF10B981),
      _            => const Color(0xFF64748B),
    };

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            // Avatar
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(19),
              ),
              child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                name_.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '),
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(role_.toUpperCase(), style: TextStyle(color: roleColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              ),
            ])),
          ]),
          const SizedBox(height: 10),
          // Logout button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, size: 14),
              label: const Text('Sign Out', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
