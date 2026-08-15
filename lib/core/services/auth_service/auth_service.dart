import 'package:hema_fruits/core/services/auth_service/sso_service.dart';
import 'package:hema_fruits/core/services/feature_services.dart';
import 'package:hema_fruits/core/services/notification/fcm_service.dart';
import 'package:hema_fruits/core/services/offline_queue_service.dart';
import 'package:hema_fruits/shared/local_storage/hive_service.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException({required this.message, this.code});

  @override
  String toString() => message;
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignInAccount();

  User? _currentUser;
  String? username;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  String? _errorMessage;
  String userId = '';

  // Getters
  User? get currentUser => _currentUser;
  bool get loadlogin => true;
  bool get isGoogleLoading => _isGoogleLoading;
  bool get isAppleLoading => _isAppleLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    _initializeAuthListener();
  }

  /// Initialize auth state listener to check for existing sessions
  void _initializeAuthListener() {
    _firebaseAuth.authStateChanges().listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      _isGoogleLoading = true;
      notifyListeners();

      GoogleSignInService googleSignInService = GoogleSignInService();
      UserCredential? userCredential = await googleSignInService
          .signInWithGoogle();
      _currentUser = userCredential?.user;

      // final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // if (googleUser == null) {
      //   throw AuthException(
      //     message: 'Sign-in cancelled',
      //     code: 'USER_CANCELLED',
      //   );
      // }

      // final googleAuth = await googleUser.authentication;

      // final credential = GoogleAuthProvider.credential(
      //   accessToken: googleAuth.accessToken,
      //   idToken: googleAuth.idToken,
      // );

      // final userCredential = await _firebaseAuth.signInWithCredential(
      //   credential,
      // );
      // _currentUser = userCredential.user;
      // _currentUser = FirebaseAuth.instance.currentUser;

      final response = await ssoLogin(
        email: _currentUser?.email ?? '',
        providerId: _currentUser?.uid ?? '',
        providerBy: "google.com",
        name: _currentUser?.displayName ?? '',
        profileImage: _currentUser?.photoURL ?? '',
      );

      if (response != null && response["token"] != null) {
        final token = response["token"];

        await SecureStorageService.saveToken(token);
        await FCMService.initialize();
        Map<String, dynamic> userData = JwtDecoder.decode(token);
        userId = userData['id'];

        await getUser(userId);
      }
    } catch (e) {
      _errorMessage = e.toString();
      throw AuthException(message: _errorMessage!);
    } finally {
      _isGoogleLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithApple(BuildContext context) async {
    try {
      _isAppleLoading = true;
      notifyListeners();

      final appleService = AppleSignInService();

      final userCredential = await appleService.signInWithApple();

      _currentUser = userCredential?.user;

      final response = await ssoLogin(
        email: _currentUser?.email ?? '',
        providerId: _currentUser?.uid ?? '',
        providerBy: "apple.com",
        name: _currentUser?.displayName ?? '',
        profileImage: _currentUser?.photoURL ?? '',
      );

      if (response != null && response["token"] != null) {
        final token = response["token"];

        await SecureStorageService.saveToken(token);

        await FCMService.initialize();

        final userData = JwtDecoder.decode(token);

        userId = userData["id"];

        await getUser(userId);
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrintStack();
      throw AuthException(message: _errorMessage!);
    } finally {
      _isAppleLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signOut({bool isFcm = true}) async {
    try {
      _isGoogleLoading = true;
      _isAppleLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Sign out from Firebase
      await _firebaseAuth.signOut();
      if (isFcm) {
        await FCMService.signOut();
      }
      GoogleSignInService googleSignInService = GoogleSignInService();
      await googleSignInService.signOut();

      _currentUser = null;
      _isGoogleLoading = false;
      _isAppleLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isGoogleLoading = false;
      _isAppleLoading = false;
      _errorMessage = 'Error signing out: ${e.toString()}';
      notifyListeners();
      throw AuthException(message: _errorMessage!);
    } finally {
      await SecureStorageService.clearAll();
      await HiveService.instance.clearAll();
    }
  }

  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final response = await getUser(userId);
      if (response != null) {
        username = response['name'];
        notifyListeners();
        return response;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password.';
      case 'email-already-in-use':
        return 'The email address is already in use.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  Future<void> deleteAccount() async {
    try {
      _isGoogleLoading = true;
      _isAppleLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _currentUser?.delete();
      // await _googleSignIn.disconnect();
      // GoogleSignInService googleSignInService = GoogleSignInService();
      // await googleSignInService.signOut();

      _currentUser = null;
      _isGoogleLoading = false;
      _isAppleLoading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _isGoogleLoading = false;
      _isAppleLoading = false;
      _errorMessage = _handleFirebaseAuthException(e);
      notifyListeners();
      throw AuthException(message: _errorMessage!, code: e.code);
    } catch (e) {
      _isGoogleLoading = false;
      _isAppleLoading = false;
      _errorMessage = 'Error deleting account: ${e.toString()}';
      notifyListeners();
      throw AuthException(message: _errorMessage!);
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

Future<dynamic> getUser(String userid) async {
  try {
    ApiDioGetService dio = ApiDioGetService();
    // final url = Uri.parse("https://api.kajupro.com/entities/users/$userid");
    final token = await SecureStorageService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception("No authentication token found");
    }
    final response = await dio.getdata(endpoint: "entities/users/$userid");
    // final response = await http
    //     .get(
    //       url,
    //       headers: {
    //         "Content-Type": "application/json",
    //         "orgid": "TEAMALPHA",
    //         "Authorization": "Bearer $token",
    //       },
    //     )
    //     .timeout(const Duration(seconds: 30));

    if (response['status'] == 200) {
      if (response != null && response["data"] != null) {
        final userData = response["data"][0];
        await SecureStorageService.saveUserData(userData);
        return userData;
      }
    } else {
      throw Exception("Failed to fetch user: ${response.statusCode}");
    }
  } catch (e) {
    rethrow;
  }
}

Future<bool> updateProfile({
  required dynamic payload,
  required String userId,
}) async {
  ApiDioPutService dio = ApiDioPutService();
  final endpoint = "entities/users/$userId";

  try {
    final token = await SecureStorageService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception("No authentication token found");
    }

    if (await OfflineQueueService.instance.isOnline() == false) {
      await OfflineQueueService.instance.queueRequest(
        method: 'PUT',
        endpoint: endpoint,
        data: Map<String, dynamic>.from(payload as Map),
        actionType: 'updateProfile',
      );
      return true;
    }

    final response = await dio.getdata(endpoint: endpoint, data: payload);

    // final url = Uri.parse("https://api.kajupro.com/$endpoint");

    // final response = await http
    //     .put(
    //       url,
    //       headers: {
    //         "Content-Type": "application/json",
    //         "orgid": "TEAMALPHA",
    //         "Authorization": "Bearer $token",
    //       },
    //       body: jsonEncode(payload),
    //     )
    //     .timeout(const Duration(seconds: 30));

    // final responseData = jsonDecode(response.data);

    if (response["status"] == 200) {
      await getUser(userId);
      return true;
    } else {
      throw Exception(response["error_msg"] ?? "Update failed");
    }
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionTimeout) {
      await OfflineQueueService.instance.queueRequest(
        method: 'PUT',
        endpoint: endpoint,
        data: Map<String, dynamic>.from(payload as Map),
        actionType: 'updateProfile',
      );
      return true;
    }
    throw Exception("Profile update error: $e");
  }
}
