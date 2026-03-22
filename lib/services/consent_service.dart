import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Wraps Google's User Messaging Platform (UMP) for GDPR consent collection
/// and Apple's App Tracking Transparency (ATT) for iOS.
class ConsentService {
  ConsentService._();
  static final instance = ConsentService._();

  bool _canRequestAds = false;

  /// Whether ads can be loaded (consent obtained or not required).
  bool get canRequestAds => _canRequestAds;

  /// Initialize consent — call BEFORE MobileAds.instance.initialize().
  ///
  /// 1. UMP consent check (GDPR — EEA/UK users)
  /// 2. ATT prompt (iOS only — after UMP)
  /// 3. Update canRequestAds flag
  Future<void> initialize({bool debugEEA = false}) async {
    final params = ConsentRequestParameters();

    if (kDebugMode && debugEEA) {
      final debugSettings = ConsentDebugSettings(
        debugGeography: DebugGeography.debugGeographyEea,
      );
      final debugParams = ConsentRequestParameters(
        consentDebugSettings: debugSettings,
      );
      await _requestConsent(debugParams);
    } else {
      await _requestConsent(params);
    }

    // iOS: request ATT after UMP consent
    if (Platform.isIOS) {
      await _requestATT();
    }
  }

  Future<void> _requestConsent(ConsentRequestParameters params) async {
    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        // Success — show consent form if required
        debugPrint('ConsentService: consent info updated');
        await _showConsentFormIfRequired();
        await _updateCanRequestAds();
        completer.complete();
      },
      (FormError error) {
        debugPrint(
            'ConsentService: error updating consent info: ${error.message}');
        // Fail open for non-EEA users
        _canRequestAds = true;
        completer.complete();
      },
    );

    return completer.future;
  }

  Future<void> _showConsentFormIfRequired() async {
    final completer = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired(
      (FormError? error) {
        if (error != null) {
          debugPrint(
              'ConsentService: consent form error: ${error.message}');
        }
        completer.complete();
      },
    );
    return completer.future;
  }

  Future<void> _requestATT() async {
    try {
      final status =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      debugPrint('ConsentService: ATT current status = $status');

      if (status == TrackingStatus.notDetermined) {
        // Brief delay recommended by Apple for ATT prompt after app launch
        await Future<void>.delayed(const Duration(milliseconds: 500));
        final result =
            await AppTrackingTransparency.requestTrackingAuthorization();
        debugPrint('ConsentService: ATT result = $result');
      }
    } catch (e) {
      debugPrint('ConsentService: ATT error: $e');
    }
  }

  Future<void> _updateCanRequestAds() async {
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    debugPrint('ConsentService: canRequestAds = $_canRequestAds');
  }

  /// Re-show the consent form (for "Manage Privacy" in settings).
  Future<void> showPrivacyOptions() async {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm(
      (FormError? error) {
        if (error != null) {
          debugPrint(
              'ConsentService: privacy options error: ${error.message}');
        }
        completer.complete();
      },
    );
    await completer.future;
    await _updateCanRequestAds();
  }

  /// Reset consent state (debug only).
  Future<void> resetConsent() async {
    if (kDebugMode) {
      await ConsentInformation.instance.reset();
      _canRequestAds = false;
    }
  }
}
