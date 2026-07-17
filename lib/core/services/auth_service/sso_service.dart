import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cashew_marketplace/core/services/feature_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class GoogleSignInService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _auth.signOut();

      if (kIsWeb) {
        return await _signInWeb();
      } else {
        return await _signInNative();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _mapFirebaseError(e.code);
    } on PlatformException catch (e) {
      debugPrint('Platform Error: ${e.code} - ${e.message}');
      if (e.code == 'sign_in_canceled' || e.code == 'sign_in_failed') {
        return null; // user cancelled
      }
      throw Exception('Sign-in failed. Please try again.');
    } on GoogleSignInException catch (e) {
      debugPrint('GoogleSignInException: ${e.code} - ${e.details}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null; // user cancelled — not an error
      }
      throw Exception('Google Sign-In failed: ${e.details}');
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  Future<UserCredential> _signInWeb() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile');
    return await _auth.signInWithPopup(provider);
  }

  Future<UserCredential?> _signInNative() async {
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();

    await googleSignIn.signOut().catchError((_) {});
    await googleSignIn.disconnect().catchError((_) {});

    if (!googleSignIn.supportsAuthenticate()) {
      throw Exception('Google Sign-In is not supported on this device.');
    }

    final googleUser = await googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.disconnect().catchError((_) {});
      await GoogleSignIn.instance.signOut().catchError((_) {});
      await _auth.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out Error: $e');
      rethrow;
    }
  }

  /// Extracts a standard user map from a [UserCredential]
  Map<String, String> extractUserData(UserCredential credential) {
    final user = credential.user!;
    final displayName = user.displayName ?? '';
    return {
      'email': user.email ?? '',
      'name': displayName,
      'firstName': displayName.split(' ').first,
      'lastName': displayName.split(' ').skip(1).join(' '),
      'photoUrl': user.photoURL ?? '',
      'providerId': 'google.com',
      'provideBy': 'google',
    };
  }

  Exception _mapFirebaseError(String code) {
    switch (code) {
      case 'popup-closed-by-user':
      case 'cancelled':
        return Exception('Sign-in was cancelled. Please try again.');
      case 'network-request-failed':
        return Exception(
          'Network error. Please check your internet connection.',
        );
      case 'account-exists-with-different-credential':
        return Exception(
          'An account already exists with this email using a different sign-in method.',
        );
      case 'invalid-credential':
        return Exception('Invalid credentials. Please try again.');
      default:
        return Exception('Authentication failed. Please try again.');
    }
  }
}

class AppleLoginResult {
  final UserCredential userCredential;
  final AuthorizationCredentialAppleID appleCredential;

  AppleLoginResult({
    required this.userCredential,
    required this.appleCredential,
  });
}

class AppleSignInService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<UserCredential?> signInWithApple() async {
    try {
      if (kIsWeb || Platform.isAndroid) {
        final appleProvider = AppleAuthProvider()
          ..addScope('email')
          ..addScope('name');

        if (kIsWeb) {
          return await _firebaseAuth.signInWithPopup(appleProvider);
        }

        return await _firebaseAuth.signInWithProvider(appleProvider);
      }

      final AuthorizationCredentialAppleID appleCredential;
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      return await _firebaseAuth.signInWithCredential(oauthCredential);
    } catch (e) {
      rethrow;
    }
  }
}

Future<Map<String, dynamic>?> ssoLogin({
  required String email,
  required String providerId,
  required String providerBy,
  required String name,
  required String profileImage,
}) async {
  try {
    ApiDioPostService dio = ApiDioPostService();
    // final url = Uri.parse("https://api.kajupro.com/market-auth/sso-login");

    final body = {
      "email": email,
      "provider_id": providerId,
      "provider_by": providerBy,
      "name": name,
      "profilePicture": profileImage,
    };

    final response = await dio.getdata(
      endpoint: "market-auth/sso-login",
      data: body,
    );

    // final response = await http
    //     .post(
    //       url,
    //       headers: {"Content-Type": "application/json", "orgid": "TEAMALPHA"},
    //       body: jsonEncode(body),
    //     )
    //     .timeout(const Duration(seconds: 30));

    if (response['status'] == "success") {
      return response;
    } else {
      throw Exception(response['message'] ?? "SSO Login Failed");
    }
  } catch (e) {
    rethrow;
  }
}
