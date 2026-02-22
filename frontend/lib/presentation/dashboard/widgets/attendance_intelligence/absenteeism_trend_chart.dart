import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AbsenteeismTrendChart extends StatefulWidget {
  const AbsenteeismTrendChart({super.key});

  @override
  State<AbsenteeismTrendChart> createState() => _AbsenteeismTrendChartState();
}

class _AbsenteeismTrendChartState extends State<AbsenteeismTrendChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  String selectedPeriod = 'Week';
  
  // Mock data for last 7 days
  final List<Map<String, dynamic>> weeklyData = [
    {'day': 'Mon', 'rate': 4.2},
    {'day': 'Tue', 'rate': 5.1},
    {'day': 'Wed', 'rate': 3.8},
    {'day': 'Thu', 'rate': 6.5},
    {'day': 'Fri', 'rate': 4.9},
    {'day': 'Sat', 'rate': 2.1},
    {'day': 'Sun', 'rate': 1.5},
  ];

  final double averageRate = 4.5;
  final double criticalThreshold = 7.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_down_rounded,
                  color: Theme.of(context).cardColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Absenteeism Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              _buildPeriodSelector(),
            ],
          ),
          const SizedBox(height: 24),

          // Current Rate
          Row(
            children: [
              Text(
                '${weeklyData.last['rate']}%',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.trending_down_rounded,
                      color: Color(0xFF10B981),
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Improving',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Today\'s Rate',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Chart
          SizedBox(
            height: 200,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 2,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Theme.of(context).dividerColor,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < weeklyData.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  weeklyData[value.toInt()]['day'],
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (weeklyData.length - 1).toDouble(),
                    minY: 0,
                    maxY: 10,
                    lineBarsData: [
                      // Actual data line
                      LineChartBarData(
                        spots: List.generate(
                          weeklyData.length,
                          (i) => FlSpot(
                            i.toDouble(),
                            weeklyData[i]['rate'] * _animation.value,
                          ),
                        ),
                        isCurved: true,
                        color: const Color(0xFFF59E0B),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            final rate = weeklyData[index]['rate'];
                            Color dotColor;
                            if (rate >= criticalThreshold) {
                              dotColor = const Color(0xFFEF4444);
                            } else if (rate >= averageRate) {
                              dotColor = const Color(0xFFF59E0B);
                            } else {
                              dotColor = const Color(0xFF10B981);
                            }
                            return FlDotCirclePainter(
                              radius: 5,
                              color: dotColor,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFFF59E0B).withOpacity(0.3),
                              const Color(0xFFF59E0B).withOpacity(0.05),
                            ],
                          ),
                        ),
                      ),
                      // Average line
                      LineChartBarData(
                        spots: List.generate(
                          weeklyData.length,
                          (i) => FlSpot(i.toDouble(), averageRate),
                        ),
                        isCurved: false,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                        barWidth: 2,
                        dashArray: [5, 5],
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Legend
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 16,
            runSpacing: 10,
            children: [
              _buildLegendItem('Good', const Color(0xFF10B981)),
              _buildLegendItem('Warning', const Color(0xFFF59E0B)),
              _buildLegendItem('Critical', const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: ['Week', 'Month'].map((period) {
          final isSelected = selectedPeriod == period;
          return GestureDetector(
            onTap: () => setState(() => selectedPeriod = period),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                period,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}