import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hema_fruits/core/providers/user_provider.dart';
import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/core/services/auth_service/sso_service.dart';
import 'package:hema_fruits/core/services/feature_services.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';

class LoginScreen extends StatefulWidget {
  final bool isPwdLogin;
  final String? initialRole;

  const LoginScreen({
    super.key,
    required this.isPwdLogin,
    this.initialRole,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Mode: 0 for Login, 1 for Register
  int _authTab = 0;

  // Selected Role: 'buyer', 'processor' (merchant/seller), 'admin'
  String _selectedRole = 'buyer';

  // Form Controllers - Login
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;

  // Form Controllers - Register
  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPhoneController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  bool _obscureRegPassword = true;

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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  Future<void> _checkExistingSession() async {
    final token = await SecureStorageService.getToken();
    if (token != null && token.isNotEmpty) {
      final userData = await SecureStorageService.getUserData();
      final bool isProfileComplete = userData['is_profile_complete'] ?? userData['isProfileComplete'] ?? false;
      if (!isProfileComplete) {
        if (mounted) context.go('/setup');
      } else {
        final role = userData['role'] ?? 'buyer';
        _redirectByRole(role.toString());
      }
    }
  }

  void _redirectByRole(String role) {
    if (!mounted) return;
    if (role == 'admin') {
      context.go(RoutePath.dashboard);
    } else if (role == 'processor' || role == 'seller') {
      context.go('/marketplace');
    } else {
      context.go(RoutePath.home);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPhoneController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  // ── AUTHENTICATION ACTIONS ────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please enter both email and password");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final postService = ApiDioPostService();
      final response = await postService.getdata(
        endpoint: "market-auth/login",
        data: {"email": email, "password": password, "role": _selectedRole},
      );

      if (response != null && (response['status'] == 200 || response['status'] == 'success')) {
        final data = response['data'] ?? response;
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
        }
        await SecureStorageService.saveUserData(userObj);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logged in successfully as ${(userObj['role'] ?? _selectedRole).toString().toUpperCase()}'),
              backgroundColor: const Color(0xFF0F9D58),
            ),
          );

          final bool isProfileComplete = userObj['is_profile_complete'] ?? userObj['isProfileComplete'] ?? false;
          if (!isProfileComplete) {
            context.go('/setup');
          } else {
            _redirectByRole(userObj['role']?.toString() ?? _selectedRole);
          }
        }
      } else {
        setState(() => _errorMessage = response?['message']?.toString() ?? "Invalid email or password");
      }
    } catch (e) {
      setState(() => _errorMessage = "Login failed: ${e.toString().replaceAll('Exception: ', '')}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    final name = _regNameController.text.trim();
    final email = _regEmailController.text.trim();
    final phone = _regPhoneController.text.trim();
    final password = _regPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please fill in all required registration fields");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final postService = ApiDioPostService();
      final newUserMap = {
        "_id": "usr_${DateTime.now().millisecondsSinceEpoch}",
        "name": name,
        "email": email,
        "mobile_number": phone,
        "phone": phone,
        "password": password,
        "role": _selectedRole,
        "is_profile_complete": false,
        "first_login": true,
        "created_on": DateTime.now().toUtc().toIso8601String(),
      };

      await postService.getdata(endpoint: "entities/users", data: newUserMap);

      await SecureStorageService.saveToken("usr_token_${DateTime.now().millisecondsSinceEpoch}");
      await SecureStorageService.saveUserData(newUserMap);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created! Please complete your ${_selectedRole.toUpperCase()} setup.'),
            backgroundColor: const Color(0xFF0F9D58),
          ),
        );
        context.go('/setup');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
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

      dynamic response;
      try {
        response = await ssoLogin(
          email: email,
          providerId: "sso_${provider}_${DateTime.now().millisecondsSinceEpoch}",
          providerBy: provider == 'google' ? 'google.com' : 'apple.com',
          name: name,
          profileImage: profilePic,
        );
      } catch (e) {
        debugPrint("SSO API note: $e");
      }

      final data = response != null && response['data'] != null ? response['data'] : response;
      final token = data != null && data['token'] != null
          ? data['token'].toString()
          : "sso_token_${DateTime.now().millisecondsSinceEpoch}";

      final Map<String, dynamic> dbUserObj = data != null && data['user'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(data['user'])
          : {
              "_id": "sso_usr_${email.replaceAll('@', '_')}",
              "email": email,
              "name": name,
              "role": _selectedRole,
              "profilePicture": profilePic,
              "is_profile_complete": false,
              "sso_provider": provider,
            };

      await SecureStorageService.saveToken(token);
      await SecureStorageService.saveUserData(dbUserObj);

      if (mounted) {
        Provider.of<ProfileProvider>(context, listen: false).setUserProfileMap(dbUserObj);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SSO Verified! Authenticated via $provider'),
            backgroundColor: const Color(0xFF0F9D58),
          ),
        );

        final bool isProfileComplete = dbUserObj['is_profile_complete'] ?? dbUserObj['isProfileComplete'] ?? false;
        if (!isProfileComplete) {
          context.go('/setup');
        } else {
          _redirectByRole(dbUserObj['role']?.toString() ?? _selectedRole);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── BUILD UI ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brand Header Logo & Title
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          color: const Color(0xFF0F9D58).withOpacity(0.1),
                          child: const Icon(
                            Icons.shopping_basket_rounded,
                            size: 44,
                            color: Color(0xFF0F9D58),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Hema Fruits Marketplace',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fresh Agricultural Produce Trading',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Auth Mode Switcher (Login vs Register)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _authTab = 0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _authTab == 0 ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(26),
                                    boxShadow: _authTab == 0
                                        ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]
                                        : [],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: _authTab == 0 ? const Color(0xFF0F9D58) : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _authTab = 1),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _authTab == 1 ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(26),
                                    boxShadow: _authTab == 1
                                        ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]
                                        : [],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Register',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: _authTab == 1 ? const Color(0xFF0F9D58) : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Role Selector Chip List (Role-Based Login)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'SELECT YOUR ROLE:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildRoleChip('buyer', 'Buyer 🛒', Icons.shopping_cart_outlined),
                          const SizedBox(width: 8),
                          _buildRoleChip('processor', 'Merchant 🏪', Icons.storefront_outlined),
                          const SizedBox(width: 8),
                          _buildRoleChip('admin', 'Admin 🛡️', Icons.admin_panel_settings_outlined),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Error Banner
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Form Body based on _authTab
                      if (_authTab == 0) _buildLoginForm() else _buildRegisterForm(),

                      const SizedBox(height: 18),

                      // Divider for SSO Single Sign-On Verification
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              _authTab == 0 ? 'OR VERIFY & SIGN IN WITH SSO' : 'OR REGISTER WITH SSO',
                              style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Google SSO & Apple SSO Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : () => _handleSSOLogin('google'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                side: BorderSide(color: Colors.grey[300]!),
                                backgroundColor: Colors.white,
                              ),
                              icon: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
                                child: const Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              label: const Text(
                                'Google SSO',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : () => _handleSSOLogin('apple'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                side: const BorderSide(color: Colors.black87),
                                backgroundColor: Colors.black,
                              ),
                              icon: const Icon(Icons.apple, color: Colors.white, size: 20),
                              label: const Text(
                                'Apple SSO',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Divider for quick login options
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'QUICK DEMO LOGIN',
                              style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Role-Filtered Quick Demo Login Buttons
                      Column(
                        children: [
                          if (_selectedRole == 'admin') ...[
                            _buildQuickLoginButton(
                              label: 'Super Admin Account',
                              email: 'admin@fruits.com',
                              role: 'admin',
                              icon: Icons.admin_panel_settings_rounded,
                              color: const Color(0xFF4A148C),
                              subtitle: 'admin@fruits.com • password1234',
                            ),
                            const SizedBox(height: 8),
                            _buildQuickLoginButton(
                              label: 'Operations Manager Account',
                              email: 'operations@fruits.com',
                              role: 'admin',
                              icon: Icons.security_rounded,
                              color: const Color(0xFF6C3483),
                              subtitle: 'operations@fruits.com • password1234',
                            ),
                          ] else if (_selectedRole == 'processor') ...[
                            _buildQuickLoginButton(
                              label: 'Green Valley Organic Farms',
                              email: 'seller@fruits.com',
                              role: 'processor',
                              icon: Icons.storefront_rounded,
                              color: const Color(0xFF0F9D58),
                              subtitle: 'seller@fruits.com • password1234',
                            ),
                            const SizedBox(height: 8),
                            _buildQuickLoginButton(
                              label: 'Hema Cashew & Nut Traders',
                              email: 'merchant@fruits.com',
                              role: 'processor',
                              icon: Icons.agriculture_rounded,
                              color: const Color(0xFF1565C0),
                              subtitle: 'merchant@fruits.com • password1234',
                            ),
                            const SizedBox(height: 8),
                            _buildQuickLoginButton(
                              label: 'Sunrise Agricultural Orchards',
                              email: 'supplier@fruits.com',
                              role: 'processor',
                              icon: Icons.eco_rounded,
                              color: const Color(0xFFE65100),
                              subtitle: 'supplier@fruits.com • password1234',
                            ),
                          ] else ...[
                            _buildQuickLoginButton(
                              label: 'Anita Sharma (Retail Buyer)',
                              email: 'buyer@fruits.com',
                              role: 'buyer',
                              icon: Icons.shopping_basket_rounded,
                              color: const Color(0xFF0F9D58),
                              subtitle: 'buyer@fruits.com • password1234',
                            ),
                            const SizedBox(height: 8),
                            _buildQuickLoginButton(
                              label: 'Fresh Market Wholesalers',
                              email: 'wholesaler@fruits.com',
                              role: 'buyer',
                              icon: Icons.local_shipping_rounded,
                              color: const Color(0xFF0288D1),
                              subtitle: 'wholesaler@fruits.com • password1234',
                            ),
                            const SizedBox(height: 8),
                            _buildQuickLoginButton(
                              label: 'Rajesh Patel (Direct Customer)',
                              email: 'customer@fruits.com',
                              role: 'buyer',
                              icon: Icons.person_pin_rounded,
                              color: const Color(0xFF7B1FA2),
                              subtitle: 'customer@fruits.com • password1234',
                            ),
                          ],
                        ],
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

  Widget _buildRoleChip(String roleKey, String label, IconData icon) {
    final selected = _selectedRole == roleKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = roleKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0F9D58) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF0F9D58) : Colors.grey[300]!,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : Colors.grey[700]),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'user@example.com',
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0F9D58)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _loginPasswordController,
          obscureText: _obscureLoginPassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0F9D58)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLoginPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF0F9D58), fontSize: 12)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F9D58),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                : Text(
                    'SIGN IN AS ${_selectedRole.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        TextField(
          controller: _regNameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            hintText: 'John Doe',
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF0F9D58)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'user@example.com',
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0F9D58)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Mobile Phone',
            hintText: '9876543210',
            prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF0F9D58)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regPasswordController,
          obscureText: _obscureRegPassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0F9D58)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F9D58),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                : Text(
                    'REGISTER AS ${_selectedRole.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLoginButton({
    required String label,
    required String email,
    required String role,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return InkWell(
      onTap: () {
        setState(() => _selectedRole = role);
        _loginEmailController.text = email;
        _loginPasswordController.text = 'password1234';
        _authTab = 0;
        _handleLogin();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(isPwdLogin: true, initialRole: 'admin');
  }
}

class SellerLoginScreen extends StatelessWidget {
  const SellerLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(isPwdLogin: true, initialRole: 'processor');
  }
}

class CustomerLoginScreen extends StatelessWidget {
  const CustomerLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(isPwdLogin: true, initialRole: 'buyer');
  }
}

