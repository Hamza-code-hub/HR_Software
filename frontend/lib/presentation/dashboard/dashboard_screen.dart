import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// Navigation state provider
final selectedMenuProvider = StateProvider<String>((ref) => 'dashboard');
final expandedMenuProvider = StateProvider<Set<String>>((ref) => {});
final selectedModuleTabProvider = StateProvider<int>((ref) => 0);

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
      description: 'Senior Developer position - Jane Wilson',
      time: '5 hours ago',
      color: const Color(0xFFEC4899),
    ),
    ActivityItem(
      icon: Icons.exit_to_app,
      title: 'Resignation Processed',
      description: 'Robert Brown - Last working day: Feb 28',
      time: '1 day ago',
      color: const Color(0xFFEF4444),
    ),
  ];
});

final upcomingEventsProvider = Provider<List<CalendarEvent>>((ref) {
  return [
    CalendarEvent('Team Meeting', DateTime.now().add(const Duration(hours: 2)), const Color(0xFF0EA5E9)),
    CalendarEvent('Performance Review', DateTime.now().add(const Duration(days: 1)), const Color(0xFFEC4899)),
    CalendarEvent('Training Session', DateTime.now().add(const Duration(days: 2)), const Color(0xFF10B981)),
    CalendarEvent('Payroll Processing', DateTime.now().add(const Duration(days: 5)), const Color(0xFF8B5CF6)),
  ];
});

class HRDashboardScreen extends ConsumerStatefulWidget {
  const HRDashboardScreen({super.key});

  @override
  ConsumerState<HRDashboardScreen> createState() => _HRDashboardScreenState();
}

