import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreenConstants {
  static const int phoneNumberLength = 10;
  static const int otpLength = 4;
  static const int imageSizeLimitMb = 5;
  static const int imageSizeLimitBytes = imageSizeLimitMb * 1024 * 1024;
  static const int imageQuality = 80;
  static const String mockOtp = '1234';

  static const List<String> supportedCountries = [
    'India',
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
  ];

  static const List<String> userTypeOptions = ['buyer', 'processor'];
  static const List<String> dealingWithOptions = ['RCN', 'Kernel'];
  static const List<String> businessTypeOptions = [
    'Processor',
    'Agent',
    // "Registered agent",
  ];
  static const List<String> isregistered = ['Yes', 'No'];
  static const List<String> initialPages = [
    'Marketplace',
    'Dashboard',
    "BiddingScreen",
  ];

  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration navigationDelay = Duration(milliseconds: 500);
}

// ==================== Enums ====================

enum ProfileScreenMode { create, edit }

enum ImagePickerError {
  permissionDenied,
  invalidFile,
  sizeTooLarge,
  conversionFailed,
}

// ==================== Models ====================

/// Configuration for profile screen behavior
class ProfileScreenConfig {
  final ProfileScreenMode mode;
  final bool showProgressIndicator;
  final bool enableTwoPhaseSetup;
  final bool showRewardScreen;
  final String? nextRoute;
  final VoidCallback? onProfileComplete;
  final void Function(String)? onError;

  const ProfileScreenConfig({
    required this.mode,
    this.showProgressIndicator = false,
    this.enableTwoPhaseSetup = false,
    this.showRewardScreen = false,
    this.nextRoute,
    this.onProfileComplete,
    this.onError,
  });

  /// Factory for profile creation flow
  factory ProfileScreenConfig.createMode({
    bool showProgressIndicator = true,
    bool enableTwoPhaseSetup = true,
    bool showRewardScreen = true,
    VoidCallback? onProfileComplete,
    void Function(String)? onError,
  }) {
    return ProfileScreenConfig(
      mode: ProfileScreenMode.create,
      showProgressIndicator: showProgressIndicator,
      enableTwoPhaseSetup: enableTwoPhaseSetup,
      showRewardScreen: showRewardScreen,
      onProfileComplete: onProfileComplete,
      onError: onError,
    );
  }

  /// Factory for profile editing flow
  factory ProfileScreenConfig.editMode({
    VoidCallback? onProfileComplete,
    void Function(String)? onError,
  }) {
    return ProfileScreenConfig(
      mode: ProfileScreenMode.edit,
      showProgressIndicator: false,
      enableTwoPhaseSetup: false,
      showRewardScreen: false,
      onProfileComplete: onProfileComplete,
      onError: onError,
    );
  }

  /// Copy with modifications
  ProfileScreenConfig copyWith({
    ProfileScreenMode? mode,
    bool? showProgressIndicator,
    bool? enableTwoPhaseSetup,
    bool? showRewardScreen,
    String? nextRoute,
    VoidCallback? onProfileComplete,
    void Function(String)? onError,
  }) {
    return ProfileScreenConfig(
      mode: mode ?? this.mode,
      showProgressIndicator:
          showProgressIndicator ?? this.showProgressIndicator,
      enableTwoPhaseSetup: enableTwoPhaseSetup ?? this.enableTwoPhaseSetup,
      showRewardScreen: showRewardScreen ?? this.showRewardScreen,
      nextRoute: nextRoute ?? this.nextRoute,
      onProfileComplete: onProfileComplete ?? this.onProfileComplete,
      onError: onError ?? this.onError,
    );
  }
}

/// User profile data model
class UserProfileData {
  final String? id;
  final String name;
  final String email;
  final String phone;
  // final String? country;
  // final String? state;
  // final String? city;
  // final String? initialPage;
  final String dialcode;
  // final String? address;
  final bool? register;
  final String? role;
  final String? businessType;
  final String? natureOfBusiness;
  final String? profilePicture;
  final String? status;
  final bool isProfileComplete;
  final List<dynamic>? image;

  const UserProfileData({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.dialcode,
    this.register,
    // this.country,
    // this.state,
    // this.city,
    // this.initialPage,
    // this.address,
    required this.status,
    this.role,
    this.businessType,
    this.natureOfBusiness,
    this.profilePicture,
    this.image,
    required this.isProfileComplete,
  });

