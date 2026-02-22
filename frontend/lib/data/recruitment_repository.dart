import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import 'models/recruitment.dart';
import 'auth_repository.dart';

final recruitmentRepositoryProvider = Provider((ref) {
  final client = ref.watch(apiClientProvider);
  return RecruitmentRepository(client, ref);
});

final jobPostingsProvider = FutureProvider<List<JobPosting>>((ref) async {
  return ref.watch(recruitmentRepositoryProvider).listJobPostings();
});

final candidatesProvider = FutureProvider<List<Candidate>>((ref) async {
  return ref.watch(recruitmentRepositoryProvider).listCandidates();
});

final interviewsProvider = FutureProvider<List<Interview>>((ref) async {
  return ref.watch(recruitmentRepositoryProvider).listInterviews();
});

class RecruitmentRepository {
  final ApiClient _client;
  final Ref _ref;

  RecruitmentRepository(this._client, this._ref);

  Future<List<JobPosting>> listJobPostings() async {
    final res = await _client.get('/api/recruitment/postings');
    return (res as List).map((e) => JobPosting.fromJson(e)).toList();
  }

  Future<JobPosting> createJobPosting(Map<String, dynamic> data) async {
    final res = await _client.post('/api/recruitment/postings', body: data);
    return JobPosting.fromJson(res);
  }

  Future<List<Candidate>> listCandidates() async {
    final res = await _client.get('/api/recruitment/candidates');
    return (res as List).map((e) => Candidate.fromJson(e)).toList();
  }

  Future<List<Interview>> listInterviews() async {
    final res = await _client.get('/api/recruitment/interviews');
    return (res as List).map((e) => Interview.fromJson(e)).toList();
  }
}
