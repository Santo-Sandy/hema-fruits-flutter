import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cashew_marketplace/core/services/api_service.dart';
import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
import 'package:flutter/foundation.dart';

/// Production-ready referral deep-link service.
///
/// Responsibilities:
///  - [initialize]         Subscribe to incoming URIs (foreground + cold-start)
///  - [handleIncomingUri]  Parse `?ref=` param, validate, store
///  - [getReferralCode]    Read the persisted code (used at registration time)
///  - [clearReferralCode]  Erase after backend confirms successful registration
///  - [fetchMyReferral]    POST `/capitalmarket/refferal` to get the user's
///                         own shareable link + code (JWT-authenticated)
///
/// Usage:
/// ```dart
/// await ReferralService.instance.initialize();           // once in main()
/// final code = await ReferralService.instance.getReferralCode();
/// await ReferralService.instance.clearReferralCode();    // after registration
/// final details = await ReferralService.instance.fetchMyReferral(userId);
/// ```
class ReferralService {
  // ── Singleton ────────────────────────────────────────────────
  ReferralService._();
  static final instance = ReferralService._();

  // ── Internals ────────────────────────────────────────────────
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// Tracks the last URI we processed to prevent duplicate handling
  /// when the OS delivers the same link multiple times.
  Uri? _lastHandledUri;

  bool _initialized = false;

  /// Session-level cache: avoids repeated network calls while the
  /// referral card is visible or the screen is rebuilt.
  ReferralDetails? _cachedDetails;

  // ── Public API ───────────────────────────────────────────────