  /// Create from JSON
  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      id: json['_id'] as String?,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      // country: json['country'] as String? ?? 'India',
      // state: json['state'] as String? ?? '',
      dialcode: json['dialcode'] as String? ?? '+91',
      // city: json['city'] as String? ?? '',
      status: json['status'] as String? ?? '',
      image: json['image'] as List? ?? [],
      register: json['gstRegistered'] ?? true,
      // initialPage: json['initializer_screen'] as String? ?? 'Marketplace',
      // address: json['address'] as String? ?? '',
      role: json['role'] as String? ?? 'both',
      businessType: json['businessType'] as String? ?? 'Both',
      natureOfBusiness: json['natureOfBusiness'] as String? ?? 'Processor',
      profilePicture: json['profilePicture'] as String?,
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
    );
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'role': role,
      'mail': email,
      'phone': phone,
      'profilePicture': profilePicture,
      'registrationType': 'PRIVATE_LIMITED',
      // 'initializer_screen': initialPage,
      // 'city': city,
      'dialcode': dialcode,
      // 'address': address,
      'gstRegistered': register,
      'image': image,
      'businessType': businessType,
      // 'state': state,
      'natureOfBusiness': natureOfBusiness,
      // 'country': country,
      'isProfileComplete': isProfileComplete,
      'status': status,
    };
  }
}

// ==================== Services ====================

/// Service for image operations
class ImageService {
  static const _supportedFormats = ['png', 'jpg', 'jpeg', 'avif', 'webp'];

  /// Pick image from gallery
  static Future<File?> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: ProfileScreenConstants.imageQuality,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      rethrow;
    }
  }

  /// Validate image
  static Future<bool> validateImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      // Check size
      if (bytes.lengthInBytes > ProfileScreenConstants.imageSizeLimitBytes) {
        throw ImagePickerError.sizeTooLarge;
      }

      // Check format
      final extension = _getFileExtension(imageFile.path);
      if (!_supportedFormats.contains(extension)) {
        throw ImagePickerError.invalidFile;
      }

      return true;
    } catch (e) {
      debugPrint('Error validating image: $e');
      rethrow;
    }
  }

  /// Convert image to base64 data URI
  static Future<String> convertToBase64DataUri(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      final mimeType = _getMimeType(imageFile.path);

      return "data:$mimeType;base64,$base64String";
    } catch (e) {
      debugPrint('Error converting image: $e');
      rethrow;
    }
  }

  /// Get MIME type from path
  static String _getMimeType(String path) {
    final extension = _getFileExtension(path);
    return switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'avif' => 'image/avif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  /// Get file extension
  static String _getFileExtension(String path) {
    return path.split('.').last.toLowerCase();
  }

  /// Get formatted error message
  static String getErrorMessage(Object error) {
    if (error is ImagePickerError) {
      return switch (error) {
        ImagePickerError.permissionDenied => 'Camera/Gallery permission denied',
        ImagePickerError.invalidFile => 'Invalid image format',
        ImagePickerError.sizeTooLarge =>
          'Image too large (max ${ProfileScreenConstants.imageSizeLimitMb}MB)',
        ImagePickerError.conversionFailed => 'Failed to process image',
      };
    }
    return 'Unknown image error';
  }
}

/// Service for form validation
class FormValidationService {
  /// Validate full name
  static String? validateFullName(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Full name is required';
    }
    if (value!.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Phone number is required';
    }
    if (value!.length != ProfileScreenConstants.phoneNumberLength) {
      return 'Phone must be ${ProfileScreenConstants.phoneNumberLength} digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Phone must contain only digits';
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value?.isEmpty ?? true) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Check if basic profile is valid
  static bool isBasicProfileValid({
    required bool hasName,
    required bool hasPhone,
    // required bool phoneVerified,
    required bool userTypeSelected,
  }) {
    return hasName && hasPhone && userTypeSelected;
  }

  /// Check if additional profile is valid
  static bool isAdditionalProfileValid({
    required bool hasName,
    required bool hasPhone,
    required bool phoneVerified,
    required bool userTypeSelected,
    // required bool hasCountry,
    // required bool hasState,
    // required bool hasCity,
    // required bool hasAddress,
    required bool dealingWithSelected,
    required bool businessTypeSelected,
  }) {
    return isBasicProfileValid(
          hasName: hasName,
          hasPhone: hasPhone,
          userTypeSelected: userTypeSelected,
        ) &&
        phoneVerified &&
        // hasCountry &&
        // hasState &&
        // hasCity &&
        // hasAddress &&
        dealingWithSelected &&
        businessTypeSelected;
  }
}

/// Service for profile data operations
class ProfileDataService {
  /// Parse user type from string to list
  static List<String> parseUserType(String userType) {
    return switch (userType) {
      'both' => ['buyer', 'processor'],
      'buyer' => ['buyer'],
      'processor' => ['processor'],
      _ => ['buyer'],
    };
  }

  /// Parse dealing with from string to list
  static List<String> parseDealingWith(String dealingWith) {
    return switch (dealingWith) {
      'Both' => ['RCN', 'Kernel'],
      'RCN' => ['RCN'],
      'Kernel' => ['Kernel'],
      _ => ['RCN'],
    };
  }

