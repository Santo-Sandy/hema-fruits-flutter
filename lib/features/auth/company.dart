import 'package:hema_fruits/core/providers/language_provider.dart';
import 'package:hema_fruits/core/providers/user_provider.dart';
import 'package:hema_fruits/core/repositories/settings_repository.dart';
import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/core/services/auth_service/auth_service.dart';
import 'package:hema_fruits/core/services/filter_request.dart';
import 'package:hema_fruits/core/services/translate.dart';
import 'package:hema_fruits/core/utils/Responsive/responsivea_context.dart';
import 'package:hema_fruits/core/utils/context_manager.dart';
import 'package:hema_fruits/core/utils/formatters.dart';
import 'package:hema_fruits/features/screens/creditPoint/firstReward_credit.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:hema_fruits/shared/theme/app_text_theme.dart';
import 'package:hema_fruits/shared/widgets/custom.dart';
import 'package:hema_fruits/shared/widgets/custom_input.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

enum BusinessInfoMode { create, update }

class BusinessInfoForm extends StatefulWidget {
  /// Mode determines if this is for creating new business info or updating existing
  final BusinessInfoMode mode;

  /// If mode is 'create', set showReward to true to show reward screen after save
  /// If mode is 'update', set showReward to false for simple navigation back
  final bool showReward;

  /// Optional step indicator for create mode (e.g., "Step 2 of 3")
  final int? currentStep;
  final int? totalSteps;

  const BusinessInfoForm({
    Key? key,
    this.mode = BusinessInfoMode.create,
    this.showReward = false,
    this.currentStep,
    this.totalSteps,
  }) : super(key: key);

  @override
  State<BusinessInfoForm> createState() => _BusinessInfoFormState();
}

class _BusinessInfoFormState extends State<BusinessInfoForm> {
  final _formKey = GlobalKey<FormState>();

  // Form field controllers
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _businessDescController = TextEditingController();
  final TextEditingController _countryDisplayController =
      TextEditingController();
  final TextEditingController _dialcodeDisplayController =
      TextEditingController();

  // Form state variables
  String? _registrationType;
  String? _country = 'India';
  // bool _gstRegistered = true;
  bool _isFormValid = false;
  bool _isLoading = false;
  bool iscompany = true;
  bool _ispageLoading = false;
  final String _countryCode = '+91';
  Map<String, dynamic>? userData = {};

  // Registration types
  late final List<String> _registrationTypes = [
    "Sole Proprietorship",
    "Partnership",
    "Private Limited",
    "Public Limited",
    "LLP",
    "One Person Company",
  ];

  // Countries list
  late List<String> _countries = [
    'India',
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
  ];
  late List<String> dialnumbers = ['+91', '+1', '+7', '+809', '+44'];

  @override
  void initState() {
    super.initState();

    _initializeForm();
  }

  Future<void> _initializeForm() async {
    try {
      setState(() {
        _ispageLoading = true;
      });
      await Countryfetch();
      await _loadUserData();
      if (iscompany) {
        _yearController.addListener(_validateForm);
        _companyNameController.addListener(_validateForm);
      }
      // Add listeners to update submit-button state only
      _stateController.addListener(_validateForm);
      _pincodeController.addListener(_validateForm);
      _addressController.addListener(_validateForm);
      // _phoneController.addListener(_validateForm);
    } catch (e) {
      _showErrorSnackBar('Error initializing form: ${e.toString()}');
    } finally {
      setState(() {
        _ispageLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    userData = await SecureStorageService.getUserData();
    final userId = userData?['_id'];
    iscompany = userData!['gstRegistered'] ?? true;
    _populateFormFields();
    if (userId != null && widget.mode == BusinessInfoMode.update) {
      await _loadUserCompanyData(userId);
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
          _countries = country.map((e) => "${e['flag']} ${e['name']}").toList();
          _countries.sort();
          dialnumbers = country
              .map((e) => "${e['flag']} ${e['dialCode']}")
              .toList();
          dialnumbers.sort();
        });
      } catch (e) {
        debugPrintStack();
      }
    }
  }

