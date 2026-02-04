import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/auth/login_screen.dart';
import '../presentation/auth/signup_screen.dart';
import '../presentation/dashboard/dashboard_screen.dart';
import '../presentation/employees/employees_screen.dart';
import '../presentation/attendance/attendance_screen.dart';
import '../presentation/payroll/payroll_screen.dart';
import '../presentation/accounting/accounting_screen.dart';
import '../data/auth_repository.dart';

import '../presentation/accounting/salary_rules_screen.dart';
import '../presentation/accounting/salary_reports_screen.dart';
import '../presentation/accounting/expenses_screen.dart';
import '../presentation/hr/assets_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final tokens = authState.valueOrNull;
      final isLoggedIn = tokens != null;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const HRDashboardScreen(),
      ),
      GoRoute(
        path: '/employees',
        builder: (_, __) => const EmployeesScreen(),
      ),
      GoRoute(
        path: '/attendance',
        builder: (_, __) => const AttendanceScreen(),
      ),
      GoRoute(
        path: '/payroll',
        builder: (_, __) => const PayrollScreen(),
      ),
      GoRoute(
        path: '/accounting',
        builder: (_, __) => const AccountingScreen(),
      ),
      GoRoute(
        path: '/accounting/rules',
        builder: (_, __) => const SalaryRulesScreen(),
      ),
      GoRoute(
        path: '/accounting/reports',
        builder: (_, __) => const SalaryReportsScreen(),
      ),
      GoRoute(
        path: '/accounting/expenses',
        builder: (_, __) => ExpensesScreen(),
      ),
      GoRoute(
        path: '/hr/assets',
        builder: (_, __) => AssetsScreen(),
      ),
    ],
  );
});
