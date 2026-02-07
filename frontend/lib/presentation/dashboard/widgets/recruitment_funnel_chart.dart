import 'package:flutter/material.dart';

class RecruitmentFunnelChart extends StatelessWidget {
  final List<FunnelStage> data;

  const RecruitmentFunnelChart({
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
                    colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.filter_list, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recruitment Funnel',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...data.asMap().entries.map((entry) {
            return _buildFunnelStage(entry.value, entry.key, data.length);
          }),
        ],
      ),
    );
  }

  Widget _buildFunnelStage(FunnelStage stage, int index, int total) {
    final colors = [
      const Color(0xFF0EA5E9),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
    ];

    final color = colors[index % colors.length];
    final widthPercentage = 1.0 - (index * 0.15);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Container(
            height: 60,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    stage.stage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      stage.count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${stage.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (index < total - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Icon(
                Icons.arrow_downward,
                color: Colors.grey[400],
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

class FunnelStage {
  final String stage;
  final int count;
  final double percentage;

  FunnelStage({
    required this.stage,
    required this.count,
    required this.percentage,
  });

  factory FunnelStage.fromJson(Map<String, dynamic> json) {
    return FunnelStage(
      stage: json['stage'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}
