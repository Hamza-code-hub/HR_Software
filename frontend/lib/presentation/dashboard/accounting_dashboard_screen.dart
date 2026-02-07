import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// Mock providers - will be replaced with real API calls
final accountingStatsProvider = Provider((ref) {
  return AccountingStats(
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
});

class AccountingDashboardScreen extends ConsumerWidget {
  const AccountingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(accountingStatsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768 && screenWidth <= 1200;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 32 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
            _buildWelcomeBanner(),
            const SizedBox(height: 24),

            // KPI Cards
            _buildKPICards(stats, isDesktop),
            const SizedBox(height: 24),

            // Revenue vs Expenses Chart
            _buildRevenueExpensesChart(),
            const SizedBox(height: 24),

            // Cash Flow & Expense Breakdown
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildCashFlowChart()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildExpenseBreakdown()),
                    ],
                  )
                : Column(
                    children: [
                      _buildCashFlowChart(),
                      const SizedBox(height: 24),
                      _buildExpenseBreakdown(),
                    ],
                  ),
            const SizedBox(height: 24),

            // Aging Analysis & Budget vs Actual
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildAgingAnalysis()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildBudgetVsActual()),
                    ],
                  )
                : Column(
                    children: [
                      _buildAgingAnalysis(),
                      const SizedBox(height: 24),
                      _buildBudgetVsActual(),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF047857)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
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
                const Text(
                  'Accounting Dashboard 📊',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Financial insights and analytics at a glance',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                  ),
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
              Icons.account_balance,
              size: 48,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICards(AccountingStats stats, bool isDesktop) {
    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: isDesktop ? 1.8 : 1.5,
      children: [
        _buildKPICard(
          'Revenue (MTD)',
          '₨${_formatCurrency(stats.totalRevenueMTD)}',
          Icons.trending_up,
          const Color(0xFF10B981),
          '+12.5%',
        ),
        _buildKPICard(
          'Expenses (MTD)',
          '₨${_formatCurrency(stats.totalExpensesMTD)}',
          Icons.trending_down,
          const Color(0xFFEF4444),
          '+8.2%',
        ),
        _buildKPICard(
          'Net Profit (MTD)',
          '₨${_formatCurrency(stats.netProfitMTD)}',
          Icons.monetization_on,
          const Color(0xFF0EA5E9),
          '+18.3%',
        ),
        _buildKPICard(
          'Cash Balance',
          '₨${_formatCurrency(stats.cashBalance)}',
          Icons.account_balance_wallet,
          const Color(0xFF8B5CF6),
          'Healthy',
        ),
        _buildKPICard(
          'Current Ratio',
          stats.currentRatio.toStringAsFixed(2),
          Icons.balance,
          const Color(0xFFF59E0B),
          'Good',
        ),
        _buildKPICard(
          'Working Capital',
          '₨${_formatCurrency(stats.workingCapital)}',
          Icons.payment,
          const Color(0xFFEC4899),
          'Stable',
        ),
        _buildKPICard(
          'AR Days',
          stats.accountsReceivableDays.toString(),
          Icons.receipt_long,
          const Color(0xFF06B6D4),
          'Target: 30',
        ),
        _buildKPICard(
          'AP Days',
          stats.accountsPayableDays.toString(),
          Icons.assignment,
          const Color(0xFF8B5CF6),
          'Target: 45',
        ),
      ],
    );
  }

  Widget _buildKPICard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueExpensesChart() {
    // Mock data
    final data = [
      {'month': 'Jan', 'revenue': 7500000.0, 'expenses': 5800000.0},
      {'month': 'Feb', 'revenue': 8200000.0, 'expenses': 6100000.0},
      {'month': 'Mar', 'revenue': 7800000.0, 'expenses': 5900000.0},
      {'month': 'Apr', 'revenue': 8500000.0, 'expenses': 6300000.0},
      {'month': 'May', 'revenue': 9000000.0, 'expenses': 6500000.0},
      {'month': 'Jun', 'revenue': 8800000.0, 'expenses': 6400000.0},
    ];

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
                    colors: [Color(0xFF10B981), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.show_chart, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Revenue vs Expenses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildChartLegend('Revenue', const Color(0xFF10B981)),
              const SizedBox(width: 16),
              _buildChartLegend('Expenses', const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2000000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₨${(value / 1000000).toStringAsFixed(1)}M',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              data[value.toInt()]['month'].toString(),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value['revenue'] as double);
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF10B981),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10B981).withOpacity(0.3),
                          const Color(0xFF10B981).withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value['expenses'] as double);
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFFEF4444),
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

  Widget _buildCashFlowChart() {
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
                    colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.waterfall_chart, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cash Flow (Monthly)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCashFlowItem('Opening Balance', 5000000, true),
          _buildCashFlowItem('Sales Revenue', 8500000, true),
          _buildCashFlowItem('Payroll', -6200000, false),
          _buildCashFlowItem('Operations', -1200000, false),
          _buildCashFlowItem('Tax', -600000, false),
          const Divider(height: 24),
          _buildCashFlowItem('Closing Balance', 5500000, true, isClosing: true),
        ],
      ),
    );
  }

  Widget _buildCashFlowItem(String label, double amount, bool isInflow,
      {bool isClosing = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isClosing ? Colors.black : Colors.grey[700],
                fontWeight: isClosing ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '₨${_formatCurrency(amount.abs())}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isClosing
                  ? const Color(0xFF10B981)
                  : isInflow
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseBreakdown() {
    final data = [
      {'category': 'Payroll', 'amount': 6200000.0, 'percentage': 72.1, 'color': const Color(0xFF0EA5E9)},
      {'category': 'Operations', 'amount': 1200000.0, 'percentage': 14.0, 'color': const Color(0xFF8B5CF6)},
      {'category': 'Marketing', 'amount': 800000.0, 'percentage': 9.3, 'color': const Color(0xFFEC4899)},
      {'category': 'R&D', 'amount': 300000.0, 'percentage': 3.5, 'color': const Color(0xFF10B981)},
      {'category': 'Other', 'amount': 100000.0, 'percentage': 1.1, 'color': const Color(0xFFF59E0B)},
    ];

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
                ),
                child: const Icon(Icons.pie_chart, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Expense Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...data.map((item) => _buildExpenseItem(
                item['category'] as String,
                item['percentage'] as double,
                item['color'] as Color,
              )),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(String category, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              color: color,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgingAnalysis() {
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
                ),
                child: const Icon(Icons.access_time, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Aging Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildAgingRow('0-30 days', 2500000, const Color(0xFF10B981)),
          _buildAgingRow('31-60 days', 1200000, const Color(0xFFF59E0B)),
          _buildAgingRow('61-90 days', 600000, const Color(0xFFEF4444)),
          _buildAgingRow('90+ days', 300000, const Color(0xFF991B1B)),
        ],
      ),
    );
  }

  Widget _buildAgingRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
          Text(
            '₨${_formatCurrency(amount)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetVsActual() {
    final data = [
      {'dept': 'Engineering', 'budget': 3500000.0, 'actual': 3200000.0},
      {'dept': 'Marketing', 'budget': 1000000.0, 'actual': 1100000.0},
      {'dept': 'Sales', 'budget': 1200000.0, 'actual': 1050000.0},
    ];

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
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.compare_arrows, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Budget vs Actual',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...data.map((item) => _buildBudgetRow(
                item['dept'] as String,
                item['budget'] as double,
                item['actual'] as double,
              )),
        ],
      ),
    );
  }

  Widget _buildBudgetRow(String dept, double budget, double actual) {
    final variance = ((actual - budget) / budget * 100);
    final isOver = variance > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dept,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                '${variance > 0 ? '+' : ''}${variance.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 13,
                  color: isOver ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget: ₨${_formatCurrency(budget)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 1.0,
                        backgroundColor: Colors.grey[200],
                        color: Colors.grey[400],
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actual: ₨${_formatCurrency(actual)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: actual / budget,
                        backgroundColor: Colors.grey[200],
                        color: isOver ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
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
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

class AccountingStats {
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

  AccountingStats({
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
}
