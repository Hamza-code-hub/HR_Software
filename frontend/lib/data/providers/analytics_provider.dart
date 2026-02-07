import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/dashboard_stats.dart';

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// HR Dashboard Stats Provider
final hrDashboardStatsProvider = FutureProvider<HRDashboardStats>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  
  try {
    final response = await apiService.getHRDashboardStats();
    
    if (response['success'] == true && response['data'] != null) {
      return HRDashboardStats.fromJson(response['data']);
    } else {
      throw Exception('Failed to load HR dashboard stats');
    }
  } catch (e) {
    // Return mock data as fallback
    return HRDashboardStats(
      totalEmployees: 245,
      activeEmployees: 238,
      presentToday: 212,
      onLeave: 15,
      lateToday: 11,
      remoteToday: 8,
      monthlyPayroll: 12500000,
      pendingLeaveApprovals: 8,
      openPositions: 5,
      avgAttendance: 94.2,
      employeeGrowth: 12.5,
      pendingContracts: 4,
      expiredContracts: 2,
      overtimeHours: 156,
      onboardingInProgress: 3,
      performanceReviewsDue: 12,
      trainingCompleted: 45,
      assetsPending: 3,
      pendingResignations: 2,
      pendingOfferLetters: 3,
      activeRecruitment: 8,
      interviewsScheduled: 12,
    );
  }
});

// Accounting Dashboard Stats Provider
final accountingDashboardStatsProvider = FutureProvider<AccountingDashboardStats>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  
  try {
    final response = await apiService.getAccountingDashboardStats();
    
    if (response['success'] == true && response['data'] != null) {
      return AccountingDashboardStats.fromJson(response['data']);
    } else {
      throw Exception('Failed to load accounting dashboard stats');
    }
  } catch (e) {
    // Return mock data as fallback
    return AccountingDashboardStats(
      totalRevenueMTD: 8500000,
      totalRevenueYTD: 95000000,
      totalExpensesMTD: 6200000,
      totalExpensesYTD: 72000000,
      netProfitMTD: 2300000,
      netProfitYTD: 23000000,
      currentRatio: 2.5,
      quickRatio: 1.8,
      accountsPayableDays: 45,
      accountsReceivableDays: 32,
      workingCapital: 15000000,
      cashBalance: 8200000,
    );
  }
});

// Auto-refresh provider (refreshes every 30 seconds)
final autoRefreshProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(
    const Duration(seconds: 30),
    (_) => DateTime.now(),
  );
});
