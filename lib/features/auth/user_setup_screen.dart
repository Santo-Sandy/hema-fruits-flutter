import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hema_fruits/core/providers/user_provider.dart';
import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/core/services/feature_services.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';

class UserSetupScreen extends StatefulWidget {
  final Map<String, dynamic>? initialUserData;

  const UserSetupScreen({
    super.key,
    this.initialUserData,
  });

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Selected Role: 'buyer' or 'processor' (seller)
  String _selectedRole = 'buyer';

  // Common User Info
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  // Buyer Specific Form Fields
  late final TextEditingController _buyerAddressController;
  late final TextEditingController _buyerCityController;
  late final TextEditingController _buyerStateController;
  late final TextEditingController _buyerPincodeController;
  String _buyerType = 'Retail Buyer';

  // Seller Specific Store Form Fields (Distinct Store Details)
  late final TextEditingController _storeNameController;
  late final TextEditingController _storeCategoryController;
  late final TextEditingController _storeGstController;
  late final TextEditingController _storeEstYearController;
  late final TextEditingController _storePhoneController;
  late final TextEditingController _storeEmailController;
  late final TextEditingController _storeAddressController;
  late final TextEditingController _storeCityController;
  late final TextEditingController _storeStateController;
  late final TextEditingController _storePincodeController;
  late final TextEditingController _storeDescController;
  String _sellerBusinessType = 'Wholesaler & Processor';

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _userData = {};

  final List<String> _sellerCategories = [
    'Wholesaler & Processor',
    'Fruit Farmer / Orchard Owner',
    'Commission Agent & Mandi Trader',
    'Produce Importer & Exporter',
    'Retail Produce Store',
  ];

  final List<String> _buyerTypes = [
    'Retail Buyer',
    'Wholesale Supermarket',
    'Hotel & Restaurant Supply',
    'Direct End Consumer',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();

    _buyerAddressController = TextEditingController();
    _buyerCityController = TextEditingController();
    _buyerStateController = TextEditingController();
    _buyerPincodeController = TextEditingController();

    _storeNameController = TextEditingController();
    _storeCategoryController = TextEditingController();
    _storeGstController = TextEditingController();
    _storeEstYearController = TextEditingController();
    _storePhoneController = TextEditingController();
    _storeEmailController = TextEditingController();
    _storeAddressController = TextEditingController();
    _storeCityController = TextEditingController();
    _storeStateController = TextEditingController();
    _storePincodeController = TextEditingController();
    _storeDescController = TextEditingController();

    _loadExistingUserData();
  }

