import 'package:cashew_marketplace/core/constants/app_assets.dart';
import 'package:cashew_marketplace/core/router/router_setup.dart';
import 'package:cashew_marketplace/core/services/auth_service/auth_service.dart';
import 'package:cashew_marketplace/core/utils/context_manager.dart';
import 'package:cashew_marketplace/core/utils/Responsive/responsivea_context.dart';
import 'package:cashew_marketplace/core/utils/initial_function.dart';
import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';
import 'package:cashew_marketplace/shared/widgets/custom_input.dart';
import 'package:cashew_marketplace/core/services/feature_services.dart';
import 'package:cashew_marketplace/core/services/notification/fcm_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  bool isPwdLogin = false;
  LoginScreen({super.key, required this.isPwdLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isFormValid = false;
  bool _isLoginLoading = false;
  bool isPwdLogin = false;

  @override
  void initState() {
    super.initState();
    isPwdLogin = widget.isPwdLogin;
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkLogin();
    });
    _initializeAnimations();
  }

  void _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final isEmailValid = emailRegex.hasMatch(email);
    final isPasswordValid = password.length >= 6;
    final isValid = isEmailValid && isPasswordValid;
    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  // Future<void> layoutLogin() async {
  //   try {
  //     isPwdLogin = await InitialFunction.layoutLogin();
  //     setState(() {
  //       isPwdLogin;
  //     });
  //   } catch (e) {
  //     debugPrintStack();
  //   }
  // }

  Future<void> _handleEmailPasswordLogin() async {
    if (!_isFormValid || _isLoginLoading) return;

    setState(() {
      _isLoginLoading = true;
    });

    try {
      final dio = ApiDioPostService();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final res = await dio.getdata(
        endpoint: "market-auth/login",
        data: {"email": email, "password": password},
      );

      bool isSuccess = false;
      String? token;

      if (res['status'] == 200) {
        final response = res['data'];
        if (response != null) {
          if (response is Map) {
            isSuccess =
                response['success'] == true ||
                response['status'] == 'success' ||
                response['status'] == true ||
                response['token'] != null;
            token = response['token']?.toString();
          } else if (response is bool) {
            isSuccess = response;
          }
        }
      } else {
        isSuccess = false;
      }

      if (isSuccess) {
        if (token != null && token.isNotEmpty) {
          await SecureStorageService.saveToken(token);
          await FCMService.initialize();
          final userData = JwtDecoder.decode(token);
          final String uid = userData['id'] ?? '';
          if (uid.isNotEmpty) {
            await getUser(uid);
            await loadlastlogin(uid);
          }
        }
        if (mounted) {
          await checkLogin();
        }
      } else {
        throw Exception("Invalid credentials or login failed.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoginLoading = false;
        });
      }
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> checkLogin() async {
    final String token = await SecureStorageService.getToken() ?? '';
    if (token.isEmpty) return;

    final userdata = await SecureStorageService.getUserData();
    bool? isprofileLocal =
        await SecureStorageService.getprofilestatus() ?? false;
    bool isprofile = userdata['isProfileComplete'] ?? false;
    if (userdata['status'] == 'deactive') {
      showBlockedByAdminDialog(context);
      return;
    }
    if (userdata['role'] == 'admin') {
      await showadmindialog(context);
      return;
    }
    if (!isprofileLocal) {
      if (!isprofile) {
        context.push('/profilesetup');
        return;
      }
    }
    if (userdata['initializer_screen'] == "Dashboard") {
      context.go(RoutePath.dashboard);
    } else if (userdata['initializer_screen'] == "BiddingScreen") {
      // context.go(RoutePath.home);
      context.go(RoutePath.salesBuyBidding);
    } else if (userdata['initializer_screen'] == "Marketplace") {
      context.go(RoutePath.home);
    } else {
      context.go(RoutePath.dashboard);
    }
  }

  Future<void> loadlastlogin(String userid) async {
    try {
      await updateProfile(
        payload: {"last_login": DateTime.now().toUtc().toIso8601String()},
        userId: userid,
      );
    } catch (e) {
      debugPrintStack();
    }
  }

  Future<void> showBlockedByAdminDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon - compact size for mobile
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.block_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Title + Description (combined for brevity)
                  Text(
                    'Account Blocked',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Policy violation detected. Contact support to resolve.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons - stacked for mobile
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _contactSupport(context),
                      child: const Text(
                        'Contact Support',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: Icon(
                  Icons.close,
                  size: 24,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showadmindialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 48,
                    color: AppColors.accent,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Admin Restricted",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  "You are admin.\nPlease use the web platform to continue.",
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("OK", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper to handle support contact
  void _contactSupport(BuildContext context) {
    final email = 'support@cashewmarketplace.com';
    final subject = Uri.encodeComponent('Account Blocked - Support Request');
    final body = Uri.encodeComponent(
      'My account has been blocked. Please help me resolve this issue.\n\nUser ID: [auto-fill from auth]',
    );

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=$subject&body=$body',
    );

    launchUrl(uri);
    Navigator.pop(context);
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final authService = context.read<AuthService>();
      await authService.signInWithGoogle(context);
      await checkLogin();
      await loadlastlogin(authService.userId);
    } catch (e) {
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text("Failed to sign in. Please try again."),
        //     backgroundColor: AppColors.error,
        //     duration: const Duration(seconds: 4),
        //   ),
        // );
      }
    }
  }

  Future<void> _handleAppleSignIn(BuildContext context) async {
    try {
      final authService = context.read<AuthService>();
      await authService.signInWithApple(context);
      await checkLogin();
      await loadlastlogin(authService.userId);
    } catch (e) {
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text("Failed to sign in. Please try again."),
        //     backgroundColor: AppColors.error,
        //     duration: const Duration(seconds: 4),
        //   ),
        // );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ContextManager().saveCurrentPage('login', context);
    final tt = AppTextThemes.getgetLightTextTheme(context);
    final double height = MediaQuery.of(context).size.height;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: height * 0.60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 448),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLogoSection(),
                          const SizedBox(height: 32),
                          _buildHeadlineSection(context, tt),
                          const SizedBox(height: 40),
                          _buildActionSection(context, tt),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      width: 100,
      height: 100,
      child: Center(
        child: Image.asset(AppAssets.iconCashewLogo, width: 150, height: 150),
      ),
    );
  }

  Widget _buildHeadlineSection(BuildContext context, TextTheme tt) {
    return Column(
      children: [
        Text(
          'Cashew Marketplace',
          textAlign: TextAlign.center,
          style: tt.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'Secure marketplace for RCN and Kernel products. Connect with verified buyers and merchants globally.',
          textAlign: TextAlign.center,
          style: tt.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildActionSection(BuildContext context, TextTheme tt) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email Input
            if (isPwdLogin) ...[
              CustomTextFormField(
                controller: _emailController,
                label: 'Email Address',
                hintText: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
              ),
              // const SizedBox(height: 16),

              // Password Input
              CustomTextFormField(
                controller: _passwordController,
                label: 'Password',
                hintText: 'Enter your password',
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
              ),
              // const SizedBox(height: 24),

              // Login Button
              CustomSubmitButton(
                label: 'Sign In',
                isLoading: _isLoginLoading,
                onPressed: _isFormValid ? _handleEmailPasswordLogin : null,
                borderRadius: 10,
                height: 50,
                enabledColor: AppColors.accent,
                disabledColor: AppColors.buttonDisabled,
                textStyle: tt.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Divider: "Or continue with"
              Row(
                children: [
                  Expanded(
                    child: Divider(color: AppColors.borderDark, thickness: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Or continue with',
                      style: tt.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: AppColors.borderDark, thickness: 1),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Google Button
            _buildGoogleSignInButton(context, tt, authService),
            const SizedBox(height: 16),

            // Apple Button
            _buildAppleSignInButton(context, tt, authService),
            const SizedBox(height: 24),

            if (authService.errorMessage != null)
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening support...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Center(
                  child: Text(
                    'Trouble signing in? Contact Support',
                    style: tt.bodySmall,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGoogleSignInButton(
    BuildContext context,
    TextTheme tt,
    AuthService authService,
  ) {
    return SizedBox(
      width: double.infinity,
      height: context.buttonHeight <= 50 ? context.buttonHeight : 50,
      child: Material(
        color: AppColors.primary,
        elevation: 1,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: authService.isGoogleLoading
              ? null
              : () => _handleGoogleSignIn(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Image.asset(
                      AppAssets.googleLogo,
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
                authService.isGoogleLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.accent),
                        ),
                      )
                    : Text(
                        'Sign in with Google',
                        style: tt.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.25,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppleSignInButton(
    BuildContext context,
    TextTheme tt,
    AuthService authService,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white),
      ),
      width: double.infinity,
      height: context.buttonHeight <= 50 ? context.buttonHeight : 50,
      child: Material(
        color: AppColors.primary,
        elevation: 1,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: authService.isAppleLoading
              ? null
              : () => _handleAppleSignIn(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Image.asset(
                      AppAssets.appleLogo,
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
                authService.isAppleLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.accent),
                        ),
                      )
                    : Text(
                        'Sign in with Apple',
                        style: tt.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.25,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