  /// Call once during app startup (in `main()`) before `runApp()`.
  ///
  /// Handles both:
  /// - Cold start  : app launched directly from a deep link
  /// - Foreground  : link received while app is already running
  ///
  /// Failures are caught and logged; the app continues normally.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // ── Cold-start link ───────────────────────────────────────
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('[ReferralService] Cold-start URI received: $initialUri');
        await handleIncomingUri(initialUri);
      } else {
        debugPrint('[ReferralService] No cold-start URI.');
      }

      // ── Foreground / background link stream ───────────────────
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) async {
          debugPrint('[ReferralService] Foreground URI received: $uri');
          await handleIncomingUri(uri);
        },
        onError: (Object error, StackTrace stack) {
          debugPrint('[ReferralService] Stream error: $error');
        },
      );

      debugPrint('[ReferralService] Initialized successfully.');
    } catch (e, stack) {
      // Initialization must never crash the app.
      debugPrint('[ReferralService] Initialization failed: $e\n$stack');
    }
  }

  /// Parse the URI, extract `?ref=`, validate and persist the code.
  ///
  /// Silently ignores:
  /// - Duplicate URIs (same link delivered twice by the OS)
  /// - Malformed URIs with no query parameters
  /// - Missing or empty `ref` parameter
  Future<void> handleIncomingUri(Uri uri) async {
    try {
      // ── Duplicate guard ───────────────────────────────────────
      if (_lastHandledUri == uri) {
        debugPrint('[ReferralService] Duplicate URI ignored: $uri');
        return;
      }
      _lastHandledUri = uri;

      // ── Validate URI structure ────────────────────────────────
      if (!uri.hasQuery) {
        debugPrint(
          '[ReferralService] URI has no query parameters — ignored: $uri',
        );
        return;
      }

      // ── Extract referral code ─────────────────────────────────
      final ref = uri.queryParameters['ref'];

      if (ref == null || ref.trim().isEmpty) {
        debugPrint('[ReferralService] No `ref` parameter found in URI: $uri');
        return;
      }

      final code = ref.trim();
      debugPrint('[ReferralService] Referral code extracted: $code');

      // ── Persist securely ──────────────────────────────────────
      await saveReferralCode(code);
    } catch (e, stack) {
      debugPrint('[ReferralService] Error handling URI $uri: $e\n$stack');
    }
  }

  /// Returns the stored referral code, or `null` if none is pending.
  Future<String?> getReferralCode() async {
    try {
      final code = await SecureStorageService.getReferralCode();
      debugPrint('[ReferralService] getReferralCode → $code');
      return code;
    } catch (e) {
      debugPrint('[ReferralService] getReferralCode error: $e');
      return null;
    }
  }

  /// Clears the stored referral code.
  ///
  /// Call this ONLY after the backend confirms successful registration.
  Future<void> clearReferralCode() async {
    try {
      await SecureStorageService.clearReferralCode();
      debugPrint('[ReferralService] Referral code cleared.');
    } catch (e) {
      debugPrint('[ReferralService] clearReferralCode error: $e');
    }
  }

  /// Fetches the current user's referral link and code from the backend.
  ///
  /// Endpoint: `POST /capitalmarket/refferal`
  /// Auth    : JWT Bearer token (injected automatically by `_AuthInterceptor`)
  ///
  /// The result is cached in-memory for the lifetime of the session so the
  /// card widget can call this freely without hammering the network.
  ///
  /// Returns `null` if the request fails or the response is malformed.
  Future<ReferralDetails?> fetchMyReferral(String userId) async {
    // ── Return cached value if already loaded ─────────────────
    if (_cachedDetails != null) {
      debugPrint(
        '[ReferralService] fetchMyReferral → returning cached details',
      );
      return _cachedDetails;
    }

    try {
      debugPrint(
        '[ReferralService] fetchMyReferral → calling API for userId: $userId',
      );
      final response = await ApiService.instance.dio.post(
        '/capitalmarket/refferal',
        data: {'userId': userId},
      );

      if (response.statusCode == 200) {
        final body = response.data;
        if (body is Map<String, dynamic> && body['data'] != null) {
          final data = body['data'] as Map<String, dynamic>;
          final details = ReferralDetails(
            referralLink: data['referral_link']?.toString() ?? '',
            referralCode: data['referral_code']?.toString() ?? '',
          );
          _cachedDetails = details;
          debugPrint(
            '[ReferralService] fetchMyReferral → link: ${details.referralLink}, code: ${details.referralCode}',
          );
          return details;
        }
      }
      debugPrint(
        '[ReferralService] fetchMyReferral → unexpected response: ${response.data}',
      );
    } catch (e) {
      debugPrint('[ReferralService] fetchMyReferral error: $e');
    }
    return null;
  }

  Future<void> fetchReferralreward(
    String userId,
    String code,
    String reward,
    String reffered_id,
  ) async {
    // ── Return cached value if already loaded ─────────────────
    if (_cachedDetails != null) {
      debugPrint(
        '[ReferralService] fetchMyReferral → returning cached details',
      );
      // return _cachedDetails;
    }

    try {
      debugPrint(
        '[ReferralService] fetchMyReferral → calling API for userId: $userId',
      );
      final payload = {
        "referralCode": code,
        "points": reward,
        "referrerId": reffered_id,
        "UserId": userId,
        "status": "pending",
        "rewardGiven": false,
        "createdAt": DateTime.now().toIso8601String(),
        "completedAt": null,
      };
      final response = await ApiService.instance.dio.post(
        '/reward',
        data: payload,
      );

      if (response.statusCode == 200) {
        final body = response.data;
        if (body is Map<String, dynamic> && body['data'] != null) {
          final data = body['data'] as Map<String, dynamic>;
          // return details;
        }
      }
      debugPrint(
        '[ReferralService] fetchMyReferral → unexpected response: ${response.data}',
      );
    } catch (e) {
      debugPrint('[ReferralService] fetchMyReferral error: $e');
    }
    return null;
  }

  /// Invalidates the session cache so the next [fetchMyReferral] call
  /// hits the network again (e.g. after a profile update).
  void clearReferralCache() {
    _cachedDetails = null;
    debugPrint('[ReferralService] Referral cache cleared.');
  }

  /// Validates a referral code against the backend.
  ///
  /// Endpoint: `GET /api/referral/validate?code=<code>`
  /// Auth    : None — public endpoint, no JWT required.
  ///
  /// Returns a map with validation details on success, e.g.,
  /// `{ "valid": true, "referrerName": "Santo", "reward": 50 }`
  /// Returns `null` on network failure or an invalid/malformed response.
  Future<Map<String, dynamic>?> validateReferralCode(String code) async {
    try {
      debugPrint('[ReferralService] Validating referral code: $code');
      final response = await ApiService.instance.dio.get(
        '/referral/validate',
        queryParameters: {'code': code},
      );
      if (response.statusCode == 200) {
        final body = response.data;
        if (body is Map<String, dynamic> && body['data'] != null) {
          final data = Map<String, dynamic>.from(body['data']);
          debugPrint('[ReferralService] Validation response: $data');
          return data;
        }
      }
    } catch (e) {
      debugPrint('[ReferralService] Error validating referral code: $e');
    }
    return null;
  }

  /// Cancel the URI stream subscription.
  ///
  /// Not strictly required in most apps (singletons live for the entire
  /// app lifetime) but provided for completeness and testability.
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _initialized = false;
    _cachedDetails = null;
    debugPrint('[ReferralService] Disposed.');
  }

  // ── Private helpers ──────────────────────────────────────────

  Future<void> saveReferralCode(String code) async {
    try {
      await SecureStorageService.saveReferralCode(code);
      debugPrint('[ReferralService] Referral code stored securely: $code');
    } catch (e) {
      debugPrint('[ReferralService] Failed to store referral code: $e');
    }
  }
}

// ── Value model ──────────────────────────────────────────────────────────────

/// Immutable value object holding the data returned by
/// `POST /capitalmarket/refferal`.
class ReferralDetails {
  final String referralLink;
  final String referralCode;

  const ReferralDetails({
    required this.referralLink,
    required this.referralCode,
  });

  bool get isEmpty => referralLink.isEmpty && referralCode.isEmpty;

  @override
  String toString() =>
      'ReferralDetails(link: $referralLink, code: $referralCode)';
}
