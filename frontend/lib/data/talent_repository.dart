import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import 'models/talent.dart';

final talentRepositoryProvider = Provider((ref) {
  final client = ref.watch(apiClientProvider);
  return TalentRepository(client);
});

final trainingsProvider = FutureProvider<List<Training>>((ref) async {
  return ref.watch(talentRepositoryProvider).listTrainings();
});

final performanceReviewsProvider = FutureProvider<List<PerformanceReview>>((ref) async {
  return ref.watch(talentRepositoryProvider).listPerformanceReviews();
});

class TalentRepository {
  final ApiClient _client;

  TalentRepository(this._client);

  Future<List<Training>> listTrainings() async {
    final res = await _client.get('/api/talent/trainings');
    return (res as List).map((e) => Training.fromJson(e)).toList();
  }

  Future<List<PerformanceReview>> listPerformanceReviews() async {
    final res = await _client.get('/api/talent/performance-reviews');
    return (res as List).map((e) => PerformanceReview.fromJson(e)).toList();
  }
}
