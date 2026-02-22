import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/auth/login_screen.dart';
import '../presentation/auth/signup_screen.dart';
import '../presentation/common/app_shell.dart';
import '../presentation/common/generic_feature_screen.dart';
import '../presentation/dashboard/dashboard_screen.dart';
import '../presentation/employees/employees_screen.dart';
import '../presentation/attendance/attendance_screen.dart';
import '../presentation/payroll/payroll_screen.dart';
import '../presentation/accounting/accounting_screen.dart';
import '../presentation/accounting/salary_rules_screen.dart';
import '../presentation/accounting/salary_reports_screen.dart';
import '../presentation/accounting/expenses_screen.dart';
import '../presentation/hr/leave_management_screen.dart';
import '../presentation/hr/assets_screen.dart';
import '../presentation/hr/resource_requirements_screen.dart';
import '../presentation/hr/resignation_management_screen.dart';
import '../presentation/hr/job_postings_screen.dart';
import '../presentation/hr/candidates_screen.dart';
import '../presentation/hr/interviews_screen.dart';
import '../presentation/hr/probation_screen.dart';
import '../presentation/hr/documents_screen.dart';
import '../presentation/hr/promotions_screen.dart';
import '../presentation/hr/announcements_screen.dart';
import '../presentation/hr/shifts_screen.dart';
import '../presentation/hr/timesheets_screen.dart';
import '../presentation/hr/exit_clearance_screen.dart';
import '../presentation/hr/exit_interview_screen.dart';
import '../presentation/hr/add_employee_screen.dart';
import '../presentation/hr/offer_letters_screen.dart';
import '../presentation/hr/employee_contracts_screen.dart';
import '../presentation/hr/leave_history_screen.dart';
import '../presentation/hr/leave_types_screen.dart';
import '../presentation/hr/leave_calendar_screen.dart';
import '../presentation/hr/attendance_report_screen.dart';
import '../presentation/hr/department_attendance_screen.dart';
import '../presentation/hr/employee_attendance_screen.dart';
import '../presentation/hr/projects_management_screen.dart';
import '../presentation/hr/overtime_tracking_screen.dart';
import '../presentation/hr/training_management_screen.dart';
import '../presentation/hr/performance_appraisal_screen.dart';
import '../presentation/admin/admin_dashboard_screen.dart';
import '../presentation/admin/user_management_screen.dart';
import '../presentation/admin/department_management_screen.dart';
import '../presentation/employees/employee_dashboard_screen.dart';
import '../presentation/employees/my_profile_screen.dart';
import '../presentation/employees/settings_screen.dart';
import '../presentation/employees/apply_leave_screen.dart';
import '../presentation/employees/log_time_screen.dart';
import '../presentation/employees/my_assets_screen.dart';
import '../data/auth_repository.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: _AuthStateListenable(ref),
    redirect: (context, state) {
      final tokens     = authState.valueOrNull;
      final isLoggedIn = tokens != null;
      final path       = state.matchedLocation;
      final isAuthPage = path == '/login' || path == '/signup';
      final role       = tokens?.role ?? 'guest';

      // Not logged in → always go to login
      if (!isLoggedIn && !isAuthPage) return '/login';

      // Logged in but still on auth page → role-based home
      if (isLoggedIn && isAuthPage) {
        return _homeFor(role);
      }

      // RBAC guards
      if (isLoggedIn) {
        // Accounting role: can only access /accounting/*
        if (role == 'accounting') {
          if (!path.startsWith('/accounting') && path != '/login') {
            return '/accounting';
          }
        }

        // HR role: blocked from /admin
        if (role == 'hr' && path.startsWith('/admin')) {
          return '/dashboard';
        }

        // Employee: only dashboard, attendance, leave
        if (role == 'employee') {
          if (path.startsWith('/admin') ||
              path.startsWith('/payroll') ||
              path.startsWith('/accounting') ||
              path.startsWith('/employees')) {
            return '/dashboard';
          }
        }
      }

      return null;
    },
    routes: [
      // ── Public routes (no shell) ─────────────────────────────────────────
      GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/', redirect: (context, state) {
        final tokens = ref.read(authStateProvider).valueOrNull;
        if (tokens == null) return '/login';
        return _homeFor(tokens.role);
      }),

      // ── Protected routes (inside AppShell) ──────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppShell(
            currentRoute: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          // Admin
          GoRoute(path: '/admin',             builder: (_, __) => const AdminDashboardScreen()),
          GoRoute(path: '/admin/users',        builder: (_, __) => const UserManagementScreen()),
          GoRoute(path: '/admin/departments',  builder: (_, __) => const DepartmentManagementScreen()),

          // HR
          GoRoute(path: '/dashboard',  builder: (_, __) => const HRDashboardScreen()),
          GoRoute(path: '/employees',  builder: (_, __) => const EmployeesScreen()),
          GoRoute(path: '/attendance', builder: (_, __) => const AttendanceScreen()),
          GoRoute(path: '/hr/leave',   builder: (_, __) => const LeaveManagementScreen()),
          GoRoute(path: '/hr/assets',  builder: (_, __) => const AssetsScreen()),
          GoRoute(path: '/hr/resource-requirements', builder: (_, __) => const ResourceRequirementsScreen()),
          GoRoute(path: '/hr/leave/history', builder: (_, __) => const LeaveHistoryScreen()),
          GoRoute(path: '/hr/resignations',    builder: (_, __) => const ResignationManagementScreen()),
          GoRoute(path: '/hr/recruitment/postings', builder: (_, __) => const JobPostingsScreen()),
          GoRoute(path: '/hr/recruitment/candidates', builder: (_, __) => const CandidatesScreen()),
          GoRoute(path: '/hr/recruitment/interviews', builder: (_, __) => const InterviewsScreen()),
          GoRoute(path: '/hr/employee/probation', builder: (_, __) => const ProbationScreen()),
          GoRoute(path: '/hr/employee/documents', builder: (_, __) => const DocumentsScreen()),
          GoRoute(path: '/hr/employee/promotions', builder: (_, __) => const PromotionsScreen()),
          GoRoute(path: '/hr/employee/add', builder: (_, __) => const AddEmployeeScreen()),
          GoRoute(path: '/hr/employee/contracts', builder: (_, __) => const EmployeeContractsScreen()),
          GoRoute(path: '/hr/recruitment/offers', builder: (_, __) => const OfferLettersScreen()),
          GoRoute(path: '/hr/communication/announcements', builder: (_, __) => const AnnouncementsScreen()),
          GoRoute(path: '/hr/operations/shifts', builder: (_, __) => const ShiftsScreen()),
          GoRoute(path: '/hr/operations/timesheets', builder: (_, __) => const TimesheetsScreen()),
          GoRoute(path: '/hr/operations/projects', builder: (_, __) => const ProjectsManagementScreen()),
          GoRoute(path: '/hr/operations/overtime', builder: (_, __) => const OvertimeTrackingScreen()),
          GoRoute(path: '/hr/talent/trainings', builder: (_, __) => const TrainingManagementScreen()),
          GoRoute(path: '/hr/talent/performance', builder: (_, __) => const PerformanceAppraisalScreen()),
          GoRoute(path: '/hr/attendance/report', builder: (_, __) => const AttendanceReportScreen()),
          GoRoute(path: '/hr/attendance/department', builder: (_, __) => const DepartmentAttendanceScreen()),
          GoRoute(path: '/hr/attendance/employee', builder: (_, __) => const EmployeeAttendanceScreen()),
          GoRoute(path: '/hr/operations/assets', builder: (_, __) => const AssetsScreen()),
          GoRoute(path: '/hr/resignations/:id/clearance', builder: (context, state) => ExitClearanceScreen(resignationId: state.pathParameters['id']!)),
          GoRoute(path: '/hr/resignations/:id/interview', builder: (context, state) => ExitInterviewScreen(resignationId: state.pathParameters['id']!)),

          // Employee
          GoRoute(path: '/employee/dashboard', builder: (_, __) => const EmployeeDashboardScreen()),
          GoRoute(path: '/employee/profile',   builder: (_, __) => const MyProfileScreen()),
          GoRoute(path: '/employee/settings',  builder: (_, __) => const EmployeeSettingsScreen()),
          GoRoute(path: '/employee/apply-leave', builder: (_, __) => const ApplyLeaveScreen()),
          GoRoute(path: '/employee/log-time', builder: (_, __) => const LogTimeScreen()),
          GoRoute(path: '/employee/assets',   builder: (_, __) => const MyAssetsScreen()),

          // Payroll
          GoRoute(path: '/payroll', builder: (_, __) => const PayrollScreen()),

          // Accounting
          GoRoute(path: '/accounting',          builder: (_, __) => const AccountingScreen()),
          GoRoute(path: '/accounting/rules',    builder: (_, __) => const SalaryRulesScreen()),
          GoRoute(path: '/accounting/reports',  builder: (_, __) => const SalaryReportsScreen()),
          GoRoute(path: '/accounting/expenses', builder: (_, __) => ExpensesScreen()),

          // Generic Feature Catch-All
          GoRoute(
            path: '/feature/:id',
            builder: (context, state) => GenericFeatureScreen(
              featureId: state.pathParameters['id'] ?? 'unknown',
            ),
          ),
        ],
      ),
    ],
  );
});

String _homeFor(String role) => switch (role) {
  'admin'      => '/admin',
  'accounting' => '/accounting',
  'hr'         => '/dashboard',
  _            => '/employee/dashboard',
};

class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}
