import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref.read(authStateProvider.notifier).login(
        email: _email.text.trim(), password: _password.text,
      );
      if (!mounted) return;
      final role = ref.read(sessionProvider)?.role ?? 'employee';
      context.go(switch (role) { 'admin' => '/admin', 'accounting' => '/accounting', _ => '/dashboard' });
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('Login failed. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ── Left: Brand panel ───────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A5F), Color(0xFF1D4ED8)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.business_center_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('HR SaaS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Enterprise Platform', style: TextStyle(color: Color(0xFF93BBFB), fontSize: 12)),
                      ]),
                    ]),
                    const Spacer(),
                    const Text(
                      'Everything your\nbusiness needs',
                      style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, height: 1.1),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Manage HR, payroll, attendance, leave, and accounting in one unified platform.',
                      style: TextStyle(color: Color(0xFF93BBFB), fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 40),
                    // Feature badges
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _FeatureBadge(icon: Icons.people_rounded,          label: 'HR Management'),
                      _FeatureBadge(icon: Icons.payments_rounded,        label: 'Payroll'),
                      _FeatureBadge(icon: Icons.account_balance_rounded, label: 'Accounting'),
                      _FeatureBadge(icon: Icons.event_note_rounded,      label: 'Leave Tracking'),
                      _FeatureBadge(icon: Icons.access_time_rounded,     label: 'Attendance'),
                      _FeatureBadge(icon: Icons.shield_rounded,          label: 'Role-Based Access'),
                    ]),
                    const Spacer(),
                    const Text('Secure • Multi-Tenant • Enterprise', style: TextStyle(color: Color(0xFF475569), fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),

          // ── Right: Login form ────────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Welcome back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const SizedBox(height: 6),
                          const Text('Sign in to your account', style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
                          const SizedBox(height: 36),

                          // Email
                          _label('Email address'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration('you@company.com', Icons.email_outlined),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Email is required' : null,
                          ),
                          const SizedBox(height: 16),

                          // Password
                          _label('Password'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            decoration: _inputDecoration('••••••••', Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF94A3B8)),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 28),

                          // Submit button
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1D4ED8),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(0xFF93C5FD),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                  : const Text('Sign in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Sign up link
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Text("Don't have an account?", style: TextStyle(color: Color(0xFF64748B))),
                            TextButton(
                              onPressed: () => context.go('/signup'),
                              child: const Text('Create one', style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600)),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151)));

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
    prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444))),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
  );
}

class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({required this.icon, required this.label});
  final IconData icon;
  final String   label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }
}
