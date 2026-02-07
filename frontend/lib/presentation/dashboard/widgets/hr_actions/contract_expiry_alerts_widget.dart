import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ContractExpiryAlertsWidget extends StatelessWidget {
  const ContractExpiryAlertsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expiringContracts = [
      {
        'name': 'Robert Chen',
        'role': 'Senior Developer',
        'expiryDate': now.add(const Duration(days: 5)),
        'type': 'Full-time',
      },
      {
        'name': 'Lisa Williams',
        'role': 'Marketing Manager',
        'expiryDate': now.add(const Duration(days: 12)),
        'type': 'Contract',
      },
      {
        'name': 'David Martinez',
        'role': 'UI Designer',
        'expiryDate': now.add(const Duration(days: 18)),
        'type': 'Contract',
      },
      {
        'name': 'Jennifer Lee',
        'role': 'Sales Executive',
        'expiryDate': now.add(const Duration(days: 25)),
        'type': 'Full-time',
      },
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
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Contract Expiry',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEF4444)),
                ),
                child: Text(
                  '${expiringContracts.length} Expiring',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Count
          const Row(
            children: [
              Text(
                'Next 30 Days',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Contract List
          ...expiringContracts.map((contract) {
            final daysRemaining = (contract['expiryDate']! as DateTime)
                .difference(now)
                .inDays;
            return _buildContractItem(
              name: contract['name']! as String,
              role: contract['role']! as String,
              type: contract['type']! as String,
              expiryDate: contract['expiryDate']! as DateTime,
              daysRemaining: daysRemaining,
            );
          }),
          
          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_active_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Renewal Reminders',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getUrgencyColor(int daysRemaining) {
    if (daysRemaining < 7) return const Color(0xFFEF4444);
    if (daysRemaining < 15) return const Color(0xFFF59E0B);
    return const Color(0xFFFBBF24);
  }

  Widget _buildContractItem({
    required String name,
    required String role,
    required String type,
    required DateTime expiryDate,
    required int daysRemaining,
  }) {
    final color = _getUrgencyColor(daysRemaining);
    final urgencyLabel = daysRemaining < 7
        ? 'Critical'
        : daysRemaining < 15
            ? 'Urgent'
            : 'Soon';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Countdown Circle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  daysRemaining.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1,
                  ),
                ),
                Text(
                  'days',
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        urgencyLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Expires: ${DateFormat('MMM d, yyyy').format(expiryDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
