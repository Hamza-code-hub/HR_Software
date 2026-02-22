import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';

// ────────────────────────────────────────────────────────────────
// Models
// ────────────────────────────────────────────────────────────────
class Account {
  final String id;
  final String tenantId;
  final String name;
  final String type;
  final double balance;
  final String createdAt;

  Account({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.type,
    required this.balance,
    required this.createdAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id:        json['id']         as String,
      tenantId:  json['tenant_id']  as String,
      name:      json['name']       as String,
      type:      json['type']       as String,
      balance:   (json['balance']   as num? ?? 0).toDouble(),
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class JournalEntry {
  final String  id;
  final String  tenantId;
  final String  date;
  final String? description;
  final String  createdAt;

  JournalEntry({
    required this.id,
    required this.tenantId,
    required this.date,
    this.description,
    required this.createdAt,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id:          json['id']          as String,
      tenantId:    json['tenant_id']   as String,
      date:        json['date']        as String,
      description: json['description'] as String?,
      createdAt:   json['created_at']  as String? ?? '',
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Repository
// ────────────────────────────────────────────────────────────────
final accountingRepositoryProvider = Provider<AccountingRepository>((ref) {
  return AccountingRepository(ref.watch(apiClientProvider));
});

class AccountingRepository {
  AccountingRepository(this._client);
  final ApiClient _client;

  Future<List<Account>> listAccounts() async {
    final res = await _client.get('/api/accounts') as List;
    return res.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Account> createAccount(String name, String type) async {
    final res = await _client.post('/api/accounts', body: {'name': name, 'type': type}) as Map<String, dynamic>;
    return Account.fromJson(res);
  }

  Future<List<JournalEntry>> listJournals({String? from, String? to}) async {
    final Map<String, String> query = {};
    if (from != null) query['from'] = from;
    if (to   != null) query['to']   = to;
    final res = await _client.get('/api/journals', queryParameters: query.isEmpty ? null : query) as List;
    return res.map((e) => JournalEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<JournalEntry> createJournal(
    String date,
    String description,
    List<Map<String, dynamic>> lines,
  ) async {
    final res = await _client.post('/api/journals', body: {
      'date':        date,
      'description': description,
      'lines':       lines,
    }) as Map<String, dynamic>;
    return JournalEntry.fromJson(res);
  }
}

// ────────────────────────────────────────────────────────────────
// Providers
// ────────────────────────────────────────────────────────────────
final accountsListProvider = FutureProvider.autoDispose<List<Account>>((ref) async {
  return ref.watch(accountingRepositoryProvider).listAccounts();
});

final journalsListProvider = FutureProvider.autoDispose.family<List<JournalEntry>, ({String? from, String? to})>(
  (ref, args) async {
    return ref.watch(accountingRepositoryProvider).listJournals(from: args.from, to: args.to);
  },
);
