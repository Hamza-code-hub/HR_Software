import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import 'models/onboarding.dart';

final onboardingRepositoryProvider = Provider((ref) {
  final client = ref.watch(apiClientProvider);
  return OnboardingRepository(client);
});

final offerLettersProvider = FutureProvider<List<OfferLetter>>((ref) async {
  return ref.watch(onboardingRepositoryProvider).listOffers();
});

final employeeContractsProvider = FutureProvider<List<EmployeeContract>>((ref) async {
  return ref.watch(onboardingRepositoryProvider).listContracts();
});

class OnboardingRepository {
  final ApiClient _client;

  OnboardingRepository(this._client);

  Future<List<OfferLetter>> listOffers() async {
    final res = await _client.get('/api/onboarding/offers');
    return (res as List).map((e) => OfferLetter.fromJson(e)).toList();
  }

  Future<OfferLetter> createOffer(OfferLetter offer) async {
    final res = await _client.post('/api/onboarding/offers', body: offer.toJson());
    return OfferLetter.fromJson(res);
  }

  Future<List<EmployeeContract>> listContracts() async {
    final res = await _client.get('/api/onboarding/contracts');
    return (res as List).map((e) => EmployeeContract.fromJson(e)).toList();
  }

  Future<EmployeeContract> createContract(EmployeeContract contract) async {
    final res = await _client.post('/api/onboarding/contracts', body: contract.toJson());
    return EmployeeContract.fromJson(res);
  }
}
