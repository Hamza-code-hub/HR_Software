class HRDashboardStats {
  final int totalEmployees;
  final int activeEmployees;
  final int presentToday;
  final int onLeave;
  final int lateToday;
  final int remoteToday;
  final double monthlyPayroll;
  final int pendingLeaveApprovals;
  final int openPositions;
  final double avgAttendance;
  final double employeeGrowth;
  final int pendingContracts;
  final int expiredContracts;
  final int overtimeHours;
  final int onboardingInProgress;
  final int performanceReviewsDue;
  final int trainingCompleted;
  final int assetsPending;
  final int pendingResignations;
  final int pendingOfferLetters;
  final int activeRecruitment;
  final int interviewsScheduled;

  HRDashboardStats({
    required this.totalEmployees,
    required this.activeEmployees,
    required this.presentToday,
    required this.onLeave,
    required this.lateToday,
    required this.remoteToday,
    required this.monthlyPayroll,
    required this.pendingLeaveApprovals,
    required this.openPositions,
    required this.avgAttendance,
    required this.employeeGrowth,
    required this.pendingContracts,
    required this.expiredContracts,
    required this.overtimeHours,
    required this.onboardingInProgress,
    required this.performanceReviewsDue,
    required this.trainingCompleted,
    required this.assetsPending,
    required this.pendingResignations,
    required this.pendingOfferLetters,
    required this.activeRecruitment,
    required this.interviewsScheduled,
  });

  factory HRDashboardStats.fromJson(Map<String, dynamic> json) {
    return HRDashboardStats(
      totalEmployees: json['total_employees'] ?? 0,
      activeEmployees: json['active_employees'] ?? 0,
      presentToday: json['present_today'] ?? 0,
      onLeave: json['on_leave'] ?? 0,
      lateToday: json['late_today'] ?? 0,
      remoteToday: json['remote_today'] ?? 0,
      monthlyPayroll: (json['monthly_payroll'] ?? 0).toDouble(),
      pendingLeaveApprovals: json['pending_leave_approvals'] ?? 0,
      openPositions: json['open_positions'] ?? 0,
      avgAttendance: (json['avg_attendance'] ?? 0).toDouble(),
      employeeGrowth: (json['employee_growth'] ?? 0).toDouble(),
      pendingContracts: json['pending_contracts'] ?? 0,
      expiredContracts: json['expired_contracts'] ?? 0,
      overtimeHours: json['overtime_hours'] ?? 0,
      onboardingInProgress: json['onboarding_in_progress'] ?? 0,
      performanceReviewsDue: json['performance_reviews_due'] ?? 0,
      trainingCompleted: json['training_completed'] ?? 0,
      assetsPending: json['assets_pending'] ?? 0,
      pendingResignations: json['pending_resignations'] ?? 0,
      pendingOfferLetters: json['pending_offer_letters'] ?? 0,
      activeRecruitment: json['active_recruitment'] ?? 0,
      interviewsScheduled: json['interviews_scheduled'] ?? 0,
    );
  }
}

class AccountingDashboardStats {
  final double totalRevenueMTD;
  final double totalRevenueYTD;
  final double totalExpensesMTD;
  final double totalExpensesYTD;
  final double netProfitMTD;
  final double netProfitYTD;
  final double currentRatio;
  final double quickRatio;
  final int accountsPayableDays;
  final int accountsReceivableDays;
  final double workingCapital;
  final double cashBalance;

  AccountingDashboardStats({
    required this.totalRevenueMTD,
    required this.totalRevenueYTD,
    required this.totalExpensesMTD,
    required this.totalExpensesYTD,
    required this.netProfitMTD,
    required this.netProfitYTD,
    required this.currentRatio,
    required this.quickRatio,
    required this.accountsPayableDays,
    required this.accountsReceivableDays,
    required this.workingCapital,
    required this.cashBalance,
  });

  factory AccountingDashboardStats.fromJson(Map<String, dynamic> json) {
    return AccountingDashboardStats(
      totalRevenueMTD: (json['total_revenue_mtd'] ?? 0).toDouble(),
      totalRevenueYTD: (json['total_revenue_ytd'] ?? 0).toDouble(),
      totalExpensesMTD: (json['total_expenses_mtd'] ?? 0).toDouble(),
      totalExpensesYTD: (json['total_expenses_ytd'] ?? 0).toDouble(),
      netProfitMTD: (json['net_profit_mtd'] ?? 0).toDouble(),
      netProfitYTD: (json['net_profit_ytd'] ?? 0).toDouble(),
      currentRatio: (json['current_ratio'] ?? 0).toDouble(),
      quickRatio: (json['quick_ratio'] ?? 0).toDouble(),
      accountsPayableDays: json['accounts_payable_days'] ?? 0,
      accountsReceivableDays: json['accounts_receivable_days'] ?? 0,
      workingCapital: (json['working_capital'] ?? 0).toDouble(),
      cashBalance: (json['cash_balance'] ?? 0).toDouble(),
    );
  }
}
