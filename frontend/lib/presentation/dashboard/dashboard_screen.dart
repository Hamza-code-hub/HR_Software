import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'widgets/hr_actions/pending_approvals_widget.dart';
import 'widgets/hr_actions/contract_expiry_alerts_widget.dart';
import 'widgets/hr_actions/performance_review_due_widget.dart';
import 'widgets/attendance_intelligence/absenteeism_trend_chart.dart';
import 'widgets/attendance_intelligence/department_attendance_chart.dart';
import 'widgets/attendance_intelligence/wfh_onsite_ratio_widget.dart';
import 'widgets/employee_lifecycle/new_joiners_widget.dart';
import 'widgets/employee_lifecycle/attrition_rate_widget.dart';
import 'widgets/employee_lifecycle/probation_vs_confirmed_widget.dart';
import 'widgets/recruitment_funnel_chart.dart';

// ============================================================================
// FULLY RESPONSIVE HR DASHBOARD - PRODUCTION READY
// ============================================================================
// Features:
// ✅ 5 Responsive Breakpoints (Ultra-Wide to Mobile)
// ✅ IntrinsicHeight for Equal Card Heights
// ✅ Hamburger Menu with Full Sidebar
// ✅ ConstrainedBox for Max-Width Control
// ✅ LayoutBuilder for Dynamic Sizing
// ✅ Perfect Grid System
// ✅ Zero Empty Spaces
// ============================================================================

// Navigation state providers
final selectedMenuProvider = StateProvider<String>((ref) => 'dashboard');
final expandedMenuProvider = StateProvider<Set<String>>((ref) => {});

// Mock providers for HR data
final hrDashboardStatsProvider = Provider<HRDashboardStats>((ref) {
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
});

final hrAttendanceTrendProvider = Provider<List<AttendanceData>>((ref) {
  return [
    AttendanceData('Mon', 95.2, 8, 200),
    AttendanceData('Tue', 92.8, 11, 198),
    AttendanceData('Wed', 94.5, 7, 201),
    AttendanceData('Thu', 91.0, 14, 195),
    AttendanceData('Fri', 88.5, 18, 190),
    AttendanceData('Sat', 45.2, 5, 98),
  ];
});

final hrDepartmentDistributionProvider = Provider<List<DepartmentData>>((ref) {
  return [
    DepartmentData('Engineering', 85, const Color(0xFF0EA5E9)),
    DepartmentData('Design', 28, const Color(0xFFEC4899)),
    DepartmentData('Marketing', 35, const Color(0xFF10B981)),
    DepartmentData('Sales', 42, const Color(0xFFF59E0B)),
    DepartmentData('HR & Admin', 25, const Color(0xFF8B5CF6)),
    DepartmentData('Finance', 18, const Color(0xFF06B6D4)),
  ];
});

final hrRecentActivitiesProvider = Provider<List<ActivityItem>>((ref) {
  return [
    ActivityItem(
      icon: Icons.person_add,
      title: 'New Employee Onboarded',
      description: 'Sarah Johnson joined Engineering team',
      time: '2 hours ago',
      color: const Color(0xFF10B981),
    ),
    ActivityItem(
      icon: Icons.description,
      title: 'Contract Generated',
      description: 'Employment contract for John Doe',
      time: '3 hours ago',
      color: const Color(0xFF0EA5E9),
    ),
    ActivityItem(
      icon: Icons.event_busy,
      title: 'Leave Request Approved',
      description: 'Annual Leave (5 days) - Mike Smith',
      time: '4 hours ago',
      color: const Color(0xFFF59E0B),
    ),
    ActivityItem(
      icon: Icons.mail,
      title: 'Offer Letter Sent',
      description: 'Senior Developer - Jane Wilson',
      time: '5 hours ago',
      color: const Color(0xFFEC4899),
    ),
  ];
});

final upcomingEventsProvider = Provider<List<CalendarEvent>>((ref) {
  return [
    CalendarEvent('Team Meeting', DateTime.now().add(const Duration(hours: 2)), const Color(0xFF0EA5E9), Icons.groups),
    CalendarEvent('Performance Review', DateTime.now().add(const Duration(days: 1)), const Color(0xFFEC4899), Icons.assessment),
    CalendarEvent('Training Session', DateTime.now().add(const Duration(days: 2)), const Color(0xFF10B981), Icons.school),
    CalendarEvent('Payroll Processing', DateTime.now().add(const Duration(days: 5)), const Color(0xFF8B5CF6), Icons.payment),
  ];
});

class HRDashboardScreen extends ConsumerStatefulWidget {
  const HRDashboardScreen({super.key});

  @override
  ConsumerState<HRDashboardScreen> createState() => _HRDashboardScreenState();
}

