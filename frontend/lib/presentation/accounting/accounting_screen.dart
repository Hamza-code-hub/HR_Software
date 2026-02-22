import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../data/accounting_repository.dart';

class AccountingScreen extends ConsumerStatefulWidget {
  const AccountingScreen({super.key});
  @override
  ConsumerState<AccountingScreen> createState() => _State();
}

class _State extends ConsumerState<AccountingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Account>      _accounts = [];
  List<JournalEntry> _journals = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this)..addListener(() => setState(() {}));
    _loadAll();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(accountingRepositoryProvider);
      _accounts = await repo.listAccounts();
      _journals = await repo.listJournals();
      setState(() => _loading = false);
    } on AppException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ───────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Accounting', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  SizedBox(height: 2),
                  Text('Chart of accounts and journal entries', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ]),
              ),
              if (_tabs.index == 0)
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('New Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: _addAccount,
                )
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('New Journal Entry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: _addJournalEntry,
                ),
            ],
          ),
        ),

        // ── Summary stats ────────────────────────────────────────────────────
        if (!_loading && _error == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                _SummaryBadge(label: 'Total Accounts', value: _accounts.length.toString(), color: const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _SummaryBadge(label: 'Journal Entries', value: _journals.length.toString(), color: const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _SummaryBadge(label: 'Assets', value: _accounts.where((a) => a.type == 'asset').length.toString(), color: const Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                _SummaryBadge(label: 'Liabilities', value: _accounts.where((a) => a.type == 'liability').length.toString(), color: const Color(0xFFEF4444)),
              ],
            ),
          ),

        // ── Tabs ─────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            labelColor: const Color(0xFF3B82F6),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF3B82F6),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [Tab(text: 'Chart of Accounts'), Tab(text: 'Journal Entries')],
          ),
        ),
        const Divider(height: 1),

        // ── Content ───────────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                      const SizedBox(height: 12),
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadAll, child: const Text('Retry')),
                    ]))
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        // Accounts tab
                        _accounts.isEmpty
                            ? const Center(child: Text('No accounts. Add one!', style: TextStyle(color: Color(0xFF64748B))))
                            : ListView.separated(
                                padding: const EdgeInsets.all(24),
                                itemCount: _accounts.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, i) => _AccountCard(account: _accounts[i]),
                              ),

                        // Journal entries tab
                        _journals.isEmpty
                            ? const Center(child: Text('No journal entries yet.', style: TextStyle(color: Color(0xFF64748B))))
                            : ListView.separated(
                                padding: const EdgeInsets.all(24),
                                itemCount: _journals.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, i) => _JournalCard(entry: _journals[i]),
                              ),
                      ],
                    ),
        ),
      ],
    );
  }

  Future<void> _addAccount() async {
    final nameCtrl = TextEditingController();
    String type = 'asset';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('New Account', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Account Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              items: ['asset', 'liability', 'expense', 'revenue', 'equity']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
              onChanged: (v) => setState(() => type = v ?? type),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
              onPressed: () { if (nameCtrl.text.trim().isNotEmpty) Navigator.pop(ctx, true); },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(accountingRepositoryProvider).createAccount(nameCtrl.text.trim(), type);
      _loadAll();
      if (mounted) _snack('Account created!', success: true);
    } on AppException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _addJournalEntry() async {
    final descCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Journal Entry', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 2),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white),
            onPressed: () { if (descCtrl.text.trim().isNotEmpty) Navigator.pop(context, true); },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(accountingRepositoryProvider).createJournal(dateCtrl.text, descCtrl.text.trim(), []);
      _loadAll();
      if (mounted) _snack('Journal entry created!', success: true);
    } on AppException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  void _snack(String msg, {bool success = false}) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
  );
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    final colors = {
      'asset':     const Color(0xFF10B981),
      'liability': const Color(0xFFEF4444),
      'expense':   const Color(0xFFF59E0B),
      'revenue':   const Color(0xFF3B82F6),
      'equity':    const Color(0xFF8B5CF6),
    };
    final color = colors[account.type] ?? const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.account_balance_wallet_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(account.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B), fontSize: 14)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(20)),
                child: Text(account.type.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Balance', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            Text(
              account.balance >= 0 ? '+${account.balance.toStringAsFixed(2)}' : account.balance.toStringAsFixed(2),
              style: TextStyle(color: account.balance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ]),
        ],
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  const _JournalCard({required this.entry});
  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF3B82F6).withAlpha(25), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF3B82F6), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.description ?? 'Journal Entry', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B), fontSize: 14)),
              Text(entry.date, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({required this.label, required this.value, required this.color});
  final String label, value;
  final Color  color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withAlpha(50))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ]),
    );
  }
}
