import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../data/talent_repository.dart';
import '../../data/models/talent.dart';
import '../../core/app_theme.dart';

class TrainingManagementScreen extends ConsumerStatefulWidget {
  const TrainingManagementScreen({super.key});

  @override
  ConsumerState<TrainingManagementScreen> createState() => _TrainingManagementScreenState();
}

class _TrainingManagementScreenState extends ConsumerState<TrainingManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final trainingsAsync = ref.watch(trainingsProvider);
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surfaceBg,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Training Programs', style: TextStyle(color: colors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Publish and manage internal training catalogs for employee development.', style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 24),
            Expanded(
              child: trainingsAsync.when(
                data: (trainings) {
                  if (trainings.isEmpty) return _buildEmptyState();
                  return ListView.separated(
                    itemCount: trainings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _TrainingCard(training: trainings[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {}, // TODO: Add training dialog
        icon: const Icon(Icons.school_rounded),
        label: const Text('Add Course'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.library_books_outlined, size: 64, color: context.appColors.textTertiary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No training programs published yet.'),
        ],
      ),
    );
  }
}

class _TrainingCard extends StatelessWidget {
  const _TrainingCard({required this.training});
  final Training training;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
            decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.cast_for_education_rounded, color: Color(0xFF8B5CF6)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(training.title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${training.durationHours} hours • Trainer: ${training.trainerName}', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {}, // TODO: Assign training
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              foregroundColor: const Color(0xFF8B5CF6),
              elevation: 0,
            ),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }
}
