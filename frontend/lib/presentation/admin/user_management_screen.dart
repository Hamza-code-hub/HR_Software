import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
// Providers
final _userListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final list = await ref.watch(apiClientProvider).get('/api/users') as List;
  return list.cast<Map<String, dynamic>>();
});

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});
  @override
  ConsumerState<UserManagementScreen> createState() => _State();
}

class _State extends ConsumerState<UserManagementScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(_userListProvider);

    return Column(
      children: [
        // ── Page header ──────────────────────────────────────────────────────
        _PageHeader(
          title: 'User Management',
          subtitle: 'Invite users and assign roles for this organization',
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Invite User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showAddUserDialog(context),
            ),
          ],
        ),

        // ── Search + list ────────────────────────────────────────────────────
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:   (e, _) => _ErrorView(message: e is AppException ? e.message : e.toString(), onRetry: () => ref.refresh(_userListProvider)),
            data: (users) {
              final filtered = _search.isEmpty
                  ? users
                  : users.where((u) => (u['email'] as String? ?? '').toLowerCase().contains(_search.toLowerCase())).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by email...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true, fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                  if (filtered.isEmpty)
                    const Expanded(child: Center(child: Text('No users found.', style: TextStyle(color: Color(0xFF64748B)))))
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _UserCard(
                          user: filtered[i],
                          onRoleChanged: (r) => _updateRole(filtered[i]['id'] as String, r),
                          onRemove: () => _removeUser(filtered[i]['id'] as String),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _updateRole(String userId, String role) async {
    try {
      await ref.read(apiClientProvider).put('/api/users/$userId/role', body: {'role': role});
      ref.invalidate(_userListProvider);
      if (mounted) _snack('Role updated to $role', success: true);
    } on AppException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _removeUser(String userId) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => _ConfirmDialog(title: 'Remove User', message: 'This will remove the user from your organization.'));
    if (ok != true || !mounted) return;
    try {
      await ref.read(apiClientProvider).delete('/api/users/$userId');
      ref.invalidate(_userListProvider);
      if (mounted) _snack('User removed', success: true);
    } on AppException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  void _showAddUserDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl  = TextEditingController();
    String role = 'employee';
    bool loading = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Invite User', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: emailCtrl,   decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: passCtrl,    decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()), obscureText: true),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                items: ['admin', 'hr', 'accounting', 'employee'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                onChanged: (v) => setState(() => role = v ?? 'employee'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            if (loading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white),
                onPressed: () async {
                  setState(() => loading = true);
                  try {
                    await ref.read(apiClientProvider).post('/api/users', body: {
                      'email': emailCtrl.text.trim(), 'password': passCtrl.text, 'role': role,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    ref.invalidate(_userListProvider);
                    if (mounted) _snack('User invited!', success: true);
                  } on AppException catch (e) {
                    if (mounted) _snack(e.message);
                    setState(() => loading = false);
                  }
                },
                child: const Text('Invite'),
              ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), behavior: SnackBarBehavior.floating,
      backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
    ));
  }
}

// ── User card ────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onRoleChanged, required this.onRemove});
  final Map<String, dynamic> user;
  final void Function(String) onRoleChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final email = user['email'] as String? ?? '';
    final role  = user['role']  as String? ?? 'employee';
    final color = _roleColor(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(30),
            child: Text(email.isNotEmpty ? email[0].toUpperCase() : '?', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(email, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                Text(user['id'] as String? ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(20)),
            child: DropdownButton<String>(
              value: role,
              underline: const SizedBox(),
              isDense: true,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
              items: ['admin', 'hr', 'accounting', 'employee'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) { if (v != null) onRoleChanged(v); },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.person_remove_rounded, color: Color(0xFFEF4444), size: 20), onPressed: onRemove),
        ],
      ),
    );
  }

  Color _roleColor(String role) => switch (role) {
    'admin'      => const Color(0xFF3B82F6),
    'hr'         => const Color(0xFF8B5CF6),
    'accounting' => const Color(0xFF10B981),
    _            => const Color(0xFF64748B),
  };
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.subtitle, this.actions = const []});
  final String title, subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            ]),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
    ]));
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.title, required this.message});
  final String title, message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
