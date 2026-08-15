import 'dart:async';
import 'dart:io';
import 'package:hema_fruits/core/config/app_config.dart';
import 'package:hema_fruits/core/providers/language_provider.dart';
import 'package:hema_fruits/core/providers/swap_user_provider.dart';
import 'package:hema_fruits/core/providers/user_provider.dart';
import 'package:hema_fruits/core/repositories/settings_repository.dart';
import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/core/services/api_service.dart';
import 'package:hema_fruits/core/services/filter_request.dart';
import 'package:hema_fruits/core/services/referral/referral_service.dart';
import 'package:hema_fruits/core/services/translate.dart';
import 'package:hema_fruits/core/utils/context_manager.dart';
import 'package:hema_fruits/core/utils/formatters.dart';
import 'package:hema_fruits/features/auth/profile_helpers.dart';
import 'package:hema_fruits/features/screens/creditPoint/firstReward_credit.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:hema_fruits/shared/theme/app_text_theme.dart';
import 'package:hema_fruits/shared/widgets/custom_input.dart';
import 'package:hema_fruits/shared/widgets/profile_widget.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/services/auth_service/auth_service.dart';

// ==================== Constants ====================

class ProfileScreen extends StatefulWidget {
  final ProfileScreenConfig config;

  const ProfileScreen({super.key, ProfileScreenConfig? config})
    : config =
          config ?? const ProfileScreenConfig(mode: ProfileScreenMode.edit);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ==================== Controllers ====================
  late final TextEditingController _nameController;

  // ── Referral integration state (registration only) ───────────────
  bool _isCheckingReferral = false;
  bool _hasValidReferral = false;
  String? _verifiedReferralCode;
  String? _referrerName;
  String? _referrerId;
  int? _referralRewardPoints;

  late final TextEditingController _phoneController;
  late final TextEditingController _countryController;
  late final TextEditingController _stateController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late final TextEditingController _pincodeController;

  // ==================== Form Key ====================
  final _formKey = GlobalKey<FormState>();

  UserProfileData? _profileData;
  File? _selectedImage;
  String? _country = 'India';
  String? _dialcode = '+91';
  String? _status = 'active';
  String _userType = 'both';
  String _dealingWith = 'Both';
  String _businessType = 'Processor';
  bool _isregister = true;
  String _initialPage = 'Dashboard';
  List<String> _userTypes = ['buyer', 'processor'];
  List<String> _dealingWiths = ['RCN', 'Kernel'];
  late List<String> dialnumbers = ['+91', '+1', '+7', '+809', '+44'];
  // ==================== Validation Flags ====================
  bool isnewregister = true;
  bool _hasName = false;
  bool _hasPhone = false;
  bool _hasState = false;
  bool _hasCity = false;
  bool _hasAddress = true;
  bool _showAdditionalFields = false;
  bool _phoneVerified = false;
  bool _isSubmitting = false;
  bool _isFormValid = false;
  bool popuprefferal = false;
  bool secondstage = false;
  List<Map<String, dynamic>> uploadedImages = [];
  Map<String, dynamic> userData = {};
  bool isUploadingImage = false;