  Future<void> _loadExistingUserData() async {
    final savedData = await SecureStorageService.getUserData();
    if (savedData != null) {
      setState(() {
        _userData = savedData;
        _nameController.text = savedData['name'] ?? '';
        _phoneController.text = savedData['mobile_number'] ?? savedData['phone'] ?? '';
        _emailController.text = savedData['email'] ?? '';
        _storePhoneController.text = _phoneController.text;
        _storeEmailController.text = _emailController.text;
        if (savedData['role'] != null && savedData['role'].toString().isNotEmpty) {
          _selectedRole = savedData['role'] == 'admin' ? 'buyer' : savedData['role'];
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();

    _buyerAddressController.dispose();
    _buyerCityController.dispose();
    _buyerStateController.dispose();
    _buyerPincodeController.dispose();

    _storeNameController.dispose();
    _storeCategoryController.dispose();
    _storeGstController.dispose();
    _storeEstYearController.dispose();
    _storePhoneController.dispose();
    _storeEmailController.dispose();
    _storeAddressController.dispose();
    _storeCityController.dispose();
    _storeStateController.dispose();
    _storePincodeController.dispose();
    _storeDescController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _userData['_id'] ?? "usr_${DateTime.now().millisecondsSinceEpoch}";
      final String userRole = _selectedRole;

      Map<String, dynamic> updatePayload = {
        "_id": userId,
        "name": _nameController.text.trim(),
        "mobile_number": _phoneController.text.trim(),
        "phone": _phoneController.text.trim(),
        "email": _emailController.text.trim(),
        "role": userRole,
        "is_profile_complete": true,
        "first_login": false,
        "updated_at": DateTime.now().toUtc().toIso8601String(),
      };

      if (userRole == 'processor' || userRole == 'seller') {
        // Seller distinct store details
        updatePayload['companyName'] = _storeNameController.text.trim();
        updatePayload['store_name'] = _storeNameController.text.trim();
        updatePayload['businessType'] = _sellerBusinessType;
        updatePayload['registrationType'] = _sellerBusinessType;
        updatePayload['gst_number'] = _storeGstController.text.trim();
        updatePayload['establishedYear'] = _storeEstYearController.text.trim();
        updatePayload['store_phone'] = _storePhoneController.text.trim();
        updatePayload['store_email'] = _storeEmailController.text.trim();
        updatePayload['address'] = _storeAddressController.text.trim();
        updatePayload['city'] = _storeCityController.text.trim();
        updatePayload['state'] = _storeStateController.text.trim();
        updatePayload['postalCode'] = _storePincodeController.text.trim();
        updatePayload['description'] = _storeDescController.text.trim();
        updatePayload['iscompany'] = true;
      } else {
        // Buyer details
        updatePayload['buyer_type'] = _buyerType;
        updatePayload['address'] = _buyerAddressController.text.trim();
        updatePayload['city'] = _buyerCityController.text.trim();
        updatePayload['state'] = _buyerStateController.text.trim();
        updatePayload['postalCode'] = _buyerPincodeController.text.trim();
        updatePayload['iscompany'] = false;
      }

      // Save to backend database
      try {
        final postService = ApiDioPostService();
        await postService.getdata(
          endpoint: "entities/users",
          data: updatePayload,
        );
      } catch (e) {
        debugPrint("API update user setup notice: $e");
      }

      // Update local storage and app state
      await SecureStorageService.saveUserData(updatePayload);
      await SecureStorageService.companystatus(true);
      await SecureStorageService.Saveprofilestatus(true);

      if (!mounted) return;

      Provider.of<ProfileProvider>(context, listen: false).setUserProfileMap(updatePayload);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userRole == 'processor'
                ? 'Store registration setup complete! Welcome to Hema Fruits Storefront.'
                : 'Profile setup complete! Welcome to Hema Fruits Marketplace.',
          ),
          backgroundColor: const Color(0xFF0F9D58),
        ),
      );

      if (userRole == 'processor' || userRole == 'seller') {
        context.go('/marketplace');
      } else {
        context.go(RoutePath.home);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Account & Profile Setup',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 550),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Title
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F9D58).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.assignment_ind_rounded,
                              size: 38,
                              color: Color(0xFF0F9D58),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Complete Your Setup',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please configure your profile to start trading on Hema Fruits',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error Notice
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // STEP 1: Select Role (Buyer vs Seller)
                    const Text(
                      'SELECT YOUR ACCOUNT TYPE:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildRoleSelectOption(
                            roleKey: 'buyer',
                            title: 'Buyer 🛒',
                            subtitle: 'Buy produce & place orders',
                            icon: Icons.shopping_basket_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRoleSelectOption(
                            roleKey: 'processor',
                            title: 'Seller / Merchant 🏪',
                            subtitle: 'List stock & sell produce',
                            icon: Icons.storefront_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // STEP 2: Basic User Details
                    const Text(
                      'PERSONAL INFORMATION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                        label: 'Full Name *',
                        hint: 'Enter your full name',
                        icon: Icons.person_outline,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration(
                              label: 'Mobile Phone *',
                              hint: '9876543210',
                              icon: Icons.phone_outlined,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Phone is required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(
                              label: 'Email Address *',
                              hint: 'user@example.com',
                              icon: Icons.email_outlined,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Email is required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // STEP 3: Role Specific Form (Buyer vs Seller Store)
                    if (_selectedRole == 'processor' || _selectedRole == 'seller') ...[
                      // SELLER STORE DETAILS
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F9D58).withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0F9D58).withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.storefront_rounded, color: Color(0xFF0F9D58)),
                                SizedBox(width: 8),
                                Text(
                                  'STORE & BUSINESS DETAILS',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F9D58),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _storeNameController,
                              decoration: _inputDecoration(
                                label: 'Store / Business Name *',
                                hint: 'e.g. Green Valley Organic Farms',
                                icon: Icons.business_rounded,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Store name is required' : null,
                            ),
                            const SizedBox(height: 14),

                            DropdownButtonFormField<String>(
                              value: _sellerBusinessType,
                              decoration: _inputDecoration(
                                label: 'Business Category *',
                                icon: Icons.category_outlined,
                              ),
                              items: _sellerCategories
                                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _sellerBusinessType = val);
                              },
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _storeGstController,
                                    decoration: _inputDecoration(
                                      label: 'GST / Reg. Number',
                                      hint: '22AAAAA0000A1Z5',
                                      icon: Icons.receipt_long_outlined,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _storeEstYearController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: _inputDecoration(
                                      label: 'Est. Year',
                                      hint: '2018',
                                      icon: Icons.calendar_today_outlined,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _storeAddressController,
                              maxLines: 2,
                              decoration: _inputDecoration(
                                label: 'Store Address *',
                                hint: 'Building, Farm Road, Industrial Area',
                                icon: Icons.location_on_outlined,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Store address is required' : null,
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _storeCityController,
                                    decoration: _inputDecoration(
                                      label: 'City / Market *',
                                      hint: 'e.g. Pune',
                                      icon: Icons.location_city_outlined,
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'City is required' : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _storeStateController,
                                    decoration: _inputDecoration(
                                      label: 'State *',
                                      hint: 'e.g. Maharashtra',
                                      icon: Icons.map_outlined,
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'State is required' : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _storePincodeController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: _inputDecoration(
                                      label: 'Pincode *',
                                      hint: '411001',
                                      icon: Icons.pin_drop_outlined,
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Pincode required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _storeDescController,
                              maxLines: 3,
                              decoration: _inputDecoration(
                                label: 'Store Description & Produce Specialties',
                                hint: 'Describe your farm produce, fruits offered, or trading services',
                                icon: Icons.description_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // BUYER DETAILS
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.shopping_cart_rounded, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'BUYER & DELIVERY DETAILS',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.blue,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            DropdownButtonFormField<String>(
                              value: _buyerType,
                              decoration: _inputDecoration(
                                label: 'Buyer Type *',
                                icon: Icons.person_pin_outlined,
                              ),
                              items: _buyerTypes
                                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _buyerType = val);
                              },
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _buyerAddressController,
                              maxLines: 2,
                              decoration: _inputDecoration(
                                label: 'Delivery Address *',
                                hint: 'House/Flat No, Street Name',
                                icon: Icons.home_outlined,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _buyerCityController,
                                    decoration: _inputDecoration(
                                      label: 'City *',
                                      hint: 'Mumbai',
                                      icon: Icons.location_city_outlined,
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'City required' : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _buyerStateController,
                                    decoration: _inputDecoration(
                                      label: 'State *',
                                      hint: 'Maharashtra',
                                      icon: Icons.map_outlined,
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'State required' : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _buyerPincodeController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: _inputDecoration(
                                      label: 'Pincode *',
                                      hint: '400001',
                                      icon: Icons.pin_drop_outlined,
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Pincode required' : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSaveSetup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F9D58),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                            : Text(
                                _selectedRole == 'processor'
                                    ? 'COMPLETE & OPEN STORE 🏪'
                                    : 'COMPLETE SETUP & CONTINUE 🚀',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
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

  Widget _buildRoleSelectOption({
    required String roleKey,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool isSelected = _selectedRole == roleKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = roleKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F9D58) : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F9D58) : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 26, color: isSelected ? Colors.white : Colors.grey[700]),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF0F9D58), size: 20) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F9D58), width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    );
  }
}
