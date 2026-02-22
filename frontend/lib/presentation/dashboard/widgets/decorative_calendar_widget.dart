import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DecorativeCalendarWidget extends StatefulWidget {
  const DecorativeCalendarWidget({super.key});

  @override
  State<DecorativeCalendarWidget> createState() =>
      _DecorativeCalendarWidgetState();
}

class _DecorativeCalendarWidgetState extends State<DecorativeCalendarWidget> {
  final DateTime now = DateTime.now();
  
  // Mock event data - different colored dots for different event types
  final Map<int, List<Color>> eventDots = {
    5: [const Color(0xFF10B981)], // Joining
    8: [const Color(0xFFEF4444)], // Last working day
    12: [const Color(0xFFF59E0B)], // Birthday
    15: [const Color(0xFF0EA5E9), const Color(0xFFF59E0B)], // Meeting + Birthday
    18: [const Color(0xFF10B981)], // Joining
    22: [const Color(0xFF0EA5E9)], // Meeting
    28: [const Color(0xFFEF4444)], // Last working day
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: Theme.of(context).cardColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat('MMMM yyyy').format(now),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Calendar Grid
          _buildCalendarGrid(),
          
          const SizedBox(height: 20),

          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildLegendItem('Joining', const Color(0xFF10B981)),
              _buildLegendItem('Exit', const Color(0xFFEF4444)),
              _buildLegendItem('Birthday', const Color(0xFFF59E0B)),
              _buildLegendItem('Meeting', const Color(0xFF0EA5E9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    // Week day headers
    const weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    
    return Column(
      children: [
        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays.map((day) {
            return SizedBox(
              width: 36,
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        
        // Calendar days
        ...List.generate(6, (weekIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (dayIndex) {
                final dayNumber = weekIndex * 7 + dayIndex - startWeekday + 1;
                
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox(width: 36, height: 36);
                }
                
                return _buildDayCell(dayNumber);
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDayCell(int day) {
    final isToday = day == now.day;
    final hasEvents = eventDots.containsKey(day);
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isToday
              ? const Color(0xFF8B5CF6)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday
                    ? Colors.white
                    : const Color(0xFF1E293B),
              ),
            ),
            if (hasEvents) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: eventDots[day]!.take(3).map((color) {
                  return Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}