class _HRDashboardScreenState extends ConsumerState<HRDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
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
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768 && screenWidth <= 1200;
    final isMobile = screenWidth <= 768;

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
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 32 : (isTablet ? 24 : 16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Banner
                        _buildWelcomeBanner(),
                        const SizedBox(height: 24),

                        // Quick Stats
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: AnimatedBuilder(
                            animation: _slideAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _slideAnimation.value),
                                child: child,
                              );
                            },
                            child: _buildQuickStats(stats, isDesktop, isTablet, isMobile),
                          ),
                        ),
                        SizedBox(height: isDesktop ? 32 : 24),

                        // Main Content Grid
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: isDesktop
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        children: [
                                          _buildAttendanceChart(),
                                          const SizedBox(height: 24),
                                          _buildHRModulesGrid(stats, isDesktop, isMobile),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        children: [
                                          _buildCalendarWidget(),
                                          const SizedBox(height: 24),
                                          _buildQuickActions(),
                                          const SizedBox(height: 24),
                                          _buildRecentActivities(),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildAttendanceChart(),
                                    const SizedBox(height: 24),
                                    _buildCalendarWidget(),
                                    const SizedBox(height: 24),
                                    _buildQuickActions(),
                                    const SizedBox(height: 24),
                                    _buildHRModulesGrid(stats, false, isMobile),
                                    const SizedBox(height: 24),
                                    _buildRecentActivities(),
                                  ],
                                ),
                        ),
                        SizedBox(height: isDesktop ? 32 : 24),

                        // Department Distribution & Payroll
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: isDesktop
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildDepartmentDistribution()),
                                    const SizedBox(width: 24),
                                    Expanded(child: _buildPayrollSummary(stats)),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildDepartmentDistribution(),
                                    const SizedBox(height: 24),
                                    _buildPayrollSummary(stats),
                                  ],
                                ),
                        ),
                      ],
                    ),
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

  Widget _buildWelcomeBanner() {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17) {
      greeting = 'Good Evening';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
          ],
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, Admin! 👋',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here\'s what\'s happening with your team today.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip(Icons.calendar_today, DateFormat('EEE, MMM d').format(now)),
                    const SizedBox(width: 12),
                    _buildInfoChip(Icons.access_time, DateFormat('hh:mm a').format(now)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.emoji_emotions,
              size: 48,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarWidget() {
    final events = ref.watch(upcomingEventsProvider);
    final now = DateTime.now();

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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.calendar_month, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Upcoming Events',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _navigateToScreen('calendar'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...events.map((event) => _buildEventItem(event)),
        ],
      ),
    );
  }

  Widget _buildEventItem(CalendarEvent event) {
    final now = DateTime.now();
    final difference = event.date.difference(now);
    String timeLeft;
    
    if (difference.inHours < 24) {
      timeLeft = '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      timeLeft = '${difference.inDays}d';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: event.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: event.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: event.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, h:mm a').format(event.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: event.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              timeLeft,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
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
          _buildStatusItem(Icons.cloud_done, 'System Online', const Color(0xFF10B981)),
          const SizedBox(width: 24),
          _buildStatusItem(Icons.people, '238 Active Users', const Color(0xFF0EA5E9)),
          const Spacer(),
          Text(
            'Last Updated: ${DateFormat('hh:mm a').format(DateTime.now())}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(width: 16),
          Text(
            '© ${DateTime.now().year} CyberZeus HR',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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

  Widget _buildSidebar(BuildContext context) {
    final selectedMenu = ref.watch(selectedMenuProvider);
    final expandedMenus = ref.watch(expandedMenuProvider);

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
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
          // Logo Section
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
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
                  child: const Icon(
                    Icons.people_rounded,
                    color: Colors.white,
                    size: 32,
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
          
          // Navigation Menu
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

  Widget _buildSidebarQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF0EA5E9), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarAlert({
    required IconData icon,
    required String label,
    required Color color,
    required String count,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

  Widget _buildAppBar(BuildContext context, bool isMobile) {
    return Container(
      height: 140,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF0EA5E9),
            Color(0xFF06B6D4),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (isMobile)
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: isMobile ? 11 : 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'HR Management System',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 16 : 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Badge(
                        label: const Text('8', style: TextStyle(fontSize: 10)),
                        backgroundColor: const Color(0xFFEF4444),
                        child: Icon(Icons.notifications_outlined,
                            color: Colors.white, size: isMobile ? 18 : 22),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.settings_outlined,
                          color: Colors.white, size: isMobile ? 18 : 22),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(HRDashboardStats stats, bool isDesktop, bool isTablet, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth >= 1400) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth >= 1000) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _StatCard(
              title: 'Total Employees',
              value: stats.totalEmployees.toString(),
              subtitle: '${stats.activeEmployees} active',
              icon: Icons.people_rounded,
              color: const Color(0xFF0EA5E9),
              progress: stats.activeEmployees / stats.totalEmployees,
              trend: stats.employeeGrowth,
              trendLabel: 'from last month',
            ),
            _StatCard(
              title: 'Present Today',
              value: stats.presentToday.toString(),
              subtitle: '${stats.avgAttendance.toStringAsFixed(1)}% attendance',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
              progress: stats.presentToday / stats.activeEmployees,
              trend: 2.4,
              trendLabel: 'vs yesterday',
            ),
            _StatCard(
              title: 'On Leave',
              value: stats.onLeave.toString(),
              subtitle: '${stats.pendingLeaveApprovals} pending',
              icon: Icons.event_busy_rounded,
              color: const Color(0xFFF59E0B),
              progress: stats.onLeave / stats.activeEmployees,
              isAlert: stats.pendingLeaveApprovals > 5,
            ),
            _StatCard(
              title: 'Open Positions',
              value: stats.openPositions.toString(),
              subtitle: '${stats.activeRecruitment} active',
              icon: Icons.work_outline_rounded,
              color: const Color(0xFF8B5CF6),
              progress: stats.activeRecruitment / (stats.openPositions + stats.activeRecruitment),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHRModulesGrid(HRDashboardStats stats, bool isDesktop, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Module Tabs
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '🎯 Core HR'),
                Tab(text: '⭐ Talent'),
                Tab(text: '💰 Finance'),
                Tab(text: '📊 Reports'),
              ],
              indicatorColor: const Color(0xFF0EA5E9),
              labelColor: const Color(0xFF0EA5E9),
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Tab Content
        SizedBox(
          height: 480,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Core HR Tab
              _buildResponsiveModuleGrid(
                stats,
                isDesktop,
                isMobile,
                [
                  _buildModuleCard('Employees', 238, 245, Icons.people_outline, const Color(0xFF0EA5E9), 'Active employees', () => _navigateToScreen('employee')),
                  _buildModuleCard('Onboarding', stats.onboardingInProgress, stats.onboardingInProgress + 2, Icons.person_add_outlined, const Color(0xFFF59E0B), 'In progress', () => _navigateToScreen('onboarding')),
                  _buildModuleCard('Resignations', stats.pendingResignations, stats.pendingResignations + 3, Icons.exit_to_app, const Color(0xFFEF4444), 'Pending exit', () => _navigateToScreen('resignation')),
                  _buildModuleCard('Attendance', stats.presentToday, stats.activeEmployees, Icons.access_time, const Color(0xFF8B5CF6), 'Present today', () => _navigateToScreen('attendance')),
                  _buildModuleCard('Leave Balance', 28, 45, Icons.event_available, const Color(0xFF06B6D4), 'Days available', () => _navigateToScreen('leave_balance')),
                  _buildModuleCard('Leave Requests', stats.pendingLeaveApprovals, stats.pendingLeaveApprovals + 12, Icons.approval, const Color(0xFF10B981), 'Pending approvals', () => _navigateToScreen('leave')),
                  _buildModuleCard('Documents', 220, 245, Icons.description_outlined, const Color(0xFF10B981), 'Uploaded & verified', () => _navigateToScreen('documents')),
                  _buildModuleCard('Asset Assignment', 238, 245, Icons.laptop_chromebook_outlined, const Color(0xFF059669), 'Assigned', () => _navigateToScreen('asset_assignment')),
                ],
              ),
              // Talent Tab
              _buildResponsiveModuleGrid(
                stats,
                isDesktop,
                isMobile,
                [
                  _buildModuleCard('Recruitment', stats.activeRecruitment, stats.openPositions + stats.activeRecruitment, Icons.work_outline, const Color(0xFF0EA5E9), 'Active postings', () => _navigateToScreen('recruitment')),
                  _buildModuleCard('Job Positions', stats.openPositions, 10, Icons.work, const Color(0xFF8B5CF6), 'Open positions', () => _navigateToScreen('job_positions')),
                  _buildModuleCard('Candidates', 45, 120, Icons.person_search_outlined, const Color(0xFFEC4899), 'In pipeline', () => _navigateToScreen('candidates')),
                  _buildModuleCard('Interviews', stats.interviewsScheduled, 35, Icons.calendar_month_outlined, const Color(0xFFF59E0B), 'Scheduled', () => _navigateToScreen('interviews')),
                  _buildModuleCard('Performance Review', 18, 45, Icons.assessment_outlined, const Color(0xFF10B981), 'Completed', () => _navigateToScreen('performance')),
                  _buildModuleCard('Appraisals', stats.performanceReviewsDue, stats.activeEmployees, Icons.star_outline, const Color(0xFFF59E0B), 'Due this month', () => _navigateToScreen('appraisal')),
                  _buildModuleCard('Training', stats.trainingCompleted, 120, Icons.school_outlined, const Color(0xFF0EA5E9), 'Completed', () => _navigateToScreen('training')),
                  _buildModuleCard('Goals', 120, 245, Icons.flag_outlined, const Color(0xFF0EA5E9), 'Active goals', () => _navigateToScreen('goals')),
                ],
              ),
              // Finance Tab
              _buildResponsiveModuleGrid(
                stats,
                isDesktop,
                isMobile,
                [
                  _buildModuleCard('Payroll Run', 245, 245, Icons.account_balance_wallet_rounded, const Color(0xFF059669), 'Monthly processed', () => _navigateToScreen('payroll')),
                  _buildModuleCard('Payslips', 238, 245, Icons.receipt_long_outlined, const Color(0xFFDC2626), 'Generated & sent', () => _navigateToScreen('payslips')),
                  _buildModuleCard('Tax Deduction', 245, 245, Icons.calculate_outlined, const Color(0xFF7C3AED), 'Applied to salary', () => _navigateToScreen('tax')),
                  _buildModuleCard('Allowances', 235, 245, Icons.card_giftcard_outlined, const Color(0xFFF59E0B), 'Configured', () => _navigateToScreen('allowances')),
                  _buildModuleCard('Contracts', stats.activeEmployees - stats.pendingContracts, stats.activeEmployees, Icons.handshake_outlined, const Color(0xFF06B6D4), 'Need signature', () => _navigateToScreen('contracts')),
                  _buildModuleCard('Offer Letters', stats.pendingOfferLetters, stats.pendingOfferLetters + 7, Icons.mail_outline, const Color(0xFFEC4899), 'Pending approval', () => _navigateToScreen('offer_letters')),
                  _buildModuleCard('Probation', 12, 15, Icons.timer_outlined, const Color(0xFF8B5CF6), 'Under review', () => _navigateToScreen('probation')),
                  _buildModuleCard('Inventory', 240, 250, Icons.inventory_2_outlined, const Color(0xFF8B5CF6), 'Total assets', () => _navigateToScreen('inventory')),
                ],
              ),
              // Reports Tab
              _buildResponsiveModuleGrid(
                stats,
                isDesktop,
                isMobile,
                [
                  _buildModuleCard('Attendance Report', 94, 100, Icons.bar_chart_outlined, const Color(0xFF10B981), 'Monthly report', () => _navigateToScreen('attendance_report')),
                  _buildModuleCard('Leave Report', 28, 100, Icons.show_chart, const Color(0xFFF59E0B), 'Summary data', () => _navigateToScreen('leave_report')),
                  _buildModuleCard('Payroll Report', 245, 245, Icons.receipt_outlined, const Color(0xFF0EA5E9), 'Monthly summary', () => _navigateToScreen('payroll_report')),
                  _buildModuleCard('Export Data', 50, 100, Icons.download_outlined, const Color(0xFF06B6D4), 'CSV exports', () => _navigateToScreen('export')),
                  _buildModuleCard('Announcements', 8, 12, Icons.campaign_outlined, const Color(0xFF059669), 'This month', () => _navigateToScreen('announcements')),
                  _buildModuleCard('HR Notices', 12, 25, Icons.notifications_active_outlined, const Color(0xFFEC4899), 'Active notices', () => _navigateToScreen('notices')),
                  _buildModuleCard('Communications', 45, 60, Icons.mail_outline, const Color(0xFF8B5CF6), 'Total sent', () => _navigateToScreen('communications')),
                  _buildModuleCard('Clearance', 2, 2, Icons.verified_outlined, const Color(0xFF10B981), 'Pending exit', () => _navigateToScreen('clearance')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveModuleGrid(
    HRDashboardStats stats,
    bool isDesktop,
    bool isMobile,
    List<Widget> cards,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine grid columns based on available width
        int crossAxisCount;
        if (constraints.maxWidth >= 1600) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth >= 1200) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 800) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            physics: const NeverScrollableScrollPhysics(),
            children: cards,
          ),
        );
      },
    );
  }

  Widget _buildModuleCard(
    String title,
    int completed,
    int total,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap,
  ) {
    final progress = total > 0 ? completed / total : 0.0;
    final percentage = (progress * 100).toStringAsFixed(0);

    return SizedBox(
      height: 160,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 18),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 1),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          completed.toString(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: color,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '/ $total',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const Spacer(flex: 1),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Remaining: ${total - completed}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceChart() {
    final attendanceData = ref.watch(hrAttendanceTrendProvider);

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.analytics, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attendance Trends',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last 7 days performance',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              Wrap(
                spacing: 16,
                children: [
                  _buildLegendItem('Present', const Color(0xFF10B981)),
                  _buildLegendItem('Late', const Color(0xFFF59E0B)),
                  _buildLegendItem('Total', const Color(0xFF0EA5E9)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= attendanceData.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            attendanceData[value.toInt()].day,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (attendanceData.length - 1).toDouble(),
                minY: 0,
                maxY: 220,
                lineBarsData: [
                  LineChartBarData(
                    spots: attendanceData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(
                            e.key.toDouble(), e.value.total.toDouble()))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFF0EA5E9),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: attendanceData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(
                            e.key.toDouble(), e.value.present.toDouble()))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFF10B981),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF10B981).withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: attendanceData
                        .asMap()
                        .entries
                        .map((e) =>
                            FlSpot(e.key.toDouble(), e.value.late.toDouble()))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFFF59E0B),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentDistribution() {
    final deptData = ref.watch(hrDepartmentDistributionProvider);
    final total = deptData.fold(0, (sum, item) => sum + item.count);

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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.pie_chart_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Employee Distribution',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 400;
              return isSmall
                  ? Column(
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 60,
                              sections: deptData.map((dept) {
                                final percentage = (dept.count / total) * 100;
                                return PieChartSectionData(
                                  color: dept.color,
                                  value: dept.count.toDouble(),
                                  title: '${percentage.toStringAsFixed(0)}%',
                                  radius: 55,
                                  titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: deptData.map((dept) {
                              final percentage = (dept.count / total) * 100;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: dept.color,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            dept.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          dept.count.toString(),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: dept.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: dept.count / total,
                                        backgroundColor: Colors.grey[200],
                                        valueColor: AlwaysStoppedAnimation<Color>(dept.color),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 60,
                              sections: deptData.map((dept) {
                                final percentage = (dept.count / total) * 100;
                                return PieChartSectionData(
                                  color: dept.color,
                                  value: dept.count.toDouble(),
                                  title: '${percentage.toStringAsFixed(0)}%',
                                  radius: 55,
                                  titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: deptData.map((dept) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: dept.color,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            dept.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          dept.count.toString(),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: dept.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: dept.count / total,
                                        backgroundColor: Colors.grey[200],
                                        valueColor: AlwaysStoppedAnimation<Color>(dept.color),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
            },
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
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.flash_on, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            'Add Employee',
            Icons.person_add_rounded,
            const Color(0xFF0EA5E9),
            () => _navigateToScreen('add_employee'),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Generate Offer Letter',
            Icons.mail_rounded,
            const Color(0xFFEC4899),
            () => _navigateToScreen('offer_letters'),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Create Contract',
            Icons.description_rounded,
            const Color(0xFF10B981),
            () => _navigateToScreen('contracts'),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Process Payroll',
            Icons.account_balance_wallet_rounded,
            const Color(0xFF8B5CF6),
            () => _navigateToScreen('process_payroll'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
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
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    final activities = ref.watch(hrRecentActivitiesProvider);

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0EA5E9).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.history_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Recent Activities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _navigateToScreen('activities'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...activities.map((activity) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildActivityItem(activity),
              )),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ActivityItem activity) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: activity.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(activity.icon, color: activity.color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activity.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activity.time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPayrollSummary(HRDashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Payroll Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildPayrollItem(
            'Monthly Payroll',
            'PKR ${_formatCurrency(stats.monthlyPayroll)}',
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.75,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          _buildPayrollItem(
            'Overtime Hours',
            '${stats.overtimeHours} hrs',
          ),
          const SizedBox(height: 16),
          _buildPayrollItem(
            'Tax Deducted',
            'PKR ${_formatCurrency(stats.monthlyPayroll * 0.15)}',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToScreen('process_payroll'),
              icon: const Icon(Icons.play_arrow),
              label: const Text(
                'Process Payroll',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF8B5CF6),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    }
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }
}

// Stat Card Widget with Progress Bar
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double? progress;
  final double? trend;
  final String? trendLabel;
  final bool isAlert;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.progress,
    this.trend,
    this.trendLabel,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                if (isAlert)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.priority_high,
                            color: Color(0xFFF59E0B), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Alert',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
                height: 1,
              ),
            ),
            const SizedBox(height: 12),
            if (trend != null)
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: trend! >= 0
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          trend! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: trend! >= 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${trend!.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: trend! >= 0
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trendLabel ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            else
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(progress! * 100).toStringAsFixed(0)}% Complete',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
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

  CalendarEvent(this.title, this.date, this.color);
}