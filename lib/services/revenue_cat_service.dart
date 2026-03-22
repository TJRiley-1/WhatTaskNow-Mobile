import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

/// Subscription status derived from RevenueCat entitlements.
enum SubscriptionStatus {
  /// Active trial period.
  trial,

  /// Active paid subscription or lifetime purchase.
  active,

  /// Trial or subscription has expired.
  expired,

  /// Never purchased / no entitlement.
  free,
}

class RevenueCatService {
  RevenueCatService._();
  static final instance = RevenueCatService._();

  static const _entitlementId = 'premium';
  bool _initialized = false;

  /// Initialize RevenueCat SDK. Call after Supabase auth is ready.
  Future<void> init() async {
    if (_initialized) return;

    final apiKey = Platform.isIOS
        ? Env.revenueCatAppleKey
        : Env.revenueCatGoogleKey;

    final config = PurchasesConfiguration(apiKey);

    // Identify with Supabase user ID if logged in
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      config.appUserID = user.id;
    }

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    await Purchases.configure(config);

    _initialized = true;
    debugPrint('RevenueCatService: initialized');
  }

  /// Identify user after login (e.g., after Supabase auth).
  Future<void> identify(String userId) async {
    await Purchases.logIn(userId);
    debugPrint('RevenueCatService: identified user $userId');
  }

  /// Log out (on sign out).
  Future<void> logOut() async {
    if (await Purchases.isAnonymous) return;
    await Purchases.logOut();
  }

  /// Check if user has premium entitlement.
  Future<bool> checkEntitlement() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.all[_entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('RevenueCatService: error checking entitlement: $e');
      return false;
    }
  }

  /// Get current subscription status.
  SubscriptionStatus getStatus(CustomerInfo info) {
    final entitlement = info.entitlements.all[_entitlementId];
    if (entitlement == null || !entitlement.isActive) {
      // Check if they ever had it (expired)
      if (info.entitlements.all.containsKey(_entitlementId)) {
        return SubscriptionStatus.expired;
      }
      return SubscriptionStatus.free;
    }

    if (entitlement.periodType == PeriodType.trial) {
      return SubscriptionStatus.trial;
    }

    return SubscriptionStatus.active;
  }

  /// Get trial end date if in trial.
  DateTime? getTrialEndDate(CustomerInfo info) {
    final entitlement = info.entitlements.all[_entitlementId];
    if (entitlement == null) return null;
    if (entitlement.periodType != PeriodType.trial) return null;
    final exp = entitlement.expirationDate;
    if (exp == null) return null;
    return DateTime.tryParse(exp);
  }

  /// Fetch available offerings (packages with localised prices).
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('RevenueCatService: error fetching offerings: $e');
      return null;
    }
  }

  /// Purchase a package.
  Future<bool> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      final isPremium =
          customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;

      // Sync to Supabase
      if (isPremium) {
        await _syncToSupabase(true);
      }

      return isPremium;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('RevenueCatService: purchase cancelled');
        return false;
      }
      rethrow;
    }
  }

  /// Restore purchases.
  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      final isPremium =
          info.entitlements.all[_entitlementId]?.isActive ?? false;
      await _syncToSupabase(isPremium);
      return isPremium;
    } catch (e) {
      debugPrint('RevenueCatService: error restoring: $e');
      return false;
    }
  }

  /// Stream of CustomerInfo changes (real-time entitlement updates).
  /// Wraps RevenueCat's callback-based listener as a broadcast stream.
  Stream<CustomerInfo> get customerInfoStream {
    final controller = StreamController<CustomerInfo>.broadcast(
      onListen: () {
        Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdate);
      },
      onCancel: () {
        Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdate);
      },
    );
    _customerInfoController = controller;
    return controller.stream;
  }

  StreamController<CustomerInfo>? _customerInfoController;

  void _onCustomerInfoUpdate(CustomerInfo info) {
    _customerInfoController?.add(info);
    // Sync premium status to Supabase whenever it changes
    final isPremium = info.entitlements.all[_entitlementId]?.isActive ?? false;
    _syncToSupabase(isPremium);
  }

  /// Sync premium status back to Supabase profiles for server-side queries.
  Future<void> _syncToSupabase(bool isPremium) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await Supabase.instance.client
          .from('profiles')
          .update({'is_premium': isPremium}).eq('id', user.id);
    } catch (e) {
      debugPrint('RevenueCatService: error syncing to Supabase: $e');
    }
  }
}
