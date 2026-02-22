// ignore_for_file: unused_element, unused_import, unused_local_variable
import 'package:flutter/material.dart';

class NewJoinersWidget extends StatefulWidget {
  const NewJoinersWidget({super.key});

  @override
  State<NewJoinersWidget> createState() => _NewJoinersWidgetState();
}

class _NewJoinersWidgetState extends State<NewJoinersWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _countAnimation;

  final int newJoinersCount = 8;
  final double growthRate = 12.5;
  final List<Map<String, String>> recentJoiners = [
    {'name': 'Sarah Johnson', 'avatar': 'SJ', 'role': 'Engineer'},
    {'name': 'Mike Chen', 'avatar': 'MC', 'role': 'Designer'},
    {'name': 'Anna Davis', 'avatar': 'AD', 'role': 'Marketing'},
    {'name': 'John Smith', 'avatar': 'JS', 'role': 'Sales'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _countAnimation = Tween<double>(begin: 0, end: newJoinersCount.toDouble())
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10B981),
            Color(0xFF059669),
          ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  color: Theme.of(context).cardColor,
                  size: 24,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: Theme.of(context).cardColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${growthRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Theme.of(context).cardColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Animated Count
          AnimatedBuilder(
            animation: _countAnimation,
            builder: (context, child) {
              return Text(
                _countAnimation.value.floor().toString(),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).cardColor,
                  height: 1,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'New Joiners',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This Month',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          
          // Recent Joiners Avatars
          Row(
            children: [
              ...recentJoiners.take(4).map((joiner) {
                final index = recentJoiners.indexOf(joiner);
                return Transform.translate(
                  offset: Offset(-index * 12.0, 0),
                  child: _buildAvatar(joiner['avatar']!),
                );
              }),
              if (newJoinersCount > 4)
                Transform.translate(
                  offset: const Offset(-48, 0),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).cardColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '+${newJoinersCount - 4}',
                        style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String initials) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF10B981), width: 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Color(0xFF10B981),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}