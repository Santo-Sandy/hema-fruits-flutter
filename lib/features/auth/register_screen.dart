import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hema_fruits/core/config/app_config.dart';
import 'package:hema_fruits/core/providers/user_provider.dart';
import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  final String? initialRole;

  const RegisterScreen({super.key, this.initialRole});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Selected role: 'buyer' or 'processor' (seller)
  String _selectedRole = 'buyer';

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.initialRole != null && widget.initialRole!.isNotEmpty) {
      _selectedRole = widget.initialRole!;
    }
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _storeNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = AppConfig.instance.dio;
      final payload = {
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim().toLowerCase(),
        "password": _passwordController.text,
        "role": _selectedRole,
        "mobile_number": _phoneController.text.trim(),
        "phone": _phoneController.text.trim(),
        "store_name": _selectedRole == 'processor' || _selectedRole == 'seller'
            ? _storeNameController.text.trim()
            : '',
        "city": _cityController.text.trim(),
      };

      final response = await dio.post('market-auth/register', data: payload);

      if (response.data != null &&
          (response.data['status'] == 200 || response.data['status'] == 'success')) {
        final data = response.data['data'] ?? response.data;
        final token = data['token']?.toString() ?? '';
        final userObj = data['user'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['user'])
            : <String, dynamic>{
                "name": _nameController.text.trim(),
                "email": _emailController.text.trim(),
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

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Welcome to Hema Fruits, ${userObj['name'] ?? 'User'}! 🎉 (Role: ${_selectedRole.toUpperCase()})',
              ),
              backgroundColor: const Color(0xFF0F9D58),
            ),
          );

          if (_selectedRole == 'admin') {
            context.go('/admin/control');
          } else if (_selectedRole == 'processor' || _selectedRole == 'seller') {
            context.go('/seller/sales-dashboard');
          } else {
            context.go(RoutePath.home);
          }
        }
      } else {
        setState(() {
          _errorMessage = response.data?['message']?.toString() ?? "Registration failed";
        });
      }
    } on DioException catch (e) {
      final msg = AppConfig.parseError(e);
      setState(() => _errorMessage = msg);
    } catch (e) {
      setState(() => _errorMessage = "Registration error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B)),
          onPressed: () => context.go('/login'),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F9D58), Color(0xFF0B8043)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'Hema Fruits',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 40 : 20,
            vertical: 20,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 580),
            padding: EdgeInsets.all(isDesktop ? 36 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading
                    const Text(
                      'Create Your Account',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Join Hema Fruits marketplace as a Buyer or Producer Seller',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Role Selector Cards
                    const Text(
                      'I WANT TO JOIN AS:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _RoleCard(
                            title: 'Customer / Buyer',
                            subtitle: 'Buy fresh produce & organic nuts',
                            icon: Icons.shopping_basket_rounded,
                            isSelected: _selectedRole == 'buyer',
                            activeColor: const Color(0xFF0F9D58),
                            onTap: () => setState(() => _selectedRole = 'buyer'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RoleCard(
                            title: 'Produce Seller',
                            subtitle: 'List stocks & sell harvests',
                            icon: Icons.storefront_rounded,
                            isSelected: _selectedRole == 'processor' || _selectedRole == 'seller',
                            activeColor: const Color(0xFF1565C0),
                            onTap: () => setState(() => _selectedRole = 'processor'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFCDD2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFD32F2F),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Full Name
                    _buildFieldLabel('FULL NAME'),
                    TextFormField(
                      controller: _nameController,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your full name' : null,
                      decoration: _inputDecoration(
                        hint: 'e.g. Rajesh Kumar',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    _buildFieldLabel('EMAIL ADDRESS'),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter your email';
                        if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email address';
                        return null;
                      },
                      decoration: _inputDecoration(
                        hint: 'e.g. rajesh@farms.com',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mobile Number
                    _buildFieldLabel('PHONE NUMBER'),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().length < 10 ? 'Enter a 10-digit phone number' : null,
                      decoration: _inputDecoration(
                        hint: 'e.g. 9876543210',
                        icon: Icons.phone_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Store Name (if Seller)
                    if (_selectedRole == 'processor' || _selectedRole == 'seller') ...[
                      _buildFieldLabel('STORE / FARM NAME'),
                      TextFormField(
                        controller: _storeNameController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your store or farm name' : null,
                        decoration: _inputDecoration(
                          hint: 'e.g. Green Valley Organic Orchards',
                          icon: Icons.agriculture_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // City
                    _buildFieldLabel('CITY / REGION (OPTIONAL)'),
                    TextFormField(
                      controller: _cityController,
                      decoration: _inputDecoration(
                        hint: 'e.g. Ratnagiri, Maharashtra',
                        icon: Icons.location_city_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    _buildFieldLabel('PASSWORD'),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                      decoration: InputDecoration(
                        hintText: 'Minimum 6 characters',
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
                    const SizedBox(height: 28),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedRole == 'processor' || _selectedRole == 'seller'
                              ? const Color(0xFF1565C0)
                              : const Color(0xFF0F9D58),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                _selectedRole == 'processor' || _selectedRole == 'seller'
                                    ? 'REGISTER AS SELLER'
                                    : 'CREATE BUYER ACCOUNT',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Switch to Login
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        child: RichText(
                          text: const TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                            children: [
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                  color: Color(0xFF0F9D58),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
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

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: isSelected ? Colors.white : Colors.grey[700], size: 18),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: activeColor, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? activeColor : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
