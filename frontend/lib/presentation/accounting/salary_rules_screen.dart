import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SalaryRule {
  final String id;
  final String name;
  final String type; // 'Earning' or 'Deduction'
  final bool isFixed; // true for fixed amount, false for percentage
  final double value;
  final bool isActive;

  SalaryRule({
    required this.id,
    required this.name,
    required this.type,
    required this.isFixed,
    required this.value,
    this.isActive = true,
  });
}

final salaryRulesProvider = StateProvider<List<SalaryRule>>((ref) {
  return [
    SalaryRule(id: '1', name: 'Basic Salary', type: 'Earning', isFixed: false, value: 50.0),
    SalaryRule(id: '2', name: 'House Rent Allowance', type: 'Earning', isFixed: false, value: 20.0),
    SalaryRule(id: '3', name: 'Medical Allowance', type: 'Earning', isFixed: true, value: 5000.0),
    SalaryRule(id: '4', name: 'Provident Fund', type: 'Deduction', isFixed: false, value: 10.0),
    SalaryRule(id: '5', name: 'Income Tax', type: 'Deduction', isFixed: false, value: 5.0),
  ];
});

class SalaryRulesScreen extends ConsumerWidget {
  const SalaryRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(salaryRulesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Salary Rules', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implement add rule dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Rule feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Salary Components',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Define earnings and deductions structures.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: rules.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final rule = rules[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: rule.type == 'Earning' 
                            ? Colors.green.withOpacity(0.1) 
                            : Colors.red.withOpacity(0.1),
                        child: Icon(
                          rule.type == 'Earning' ? Icons.arrow_upward : Icons.arrow_downward,
                          color: rule.type == 'Earning' ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(
                        rule.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${rule.type} • ${rule.isFixed ? 'Fixed Amount' : 'Percentage of Base'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            rule.isFixed ? 'PKR ${rule.value.toStringAsFixed(0)}' : '${rule.value}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Switch(
                            value: rule.isActive,
                            onChanged: (val) {
                              // Mock toggle
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