  Future<void> _loadUserCompanyData(String userId) async {
    try {
      FilterRequest request = FilterRequest(userId: userId);
      await context.read<ProfileProvider>().userprofilefetch(
        endpoint: "entities/filter/users",
        filterPayload: request.getuserprofile(),
      );

      final userProfileProvider = context.read<ProfileProvider>();
      final userCountry = userProfileProvider.country();
      final businessType = userProfileProvider.businessType();

      // Add fetched data to lists if not already present
      if (userCountry.isNotEmpty && !_countries.contains(userCountry)) {
        _countries.add(userCountry);
      }
      if (businessType.isNotEmpty &&
          !_registrationTypes.contains(businessType)) {
        _registrationTypes.add(businessType);
      }

      userData = await SecureStorageService.getUserProfileData();
      if (mounted) {
        setState(() => _ispageLoading = false);
        _populateFormFields();
      }
    } catch (e) {
      _showErrorSnackBar('Error loading profile: ${e.toString()}');
    }
  }

  void _populateFormFields() {
    final country = _countries.firstWhere((element) {
      final name = element.toString().toLowerCase();
      final target = (userData?['country']?.toString() ?? "India")
          .toLowerCase();
      return name.contains(target);
    });
    // final dailcode = dialnumbers.firstWhere((element) {
    //   final name = element.toString().toLowerCase();
    //   final target = (userData?['dialcodeb']?.toString() ?? "+91")
    //       .toLowerCase();
    //   return name.contains(target);
    // });
    setState(() {
      _companyNameController.text = userData?['companyName'] ?? '';
      // _emailController.text = userData?['officeEmail'] ?? '';
      _yearController.text = userData?['establishedYear'] ?? '';
      _stateController.text = userData?['state'] ?? '';
      _pincodeController.text = userData?['postalCode'] ?? '';
      _addressController.text = userData?['address'] ?? '';
      _businessDescController.text = userData?['description'] ?? '';
      _registrationType = userData?['registrationType'] == "PRIVATE_LIMITED"
          ? "Private Limited"
          : userData?['registrationType'];
      _country = country;
      _countryDisplayController.text = _country ?? 'India';
      // _gstRegistered = userData?['gstRegistered'] ?? true;
      // Only update submit-button state, never trigger field error display
      _isFormValid = _isAllFieldsValid();
    });
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _yearController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _businessDescController.dispose();
    _countryDisplayController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _isAllFieldsValid();
    });
  }

  bool _isBusinessInfoValid() {
    return _isAllFieldsValid();
  }

  bool _isAllFieldsValid() {
    final valid = iscompany
        ? (_companyNameController.text.isNotEmpty &&
              _registrationType != null &&
              _isValidYear(_yearController.text) &&
              _stateController.text.isNotEmpty &&
              _isValidPincode(_pincodeController.text) &&
              _addressController.text.isNotEmpty)
        : (_stateController.text.isNotEmpty &&
              _isValidPincode(_pincodeController.text) &&
              _addressController.text.isNotEmpty);
    return valid;
    //  &&
    // _isValidEmail(_emailController.text)
    // &&
    // _isValidPhone(_phoneController.text);
  }

  bool _isValidEmail(String email) {
    return email.isNotEmpty && RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  // bool _isValidPhone(String phone) {
  //   return phone.length == 10 && RegExp(r'^[0-9]{10}$').hasMatch(phone);
  // }

  bool _isValidYear(String year) {
    if (year.isEmpty || year.length != 4) return false;

    try {
      final yearInt = int.parse(year);
      final currentYear = DateTime.now().year;
      return yearInt >= 1900 && yearInt <= currentYear;
    } catch (e) {
      return false;
    }
  }

  bool _isValidPincode(String pincode) {
    return RegExp(r'^[0-9]{4,12}$').hasMatch(pincode);
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        "companyName": _companyNameController.text.trim(),
        "country": _country!.split(' ')[1],
        // "dialcodeb": _dialcode!.split(" ")[1],
        "description": _businessDescController.text.trim(),
        "establishedYear": _yearController.text.trim(),
        "address": _addressController.text.trim(),
        // "officeEmail": _emailController.text.trim(),
        // "officePhone": _phoneController.text.trim(),
        "postalCode": _pincodeController.text.trim(),
        "registrationType": _registrationType,
        "state": _stateController.text.trim(),
        // "gstRegistered": _gstRegistered,
        "iscompany": true,
        'isProfileComplete': true,
      };

      final userId = userData?['_id'];
      if (userId == null) {
        _showErrorSnackBar('User ID not found');
        return;
      }

      final success = await updateProfile(payload: payload, userId: userId);

      if (widget.mode == BusinessInfoMode.create &&
          userData?['referralCode'] != null) {}

      if (success) {
        _showSuccessSnackBar("Business details updated successfully!");

        if (mounted) {
          await SecureStorageService.companystatus(true);

          if ((widget.mode == BusinessInfoMode.create && widget.showReward) ||
              userData?['points'] == null) {
            int points = await rewardgetter(userId);
            _navigateToReward(points);
          } else {
            context.pop();
          }
        }
      } else {
        _showErrorSnackBar('Failed to update profile. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<int> rewardgetter(String id) async {
    await context.read<ProfileProvider>().rewardfetch(endpoint: "confirm/$id");

    final filterRequest = FilterRequest(userId: id);
    await context.read<ProfileProvider>().userprofilefetch(
      endpoint: "entities/filter/users",
      filterPayload: filterRequest.getuserprofile(),
    );
    userData = await SecureStorageService.getUserProfileData();

    return userData!['points']; // Replace with actual reward points
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

  Future<int?> showYearGridPicker(BuildContext context) async {
    final currentYear = DateTime.now().year;

    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Year'),
          content: SizedBox(
            width: 350,
            height: 200,
            child: GridView.builder(
              itemCount: 100, // Last 100 years
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2,
              ),
              itemBuilder: (context, index) {
                final year = currentYear - index;

                return InkWell(
                  onTap: () => Navigator.pop(context, year),
                  borderRadius: BorderRadius.circular(8),
                  customBorder: Border.all(color: AppColors.primary),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.beige),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      year.toString(),
                      style: AppTextThemes.getLightTextTheme.titleSmall!
                          .copyWith(),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleSaveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      await _completeProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    ContextManager().saveCurrentPage('business', context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: iscompany
          ? widget.mode == BusinessInfoMode.create
                ? AppBar(
                    backgroundColor: AppColors.primaryDark,
                    elevation: 0,
                    centerTitle: true,
                    title:
                        widget.currentStep != null && widget.totalSteps != null
                        ? StepProgressIndicator(
                            totalSteps: widget.totalSteps!,
                            currentStep: widget.currentStep!,
                            activeColor: AppColors.backgroundLight,
                            inactiveColor: AppColors.primary,
                          )
                        : null,
                  )
                : AppBar(
                    backgroundColor: AppColors.primaryDark,
                    elevation: 0,
                    leading: IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    title: Text(
                      Translate.t("business_info.update_business"),
                      style: AppTextThemes.getgetLightTextTheme(context)
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                  )
          : widget.mode == BusinessInfoMode.create
          ? AppBar(
              backgroundColor: AppColors.primaryDark,
              elevation: 0,
              centerTitle: true,
              title: widget.currentStep != null && widget.totalSteps != null
                  ? StepProgressIndicator(
                      totalSteps: widget.totalSteps!,
                      currentStep: widget.currentStep!,
                      activeColor: AppColors.backgroundLight,
                      inactiveColor: AppColors.primary,
                    )
                  : null,
            )
          : AppBar(
              backgroundColor: AppColors.primaryDark,
              elevation: 0,
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
              title: Text(
                Translate.t("business_info.update_additional"),
                style: AppTextThemes.getgetLightTextTheme(context).titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
            ),
      body:
          // _ispageLoading
          //     ? Column(
          //         mainAxisAlignment: MainAxisAlignment.center,
          //         crossAxisAlignment: CrossAxisAlignment.center,
          //         children: [
          //           Center(
          //             child: CircularProgressIndicator(color: AppColors.primary),
          //           ),
          //         ],
          //       )
          //     :
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                width: MediaQuery.sizeOf(context).width < 600 ? null : 600,
                child: Form(
                  autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // Header section (only for create mode)
                      if (iscompany) ...[
                        if (widget.mode == BusinessInfoMode.create) ...[
                          Text(
                            Translate.t("business_info.title"),
                            style: AppTextThemes.getgetLightTextTheme(context)
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          Text(
                            Translate.t("business_info.subtitle"),
                            style: AppTextThemes.getgetLightTextTheme(context)
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHint,
                                ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ] else ...[
                        if (widget.mode == BusinessInfoMode.create) ...[
                          Text(
                            Translate.t("business_info.addresstitle"),
                            style: AppTextThemes.getgetLightTextTheme(context)
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          Text(
                            Translate.t("business_info.addresssub"),
                            style: AppTextThemes.getgetLightTextTheme(context)
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHint,
                                ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
              
                      // Company Name and Established Year Row
                      if (iscompany) ...[
                        CustomTextFormField(
                          controller: _companyNameController,
                          label: Translate.t("business_info.company_name"),
                          hintText: Translate.t(
                            "business_info.company_name_hint",
                          ),
                          inputFormatters: [FirstLetterUpperCaseFormatter()],
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return Translate.t(
                                "business_info.company_name_required",
                              );
                            }
                            if (value!.length < 2) {
                              return Translate.t(
                                "business_info.company_name_min",
                              );
                            }
                            return null;
                          },
                        ),
                        // const SizedBox(height: 8),
                        // Column(
                        //   children: [
                        //     CustomTextFormField(
                        //       controller: _emailController,
                        //       label: Translate.t("business_info.office_email"),
                        //       hintText: Translate.t(
                        //         "business_info.office_email_hint",
                        //       ),
                        //       keyboardType: TextInputType.emailAddress,
                        //       validator: (value) {
                        //         if (value?.isEmpty ?? true) {
                        //           return Translate.t(
                        //             "business_info.email_required",
                        //           );
                        //         }
                        //         if (!_isValidEmail(value!)) {
                        //           return Translate.t(
                        //             "business_info.email_invalid",
                        //           );
                        //         }
                        //         return null;
                        //       },
                        //     ),
                        //   ],
                        // ),
                        const SizedBox(height: 8),
                        CustomDropdownFormField<String>(
                          value: _registrationType,
                          items: _registrationTypes,
                          prefixIcon: Icons.groups_outlined,
                          labels: _registrationTypes,
                          // searchHint: "Search",
                          // searchable: true,
                          label: Translate.t("business_info.registration_type"),
                          onChanged: (v) => setState(() {
                            _registrationType = v;
                            _validateForm();
                          }),
                          validator: (value) {
                            if (value == null) {
                              return Translate.t(
                                "business_info.registration_required",
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
              
                        // Registration Type and GST Registered Row
                        CustomTextFormField(
                          controller: _yearController,
                          label: Translate.t("business_info.est_year"),
                          suffixIcon: Icons.calendar_month_outlined,
                          onVerifyPressed: () async {
                            final year = await showYearGridPicker(context);
              
                            if (year != null) {
                              setState(() {
                                _yearController.text = year.toString();
                              });
                            }
                          },
                          hintText: Translate.t("business_info.est_year_hint"),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return Translate.t("business_info.year_required");
                            }
                            if (!_isValidYear(value!)) {
                              return Translate.t("business_info.year_invalid");
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        // Office Email
                        // const SizedBox(height: 16),
                        // CustomDropdownFormField(
                        //   value: _gstRegistered,
                        //   // prefixIcon: Icons.money,
                        //   label: Translate.t("business_info.gst_registered"),
                        //   items: [true, false],
                        //   labels: ["Yes", "No"],
              
                        //   onChanged: (value) {
                        //     setState(() => _gstRegistered = value!);
                        //   },
                        // ),
                        // // Office Email
                        // const SizedBox(height: 16),
              
                        // Phone Number
                        // Row(
                        //   children: [
                        //     Column(
                        //       children: [
                        //         IntrinsicWidth(
                        //           child: CustomDropdownFormField<String>(
                        //             value: _dialcode,
                        //             items: dialnumbers,
                        //             // prefixIcon: Icons.language,
                        //             labels: dialnumbers,
                        //             label: Translate.t(
                        //               "business_info.dialcode",
                        //             ),
                        //             onChanged: (v) => setState(() {
                        //               _dialcode = v;
                        //               _validateForm();
                        //             }),
                        //             validator: (value) {
                        //               if (value == null) {
                        //                 return Translate.t(
                        //                   "business_info.country_required",
                        //                 );
                        //               }
                        //               return null;
                        //             },
                        //           ),
                        //         ),
                        //         const SizedBox(height: 20),
                        //       ],
                        //     ),
                        //     // SizedBox(
                        //     //   width: 70,
                        //     //   child: Center(
                        //     //     child: TextFormField(
                        //     //       readOnly: true,
                        //     //       initialValue: _countryCode,
                        //     //       decoration: _buildInputDecoration(
                        //     //         context,
                        //     //         prefixIcon: const Padding(
                        //     //           padding: EdgeInsets.all(8.0),
                        //     //           child: Text('🇮🇳 +91'),
                        //     //         ),
                        //     //       ),
                        //     //     ),
                        //     //   ),
                        //     // ),
                        //     const SizedBox(width: 8),
                        //     Expanded(
                        //       child: CustomTextFormField(
                        //         controller: _phoneController,
                        //         label: Translate.t("business_info.mobile"),
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
                        // const SizedBox(height: 16),
                      ],
                      CustomDropdownFormField<String>(
                        value: _country,
                        items: _countries,
                        prefixIcon: Icons.language,
                        labels: _countries,
                        searchHint: "Search",
                        searchable: true,
                        label: Translate.t("business_info.country"),
                        onChanged: (v) => setState(() {
                          _country = v;
                          _validateForm();
                        }),
                        validator: (value) {
                          if (value == null) {
                            return Translate.t(
                              "business_info.country_required",
                            );
                          }
                          return null;
                        },
                      ),
              
                      // Country
                      // CustomTextFormField(
                      //   controller: _countryDisplayController,
                      //   label: 'Country',
                      //   hintText: " Select a country",
                      //   readonly: true,
                      //   suffixIcon: Icons.language,
                      //   validator: (value) {
                      //     if (value?.isEmpty ?? true) {
                      //       return 'Country is required';
                      //     }
                      //     return null;
                      //   },
                      //   onTap: _showCountryPicker,
                      // ),
                      const SizedBox(height: 16),
              
                      // State and Pincode Row
                      CustomTextFormField(
                        controller: _stateController,
                        label: Translate.t("business_info.state"),
                        hintText: Translate.t("business_info.state_hint"),
                        inputFormatters: [FirstLetterUpperCaseFormatter()],
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return Translate.t("business_info.state_required");
                          }
                          if (value!.length < 2) {
                            return Translate.t("business_info.state_min");
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomTextFormField(
                        controller: _pincodeController,
                        label: Translate.t("business_info.pincode"),
                        hintText: '000000',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return Translate.t(
                              "business_info.pincode_required",
                            );
                          }
                          if (value.length < 4) {
                            return Translate.t("business_info.pincode_min");
                          }
                          if (value.length > 12) {
                            return Translate.t("business_info.pincode_max");
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
              
                      // Address
                      CustomTextFormField(
                        controller: _addressController,
                        label: Translate.t("business_info.address"),
                        hintText: Translate.t("business_info.address_hint"),
                        maxLines: 4,
                        inputFormatters: [FirstLetterUpperCaseFormatter()],
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return Translate.t(
                              "business_info.address_required",
                            );
                          }
                          if (value!.length < 5) {
                            return Translate.t("business_info.address_invalid");
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
              
                      // Business Description
                      CustomTextFormField(
                        height: 150,
                        minLines: 5,
                        controller: _businessDescController,
                        label: Translate.t("business_info.business_desc"),
                        hintText: Translate.t(
                          "business_info.business_desc_hint",
                        ),
                        maxLines: 6,
                      ),
                      const SizedBox(height: 24),
              
                      // Save & Continue Button
                      CustomSubmitButton(
                        label: _isLoading
                            ? Translate.t("business_info.saving")
                            : Translate.t("business_info.save_continue"),
                        onPressed: (_isLoading || !_isFormValid)
                            ? null
                            : () {
                                _handleSaveAndContinue();
                              },
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  InputDecoration _buildInputDecoration(
    BuildContext context, {
    String? hintText,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppColors.textHint,
        fontSize: context.fontSizeBase,
      ),
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