class _HRDashboardScreenState extends ConsumerState<HRDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Collapsible sections state
  bool _showEmployeeLifecycle = true;
  bool _showAttendanceAnalytics = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToScreen(String routeName) {
    ref.read(selectedMenuProvider.notifier).state = routeName;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('Navigating to ${routeName.toUpperCase()}'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _toggleMenu(String menuId) {
    final expandedMenus = ref.read(expandedMenuProvider);
    final newSet = Set<String>.from(expandedMenus);
    
    if (newSet.contains(menuId)) {
      newSet.remove(menuId);
    } else {
      newSet.add(menuId);
    }
    
    ref.read(expandedMenuProvider.notifier).state = newSet;
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(hrDashboardStatsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Enhanced responsive breakpoints
    final isUltraWide = screenWidth > 1920;
    final isWide = screenWidth > 1600 && screenWidth <= 1920;
    final isDesktop = screenWidth > 1200 && screenWidth <= 1600;
    final isTablet = screenWidth > 768 && screenWidth <= 1200;
    final isMobile = screenWidth <= 768;

    // Dynamic spacing based on screen size
    final sidePadding = isUltraWide ? 32.0 : (isWide ? 28.0 : (isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)));
    final cardSpacing = isUltraWide ? 20.0 : (isWide ? 18.0 : (isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0)));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(context),
          Expanded(
            child: Column(
              children: [
                _buildAppBar(context, isMobile),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.all(sidePadding),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isUltraWide ? 2400 : double.infinity,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Welcome Banner
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: _buildWelcomeBanner(isDesktop || isWide || isUltraWide),
                              ),
                              SizedBox(height: cardSpacing),

                              // Main Content Area with 75/25 Split (only for top 2 rows)
                              if (isDesktop || isWide || isUltraWide || isTablet)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // Top Row: 3 Key Cards
                                          FadeTransition(
                                            opacity: _fadeAnimation,
                                            child: _buildTopStatsCards(stats, screenWidth, cardSpacing),
                                          ),
                                          SizedBox(height: cardSpacing),

                                          // Second Row: 3 Cards (Open Positions + 2 new)
                                          FadeTransition(
                                            opacity: _fadeAnimation,
                                            child: _buildSecondRowStats(stats, screenWidth, cardSpacing),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: cardSpacing),
                                    // Right Side: 25% - Calendar (aligned with top 2 rows)
                                    Expanded(
                                      flex: 1,
                                      child: FadeTransition(
                                        opacity: _fadeAnimation,
                                        child: _buildMiniCalendarWidget(),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                // Mobile: Top 2 rows first
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: _buildTopStatsCards(stats, screenWidth, cardSpacing),
                                    ),
                                    SizedBox(height: cardSpacing),
                                    FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: _buildSecondRowStats(stats, screenWidth, cardSpacing),
                                    ),
                                    SizedBox(height: cardSpacing),
                                  ],
                                ),
                              SizedBox(height: cardSpacing),

                              // Below rows: Calendar on mobile, full width sections
                              if (isMobile)
                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: _buildMiniCalendarWidget(),
                                ),
                              
                              if (isMobile)
                                SizedBox(height: cardSpacing),

                              // Recent Activities & Upcoming Events 
                              if (isDesktop || isWide || isUltraWide || isTablet)
                                // Desktop/Tablet: Side by Side
                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildRecentActivitiesCompact(),
                                      ),
                                      SizedBox(width: cardSpacing),
                                      Expanded(
                                        child: _buildAttractiveUpcomingEventsCompact(cardSpacing),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                // Mobile: Stacked
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: _buildRecentActivitiesCompact(),
                                    ),
                                    SizedBox(height: cardSpacing),
                                    FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: _buildAttractiveUpcomingEventsCompact(cardSpacing),
                                    ),
                                  ],
                                ),
                              SizedBox(height: cardSpacing),

                              // HR Actions
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: _buildHRActionsSection(isDesktop, isWide, isUltraWide, isTablet, cardSpacing),
                              ),
                              SizedBox(height: cardSpacing),

                              // Key Metrics
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: _buildKeyMetrics(stats, isDesktop, isWide, isUltraWide, isTablet, cardSpacing),
                              ),
                              SizedBox(height: cardSpacing),

                              // Employee Lifecycle Analytics - Collapsible
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: _buildEmployeeLifecycleSection(isDesktop, isWide, isUltraWide, isTablet, cardSpacing),
                              ),
                              SizedBox(height: cardSpacing),

                              // Attendance Analytics - Collapsible
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: _buildAttendanceAnalyticsSection(isDesktop, isWide, isUltraWide, isTablet, cardSpacing),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildStatusBar(),
              ],
            ),
          ),
        ],
      ),
      drawer: isMobile ? Drawer(child: _buildSidebar(context)) : null,
    );
  }

  // Top Stats Cards Only (Calendar is separate on right)
  Widget _buildTopStatsCards(HRDashboardStats stats, double screenWidth, double spacing) {
    int crossAxisCount;
    double childAspectRatio;

    if (screenWidth > 1920) {
      crossAxisCount = 3;
      childAspectRatio = 1.8;
    } else if (screenWidth > 1600) {
      crossAxisCount = 3;
      childAspectRatio = 1.75;
    } else if (screenWidth > 1200) {
      crossAxisCount = 3;
      childAspectRatio = 1.7;
    } else if (screenWidth > 900) {
      crossAxisCount = 2;
      childAspectRatio = 1.85;
    } else if (screenWidth > 600) {
      crossAxisCount = 1;
      childAspectRatio = 2.6;
    } else {
      crossAxisCount = 1;
      childAspectRatio = 2.8;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
      children: [
        _StatCard(
          title: 'Total Employees',
          value: stats.totalEmployees.toString(),
          subtitle: '${stats.activeEmployees} active',
          icon: Icons.people_rounded,
          color: const Color(0xFF0EA5E9),
          trend: stats.employeeGrowth,
          trendLabel: 'from last month',
          priority: 'normal',
        ),
        _StatCard(
          title: 'Present Today',
          value: stats.presentToday.toString(),
          subtitle: '${stats.avgAttendance.toStringAsFixed(1)}% attendance',
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF10B981),
          trend: 2.4,
          trendLabel: 'vs yesterday',
          priority: 'normal',
        ),
        _StatCard(
          title: 'On Leave',
          value: stats.onLeave.toString(),
          subtitle: '${stats.pendingLeaveApprovals} pending',
          icon: Icons.event_busy_rounded,
          color: const Color(0xFFF59E0B),
          priority: stats.pendingLeaveApprovals > 5 ? 'urgent' : 'warning',
          isAlert: stats.pendingLeaveApprovals > 5,
        ),
      ],
    );
  }

  // Second Row Stats - Open Positions + 2 new cards
  Widget _buildSecondRowStats(HRDashboardStats stats, double screenWidth, double spacing) {
    int crossAxisCount;
    double childAspectRatio;

    if (screenWidth > 1920) {
      crossAxisCount = 3;
      childAspectRatio = 1.85;
    } else if (screenWidth > 1200) {
      crossAxisCount = 3;
      childAspectRatio = 1.75;
    } else if (screenWidth > 900) {
      crossAxisCount = 2;
      childAspectRatio = 1.9;
    } else if (screenWidth > 600) {
      crossAxisCount = 1;
      childAspectRatio = 2.7;
    } else {
      crossAxisCount = 1;
      childAspectRatio = 2.9;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
      children: [
        _StatCard(
          title: 'Open Positions',
          value: stats.openPositions.toString(),
          subtitle: '${stats.activeRecruitment} active recruitment',
          icon: Icons.work_outline_rounded,
          color: const Color(0xFF8B5CF6),
          priority: 'normal',
        ),
        _StatCard(
          title: 'Pending Contracts',
          value: stats.pendingContracts.toString(),
          subtitle: '${stats.expiredContracts} expired',
          icon: Icons.description_rounded,
          color: const Color(0xFFEF4444),
          priority: stats.pendingContracts > 3 ? 'warning' : 'normal',
        ),
        _StatCard(
          title: 'Training Completed',
          value: stats.trainingCompleted.toString(),
          subtitle: 'This quarter',
          icon: Icons.school_rounded,
          color: const Color(0xFF10B981),
          trend: 15.5,
          trendLabel: 'vs last quarter',
          priority: 'normal',
        ),
      ],
    );
  }

  // Attractive Upcoming Events Section (Constrained for side-by-side layout)
  Widget _buildAttractiveUpcomingEvents(double spacing) {
    final events = ref.watch(upcomingEventsProvider);

    return Container(
      constraints: const BoxConstraints(maxHeight: 500),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attractive Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                  ),
                  child: const Icon(Icons.event_note, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upcoming Events',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${events.length} events',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Events List with Enhanced Styling - Scrollable
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available, 
                            color: Colors.grey[300], 
                            size: 48
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No upcoming events',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: events.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 12,
                        color: Colors.grey[200],
                      ),
                      itemBuilder: (context, index) {
                        return _buildAttractiveEventItem(events[index], index);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttractiveEventItem(CalendarEvent event, int index) {
    final now = DateTime.now();
    final difference = event.date.difference(now);
    final hours = difference.inHours;
    final days = difference.inDays;
    
    String timeText;
    Color timeColor;
    IconData timeIcon;
    
    if (hours < 0) {
      timeText = 'Past';
      timeColor = Colors.grey;
      timeIcon = Icons.history;
    } else if (hours <= 2) {
      timeText = 'Started';
      timeColor = Colors.red;
      timeIcon = Icons.notifications_active;
    } else if (hours < 24) {
      timeText = 'Today';
      timeColor = Colors.orange;
      timeIcon = Icons.schedule;
    } else {
      timeText = '${days}d away';
      timeColor = Colors.blue;
      timeIcon = Icons.calendar_today;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              // Animated Icon Container
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [event.color, event.color.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: event.color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(event.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              
              // Event Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, hh:mm a').format(event.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: timeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: timeColor.withOpacity(0.4), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(timeIcon, size: 12, color: timeColor),
                    const SizedBox(width: 6),
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: timeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Calendar Row with IntrinsicHeight for equal heights
  Widget _buildCalendarRow(bool isDesktop, bool isWide, bool isUltraWide, bool isTablet, double spacing) {
    if (isDesktop || isWide || isUltraWide || isTablet) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildMiniCalendarWidget()),
            SizedBox(width: spacing),
            Expanded(child: _buildCompactCalendar()),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          _buildMiniCalendarWidget(),
          SizedBox(height: spacing),
          _buildCompactCalendar(),
        ],
      );
    }
  }

  // Quick Stats with proper grid
  Widget _buildQuickStats(HRDashboardStats stats, double screenWidth, double spacing) {
    int crossAxisCount;
    double childAspectRatio;
    
    if (screenWidth > 1920) {
      crossAxisCount = 4;
      childAspectRatio = 1.85;
    } else if (screenWidth > 1600) {
      crossAxisCount = 4;
      childAspectRatio = 1.75;
    } else if (screenWidth > 1200) {
      crossAxisCount = 4;
      childAspectRatio = 1.65;
    } else if (screenWidth > 900) {
      crossAxisCount = 2;
      childAspectRatio = 1.85;
    } else if (screenWidth > 600) {
      crossAxisCount = 2;
      childAspectRatio = 2.0;
    } else {
      crossAxisCount = 1;
      childAspectRatio = 2.8;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
      children: [
        _StatCard(
          title: 'Total Employees',
          value: stats.totalEmployees.toString(),
          subtitle: '${stats.activeEmployees} active',
          icon: Icons.people_rounded,
          color: const Color(0xFF0EA5E9),
          trend: stats.employeeGrowth,
          trendLabel: 'from last month',
          priority: 'normal',
        ),
        _StatCard(
          title: 'Present Today',
          value: stats.presentToday.toString(),
          subtitle: '${stats.avgAttendance.toStringAsFixed(1)}% attendance',
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF10B981),
          trend: 2.4,
          trendLabel: 'vs yesterday',
          priority: 'normal',
        ),
        _StatCard(
          title: 'On Leave',
          value: stats.onLeave.toString(),
          subtitle: '${stats.pendingLeaveApprovals} pending',
          icon: Icons.event_busy_rounded,
          color: const Color(0xFFF59E0B),
          priority: stats.pendingLeaveApprovals > 5 ? 'urgent' : 'warning',
          isAlert: stats.pendingLeaveApprovals > 5,
        ),
        _StatCard(
          title: 'Open Positions',
          value: stats.openPositions.toString(),
          subtitle: '${stats.activeRecruitment} active',
          icon: Icons.work_outline_rounded,
          color: const Color(0xFF8B5CF6),
          priority: 'normal',
        ),
      ],
    );
  }

  // HR Actions with equal heights
  Widget _buildHRActionsSection(bool isDesktop, bool isWide, bool isUltraWide, bool isTablet, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('HR Actions Required', Icons.bolt_rounded, const Color(0xFFF59E0B)),
        SizedBox(height: spacing),
        if (isDesktop || isWide || isUltraWide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: PendingApprovalsWidget()),
                SizedBox(width: spacing),
                const Expanded(child: ContractExpiryAlertsWidget()),
                SizedBox(width: spacing),
                const Expanded(child: PerformanceReviewDueWidget()),
              ],
            ),
          )
        else if (isTablet)
          Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(child: PendingApprovalsWidget()),
                    SizedBox(width: spacing),
                    const Expanded(child: ContractExpiryAlertsWidget()),
                  ],
                ),
              ),
              SizedBox(height: spacing),
              const PerformanceReviewDueWidget(),
            ],
          )
        else
          Column(
            children: [
              const PendingApprovalsWidget(),
              SizedBox(height: spacing),
              const ContractExpiryAlertsWidget(),
              SizedBox(height: spacing),
              const PerformanceReviewDueWidget(),
            ],
          ),
      ],
    );
  }

  // Analytics Section with equal heights
  // Employee Lifecycle Analytics - Collapsible
  Widget _buildEmployeeLifecycleSection(bool isDesktop, bool isWide, bool isUltraWide, bool isTablet, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Collapsible Header
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _showEmployeeLifecycle = !_showEmployeeLifecycle;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.people_outline_rounded, color: Color(0xFF10B981), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Employee Lifecycle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Icon(
                    _showEmployeeLifecycle ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ),
        
        if (_showEmployeeLifecycle) ...[
          SizedBox(height: spacing),
          // Lifecycle Row
          if (isDesktop || isWide || isUltraWide)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(child: NewJoinersWidget()),
                  SizedBox(width: spacing),
                  const Expanded(child: AttritionRateWidget()),
                  SizedBox(width: spacing),
                  const Expanded(child: ProbationVsConfirmedWidget()),
                ],
              ),
            )
          else
            Column(
              children: [
                const NewJoinersWidget(),
                SizedBox(height: spacing),
                const AttritionRateWidget(),
                SizedBox(height: spacing),
                const ProbationVsConfirmedWidget(),
              ],
            ),
        ],
      ],
    );
  }

  // Attendance Analytics - Collapsible
  Widget _buildAttendanceAnalyticsSection(bool isDesktop, bool isWide, bool isUltraWide, bool isTablet, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Collapsible Header
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _showAttendanceAnalytics = !_showAttendanceAnalytics;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.trending_up_rounded, color: Color(0xFF0EA5E9), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Attendance Analytics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Icon(
                    _showAttendanceAnalytics ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ),
        
        if (_showAttendanceAnalytics) ...[
          SizedBox(height: spacing),
          // Attendance Row
          if (isDesktop || isWide || isUltraWide || isTablet)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(flex: 3, child: AbsenteeismTrendChart()),
                  SizedBox(width: spacing),
                  const Expanded(flex: 2, child: WfhOnsiteRatioWidget()),
                ],
              ),
            )
          else
            Column(
              children: [
                const AbsenteeismTrendChart(),
                SizedBox(height: spacing),
                const WfhOnsiteRatioWidget(),
              ],
            ),
          
          SizedBox(height: spacing),

          // Charts Row
          if (isDesktop || isWide || isUltraWide || isTablet)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(child: DepartmentAttendanceChart()),
                  SizedBox(width: spacing),
                  Expanded(
                    child: RecruitmentFunnelChart(
                      data: [
                        FunnelStage(stage: 'Applications', count: 450, percentage: 100),
                        FunnelStage(stage: 'Screening', count: 180, percentage: 40),
                        FunnelStage(stage: 'Interviews', count: 45, percentage: 10),
                        FunnelStage(stage: 'Offers', count: 12, percentage: 2.6),
                        FunnelStage(stage: 'Hired', count: 8, percentage: 1.7),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                const DepartmentAttendanceChart(),
                SizedBox(height: spacing),
                RecruitmentFunnelChart(
                  data: [
                    FunnelStage(stage: 'Applications', count: 450, percentage: 100),
                    FunnelStage(stage: 'Screening', count: 180, percentage: 40),
                    FunnelStage(stage: 'Interviews', count: 45, percentage: 10),
                    FunnelStage(stage: 'Offers', count: 12, percentage: 2.6),
                    FunnelStage(stage: 'Hired', count: 8, percentage: 1.7),
                  ],
                ),
              ],
            ),
        ],
      ],
    );
  }

  Widget _buildAnalyticsSection(bool isDesktop, bool isWide, bool isUltraWide, bool isTablet, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Organizational Intelligence', Icons.insights_rounded, const Color(0xFF0EA5E9)),
        SizedBox(height: spacing),
        
        // Lifecycle Row
        if (isDesktop || isWide || isUltraWide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: NewJoinersWidget()),
                SizedBox(width: spacing),
                const Expanded(child: AttritionRateWidget()),
                SizedBox(width: spacing),
                const Expanded(child: ProbationVsConfirmedWidget()),
              ],
            ),
          )
        else
          Column(
            children: [
              const NewJoinersWidget(),
              SizedBox(height: spacing),
              const AttritionRateWidget(),
              SizedBox(height: spacing),
              const ProbationVsConfirmedWidget(),
            ],
          ),
        
        SizedBox(height: spacing),

        // Attendance Row
        if (isDesktop || isWide || isUltraWide || isTablet)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(flex: 3, child: AbsenteeismTrendChart()),
                SizedBox(width: spacing),
                const Expanded(flex: 2, child: WfhOnsiteRatioWidget()),
              ],
            ),
          )
        else
          Column(
            children: [
              const AbsenteeismTrendChart(),
              SizedBox(height: spacing),
              const WfhOnsiteRatioWidget(),
            ],
          ),
        
        SizedBox(height: spacing),

        // Charts Row
        if (isDesktop || isWide || isUltraWide || isTablet)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: DepartmentAttendanceChart()),
                SizedBox(width: spacing),
                Expanded(
                  child: RecruitmentFunnelChart(
                    data: [
                      FunnelStage(stage: 'Applications', count: 450, percentage: 100),
                      FunnelStage(stage: 'Screening', count: 180, percentage: 40),
                      FunnelStage(stage: 'Interviews', count: 45, percentage: 10),
                      FunnelStage(stage: 'Offers', count: 12, percentage: 2.6),
                      FunnelStage(stage: 'Hired', count: 8, percentage: 1.7),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              const DepartmentAttendanceChart(),
              SizedBox(height: spacing),
              RecruitmentFunnelChart(
                data: [
                  FunnelStage(stage: 'Applications', count: 450, percentage: 100),
                  FunnelStage(stage: 'Screening', count: 180, percentage: 40),
                  FunnelStage(stage: 'Interviews', count: 45, percentage: 10),
                  FunnelStage(stage: 'Offers', count: 12, percentage: 2.6),
                  FunnelStage(stage: 'Hired', count: 8, percentage: 1.7),
                ],
              ),
            ],
          ),
      ],
    );
  }

  // Key Metrics with equal heights
  Widget _buildKeyMetrics(HRDashboardStats stats, bool isDesktop, bool isWide, bool isUltraWide, bool isTablet, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Key Performance Metrics', Icons.dashboard_rounded, const Color(0xFF8B5CF6)),
        SizedBox(height: spacing),
        if (isDesktop || isWide || isUltraWide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildMetricCard('Monthly Payroll', 'PKR ${_formatCurrency(stats.monthlyPayroll)}', Icons.account_balance_wallet, const Color(0xFF8B5CF6), '${stats.activeEmployees} employees')),
                SizedBox(width: spacing),
                Expanded(child: _buildMetricCard('Overtime Hours', '${stats.overtimeHours} hrs', Icons.access_time_filled, const Color(0xFFF59E0B), 'This month')),
                SizedBox(width: spacing),
                Expanded(child: _buildMetricCard('Pending Contracts', '${stats.pendingContracts}', Icons.description, const Color(0xFFEF4444), 'Need signature')),
                SizedBox(width: spacing),
                Expanded(child: _buildMetricCard('Training Completed', '${stats.trainingCompleted}', Icons.school, const Color(0xFF10B981), 'This quarter')),
              ],
            ),
          )
        else
          Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildMetricCard('Monthly Payroll', 'PKR ${_formatCurrency(stats.monthlyPayroll)}', Icons.account_balance_wallet, const Color(0xFF8B5CF6), '${stats.activeEmployees} employees')),
                    SizedBox(width: spacing),
                    Expanded(child: _buildMetricCard('Overtime Hours', '${stats.overtimeHours} hrs', Icons.access_time_filled, const Color(0xFFF59E0B), 'This month')),
                  ],
                ),
              ),
              SizedBox(height: spacing),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildMetricCard('Pending Contracts', '${stats.pendingContracts}', Icons.description, const Color(0xFFEF4444), 'Need signature')),
                    SizedBox(width: spacing),
                    Expanded(child: _buildMetricCard('Training Completed', '${stats.trainingCompleted}', Icons.school, const Color(0xFF10B981), 'This quarter')),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  // Bottom Section with equal heights
  Widget _buildBottomSection(bool isDesktop, bool isWide, bool isUltraWide, bool isTablet, double spacing) {
    if (isDesktop || isWide || isUltraWide || isTablet) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildQuickActions()),
            SizedBox(width: spacing),
            Expanded(child: _buildRecentActivities()),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          _buildQuickActions(),
          SizedBox(height: spacing),
          _buildRecentActivities(),
        ],
      );
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeBanner(bool isLargeScreen) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting = 'Good Morning';
    IconData greetingIcon = Icons.wb_sunny;
    
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny_outlined;
    } else if (hour >= 17) {
      greeting = 'Good Evening';
      greetingIcon = Icons.nights_stay;
    }

    return Container(
      padding: EdgeInsets.all(isLargeScreen ? 24 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(greetingIcon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, Admin! 👋',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 26 : 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Here\'s your HR overview for today',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 15 : 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildInfoChip(Icons.calendar_today, DateFormat('EEE, MMM d').format(now)),
              _buildInfoChip(Icons.access_time, DateFormat('hh:mm a').format(now)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCalendarWidget() {
    final screenWidth = MediaQuery.of(context).size.width;
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday;
    final events = ref.watch(upcomingEventsProvider);
    
    // Calculate stats
    int eventsThisMonth = events.where((e) {
      return e.date.month == now.month && e.date.year == now.year;
    }).length;
    
    // Hide calendar on mobile
    if (screenWidth <= 768) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 380),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attractive Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Month and navigation row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(now),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEE, MMM dd').format(now),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildCompactNavButton(Icons.chevron_left),
                        const SizedBox(width: 6),
                        _buildCompactNavButton(Icons.chevron_right),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Quick stats row - responsive
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 45,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              eventsThisMonth.toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Events',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 45,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${daysInMonth}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Days',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 50,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${((now.day / daysInMonth) * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Progress',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Calendar Grid
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Weekday Headers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                      .map((day) => Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),

                // Calendar Grid
                ...List.generate(
                  ((daysInMonth + startWeekday - 1) / 7).ceil(),
                  (week) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        7,
                        (day) {
                          final dayNum = week * 7 + day + 2 - startWeekday;
                          final isToday = dayNum == now.day;
                          final isValidDay = dayNum > 0 && dayNum <= daysInMonth;
                          
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 1),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: isToday
                                        ? const LinearGradient(
                                            colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                                          )
                                        : null,
                                    color: isToday ? null : (isValidDay ? Colors.grey[50] : Colors.transparent),
                                    borderRadius: BorderRadius.circular(6),
                                    border: !isToday && isValidDay ? Border.all(color: Colors.grey[200]!, width: 0.5) : null,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: isValidDay ? () {} : null,
                                      borderRadius: BorderRadius.circular(6),
                                      child: Center(
                                        child: Text(
                                          isValidDay ? dayNum.toString() : '',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                                            color: isToday ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactNavButton(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.white.withOpacity(0.2),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  Widget _buildCompactCalendar() {
    final events = ref.watch(upcomingEventsProvider);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compact Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.event_note, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upcoming Events',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${events.length} upcoming',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Events List
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: events.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(Icons.event_available, 
                              color: Colors.grey[300], 
                              size: 32
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No upcoming events',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  : List.generate(events.length, (index) {
                      final event = events[index];
                      final isLast = index == events.length - 1;
                      return Column(
                        children: [
                          _buildCompactEventItem(event),
                          if (!isLast) 
                            Divider(height: 1, color: Colors.grey[200], indent: 50, endIndent: 16),
                        ],
                      );
                    }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flash_on, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionButton('Add Employee', Icons.person_add_rounded, const Color(0xFF0EA5E9), () => _navigateToScreen('add_employee')),
          const SizedBox(height: 12),
          _buildActionButton('Generate Offer', Icons.mail_rounded, const Color(0xFFEC4899), () => _navigateToScreen('offer_letters')),
          const SizedBox(height: 12),
          _buildActionButton('Create Contract', Icons.description_rounded, const Color(0xFF10B981), () => _navigateToScreen('contracts')),
          const SizedBox(height: 12),
          _buildActionButton('Process Payroll', Icons.account_balance_wallet_rounded, const Color(0xFF8B5CF6), () => _navigateToScreen('process_payroll')),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    final activities = ref.watch(hrRecentActivitiesProvider);

    return Container(
      constraints: const BoxConstraints(maxHeight: 500),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recent Activities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: activities.length,
              separatorBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Colors.grey[200], height: 1),
              ),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: activity.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(activity.icon, color: activity.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activity.description,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      activity.time,
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Compact version for side-by-side layout with fixed height
  Widget _buildRecentActivitiesCompact() {
    final activities = ref.watch(hrRecentActivitiesProvider);

    return Container(
      height: 380,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Recent Activities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              itemCount: activities.length > 6 ? 6 : activities.length,
              separatorBuilder: (context, index) => Divider(
                height: 12,
                color: Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: activity.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(activity.icon, color: activity.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activity.description,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Compact version for side-by-side layout (no constraints)
  Widget _buildAttractiveUpcomingEventsCompact(double spacing) {
    final events = ref.watch(upcomingEventsProvider);

    return Container(
      height: 380,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Attractive Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                  ),
                  child: const Icon(Icons.event_note, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upcoming Events',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${events.length} events',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Events List
          if (events.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_available, 
                      color: Colors.grey[300], 
                      size: 40
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No upcoming events',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: events.length,
                separatorBuilder: (context, index) => Divider(
                  height: 12,
                  color: Colors.grey[200],
                ),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _buildCompactEventItem(event);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactEventItem(CalendarEvent event) {
    final now = DateTime.now();
    final difference = event.date.difference(now);
    final hours = difference.inHours;
    final days = difference.inDays;
    
    String timeText;
    Color timeColor;
    
    if (hours < 0) {
      timeText = 'Past';
      timeColor = Colors.grey;
    } else if (hours <= 2) {
      timeText = 'Soon';
      timeColor = Colors.red;
    } else if (hours < 24) {
      timeText = 'Today';
      timeColor = Colors.orange;
    } else {
      timeText = '${days}d';
      timeColor = Colors.blue;
    }

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [event.color, event.color.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(event.icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMM dd, hh:mm a').format(event.date),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: timeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: timeColor.withOpacity(0.3), width: 0.5),
          ),
          child: Text(
            timeText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: timeColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildStatusItem(Icons.cloud_done, 'Online', const Color(0xFF10B981)),
          const SizedBox(width: 24),
          _buildStatusItem(Icons.people, '238 Users', const Color(0xFF0EA5E9)),
          const Spacer(),
          Text(
            'Updated: ${DateFormat('hh:mm a').format(DateTime.now())}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, bool isMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768 && screenWidth <= 1200;
    final isCompactDesktop = screenWidth > 1200 && screenWidth <= 1400;
    
    // Responsive sizing
    final logoSize = isMobile ? 0.0 : (isTablet ? 32.0 : 40.0);
    final titleFontSize = isMobile ? 14.0 : (isTablet ? 16.0 : (isCompactDesktop ? 18.0 : 20.0));
    final iconSize = isMobile ? 20.0 : 22.0;
    final horizontalPadding = isMobile ? 12.0 : isTablet ? 14.0 : 16.0;

    return Container(
      height: 70,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF0EA5E9), Color(0xFF06B6D4)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              // Menu button or logo
              if (isMobile)
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                    onPressed: () {
                      try {
                        Scaffold.of(context).openDrawer();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Menu unavailable'), duration: Duration(seconds: 1)),
                        );
                      }
                    },
                  ),
                )
              else if (logoSize > 0)
                SizedBox(
                  width: logoSize,
                  height: logoSize,
                  child: Image.asset(
                    'assets/images/CyberZeus Logo Final.png',
                    fit: BoxFit.contain,
                  ),
                ),
              
              // Title
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: Text(
                  isMobile ? 'HR System' : 'HR Management System',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Action icons
              if (!isMobile) ...[
                SizedBox(width: isTablet ? 6 : 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Badge(
                      label: const Text('8', style: TextStyle(fontSize: 9)),
                      backgroundColor: const Color(0xFFEF4444),
                      child: Icon(Icons.notifications_outlined, color: Colors.white, size: iconSize),
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 6 : 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.settings_outlined, color: Colors.white, size: iconSize),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // SIDEBAR WITH COMPREHENSIVE MENU
  Widget _buildSidebar(BuildContext context) {
    final selectedMenu = ref.watch(selectedMenuProvider);
    final expandedMenus = ref.watch(expandedMenuProvider);

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/CyberZeus Logo Final.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Human Resource\nManagement',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1, thickness: 1),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSidebarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Admin Dashboard',
                  isActive: selectedMenu == 'dashboard',
                  onTap: () => _navigateToScreen('dashboard'),
                ),
                _buildSidebarItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: selectedMenu == 'profile',
                  onTap: () => _navigateToScreen('profile'),
                ),
                _buildSidebarItem(
                  icon: Icons.request_page_rounded,
                  label: 'Requirement Raising',
                  isActive: selectedMenu == 'requirement',
                  hasSubmenu: true,
                  isExpanded: expandedMenus.contains('requirement'),
                  onTap: () => _toggleMenu('requirement'),
                ),
                if (expandedMenus.contains('requirement')) ...[
                  _buildSidebarSubItem(
                    icon: Icons.add_circle_outline,
                    label: 'Create Requirement',
                    onTap: () => _navigateToScreen('create_requirement'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.list_alt,
                    label: 'View Requirements',
                    onTap: () => _navigateToScreen('view_requirements'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.approval,
                    label: 'Approve Requirements',
                    onTap: () => _navigateToScreen('approve_requirements'),
                  ),
                ],
                _buildSidebarItem(
                  icon: Icons.work_rounded,
                  label: 'Recruitment',
                  isActive: selectedMenu == 'recruitment',
                  hasSubmenu: true,
                  isExpanded: expandedMenus.contains('recruitment'),
                  onTap: () => _toggleMenu('recruitment'),
                ),
                if (expandedMenus.contains('recruitment')) ...[
                  _buildSidebarSubItem(
                    icon: Icons.post_add,
                    label: 'Job Postings',
                    onTap: () => _navigateToScreen('job_postings'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.people_outline,
                    label: 'Candidates',
                    onTap: () => _navigateToScreen('candidates'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.calendar_today,
                    label: 'Schedule Interview',
                    onTap: () => _navigateToScreen('schedule_interview'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.assessment,
                    label: 'Interview Feedback',
                    onTap: () => _navigateToScreen('interview_feedback'),
                  ),
                ],
                
                _buildSidebarItem(
                  icon: Icons.group_add_rounded,
                  label: 'New Joinings',
                  isActive: selectedMenu == 'new_joinings',
                  hasSubmenu: true,
                  isExpanded: expandedMenus.contains('new_joinings'),
                  onTap: () => _toggleMenu('new_joinings'),
                ),
                if (expandedMenus.contains('new_joinings')) ...[
                  _buildSidebarSubItem(
                    icon: Icons.person_add_alt_rounded,
                    label: 'Shortlisted Candidates',
                    onTap: () => _navigateToScreen('shortlisted_candidates'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.mail_outline_rounded,
                    label: 'Offer Letter Creation',
                    onTap: () => _navigateToScreen('offer_letter_creation'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Offer Acceptance',
                    onTap: () => _navigateToScreen('offer_acceptance'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.description_rounded,
                    label: 'Create Contract',
                    onTap: () => _navigateToScreen('create_contract'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.calendar_today_rounded,
                    label: 'Probation Period',
                    onTap: () => _navigateToScreen('probation_period'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.checklist_rounded,
                    label: 'Onboarding Checklist',
                    onTap: () => _navigateToScreen('onboarding_checklist'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.school_rounded,
                    label: 'Training Programs',
                    onTap: () => _navigateToScreen('training_programs'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.business_center_rounded,
                    label: 'Asset Allocation',
                    onTap: () => _navigateToScreen('asset_allocation'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.assignment_rounded,
                    label: 'Joining Documents',
                    onTap: () => _navigateToScreen('joining_documents'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.how_to_reg_rounded,
                    label: 'Confirm Joining',
                    onTap: () => _navigateToScreen('confirm_joining'),
                  ),
                ],
                
                _buildSidebarCategory('EMPLOYEE MANAGEMENT'),
                
                _buildSidebarItem(
                  icon: Icons.people_rounded,
                  label: 'Employee',
                  isActive: selectedMenu == 'employee',
                  hasSubmenu: true,
                  isExpanded: expandedMenus.contains('employee'),
                  onTap: () => _toggleMenu('employee'),
                ),
                if (expandedMenus.contains('employee')) ...[
                  _buildSidebarSubItem(
                    icon: Icons.person_add_rounded,
                    label: 'Add Employee',
                    onTap: () => _navigateToScreen('add_employee'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.list_rounded,
                    label: 'Employee List',
                    onTap: () => _navigateToScreen('employee_list'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.business_center_rounded,
                    label: 'Employee Assets',
                    onTap: () => _navigateToScreen('employee_assets'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.account_circle_rounded,
                    label: 'My Profile',
                    onTap: () => _navigateToScreen('my_profile'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.description_rounded,
                    label: 'Contracts',
                    onTap: () => _navigateToScreen('contracts'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.mail_rounded,
                    label: 'Offer Letters',
                    onTap: () => _navigateToScreen('offer_letters'),
                  ),
                ],
                
                _buildSidebarItem(
                  icon: Icons.check_circle_rounded,
                  label: 'Attendance',
                  isActive: selectedMenu == 'attendance',
                  hasSubmenu: true,
                  isExpanded: expandedMenus.contains('attendance'),
                  onTap: () => _toggleMenu('attendance'),
                ),
                if (expandedMenus.contains('attendance')) ...[
                  _buildSidebarSubItem(
                    icon: Icons.today,
                    label: 'Daily Attendance',
                    onTap: () => _navigateToScreen('daily_attendance'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.people,
                    label: 'Employee Attendance',
                    onTap: () => _navigateToScreen('employee_attendance'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.business,
                    label: 'Department Attendance',
                    onTap: () => _navigateToScreen('department_attendance'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.calendar_month,
                    label: 'Attendance Report',
                    onTap: () => _navigateToScreen('attendance_report'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.schedule,
                    label: 'Shift Management',
                    onTap: () => _navigateToScreen('shift_management'),
                  ),
                ],
                
                _buildSidebarItem(
                  icon: Icons.event_available_rounded,
                  label: 'Leave Tracker',
                  isActive: selectedMenu == 'leave',
                  hasSubmenu: true,
                  isExpanded: expandedMenus.contains('leave'),
                  onTap: () => _toggleMenu('leave'),
                ),
                if (expandedMenus.contains('leave')) ...[
                  _buildSidebarSubItem(
                    icon: Icons.add_box,
                    label: 'Apply Leave',
                    onTap: () => _navigateToScreen('apply_leave'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.approval,
                    label: 'Approve Leaves',
                    onTap: () => _navigateToScreen('approve_leaves'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.history,
                    label: 'Leave History',
                    onTap: () => _navigateToScreen('leave_history'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.settings,
                    label: 'Leave Types',
                    onTap: () => _navigateToScreen('leave_types'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.calendar_view_month,
                    label: 'Leave Calendar',
                    onTap: () => _navigateToScreen('leave_calendar'),
                  ),
                ],
                
                _buildSidebarItem(
                  icon: Icons.access_time_rounded,
                  label: 'Time Tracker',
                  isActive: selectedMenu == 'time',
                  hasSubmenu: true,
                  isExpanded: expandedMenus.contains('time'),
                  onTap: () => _toggleMenu('time'),
                ),
                if (expandedMenus.contains('time')) ...[
                  _buildSidebarSubItem(
                    icon: Icons.timer,
                    label: 'Log Time',
                    onTap: () => _navigateToScreen('log_time'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.assignment,
                    label: 'Timesheets',
                    onTap: () => _navigateToScreen('timesheets'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.work_history,
                    label: 'Project Time',
                    onTap: () => _navigateToScreen('project_time'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.hourglass_bottom,
                    label: 'Overtime',
                    onTap: () => _navigateToScreen('overtime'),
                  ),
                ],
                
                _buildSidebarItem(
                  icon: Icons.star_rounded,
                  label: 'Appraisal',
                  isActive: selectedMenu == 'appraisal',
                  hasSubmenu: true,
                  isExpanded: expandedMenus.contains('appraisal'),
                  onTap: () => _toggleMenu('appraisal'),
                ),
                if (expandedMenus.contains('appraisal')) ...[
                  _buildSidebarSubItem(
                    icon: Icons.rate_review,
                    label: 'Performance Review',
                    onTap: () => _navigateToScreen('performance_review'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.track_changes,
                    label: 'Goal Setting',
                    onTap: () => _navigateToScreen('goal_setting'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.feedback,
                    label: '360° Feedback',
                    onTap: () => _navigateToScreen('360_feedback'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.trending_up,
                    label: 'Performance Reports',
                    onTap: () => _navigateToScreen('performance_reports'),
                  ),
                ],
                
                _buildSidebarItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Payroll',
                  isActive: selectedMenu == 'payroll',
                  hasSubmenu: true,
                  isExpanded: expandedMenus.contains('payroll'),
                  onTap: () => _toggleMenu('payroll'),
                ),
                if (expandedMenus.contains('payroll')) ...[
                  _buildSidebarSubItem(
                    icon: Icons.payment,
                    label: 'Process Payroll',
                    onTap: () => _navigateToScreen('process_payroll'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.receipt_long,
                    label: 'Payslips',
                    onTap: () => _navigateToScreen('payslips'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.account_balance,
                    label: 'Salary Structure',
                    onTap: () => _navigateToScreen('salary_structure'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.calculate,
                    label: 'Tax Calculation',
                    onTap: () => _navigateToScreen('tax_calculation'),
                  ),
                ],
                
                _buildSidebarItem(
                  icon: Icons.campaign_rounded,
                  label: 'Announcement',
                  isActive: selectedMenu == 'announcement',
                  hasSubmenu: true,
                  isExpanded: expandedMenus.contains('announcement'),
                  onTap: () => _toggleMenu('announcement'),
                ),
                if (expandedMenus.contains('announcement')) ...[
                  _buildSidebarSubItem(
                    icon: Icons.add_comment,
                    label: 'Create Announcement',
                    onTap: () => _navigateToScreen('create_announcement'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.list_alt,
                    label: 'View Announcements',
                    onTap: () => _navigateToScreen('view_announcements'),
                  ),
                ],
                
                _buildSidebarItem(
                  icon: Icons.exit_to_app_rounded,
                  label: 'Resignation',
                  isActive: selectedMenu == 'resignation',
                  hasSubmenu: true,
                  isExpanded: expandedMenus.contains('resignation'),
                  onTap: () => _toggleMenu('resignation'),
                ),
                if (expandedMenus.contains('resignation')) ...[
                  _buildSidebarSubItem(
                    icon: Icons.send,
                    label: 'Submit Resignation',
                    onTap: () => _navigateToScreen('submit_resignation'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.pending_actions,
                    label: 'Pending Resignations',
                    onTap: () => _navigateToScreen('pending_resignations'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.exit_to_app,
                    label: 'Exit Process',
                    onTap: () => _navigateToScreen('exit_process'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.checklist,
                    label: 'Clearance Checklist',
                    onTap: () => _navigateToScreen('clearance_checklist'),
                  ),
                ],
                
                _buildSidebarItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isActive: selectedMenu == 'settings',
                  hasSubmenu: true,
                  isExpanded: expandedMenus.contains('settings'),
                  onTap: () => _toggleMenu('settings'),
                ),
                if (expandedMenus.contains('settings')) ...[
                  _buildSidebarSubItem(
                    icon: Icons.admin_panel_settings,
                    label: 'User Management',
                    onTap: () => _navigateToScreen('user_management'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.security,
                    label: 'Roles & Permissions',
                    onTap: () => _navigateToScreen('roles_permissions'),
                  ),
                  _buildSidebarSubItem(
                    icon: Icons.business,
                    label: 'Company Settings',
                    onTap: () => _navigateToScreen('company_settings'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarCategory(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    bool isActive = false,
    bool hasSubmenu = false,
    bool isExpanded = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
              )
            : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (hasSubmenu)
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    color: isActive ? Colors.white : Colors.white54,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarSubItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 28, right: 8, top: 2, bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: Colors.white60, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double? trend;
  final String? trendLabel;
  final bool isAlert;
  final String priority; // 'normal', 'warning', 'urgent'

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.trend,
    this.trendLabel,
    this.isAlert = false,
    this.priority = 'normal',
  });

  Color _getPriorityColor() {
    switch (priority) {
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'warning':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  String _getPriorityLabel() {
    switch (priority) {
      case 'urgent':
        return 'Urgent';
      case 'warning':
        return 'Alert';
      default:
        return 'Normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor();
    final priorityLabel = _getPriorityLabel();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: priority != 'normal' ? Border.all(color: priorityColor.withOpacity(0.3), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: priorityColor.withOpacity(0.5), width: 1),
                  ),
                  child: Text(
                    priorityLabel,
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
              height: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          if (trend != null)
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trend! > 0 ? Icons.trending_up : Icons.trending_down,
                      color: trend! > 0 ? Colors.green : Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${trend!.abs()}% ${trendLabel ?? ''}',
                      style: TextStyle(
                        fontSize: 10,
                        color: trend! > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
        ],
      ),
    );
  }
}

// Data Models
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
}

class AttendanceData {
  final String day;
  final double percentage;
  final int late;
  final int total;
  final int present;

  AttendanceData(this.day, this.percentage, this.late, this.total)
      : present = total - late;
}

class DepartmentData {
  final String name;
  final int count;
  final Color color;

  DepartmentData(this.name, this.count, this.color);
}

class ActivityItem {
  final IconData icon;
  final String title;
  final String description;
  final String time;
  final Color color;

  ActivityItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
    required this.color,
  });
}

class CalendarEvent {
  final String title;
  final DateTime date;
  final Color color;
  final IconData icon;

  CalendarEvent(this.title, this.date, this.color, this.icon);
}