  List<String> supportedCountries = ["🇮🇳 India", "🇺🇸 United States"];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeProfile();
  }

  /// Initialize text controllers
  void _initializeControllers() {
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _countryController = TextEditingController(text: _country);
    _stateController = TextEditingController();
    _cityController = TextEditingController();
    _addressController = TextEditingController();
    _pincodeController = TextEditingController();
  }

  /// Initialize profile based on mode
  Future<void> _initializeProfile() async {
    try {
      if (widget.config.mode == ProfileScreenMode.create) {
        setState(() => popuprefferal = true);
      }
      // Referral code validation (registration only)
      if (widget.config.mode == ProfileScreenMode.create) {
        await _loadAndValidateReferralCode();
      }

      final userData = await SecureStorageService.getUserData();
      _profileData = UserProfileData.fromJson(userData);
      await Countryfetch();
      _populateFormFields();
      if (widget.config.mode == ProfileScreenMode.edit) {
        await _loadExistingProfile();
      } else if (_profileData?.name.isNotEmpty ?? false) {
        _nameController.text = _profileData!.name;
        _hasName = true;
      }
    } catch (e) {
      debugPrint('Error initializing profile: $e');
      widget.config.onError?.call('Error loading profile: $e');
      _showErrorMessage(
        "${Translate.t("profile_info.error_loading_profile")}: $e",
      );
    }
  }

  Future<void> removeImage(int index, Map<String, dynamic> img) async {
    if (!mounted || index < 0 || index >= uploadedImages.length) return;
    setState(() => uploadedImages = []);
    try {
      final dio = ApiService.instance.dio;
      await dio.delete('file/${img['_id']}');
    } catch (e) {
      debugPrint('Delete image failed: $e');
    }
  }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;

    setState(() => isUploadingImage = true);

    for (final pickedFile in picked) {
      try {
        final bytes = await pickedFile.readAsBytes();
        final fileName = pickedFile.name;

        final dio = ApiService.instance.dio;
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: fileName),
          'folders': 'marketplace/users',
        });

        final response = await dio.post(
          'file/marketplace/users',
          data: formData,
        );
        final resData = response.data;

        if (resData != null && resData['status'] == 200) {
          // API returns data as a list; pick first item
          final fileData = resData['data'] is List
              ? resData['data'][0] as Map<String, dynamic>
              : resData['data'] as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              uploadedImages = [fileData];
            });
          }
        }
      } catch (e) {
        debugPrint('Image upload failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image upload failed: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    if (mounted) setState(() => isUploadingImage = false);
  }

  Timer? _pincodeDebounce;
  bool _isPincodeLookingUp = false;

  // Build a map of country name -> ISO code from supportedCountries list
  // supportedCountries format: "🇮🇳 India", "🇺🇸 United States"
  static const Map<String, String> _countryNameToIso = {
    'India': 'IN',
    'United States': 'US',
    'United Kingdom': 'GB',
    'Canada': 'CA',
    'Australia': 'AU',
    'Germany': 'DE',
    'France': 'FR',
    'Brazil': 'BR',
    'Japan': 'JP',
    'China': 'CN',
    'Italy': 'IT',
    'Spain': 'ES',
    'Mexico': 'MX',
    'South Korea': 'KR',
    'Russia': 'RU',
    'Netherlands': 'NL',
    'Sweden': 'SE',
    'Norway': 'NO',
    'Denmark': 'DK',
    'Finland': 'FI',
    'Poland': 'PL',
    'Belgium': 'BE',
    'Austria': 'AT',
    'Switzerland': 'CH',
    'Portugal': 'PT',
    'New Zealand': 'NZ',
    'South Africa': 'ZA',
    'Singapore': 'SG',
    'Malaysia': 'MY',
    'Indonesia': 'ID',
    'Thailand': 'TH',
    'Philippines': 'PH',
    'Pakistan': 'PK',
    'Bangladesh': 'BD',
    'Sri Lanka': 'LK',
    'Nepal': 'NP',
    'Nigeria': 'NG',
    'Ghana': 'GH',
    'Kenya': 'KE',
    'Egypt': 'EG',
    'Turkey': 'TR',
    'Israel': 'IL',
    'UAE': 'AE',
    'Saudi Arabia': 'SA',
    'Argentina': 'AR',
    'Colombia': 'CO',
    'Chile': 'CL',
    'Peru': 'PE',
    'Vietnam': 'VN',
    'Ukraine': 'UA',
    'Czech Republic': 'CZ',
    'Hungary': 'HU',
    'Romania': 'RO',
    'Ivory Coast': 'CI',
  };

  String? _extractCountryName(String? countryEntry) {
    if (countryEntry == null || countryEntry.isEmpty) return null;
    // Format is "🇮🇳 India" — strip leading emoji chars (runes until first space)
    final parts = countryEntry.trim().split(' ');
    if (parts.length <= 1) return countryEntry;
    // Emoji flags are 1 "word" (no space inside), so skip first token
    return parts.skip(1).join(' ');
  }

  String? _getIsoCode(String? countryEntry) {
    final name = _extractCountryName(countryEntry);
    if (name == null) return null;
    return _countryNameToIso[name];
  }

  // Match API country name back to our supportedCountries list entry
  String? _matchCountry(String apiCountryName) {
    try {
      return supportedCountries.firstWhere(
        (e) => e.toLowerCase().contains(apiCountryName.toLowerCase()),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> Countryfetch() async {
    try {
      await context.read<CountryProvider>().fetchCountry();
    } catch (e) {
      debugPrint('Error fetching country: $e');
    } finally {
      try {
        final country = SettingsLocalRepository.instance.getCountries();
        setState(() {
          supportedCountries = country
              .map((e) => "${e['flag']} ${e['name']}")
              .toList();
          dialnumbers = country
              .map((e) => "${e['flag']} ${e['dialCode']}")
              .toList();
          supportedCountries.sort();
          dialnumbers.sort();
        });
      } catch (e) {
        debugPrintStack();
      }
    }
  }

  /// Load existing profile for edit mode
  Future<void> _loadExistingProfile() async {
    try {
      if (_profileData?.id == null) {
        throw Exception('User ID not found');
      }

      // Fetch via provider
      final filterRequest = FilterRequest(userId: _profileData!.id!);
      if (mounted) {
        context.read<ProfileProvider>().userprofilefetch(
          endpoint: "entities/filter/users",
          filterPayload: filterRequest.getuserprofile(),
        );
      }

      // Load from local storage
      final data = await SecureStorageService.getUserProfileData();
      userData = await SecureStorageService.getUserData();
      _profileData = UserProfileData.fromJson(data);

      _populateFormFields();
    } catch (e) {
      debugPrint('Error loading profile: $e');
      rethrow;
    }
  }

  /// Populate form fields with profile data
  void _populateFormFields() {
    // final count = supportedCountries.firstWhere((element) {
    //   final name = element.toString().toLowerCase();
    //   final target = (_profileData!.country)!.toLowerCase();

    //   return name.contains(target);
    // });
    final dailcode = dialnumbers.firstWhere((element) {
      final name = element.toString().toLowerCase();
      final target = (_profileData!.dialcode).toLowerCase();

      return name.contains(target);
    });
    final imgs = _profileData!.image;

    setState(() {
      // _userType = _profileData!.role ?? 'both';
      // _userTypes = ProfileDataService.parseUserType(_userType);
      _dealingWith = _profileData!.businessType ?? 'Both';
      _dealingWiths = ProfileDataService.parseDealingWith(_dealingWith);
      _businessType = _profileData!.natureOfBusiness ?? 'Processor';
      _status = _profileData!.status;
      _nameController.text = _profileData!.name;
      _phoneController.text = _profileData!.phone;
      // _countryController.text = _profileData!.country ?? "India";
      // _country = _profileData!.country;
      // _stateController.text = _profileData!.state ?? "";
      // _cityController.text = _profileData!.city ?? "";
      // _addressController.text = _profileData!.address ?? "";
      // _country = count;
      _dialcode = dailcode;
      _isregister = _profileData!.register ?? true;
      // _initialPage = _profileData!.initialPage ?? "";
      // Update validation flags
      _hasName = _nameController.text.isNotEmpty;
      _hasPhone = _phoneController.text.isNotEmpty;
      _hasState = _stateController.text.isNotEmpty;
      _hasCity = _cityController.text.isNotEmpty;
      _hasAddress = _addressController.text.isNotEmpty;
      if (imgs is List) {
        uploadedImages = imgs
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (widget.config.mode == ProfileScreenMode.edit) {
        _phoneVerified = true;
      } // Assume verified on edit
      // Only update submit-button state, never trigger field error display
      _isFormValid = _isAllFieldsValid();
    });
  }

  Future<void> getreferal(String code) async {
    try {
      await SecureStorageService.saveReferralCode(code);
      _loadAndValidateReferralCode();
    } catch (e) {
      debugPrint('Error fetching referral code: $e');
    }
  }

  Future<void> _loadAndValidateReferralCode() async {
    try {
      setState(() {
        _isCheckingReferral = true;
        _hasValidReferral = false;
        _verifiedReferralCode = null;
        _referrerName = null;
        _referrerId = null;
        _referralRewardPoints = null;
      });

      final code = await ReferralService.instance.getReferralCode();
      if (code == null || code.isEmpty) {
        if (mounted) {
          setState(() => _isCheckingReferral = false);
        }
        return;
      }

      final validation = await ReferralService.instance.validateReferralCode(
        code,
      );

      final isValid = validation != null && (validation['valid'] == true);

      if (isValid) {
        if (mounted) {
          if (widget.config.mode == ProfileScreenMode.create) {
            setState(() => popuprefferal = false);
          }
          setState(() {
            _hasValidReferral = true;
            _verifiedReferralCode = code;
            _referrerName = validation['referrerName']?.toString();
            _referrerId = validation['referrerId']?.toString();
            final reward = validation['reward'];
            _referralRewardPoints = reward is int
                ? reward
                : int.tryParse(reward?.toString() ?? '');
            _isCheckingReferral = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasValidReferral = false;
            _verifiedReferralCode = null;
            _referrerName = null;
            _referrerId = null;
            _referralRewardPoints = null;
            _isCheckingReferral = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[ReferralService] Referral validation failed: $e');
      if (mounted) {
        setState(() {
          _isCheckingReferral = false;
          _hasValidReferral = false;
        });
      }
    }
  }

  Widget _buildReferralIndicator(bool secondstage) {
    if (_isCheckingReferral) {
      return Row(
        children: [
          const SizedBox(width: 8),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Checking referral…',
            style: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
              color: AppColors.textHint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (!_hasValidReferral) {
      return secondstage
          ? const SizedBox.shrink()
          : InkWell(
              onTap: () => setState(() {
                popuprefferal = true;
              }),
              child: Text(
                'Having Referral Code?',
                style: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
    }

    final referrer = _referrerName ?? 'Friend';
    final referrerid = _referrerId ?? '';
    final reward = _referralRewardPoints ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        // color: AppColors.secondary,
        // boxShadow: [
        //   BoxShadow(
        //     color: AppColors.success.withAlpha(40),
        //     blurRadius: 10,
        //     spreadRadius: 2,
        //     offset: const Offset(0, 6),
        //   ),
        // ],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withOpacity(0.35),
          width: 1,
        ),
      ),
      child: Text(
        'Referred by $referrer',
        style: AppTextThemes.getLightTextTheme.labelLarge?.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _isAllFieldsValid();
    });
  }

  bool _isAllFieldsValid() {
    final bool basicValid = FormValidationService.isBasicProfileValid(
      hasName: _hasName,
      hasPhone: _hasPhone,
      // phoneVerified: _phoneVerified,
      userTypeSelected: _userType.isNotEmpty,
    );

    if (!basicValid) return false;

    if (widget.config.enableTwoPhaseSetup && _showAdditionalFields) {
      return FormValidationService.isAdditionalProfileValid(
        hasName: _hasName,
        hasPhone: _hasPhone,
        phoneVerified: _phoneVerified,
        userTypeSelected: _userType.isNotEmpty,
        // hasCountry: _country != null && _country!.isNotEmpty,
        // hasState: _hasState,
        // hasCity: _hasCity,
        // hasAddress: _hasAddress,
        dealingWithSelected: _dealingWith.isNotEmpty,
        businessTypeSelected: _businessType.isNotEmpty,
      );
    }

    return basicValid;
  }

  /// Handle phone verification
  Future<void> _handlePhoneVerify() async {
    // if (widget.config.mode == ProfileScreenMode.create) {
    //   _showOtpDialog();
    // } else {
    await _showOtpBottomSheet();
    // }
  }

  /// Show OTP Bottom Sheet (edit mode)
  Future<void> _showOtpBottomSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OtpVerificationBottomSheet(
        onVerifySuccess: _onPhoneVerificationSuccess,
        onCancel: () => debugPrint('OTP verification cancelled'),
      ),
    );
  }

  /// Handle successful phone verification
  void _onPhoneVerificationSuccess() {
    setState(() {
      _phoneVerified = true;
      isnewregister = false;
      _hasPhone = true;
    });
    _validateForm();
    _showSuccessMessage(Translate.t("profile_info.phone_verified_success"));
  }

  /// Show profile image preview
  void _showImagePreview(ImageProvider imageProvider) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) =>
          ProfileImagePreviewDialog(imageProvider: imageProvider),
    );
  }

  /// Pick image
  // Future<void> _pickImage() async {
  //   try {
  //     final imageFile = await ImageService.pickImage();
  //     if (imageFile != null) {
  //       await ImageService.validateImage(imageFile);
  //       setState(() => _selectedImage = imageFile);
  //     }
  //   } catch (e) {
  //     final errorMsg = ImageService.getErrorMessage(e);
  //     widget.config.onError?.call(errorMsg);
  //     _showErrorMessage(errorMsg);
  //   }
  // }

  /// Complete/update profile
  Future<void> _completeProfile() async {
    try {
      if (_profileData?.id == null) {
        throw Exception('User data not available');
      }

      setState(() => _isSubmitting = true);

      String? profilePictureData = _profileData!.profilePicture;
      if (uploadedImages.isNotEmpty) {
        profilePictureData = uploadedImages.first['storage_name']?.toString();
      }
      userData = await SecureStorageService.getUserData();
      final userId = userData['_id'];
      FilterRequest request = FilterRequest(userId: userId);
      UserProfileData profileData;
      if (widget.config.mode == ProfileScreenMode.edit) {
        profileData = UserProfileData(
          id: _profileData!.id,
          name: _nameController.text.trim(),
          email: _profileData!.email,
          phone: _phoneController.text.trim(),
          // country: _country!.split(' ')[1],
          // state: _stateController.text.trim(),
          dialcode: _dialcode!.split(' ')[1],
          // initialPage: _initialPage,
          // city: _cityController.text.trim(),
          image: uploadedImages,
          register: _isregister,
          // address: _addressController.text.trim(),
          role: _userType,
          businessType: _dealingWith,
          natureOfBusiness: _businessType,
          profilePicture: profilePictureData,
          isProfileComplete: true,
          status: _status == '' ? _status : 'active',
        );
      } else if (_showAdditionalFields &&
          _phoneVerified &&
          widget.config.mode == ProfileScreenMode.create) {
        profileData = UserProfileData(
          id: _profileData!.id,
          name: _nameController.text.trim(),
          email: _profileData!.email,
          phone: _phoneController.text.trim(),
          dialcode: _dialcode!.split(' ')[1],
          // country: _country!.split(' ')[1],
          // state: _stateController.text.trim(),
          // initialPage: _initialPage,
          // city: _cityController.text.trim(),
          // address: _addressController.text.trim(),
          register: _isregister,
          image: uploadedImages,
          role: _userType,
          businessType: _dealingWith,
          natureOfBusiness: _businessType,
          profilePicture: profilePictureData,
          isProfileComplete: false,
          status: _status == '' ? _status : 'active',
        );
      } else {
        profileData = UserProfileData(
          id: _profileData!.id,
          name: _nameController.text.trim(),
          email: _profileData!.email,
          phone: _phoneController.text.trim(),
          role: _userType,
          // register: _isregister,
          image: uploadedImages,
          dialcode: _dialcode!.split(' ')[1],
          businessType: _dealingWith,
          // natureOfBusiness: _businessType,
          profilePicture: profilePictureData,
          isProfileComplete: false,
          status: _status == '' ? _status : 'active',
        );
      }

      // ── Build payload ─────────────────────────────────────────────────────
      Map<String, dynamic> payload = profileData.toJson();

      // ── Referral code injection (create mode only) ────────────────────────
      // Only forward a VERIFIED referral code into the POST /user payload.
      // Edit-mode saves must never forward a stale stored code.
      String? referralCode;
      if (widget.config.mode == ProfileScreenMode.create && _hasValidReferral) {
        referralCode = _verifiedReferralCode;
        if (referralCode != null && referralCode.isNotEmpty) {
          payload['referred_Code'] = referralCode;
          payload['refferred_by'] = _referrerId;
          payload['refferred_name'] = _referrerName;
          debugPrint(
            '[ReferralService] Injecting VERIFIED referral code into registration payload: $referralCode',
          );
        }
      }

      final success = await updateProfile(
        payload: payload,
        userId: _profileData!.id!,
      );

      if (!success) throw Exception('Failed to update profile');

      // ── Clear referral code after confirmed success ──────────────────────
      // Only erase after the backend confirms; preserves code on transient failures.
      // Only relevant in create mode (guarded above).
      if (widget.config.mode == ProfileScreenMode.create &&
          referralCode != null &&
          referralCode.isNotEmpty) {
        await ReferralService.instance.clearReferralCode();
        // Clear local UI state as well (prevents resubmission with stale data).
        if (mounted) {
          setState(() {
            _hasValidReferral = false;
            _verifiedReferralCode = null;
            _referrerName = null;
            _referrerId = null;
            _referralRewardPoints = null;
          });
        }
      }

      context.read<ProfileProvider>().userprofilefetch(
        endpoint: "entities/filter/users",
        filterPayload: request.getuserprofile(),
      );
      if (mounted) {
        if (widget.config.mode == ProfileScreenMode.edit) {
          context.read<SwapUserProvider>().initialize();
          context.pop();
        }
        _showSuccessMessage(
          Translate.t("profile_info.profile_updated_success"),
        );
        if (widget.config.mode == ProfileScreenMode.create &&
            _businessType == 'Agent') {
          int points = await rewardgetter(userId);
          _navigateToReward(points);
        }
        widget.config.onProfileComplete?.call();
      }
    } catch (e) {
      debugPrint('Error completing profile: $e');
      widget.config.onError?.call(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          secondstage = true;
          _isSubmitting = false;
        });
      }
    }
  }

  void showupdatepop() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          Translate.t("profile_info.proceed_profile_info"),
          textAlign: TextAlign.left,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(Translate.t(" .cancel")),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _validateForm();
              _completeProfile();
            },
            child: Text(
              Translate.t("profile_info.ok"),
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToReward(int points) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FirstLoginRewardScreen(
          rewardPoints: points,
          onAutoDismiss: () {
            Navigator.pop(context);
            context.go(RoutePath.home);
          },
          onSubscribe: () {
            Navigator.pop(context);
            context.go(RoutePath.home);
            context.push(RoutePath.creditpayment);
          },
          onSkip: () {
            Navigator.pop(context);
            context.go(RoutePath.home);
          },
        ),
      ),
    );
  }

  bool _isValidPhone(String phone) {
    return phone.length == 10 && RegExp(r'^[0-9]{10}$').hasMatch(phone);
  }

  Future<int> rewardgetter(String id) async {
    await context.read<ProfileProvider>().rewardfetch(endpoint: "confirm/$id");

    // final filterRequest = FilterRequest(userId: id);
    // await context.read<ProfileProvider>().userprofilefetch(
    //   endpoint: "entities/filter/users",
    //   filterPayload: filterRequest.getuserprofile(),
    // );
    final userData = await SecureStorageService.getUserProfileData();

    return userData['points']; // Replace with actual reward points
  }

  void verfiynumber() async {
    await _handlePhoneVerify();
    await _completeProfile();
    setState(() => _showAdditionalFields = true);
  }

  /// Handle save and continue (create mode)
  void _handleSaveAndContinue() {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          Translate.t("profile_info.proceed_profile_info"),
          textAlign: TextAlign.left,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SecureStorageService.Saveprofilestatus(true);
              _completeProfile();
              context.go(RoutePath.home);
            },
            child: Text(Translate.t("profile_info.skip")),
          ),
          TextButton(
            onPressed: () {
              setState(() => _showAdditionalFields = true);
              _validateForm();
              Navigator.pop(context);
            },
            child: Text(
              Translate.t("profile_info.ok"),
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle business information (create mode)
  void _handleBusinessInformation() {
    if (!_formKey.currentState!.validate()) return;

    _businessType == "Agent"
        ? showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                Translate.t("profile_info.proceed_confirm"),
                textAlign: TextAlign.left,
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    _completeProfile();

                    context.go(RoutePath.home);
                  },
                  child: Text(Translate.t("profile_info.ok")),
                ),
              ],
            ),
          )
        : showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                Translate.t("profile_info.proceed_business_info"),
                textAlign: TextAlign.left,
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    _completeProfile();
                    context.go(RoutePath.home);
                  },
                  child: Text(Translate.t("profile_info.skip")),
                ),
                TextButton(
                  onPressed: () async {
                    _completeProfile();
                    context.push("/companysetup");
                  },
                  child: Text(
                    Translate.t("profile_info.ok"),
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          );
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: ProfileScreenConstants.snackBarDuration,
      ),
    );
  }

  Future<void> showCurrencySelector(BuildContext context, String type) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Select Currency',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.separated(
              itemCount: dialnumbers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final dialno = dialnumbers[index];

                return Column(
                  children: [
                    ListTile(
                      title: Text(dialno),
                      onTap: () {
                        Navigator.pop(context);

                        setState(() {
                          _dialcode = dialno;
                        });
                      },
                    ),
                    IntrinsicWidth(
                      child: Divider(
                        height: 1,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Show error message
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Something went wrong."),
        backgroundColor: AppColors.error,
        duration: ProfileScreenConstants.snackBarDuration,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _pincodeDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ContextManager().saveCurrentPage('profile', context);
    // if (_isLoading) {
    //   return Scaffold(
    //     body: Center(
    //       child: CircularProgressIndicator(
    //         valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
    //       ),
    //     ),
    //   );
    // }

    return Scaffold(
      backgroundColor: widget.config.mode == ProfileScreenMode.edit
          ? AppColors.backgroundLight
          : Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: popuprefferal
              ? SizedBox(
        width: MediaQuery.sizeOf(context).width < 600 ? null : 600,
                child: ReferralCodePage(
                    onSubmit: (code) async {
                      await getreferal(code);
                      setState(() {
                        popuprefferal = false;
                      });
                    },
                    onCancel: () async {
                      setState(() {
                        popuprefferal = false;
                      });
                    },
                  ),
              )
              : SizedBox(
        width: MediaQuery.sizeOf(context).width < 600 ? null : 600,
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 20,
                    ),
                    child: Form(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Header (create mode only)
                          if (widget.config.mode == ProfileScreenMode.create)
                            FormHeader(
                              title: Translate.t(
                                "profile_info.setup_profile_title",
                              ),
                              subtitle: Translate.t(
                                "profile_info.setup_profile_subtitle",
                              ),
                            ),
                        
                          // Profile Avatar
                          ProfileAvatarWidget(
                            selectedImage: _selectedImage,
                            imageUrl: uploadedImages.isNotEmpty
                                ? uploadedImages.first['storage_name']?.toString()
                                : _profileData?.profilePicture,
                            onImagePicked: (_) => pickAndUploadImage(),
                            onTap: widget.config.mode == ProfileScreenMode.edit
                                ? () {
                                    final storageName = uploadedImages.isNotEmpty
                                        ? uploadedImages.first['storage_name']
                                              ?.toString()
                                        : _profileData?.profilePicture;
                                    if (_selectedImage != null) {
                                      _showImagePreview(
                                        FileImage(_selectedImage!),
                                      );
                                    } else if (storageName != null &&
                                        storageName.isNotEmpty) {
                                      final url = storageName.startsWith('http')
                                          ? storageName
                                          : '${AppConfig.imageurl}$storageName';
                                      _showImagePreview(NetworkImage(url));
                                    }
                                  }
                                : null,
                          ),
                          const SizedBox(height: 16),
                        
                          // Full Name
                          CustomTextFormField(
                            controller: _nameController,
                            label: Translate.t("profile_info.full_name"),
                            hintText: Translate.t("profile_info.enter_full_name"),
                            onChanged: (value) {
                              setState(() => _hasName = value.trim().isNotEmpty);
                              _validateForm();
                            },
                            inputFormatters: [FirstLetterUpperCaseFormatter()],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required';
                              }
                              if (value.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return FormValidationService.validateFullName(
                                value,
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                        
                          // Phone
                          // Row(
                          //   crossAxisAlignment: CrossAxisAlignment.start,
                          //   children: [
                          //     IntrinsicWidth(
                          //       child: CustomDropdownFormField<String>(
                          //         value: _dialcode,
                          //         items: dialnumbers,
                          //         // prefixIcon: Icons.language,
                          //         labels: dialnumbers,
                          //         label: Translate.t("business_info.dialcode"),
                          //         onChanged: (v) => setState(() {
                          //           _dialcode = v;
                          //           _validateForm();
                          //         }),
                          //         validator: (value) {
                          //           if (value == null) {
                          //             return Translate.t(
                          //               "business_info.country_required",
                          //             );
                          //           }
                          //           return null;
                          //         },
                          //       ),
                          //     ),
                          //     const SizedBox(width: 8),
                          //     Expanded(
                          //       child: CustomTextFormField(
                          //         controller: _phoneController,
                          // onChanged: (value) {
                          //   setState(() {
                          //     _hasPhone =
                          //         value.length ==
                          //         ProfileScreenConstants.phoneNumberLength;
                          //     if (_phoneController.text.length !=
                          //         ProfileScreenConstants.phoneNumberLength) {
                          //       _phoneVerified = false;
                          //     }
                          //   });
                          //   _validateForm();
                          // },
                          //         label: Translate.t("profile_info.phone_number"),
                          //         onVerifyPressed: !_phoneVerified && _hasPhone
                          //             ? _handlePhoneVerify
                          //             : () {},
                          //         verified: _phoneVerified,
                          //         suffixIconverification: true,
                          //         suffixIcon: _phoneVerified
                          //             ? Icons.verified_outlined
                          //             : null,
                          //         hintText: '98765 43210',
                          //         keyboardType: TextInputType.phone,
                          //         inputFormatters: [
                          //           FilteringTextInputFormatter.digitsOnly,
                          //           LengthLimitingTextInputFormatter(10),
                          //         ],
                          //         validator: (value) {
                          //           if (value?.isEmpty ?? true) {
                          //             return Translate.t(
                          //               "business_info.phone_required",
                          //             );
                          //           }
                          //           if (!_isValidPhone(value!)) {
                          //             return Translate.t(
                          //               "business_info.phone_invalid",
                          //             );
                          //           }
                          //           return null;
                          //         },
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          CustomTextFormFieldright(
                            height: 70,
                            readonly: widget.config.mode == ProfileScreenMode.edit
                                ? false
                                : _phoneVerified,
                            controller: _phoneController,
                            label: Translate.t("profile_info.phone_number"),
                            hintText: '98765 43210',
                            onVerifyPressed: !_phoneVerified && _hasPhone
                                ? _handlePhoneVerify
                                : () {},
                            verified: _phoneVerified,
                            onChanged: (value) {
                              setState(() {
                                _hasPhone =
                                    value.length ==
                                    ProfileScreenConstants.phoneNumberLength;
                                if (_phoneController.text.length !=
                                    ProfileScreenConstants.phoneNumberLength) {
                                  _phoneVerified = false;
                                }
                              });
                              if (value == userData['phone']?.toString()) {
                                setState(() {
                                  _phoneVerified = true;
                                });
                              }
                              _validateForm();
                            },
                            suffixIconverification: true,
                            suffixIcon: _phoneVerified
                                ? Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: AppColors.success,
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      color: AppColors.error,
                                    ),
                                  ),
                            onprefixPressed: () {
                              // showCurrencySelector(context, "selected currency");
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            prefixIcon: PopupMenuButton<String>(
                              position: PopupMenuPosition.under,
                              constraints: BoxConstraints(maxHeight: 200),
                              padding: EdgeInsets.zero,
                              onSelected: (value) {
                                setState(() {
                                  _dialcode = value;
                                });
                              },
                              itemBuilder: (context) {
                                return dialnumbers
                                    .map(
                                      (currency) => PopupMenuItem<String>(
                                        value: currency,
                                        child: Text(currency),
                                      ),
                                    )
                                    .toList();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _dialcode ?? "+91",
                                      style: AppTextThemes
                                          .getLightTextTheme
                                          .bodyMedium!
                                          .copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return Translate.t(
                                  "business_info.phone_required",
                                );
                              }
                              if (!_isValidPhone(value!)) {
                                return Translate.t("business_info.phone_invalid");
                              }
                              return null;
                            },
                          ),
                        
                          // Additional Fields
                          if (widget.config.mode == ProfileScreenMode.edit ||
                              (_showAdditionalFields &&
                                  _phoneVerified &&
                                  widget.config.mode ==
                                      ProfileScreenMode.create)) ...[
                            _buildAdditionalFields(),
                          ] else ...[
                            const SizedBox(height: 20),
                          ],
                        
                          // Submit Button
                          CustomSubmitButton(
                            label: widget.config.mode == ProfileScreenMode.create
                                ? isnewregister
                                      ? Translate.t("profile_info.verify")
                                      : Translate.t("profile_info.save_continue")
                                : Translate.t("profile_info.save"),
                            onPressed: _isFormValid
                                ? () async {
                                    if (!_formKey.currentState!.validate())
                                      return;
                                    if (widget.config.mode ==
                                        ProfileScreenMode.edit) {
                                      _completeProfile();
                                    } else if (_showAdditionalFields &&
                                        _phoneVerified) {
                                      await _completeProfile();
                                      context.push("/companysetup");
                                    } else if (isnewregister) {
                                      verfiynumber();
                                    }
                                  }
                                : null,
                            isLoading: _isSubmitting,
                          ),
                          const SizedBox(height: 20),
                          // Referral indicator (registration only)
                          if (widget.config.mode == ProfileScreenMode.create) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: IntrinsicWidth(
                                child: _buildReferralIndicator(secondstage),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),
                  ),
              ),
        ),
      ),
    );
  }

  /// Build AppBar
  PreferredSizeWidget _buildAppBar() {
    if (widget.config.mode == ProfileScreenMode.create) {
      return AppBar(
        leading: IconButton(
          onPressed: widget.config.mode == ProfileScreenMode.create
              ? () async {
                  final authservice = AuthService();
                  await authservice.signOut();
                  context.push("/login");
                }
              : () => context.pop(),
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        centerTitle: true,
        title: widget.config.showProgressIndicator
            ? StepProgressIndicator(
                totalSteps: 2,
                currentStep: 1,
                activeColor: AppColors.backgroundLight,
                inactiveColor: AppColors.primary,
              )
            : null,
      );
    }

    return AppBar(
      backgroundColor: AppColors.primaryDark,
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
      ),
      title: Text(
        Translate.t("profile_info.update_personal_info"),
        style: AppTextThemes.getgetLightTextTheme(context).titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Build additional fields section
  Widget _buildAdditionalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Type Selection
        Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              // Row(
              //   spacing: 12,
              //   children: [
              //     CustomLabel(
              //       Translate.t("profile_info.i_am"),
              //       isRequired: true,
              //     ),
              //     CustomCheckboxGroup<String>(
              //       selectedValues: _userTypes,
              //       items: ProfileScreenConstants.userTypeOptions,
              //       labels: [
              //         Translate.t("profile_info.buyer"),
              //         Translate.t("profile_info.merchant"),
              //       ],
              //       onChanged: (values) {
              //         setState(() {
              //           if (values.isEmpty) return;
              //           _userTypes = List.from(values);
              //           _userType =
              //               ProfileDataService.userTypeToString(
              //                 _userTypes,
              //               );
              //         });
              //         _validateForm();
              //       },
              //       direction: Axis.horizontal,
              //       spacing: 24,
              //       activeColor: AppColors.primary,
              //       inactiveColor: AppColors.disabled,
              //       borderColor: AppColors.borderLight,
              //     ),
              //   ],
              // ),
              // Row(
              //   spacing: 12,
              //   children: [
              //     CustomLabel(
              //       Translate.t("profile_info.dealing_with"),
              //       isRequired: true,
              //     ),
              //     CustomCheckboxGroup<String>(
              //       selectedValues: _dealingWiths,
              //       items:
              //           ProfileScreenConstants.dealingWithOptions,
              //       labels: const ['RCN', 'Kernel'],
              //       onChanged: (values) {
              //         setState(() {
              //           if (values.isEmpty) return;
              //           _dealingWiths = values;
              //           _dealingWith =
              //               ProfileDataService.dealingWithToString(
              //                 _dealingWiths,
              //               );
              //         });
              //         _validateForm();
              //       },
              //       direction: Axis.horizontal,
              //       spacing: 24,
              //       activeColor: AppColors.primary,
              //       inactiveColor: AppColors.disabled,
              //       borderColor: AppColors.borderLight,
              //     ),
              //   ],
              // ),
              Column(
                spacing: 12,
                children: [
                  CustomLabel(
                    Translate.t("profile_info.nature_of_business"),
                    isRequired: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 24.0),
                    child: CustomRadioGroup<String>(
                      value: _businessType,
                      items: ProfileScreenConstants.businessTypeOptions,
                      isrow: true,
                      labels: [
                        Translate.t("profile_info.processor"),
                        Translate.t("profile_info.agent"),
                        // Translate.t("profile_info.registeredagent"),
                      ],
                      onChanged: (value) => setState(() {
                        // if (value == "Agent") {
                        //   _userType = "buyer";
                        //   _userTypes =
                        //       ProfileDataService.parseUserType(
                        //         _userType,
                        //       );
                        // }
                        _businessType = value ?? 'Processor';
                      }),
                      direction: Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.start,
                      inactiveColor: AppColors.disabled,
                      spacing: 8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            spacing: 12,
            children: [
              CustomLabel(
                Translate.t("business_info.gst_registered"),
                isRequired: true,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: CustomRadioGroup<String>(
                  value: _isregister == true ? "Yes" : "No",
                  items: ProfileScreenConstants.isregistered,
                  isrow: true,
                  labels: [
                    Translate.t("profile_info.yes"),
                    Translate.t("profile_info.no"),
                  ],
                  onChanged: (value) => setState(() {
                    // if (value == "Agent") {
                    //   _userType = "buyer";
                    //   _userTypes =
                    //       ProfileDataService.parseUserType(
                    //         _userType,
                    //       );
                    // }
                    _isregister = value == "Yes" ? true : false;
                  }),
                  direction: Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  inactiveColor: AppColors.disabled,
                  spacing: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // CustomDropdownFormField<String>(
        //   value: _country,
        //   items: supportedCountries,
        //   prefixIcon: Icons.language,
        //   labels: supportedCountries,
        //   searchHint: "Search",
        //   searchable: true,
        //   label: Translate.t("profile_info.country"),
        //   onChanged: (v) => setState(() {
        //     _country = v;
        //     _validateForm();
        //   }),
        //   validator: (value) {
        //     if (value == null) {
        //       return Translate.t("business_info.country_required");
        //     }
        //     return null;
        //   },
        // ),
        // // _SearchableCountryDropdown(
        // //   value: _country,
        // //   items: supportedCountries,
        // //   label: Translate.t("profile_info.country"),
        // //   onChanged: (value) {
        // //     setState(() => _country = value);
        // //     _validateForm();
        // //   },
        // // ),
        // // const SizedBox(height: 16),
        // // CustomTextFormField(
        // //   controller: _pincodeController,
        // //   label: 'Pincode / Zipcode',
        // //   hintText: 'Enter to auto-fill state & city',
        // //   keyboardType: TextInputType.number,
        // //   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        // //   suffixIcon: _isPincodeLookingUp ? Icons.hourglass_top : Icons.search,
        // //   onChanged: (value) {
        // //     _pincodeDebounce?.cancel();
        // //     if (value.trim().length >= 4) {
        // //       _pincodeDebounce = Timer(
        // //         const Duration(milliseconds: 700),
        // //         () => _lookupPincode(value.trim()),
        // //       );
        // //     }
        // //   },
        // // ),
        // const SizedBox(height: 16),
        // CustomTextFormField(
        //   controller: _stateController,
        //   label: Translate.t("profile_info.state"),
        //   onChanged: (value) {
        //     setState(() => _hasState = value.trim().isNotEmpty);
        //     _validateForm();
        //   },
        //   validator: (value) =>
        //       FormValidationService.validateRequired(value, 'State'),
        // ),
        // const SizedBox(height: 8),
        // CustomTextFormField(
        //   controller: _cityController,
        //   label: Translate.t("profile_info.city"),
        //   onChanged: (value) {
        //     setState(() => _hasCity = value.trim().isNotEmpty);
        //     _validateForm();
        //   },
        //   validator: (value) =>
        //       FormValidationService.validateRequired(value, 'City'),
        // ),
        // const SizedBox(height: 8),
        // CustomTextFormField(
        //   controller: _addressController,
        //   label: Translate.t("profile_info.address"),
        //   maxLines: 3,
        //   onChanged: (value) {
        //     setState(() => _hasAddress = value.trim().isNotEmpty);
        //     _validateForm();
        //   },
        //   validator: (value) =>
        //       FormValidationService.validateRequired(value, 'Location'),
        // ),
        // const SizedBox(height: 16),
      ],
    );
  }
}

// ── Searchable country dropdown ──────────────────────────────────────────────
class _SearchableCountryDropdown extends StatefulWidget {
  final String? value;
  final List<String> items;
  final String label;
  final ValueChanged<String?> onChanged;

  const _SearchableCountryDropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
  });

  @override
  State<_SearchableCountryDropdown> createState() =>
      _SearchableCountryDropdownState();
}

class _SearchableCountryDropdownState
    extends State<_SearchableCountryDropdown> {
  void _showSearch() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CountrySearchSheet(
        items: widget.items,
        selected: widget.value,
        onSelect: (v) {
          widget.onChanged(v);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showSearch,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: AppTextThemes.getLightTextTheme.labelMedium?.copyWith(
            color: AppColors.primary,
          ),
          prefixIcon: Icon(Icons.language, color: AppColors.primary),
          suffixIcon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
        ),
        child: Text(
          widget.value ?? '',
          style: AppTextThemes.getLightTextTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _CountrySearchSheet extends StatefulWidget {
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _CountrySearchSheet({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_CountrySearchSheet> createState() => _CountrySearchSheetState();
}

class _CountrySearchSheetState extends State<_CountrySearchSheet> {
  final _searchController = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? widget.items
          : widget.items
                .where((e) => e.toLowerCase().contains(q.toLowerCase()))
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: _onSearch,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final item = _filtered[i];
                  final isSelected = item == widget.selected;
                  return ListTile(
                    title: Text(item),
                    trailing: isSelected
                        ? Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () => widget.onSelect(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
