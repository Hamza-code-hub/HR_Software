import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/accounting_repository.dart';

class AccountingScreen extends ConsumerStatefulWidget {
  const AccountingScreen({super.key});

  @override
  ConsumerState<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends ConsumerState<AccountingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  String? _error;
  List<Account> _accounts = [];
  List<JournalEntry> _journals = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadAccounts();
    _loadJournals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(accountingRepositoryProvider);
      final list = await repo.listAccounts();
      setState(() {
        _accounts = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadJournals() async {
    try {
      final repo = ref.read(accountingRepositoryProvider);
      final list = await repo.listJournals();
      setState(() => _journals = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _addAccount() async {
    final nameController = TextEditingController();
    String type = 'asset';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('New account'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                    items: ['asset', 'liability', 'expense', 'revenue']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => type = v ?? type),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    try {
      final repo = ref.read(accountingRepositoryProvider);
      await repo.createAccount(name, type);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created')));
        _loadAccounts();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounting'),
        leading: BackButton(onPressed: () => context.pop()),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Accounts'),
            Tab(text: 'Journal entries'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _loadAccounts, child: const Text('Retry')),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _accounts.length,
                      itemBuilder: (_, i) {
                        final a = _accounts[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(a.name),
                            subtitle: Text('${a.type} • Balance: ${a.balance.toStringAsFixed(2)}'),
                          ),
                        );
                      },
                    ),
          _journals.isEmpty && _error == null
              ? const Center(child: Text('No journal entries'))
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _loadJournals, child: const Text('Retry')),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _journals.length,
                      itemBuilder: (_, i) {
                        final j = _journals[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(j.description ?? 'Journal entry'),
                            subtitle: Text(j.date),
                          ),
                        );
                      },
                    ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _addAccount,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
