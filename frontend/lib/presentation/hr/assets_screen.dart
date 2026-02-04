import 'package:flutter/material.dart';

class Asset {
  final String id;
  final String name;
  final String type; // 'Laptop', 'Monitor', 'License'
  final String assignedTo;
  final String status; // 'In Use', 'Available', 'Maintenance'

  Asset(this.id, this.name, this.type, this.assignedTo, this.status);
}

class AssetsScreen extends StatelessWidget {
  AssetsScreen({super.key});

  final List<Asset> assets = [
    Asset('1', 'MacBook Pro M2', 'Laptop', 'Ali Khan', 'In Use'),
    Asset('2', 'Dell XPS 15', 'Laptop', 'Fatima Ali', 'In Use'),
    Asset('3', 'LG 27" 4K Monitor', 'Monitor', 'Usman Shah', 'In Use'),
    Asset('4', 'WebStorm License', 'License', 'Sara Ahmed', 'In Use'),
    Asset('5', 'MacBook Air M1', 'Laptop', '-', 'Available'),
    Asset('6', 'Keychron K2', 'Peripheral', '-', 'Available'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('IT Asset Tracking', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Filter Chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('All', true),
                  _buildFilterChip('Laptops', false),
                  _buildFilterChip('Monitors', false),
                  _buildFilterChip('Licenses', false),
                  _buildFilterChip('Available', false),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Assets Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: assets.length,
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(_getIconForType(asset.type), color: Colors.blueGrey),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: asset.status == 'Available' ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  asset.status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: asset.status == 'Available' ? Colors.green : Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(asset.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(asset.type, style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                asset.assignedTo == '-' ? 'Unassigned' : asset.assignedTo,
                                style: TextStyle(
                                  color: asset.assignedTo == '-' ? Colors.grey : Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {},
        backgroundColor: Colors.white,
        selectedColor: Colors.black,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Laptop': return Icons.laptop_mac;
      case 'Monitor': return Icons.monitor;
      case 'License': return Icons.vpn_key;
      default: return Icons.devices;
    }
  }
}
