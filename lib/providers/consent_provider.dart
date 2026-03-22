import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/consent_service.dart';

/// Async provider that initializes consent on first read.
final consentStatusProvider = FutureProvider<bool>((ref) async {
  await ConsentService.instance.initialize();
  return ConsentService.instance.canRequestAds;
});

/// Whether ads can be shown right now.
final canShowAdsProvider = Provider<bool>((ref) {
  return ref.watch(consentStatusProvider).valueOrNull ?? false;
});