  /// Convert user type list to string
  static String userTypeToString(List<String> types) {
    if (types.length == 2) return 'both';
    return types.isNotEmpty ? types.first : 'both';
  }

  /// Convert dealing with list to string
  static String dealingWithToString(List<String> items) {
    if (items.length == 2) return 'Both';
    return items.isNotEmpty ? items.first : 'Both';
  }
}

// ==================== Widgets - Dialogs ====================

/// OTP Dialog for create mode
class OtpVerificationDialog extends StatefulWidget {
  final VoidCallback onVerifySuccess;
  final VoidCallback? onCancel;

  const OtpVerificationDialog({
    required this.onVerifySuccess,
    this.onCancel,
    super.key,
  });

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      ProfileScreenConstants.otpLength,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      ProfileScreenConstants.otpLength,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _verifyOtp() {
    final otp = _controllers.map((c) => c.text).join();

    setState(() {
      if (otp.length != ProfileScreenConstants.otpLength) {
        _error = "Enter complete OTP";
      } else if (otp != ProfileScreenConstants.mockOtp) {
        _error = "Invalid OTP";
      } else {
        _error = null;
        Navigator.pop(context);
        widget.onVerifySuccess();
      }
    });
  }

  void _onOtpInputChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < ProfileScreenConstants.otpLength - 1) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        FocusScope.of(context).unfocus();
      }
    } else if (index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }

    if (_error != null) {
      setState(() => _error = null);
    }
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 55,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: AppTextThemes.getgetLightTextTheme(context).titleLarge,
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: AppColors.cream,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => _onOtpInputChanged(value, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "OTP Verification",
                  style: AppTextThemes.getgetLightTextTheme(
                    context,
                  ).titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onCancel?.call();
                  },
                  child: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Enter the 4-digit code sent to your phone",
              style: AppTextThemes.getgetLightTextTheme(context).bodySmall,
            ),
            const SizedBox(height: 25),

            // OTP Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                ProfileScreenConstants.otpLength,
                _buildOtpBox,
              ),
            ),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: AppColors.error)),
            ],

            const SizedBox(height: 25),

            // Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifyOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Verify"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// OTP Bottom Sheet for edit mode
class OtpVerificationBottomSheet extends StatefulWidget {
  final VoidCallback onVerifySuccess;
  final VoidCallback? onCancel;

  const OtpVerificationBottomSheet({
    required this.onVerifySuccess,
    this.onCancel,
    super.key,
  });

  @override
  State<OtpVerificationBottomSheet> createState() =>
      _OtpVerificationBottomSheetState();
}

class _OtpVerificationBottomSheetState
    extends State<OtpVerificationBottomSheet> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      ProfileScreenConstants.otpLength,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      ProfileScreenConstants.otpLength,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _verifyOtp() {
    final otp = _controllers.map((c) => c.text).join();

    setState(() {
      if (otp.length != ProfileScreenConstants.otpLength) {
        _error = "Enter complete OTP";
      } else if (otp != ProfileScreenConstants.mockOtp) {
        _error = "Invalid OTP";
      } else {
        _error = null;
        Navigator.pop(context);
        widget.onVerifySuccess();
      }
    });
  }

  void _onOtpInputChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < ProfileScreenConstants.otpLength - 1) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        FocusScope.of(context).unfocus();
      }
    } else if (index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }

    if (_error != null) {
      setState(() => _error = null);
    }
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 55,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: "",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: (value) => _onOtpInputChanged(value, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Enter OTP",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onCancel?.call();
                  },
                  child: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // OTP Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                ProfileScreenConstants.otpLength,
                _buildOtpBox,
              ),
            ),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: AppColors.error)),
            ],

            const SizedBox(height: 25),

            // Verify Button
            Center(
              child: SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Verify"),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// Country Picker Dialog
class CountryPickerDialog extends StatelessWidget {
  final List<String> countries;
  final String? selectedCountry;
  final ValueChanged<String> onCountrySelected;

  const CountryPickerDialog({
    required this.countries,
    this.selectedCountry,
    required this.onCountrySelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Country'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: countries.length,
          itemBuilder: (context, index) {
            final country = countries[index];
            final isSelected = country == selectedCountry;
            return ListTile(
              title: Text(country),
              trailing: isSelected ? const Icon(Icons.check) : null,
              onTap: () {
                onCountrySelected(country);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }
}

/// Profile Image Preview Dialog
class ProfileImagePreviewDialog extends StatelessWidget {
  final ImageProvider imageProvider;

  const ProfileImagePreviewDialog({required this.imageProvider, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: GestureDetector(
            onTap: () {},
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  color: AppColors.backgroundLight,
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(color: Colors.black),
                    child: Image(image: imageProvider, fit: BoxFit.cover),
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
