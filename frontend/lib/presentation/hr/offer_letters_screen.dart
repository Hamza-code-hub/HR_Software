import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../data/onboarding_repository.dart';
import '../../data/models/onboarding.dart';
import 'package:intl/intl.dart';

class OfferLettersScreen extends ConsumerStatefulWidget {
  const OfferLettersScreen({super.key});

  @override
  ConsumerState<OfferLettersScreen> createState() => _OfferLettersScreenState();
}

class _OfferLettersScreenState extends ConsumerState<OfferLettersScreen> {
  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(offerLettersProvider);
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surfaceBg,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            Expanded(
              child: offersAsync.when(
                data: (list) {
                  if (list.isEmpty) return _buildEmptyState();
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _OfferCard(offer: list[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {}, // TODO: Create Offer dialog
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Offer'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Offer Letters',
          style: context.appColors.textPrimary == Colors.white 
            ? const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
            : TextStyle(color: context.appColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage job offers, track acceptance, and follow up with candidates.',
          style: TextStyle(color: context.appColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.drafts_rounded, size: 64, color: context.appColors.textTertiary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No offer letters generated yet.'),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});
  final OfferLetter offer;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusColor = _getStatusColor(offer.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.description_rounded, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.candidateName ?? 'Candidate',
                  style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${offer.jobTitle} • \$${offer.salaryOffered.toStringAsFixed(0)}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Valid until: ${offer.validUntil != null ? DateFormat('MMM dd, yyyy').format(offer.validUntil!) : 'N/A'}',
                  style: TextStyle(color: colors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _badge(offer.status.toUpperCase(), statusColor),
              const SizedBox(height: 8),
              Row(
                children: [
                  _actionIcon(Icons.send_rounded, Colors.blue),
                  const SizedBox(width: 8),
                  _actionIcon(Icons.edit_rounded, Colors.orange),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _actionIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Color _getStatusColor(String status) {
    return switch (status.toLowerCase()) {
      'accepted' => const Color(0xFF10B981),
      'declined' => const Color(0xFFEF4444),
      'sent'     => const Color(0xFF3B82F6),
      'expired'  => const Color(0xFF6B7280),
      _          => const Color(0xFFF59E0B),
    };
  }
}
