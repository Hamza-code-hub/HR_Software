import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TurnoverAnalysisChart extends StatelessWidget {
  final List<TurnoverData> data;

  const TurnoverAnalysisChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(Icons.people_outline, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Employee Turnover Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              _buildLegend(),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxValue() * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String label = rodIndex == 0 ? 'Joiners' : 'Leavers';
                      return BarTooltipItem(
                        '$label\n${rod.toY.toInt()}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
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
                              data[value.toInt()].month,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
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
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.joiners.toDouble(),
                        color: const Color(0xFF10B981),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: entry.value.leavers.toDouble(),
                        color: const Color(0xFFEF4444),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxValue() {
    double max = 0;
    for (var item in data) {
      if (item.joiners > max) max = item.joiners.toDouble();
      if (item.leavers > max) max = item.leavers.toDouble();
    }
    return max;
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _buildLegendItem('Joiners', const Color(0xFF10B981)),
        const SizedBox(width: 16),
        _buildLegendItem('Leavers', const Color(0xFFEF4444)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class TurnoverData {
  final String month;
  final int joiners;
  final int leavers;
  final int net;
  final double rate;

  TurnoverData({
    required this.month,
    required this.joiners,
    required this.leavers,
    required this.net,
    required this.rate,
  });

  factory TurnoverData.fromJson(Map<String, dynamic> json) {
    return TurnoverData(
      month: json['month'] ?? '',
      joiners: json['joiners'] ?? 0,
      leavers: json['leavers'] ?? 0,
      net: json['net'] ?? 0,
      rate: (json['rate'] ?? 0).toDouble(),
    );
  }
}
