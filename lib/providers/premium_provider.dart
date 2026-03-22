import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/revenue_cat_service.dart';
import 'profile_provider.dart';

/// Stream of RevenueCat CustomerInfo — real-time entitlement changes.
final customerInfoProvider = StreamProvider<CustomerInfo>((ref) {
  return RevenueCatService.instance.customerInfoStream;
});

/// Whether the user has an active premium entitlement.
/// Falls back to Supabase profile.isPremium while RC loads.
final isPremiumProvider = Provider<bool>((ref) {
  final rcInfo = ref.watch(customerInfoProvider).valueOrNull;
  if (rcInfo != null) {
    return rcInfo.entitlements.all['premium']?.isActive ?? false;
  }
  // Fallback: cached value from Supabase profile
  final profile = ref.watch(profileProvider).valueOrNull;
  return profile?.isPremium ?? false;
});

/// Current subscription status.
final subscriptionStatusProvider = Provider<SubscriptionStatus>((ref) {
  final rcInfo = ref.watch(customerInfoProvider).valueOrNull;
  if (rcInfo == null) return SubscriptionStatus.free;
  return RevenueCatService.instance.getStatus(rcInfo);
});

/// Trial end date (null if not in trial).
final trialEndDateProvider = Provider<DateTime?>((ref) {
  final rcInfo = ref.watch(customerInfoProvider).valueOrNull;
  if (rcInfo == null) return null;
  return RevenueCatService.instance.getTrialEndDate(rcInfo);
});
