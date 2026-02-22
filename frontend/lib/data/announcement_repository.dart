import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import 'models/announcement.dart';

final announcementRepositoryProvider = Provider((ref) {
  final client = ref.watch(apiClientProvider);
  return AnnouncementRepository(client);
});

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  return ref.watch(announcementRepositoryProvider).list();
});

class AnnouncementRepository {
  final ApiClient _client;

  AnnouncementRepository(this._client);

  Future<List<Announcement>> list() async {
    final res = await _client.get('/api/announcements');
    return (res as List).map((e) => Announcement.fromJson(e)).toList();
  }

  Future<Announcement> create(Map<String, dynamic> data) async {
    final res = await _client.post('/api/announcements', body: data);
    return Announcement.fromJson(res);
  }
}
