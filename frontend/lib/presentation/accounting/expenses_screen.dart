import 'package:flutter/material.dart';

class Expense {
  final String id;
  final String employeeName;
  final String title;
  final double amount;
  final String date;
  final String status; // 'Pending', 'Approved', 'Rejected'

  Expense(this.id, this.employeeName, this.title, this.amount, this.date, this.status);
}

class ExpensesScreen extends StatelessWidget {
  ExpensesScreen({super.key});

  final List<Expense> expenses = [
    Expense('1', 'Ali Khan', 'Client Lunch', 5000, '2026-02-01', 'Pending'),
    Expense('2', 'Sara Ahmed', 'Laptop Repair', 2500, '2026-01-28', 'Approved'),
    Expense('3', 'Usman Shah', 'Travel to Lahore', 15000, '2026-01-25', 'Approved'),
    Expense('4', 'Fatima Ali', 'Online Course', 12000, '2026-02-02', 'Pending'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Expense Management', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildStatCard('Pending', '2', Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Approved', '54', Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Total Amount', 'PKR 34.5K', Colors.blue)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenses.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Text(expense.employeeName[0]),
                    ),
                    title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${expense.employeeName} • ${expense.date}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('PKR ${expense.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 16),
                        if (expense.status == 'Pending')
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () {},
                                tooltip: 'Approve',
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () {},
                                tooltip: 'Reject',
                              ),
                            ],
                          )
                        else
                          Chip(
                            label: Text(expense.status),
                            backgroundColor: expense.status == 'Approved' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            labelStyle: TextStyle(color: expense.status == 'Approved' ? Colors.green : Colors.red),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
