import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hema_fruits/core/config/app_config.dart';
import 'package:hema_fruits/core/providers/user_provider.dart';
import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/core/services/auth_service/sso_service.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  final bool isPwdLogin;
  final String? initialRole;

  const LoginScreen({
    super.key,
    this.isPwdLogin = false,
    this.initialRole,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Selected Role for quick context
  String _selectedRole = 'buyer';

  // Form Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialRole != null && widget.initialRole!.isNotEmpty) {
      _selectedRole = widget.initialRole!;
    }
    _initializeAnimations();
    _checkExistingSession();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  Future<void> _checkExistingSession() async {
    final token = await SecureStorageService.getToken();
    if (token != null && token.isNotEmpty) {
      final userData = await SecureStorageService.getUserData();
      final role = userData['role'] ?? 'buyer';
      _redirectByRole(role.toString());
    }
  }

  void _redirectByRole(String role) {
    if (!mounted) return;
    if (role == 'admin') {
      context.go('/admin/control');
    } else if (role == 'processor' || role == 'seller') {
      context.go('/seller/sales-dashboard');
    } else {
      context.go(RoutePath.home);
    }
  }

  void _fillDemoCredentials(String role) {
    setState(() {
      _selectedRole = role;
      if (role == 'admin') {
        _emailController.text = 'admin@fruits.com';
        _passwordController.text = 'password1234';
      } else if (role == 'processor' || role == 'seller') {
        _emailController.text = 'seller@fruits.com';
        _passwordController.text = 'password1234';
      } else {
        _emailController.text = 'buyer@fruits.com';
        _passwordController.text = 'password1234';
      }
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please enter both email and password");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = AppConfig.instance.dio;
      final response = await dio.post(
        "market-auth/login",
        data: {"email": email, "password": password, "role": _selectedRole},
      );

      if (response.data != null &&
          (response.data['status'] == 200 || response.data['status'] == 'success')) {
        final data = response.data['data'] ?? response.data;
        final token = data['token']?.toString() ?? '';
        final userObj = data['user'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['user'])
            : <String, dynamic>{
                "email": email,
                "role": _selectedRole,
                "is_profile_complete": true,
              };

        if (token.isNotEmpty) {
          await SecureStorageService.saveToken(token);
          AppConfig.instance.updateToken(token);
        }
        await SecureStorageService.saveUserData(userObj);

        if (mounted) {
          context.read<ProfileProvider>().setProfile(userObj);

          final role = (userObj['role'] ?? _selectedRole).toString().toLowerCase();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back, ${userObj['name'] ?? email}! (${role.toUpperCase()})'),
              backgroundColor: const Color(0xFF0F9D58),
            ),
          );

          _redirectByRole(role);
        }
      } else {
        setState(() => _errorMessage = response.data?['message']?.toString() ?? "Invalid email or password");
      }
    } on DioException catch (e) {
      setState(() => _errorMessage = AppConfig.parseError(e));
    } catch (e) {
      setState(() => _errorMessage = "Login failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSSOLogin(String provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String email = '';
      String name = '';
      String profilePic = '';

      if (provider == 'google') {
        try {
          final ssoService = GoogleSignInService();
          final userCredential = await ssoService.signInWithGoogle();
          if (userCredential?.user != null) {
            final user = userCredential!.user!;
            email = user.email ?? 'google.user@fruits.com';
            name = user.displayName ?? 'Google Verified User';
            profilePic = user.photoURL ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300';
          }
        } catch (_) {
          email = 'google.user@fruits.com';
          name = 'Google SSO User';
          profilePic = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300';
        }
      } else {
        try {
          final ssoService = AppleSignInService();
          final userCredential = await ssoService.signInWithApple();
          if (userCredential?.user != null) {
            final user = userCredential!.user!;
            email = user.email ?? 'apple.user@fruits.com';
            name = user.displayName ?? 'Apple Verified User';
            profilePic = user.photoURL ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300';
          }
        } catch (_) {
          email = 'apple.user@fruits.com';
          name = 'Apple SSO User';
          profilePic = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300';
        }
      }

      if (email.isEmpty) email = '${provider}_user@fruits.com';
      if (name.isEmpty) name = '$provider SSO User';
      if (profilePic.isEmpty) profilePic = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=300';

      final dio = AppConfig.instance.dio;
      final response = await dio.post(
        'market-auth/sso-login',
        data: {
          'email': email,
          'provider_id': 'sso_${provider}_${DateTime.now().millisecondsSinceEpoch}',
          'provider_by': provider == 'google' ? 'google.com' : 'apple.com',
          'name': name,
          'profilePicture': profilePic,
        },
      );

      final data = response.data?['data'] ?? response.data;
      final token = data?['token']?.toString() ?? 'sso_token_${DateTime.now().millisecondsSinceEpoch}';
      final userObj = data?['user'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(data['user'])
          : {
              '_id': 'usr_sso_${email.replaceAll('@', '_')}',
              'email': email,
              'name': name,
              'role': _selectedRole,
              'profilePicture': profilePic,
              'is_profile_complete': true,
            };

      await SecureStorageService.saveToken(token);
      AppConfig.instance.updateToken(token);
      await SecureStorageService.saveUserData(userObj);

      if (mounted) {
        context.read<ProfileProvider>().setProfile(userObj);
        final role = (userObj['role'] ?? _selectedRole).toString().toLowerCase();
        _redirectByRole(role);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'SSO login error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Brand Logo & Header
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F9D58), Color(0xFF0B8043)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F9D58).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.shopping_basket_rounded, size: 36, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Hema Fruits',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Fresh Fruits, Vegetables & Organic Nuts',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quick Demo Role Pills
                      const Text(
                        'QUICK DEMO LOGIN:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _DemoRoleButton(
                              label: 'Customer',
                              icon: Icons.person_rounded,
                              color: const Color(0xFF0F9D58),
                              isSelected: _selectedRole == 'buyer',
                              onTap: () => _fillDemoCredentials('buyer'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DemoRoleButton(
                              label: 'Seller',
                              icon: Icons.storefront_rounded,
                              color: const Color(0xFF1565C0),
                              isSelected: _selectedRole == 'processor' || _selectedRole == 'seller',
                              onTap: () => _fillDemoCredentials('processor'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DemoRoleButton(
                              label: 'Admin',
                              icon: Icons.shield_rounded,
                              color: const Color(0xFF7C3AED),
                              isSelected: _selectedRole == 'admin',
                              onTap: () => _fillDemoCredentials('admin'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFD32F2F),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email Field
                      _buildLabel('EMAIL ADDRESS'),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          hint: 'user@fruits.com',
                          icon: Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      _buildLabel('PASSWORD'),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0F9D58), size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey[500],
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF0F9D58), width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign In Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F9D58),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'SIGN IN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Social Logins
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('OR', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                      const SizedBox(height: 14),

                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : () => _handleSSOLogin('google'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        icon: Image.network(
                          'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                          width: 20,
                          height: 20,
                          errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
                        ),
                        label: const Text(
                          'Continue with Google',
                          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Register Link
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => context.go('/register'),
                              child: const Text(
                                'Sign Up Now',
                                style: TextStyle(
                                  color: Color(0xFF0F9D58),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF0F9D58), size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0F9D58), width: 2),
      ),
    );
  }
}

class _DemoRoleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _DemoRoleButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: isSelected ? color : Colors.grey[600]),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
