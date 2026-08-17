import 'package:hema_fruits/core/providers/user_provider.dart';
import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/core/services/filter_request.dart';
import 'package:hema_fruits/core/services/translate.dart';
import 'package:hema_fruits/core/utils/Responsive/app_spacing.dart';
import 'package:hema_fruits/core/utils/Responsive/app_typography.dart';
import 'package:hema_fruits/core/utils/context_manager.dart';
import 'package:hema_fruits/core/utils/uri_launcher.dart';
import 'package:hema_fruits/features/layouts/profile_percent.dart';
import 'package:hema_fruits/features/layouts/skeleton_loader.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:hema_fruits/shared/theme/app_text_theme.dart';
import 'package:hema_fruits/shared/widgets/custom.dart';
import 'package:hema_fruits/shared/widgets/custom_input.dart';
import 'package:hema_fruits/shared/widgets/view_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/widgets.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreen();
}

class _AccountScreen extends State<AccountScreen> {
  Map<String, dynamic> userData = {};
  double percent = 0;
  String path = RoutePath.personalInfo;
  String currentRole = "buyer";
  bool _isProfileDataCached = false;

  @override
  void initState() {
    super.initState();
    getuserprofile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh if data not cached
    if (!_isProfileDataCached) {
      getuserprofile();
    }
  }

  Future<void> getProfilePercentage() async {
    final String nature = (userData['natureOfBusiness'] ?? '').toString();
    final bool isAgent = nature.toLowerCase() == 'agent';

    // These are the best signals available in current app storage.
    final dynamic country = userData['natureOfBusiness'];
    final bool hasCountry =
        country != null && country.toString().trim().isNotEmpty;

    final bool isProfileComplete =
        (userData['natureOfBusiness'] == '' ||
            userData['natureOfBusiness'] == null) ==
        false;
    final bool isCompanyComplete =
        (userData['companyName'] == '' || userData['companyName'] == null) ==
        false;
    path = RoutePath.personalInfo;

    // Start from initial.
    percent = isAgent ? 50 : 25;

    // Address + country contributes toward second step only for non-agent.
    // If agent, request says completion becomes 100%.
    if (isAgent) {
      if (isProfileComplete) {
        percent = 100;
      } else {
        percent = 50;
      }
    } else {
      // Second step (address + country) -> reach 50%
      if (hasCountry) {
        percent = 50;
        path = RoutePath.businessInfo;
      }

      // Business profile completes -> 100%
      // For non-agent: when profile/company complete.
      if (isProfileComplete && isCompanyComplete) {
        percent = 100;
      }
    }

    setState(() {
      percent = percent.clamp(0, 100);
    });
  }

  Future<void> getuserprofile({bool forceRefresh = false}) async {
    try {
      // Skip if already cached and not forcing refresh
      if (_isProfileDataCached && !forceRefresh) {
        return;
      }

      final profileProvider = context.read<ProfileProvider>();
      userData = await SecureStorageService.getUserData();
      final userId = userData['_id'];
      FilterRequest request = FilterRequest(userId: userId);
      profileProvider.userprofilefetch(
        endpoint: "entities/filter/users",
        filterPayload: request.getuserprofile(),
      );
      // await getUser(userId);
      userData = await SecureStorageService.getUserProfileData();
      await getProfilePercentage();

      if (mounted) {
        setState(() {
          _isProfileDataCached = true;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    ContextManager().saveCurrentPage('profileScreen', context);
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        userData = provider.userprofile;
        return RefreshIndicator(
          onRefresh: () => getuserprofile(forceRefresh: true),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                userData.isNotEmpty
                    ? Container(
                        margin: EdgeInsets.all(10),
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(10, 20, 8, 0),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Avatar ──
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    ProfilePercent(
                                      percent: percent,
                                      userData: userData,
                                    ),
                                    const SizedBox(width: 14),

                                    // ── Name ──
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  userData['name']
                                                          ?.toString() ??
                                                      "User",
                                                  style: AppTextThemes
                                                      .getLightTextTheme
                                                      .titleLarge
                                                      ?.copyWith(
                                                        color: AppColors
                                                            .background,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        letterSpacing: 0.2,
                                                      ),
                                                ),

                                                const SizedBox(height: 8),

                                                // ── Role chip ──
                                                Row(
                                                  children: [
                                                    AppChip(
                                                      label:
                                                          userData['natureOfBusiness'],
                                                      color:
                                                          AppColors.background,
                                                    ),
                                                    // Divider(
                                                    //   height: 30,
                                                    //   thickness: 10,
                                                    //   indent: 10,
                                                    //   color:
                                                    //       AppColors.background,
                                                    // ),
                                                    // AppChip(
                                                    //   label:
                                                    //       userData['role'] ==
                                                    //           "both"
                                                    //       ? "Buyer & Merchant"
                                                    //       : (userData['role'] ==
                                                    //                 "processor"
                                                    //             ? "Merchant"
                                                    //             : "Buyer"),
                                                    //   color:
                                                    //       AppColors.background,
                                                    // ),
                                                  ],
                                                ),
                                                // const SizedBox(height: 8),
                                                // Row(
                                                //   children: [
                                                //     Icon(
                                                //       Icons.phone,
                                                //       size: 18,
                                                //       color: AppColors.background,
                                                //     ),
                                                //     const SizedBox(width: 8),
                                                //     Text(
                                                //       userData['phone'].split(' ')[0],
                                                //       style: AppTextThemes
                                                //           .getLightTextTheme
                                                //           .titleSmall
                                                //           ?.copyWith(
                                                //             color: AppColors.background,
                                                //             fontWeight: FontWeight.w700,
                                                //             letterSpacing: 0.2,
                                                //           ),
                                                //     ),
                                                //   ],
                                                // ),
                                                // Row(
                                                //   children: [
                                                //     Icon(
                                                //       Icons.email,
                                                //       size: 18,
                                                //       color: AppColors.background,
                                                //     ),
                                                //     const SizedBox(width: 8),
                                                //     Text(
                                                //       userData['email'].split(' ')[0],
                                                //       style: AppTextThemes
                                                //           .getLightTextTheme
                                                //           .titleSmall
                                                //           ?.copyWith(
                                                //             color: AppColors.background,
                                                //             fontWeight: FontWeight.w700,
                                                //             letterSpacing: 0.2,
                                                //           ),
                                                //     ),
                                                //   ],
                                                // ),

                                                // const SizedBox(height: 8),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              context
                                                  .pushNamed(
                                                    RouteName.personalInfo,
                                                  )
                                                  .then((_) {
                                                    getuserprofile(
                                                      forceRefresh: true,
                                                    );
                                                  });
                                            },
                                            icon: Icon(
                                              Icons.edit_square,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),
                                // ── Credit Balance Card ──
                                CreditBalanceCard(
                                  creditBalance: int.parse(
                                    '${userData['points'] ?? 0}',
                                  ),
                                  onAddCredits: () {
                                    if (MediaQuery.sizeOf(context).width >
                                        600) {
                                      context.pop();
                                    }
                                    // LoadingDialogHelper.showLoadingDialog(
                                    //   context,
                                    //   message: Translate.t("loading.loading"),
                                    // );
                                    context.push(RoutePath.creditpayment).then((
                                      _,
                                    ) {
                                      getuserprofile(forceRefresh: true);
                                    });
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ],
                        ),
                      )
                    : ProfileHeaderSkeleton(),
                // SectionHeaderCard(
                //   title: "Personal Info",
                //   borderradius: 0,
                //   titlecolor: AppColors.accent,
                //   subtitle: "Manage your personal account details",
                //   icon: Icons.person_rounded,
                // ),
                PersonalDetailsCard(user: userData),
                // const SizedBox(height: 16),
                if (userData['natureOfBusiness'] != 'Agent' &&
                    userData['companyName'] != null) ...[
                  // SectionHeaderCard(
                  //   title: "Company Details",
                  //   borderradius: 0,
                  //   titlecolor: AppColors.accent,
                  //   subtitle: "View your company information",
                  //   icon: Icons.business_rounded,
                  // ),
                  CompanyDetailsCard(
                    company: userData,
                    ontaps: () {
                      context.pushNamed(RouteName.businessInfo).then((_) {
                        getuserprofile(forceRefresh: true);
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class CompanyDetailsCard extends StatefulWidget {
  final Map<String, dynamic> company;
  final bool nolabel;
  final bool dropdown;
  final VoidCallback? ontap;
  final VoidCallback? ontaps;

  const CompanyDetailsCard({
    super.key,
    required this.company,
    this.nolabel = false,
    this.ontap,
    this.ontaps,
    this.dropdown = false,
  });

  @override
  State<CompanyDetailsCard> createState() => _CompanyDetailsCardState();
}

class _CompanyDetailsCardState extends State<CompanyDetailsCard> {
  bool get isGstRegistered => widget.company["gstRegistered"] == true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        // borderRadius: BorderRadius.circular(28),
        // border: Border.all(
        //   color: isDark ? AppColors.borderDark : AppColors.borderLight,
        // ),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowDark : AppColors.shadowLight,
            blurRadius: 24,
            // offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // if (!widget.nolabel) ...[
          //   const SizedBox(height: 20),
          //   Container(
          //     margin: EdgeInsets.all(20).copyWith(top: 2, bottom: 2),
          //     decoration: BoxDecoration(
          //       color: AppColors.background,
          //       border: Border.all(color: AppColors.borderLight),
          //       borderRadius: BorderRadius.circular(12),
          //     ),
          //     padding: const EdgeInsets.all(8.0),
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         Icon(
          //           Icons.business_rounded,
          //           size: 24,
          //           fontWeight: FontWeight.w800,
          //         ),
          //         const SizedBox(width: 10),
          //         Text(
          //           Translate.t("profile.companydetails"),
          //           style: AppTextThemes.getLightTextTheme.titleLarge!.copyWith(
          //             fontWeight: FontWeight.bold,
          //             color: AppColors.textPrimary,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          //   const SizedBox(height: 20),
          // ],
          // HEADER
          GestureDetector(
            onTap: widget.ontap,
            child: Container(
              padding: EdgeInsets.all(
                AppSpacing.lg,
              ).copyWith(left: AppSpacing.xl, right: AppSpacing.xl),
              decoration: BoxDecoration(
                color: isDark ? AppColors.appheader : AppColors.appheader,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.company["companyName"] ?? "Company",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  AppTypography.responsive(
                                    context,
                                    baseSize: 20,
                                    tabletSize: 22,
                                    desktopSize: 24,
                                  ).copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white.withOpacity(0.85),
                                  size: 18,
                                ),
                                SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    "${widget.company["state"] ?? ""}, ${widget.company["country"] ?? ""}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        AppTypography.responsive(
                                          context,
                                          baseSize: 14,
                                          tabletSize: 15,
                                          desktopSize: 16,
                                        ).copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      widget.ontap != null
                          ? !widget.dropdown
                                ? Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 40,
                                  )
                                : Icon(
                                    Icons.arrow_right,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 40,
                                  )
                          : widget.dropdown
                          ? SizedBox()
                          : InkWell(
                              onTap: widget.ontaps,
                              child: Icon(
                                Icons.edit_square,
                                color: Colors.white.withOpacity(0.9),
                                size: 24,
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // BODY
          // widget.dropdown
          //     ? const SizedBox()
          //     :
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _infoTile(
                  icon: Icons.badge_rounded,
                  title: Translate.t("profile.resgtype"),
                  value:
                      (widget.company["registrationType"] == "PRIVATE_LIMITED"
                          ? "Private Limited"
                          : widget.company["registrationType"]) ??
                      "N/A",
                  isDark: isDark,
                ),
                _infoTile(
                  icon: Icons.calendar_today_rounded,
                  title: Translate.t("profile.est"),
                  value: widget.company["establishedYear"] ?? "N/A",
                  isDark: isDark,
                ),

                // _infoTile(
                //   icon: Icons.phone_rounded,
                //   title: Translate.t("profile.phone"),
                //   value: company["officePhone"] ?? "N/A",
                //   isDark: isDark,
                // ),
                // GestureDetector(
                //   onTap: widget.ontap != null
                //       ? () => ExternalLauncher.email(
                //           widget.company["officeEmail"] ?? " ",
                //         )
                //       : null,
                //   child: _infoTile(
                //     icon: Icons.email_rounded,
                //     title: Translate.t("profile.email"),
                //     value: widget.company["officeEmail"] ?? "N/A",
                //     isDark: isDark,
                //   ),
                // ),
                _infoTile(
                  icon: Icons.receipt_long_rounded,
                  title: Translate.t("profile.gstregister"),
                  value: isGstRegistered ? "Registered" : "Not Registered",
                  valueColor: isGstRegistered
                      ? AppColors.secondary
                      : AppColors.error,
                  isDark: isDark,
                ),

                // _infoTile(
                //   icon: Icons.location_city_rounded,
                //   title: Translate.t("profile.officeaddress"),
                //   value:
                //       "${widget.company["officeAddress"] ?? ""}, ${widget.company["postalCode"] ?? ""}",
                //   isDark: isDark,
                // ),
                _infoTile(
                  icon: Icons.description_rounded,
                  isexpanded: true,
                  title: Translate.t("profile.description"),
                  value:
                      widget.company["description"] ??
                      "No description available",
                  isDark: isDark,
                ),
                // DESCRIPTION BOX

                // const SizedBox(height: 20),
                // Container(
                //   width: double.infinity,
                //   padding: const EdgeInsets.all(18),
                //   decoration: BoxDecoration(
                //     color: isDark
                //         ? AppColors.surfaceContainerDark
                //         : AppColors.surfaceContainerLight,
                //     borderRadius: BorderRadius.circular(20),
                //     border: Border.all(
                //       color: isDark
                //           ? AppColors.borderDark
                //           : AppColors.borderLight,
                //     ),
                //   ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Row(
                //         children: [
                //           Icon(
                //             Icons.description_rounded,
                //             color: AppColors.primary,
                //             size: 20,
                //           ),
                //           const SizedBox(width: 8),
                //           Text(
                //             Translate.t("profile.description"),
                //             style: TextStyle(
                //               fontSize: 16,
                //               fontWeight: FontWeight.w700,
                //               color: isDark
                //                   ? AppColors.textPrimaryDark
                //                   : AppColors.textPrimaryLight,
                //             ),
                //           ),
                //         ],
                //       ),

                //       const SizedBox(height: 14),

                //       ExpandableText(
                //         text:
                //             widget.company["description"] ??
                //             "No description available",
                //         style: TextStyle(
                //           height: 1.6,
                //           fontSize: 14,
                //           color: isDark
                //               ? AppColors.textSecondaryDark
                //               : AppColors.textSecondaryLight,
                //         ),
                //       ),

                //       // Text(
                //       //   company["description"] ?? "No description available",
                //       //   style: TextStyle(
                //       //     height: 1.6,
                //       //     fontSize: 14,
                //       //     color: isDark
                //       //         ? AppColors.textSecondaryDark
                //       //         : AppColors.textSecondaryLight,
                //       //   ),
                //       // ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    bool isexpanded = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              // color: isDark
              //     ? AppColors.surfaceContainerDark
              //     : AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),

                isexpanded
                    ? ExpandableText(
                        text: value,
                        size: 13,
                        isonlytext: true,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color:
                              valueColor ??
                              (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight),
                        ),
                      )
                    : Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color:
                              valueColor ??
                              (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PersonalDetailsCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isotheruser;

  const PersonalDetailsCard({
    super.key,
    required this.user,
    this.isotheruser = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool isCompleted = user["isProfileComplete"] == true;

    final String image = user["profilePicture"]?.toString() ?? "";

    return Container(
      // margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        // borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowDark : AppColors.shadowLight,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // BODY
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                GestureDetector(
                  onTap: isotheruser
                      ? () => ExternalLauncher.email(user["mail"] ?? "")
                      : null,
                  child: _infoTile(
                    icon: Icons.email_rounded,
                    title: Translate.t("profile.email"),
                    value: user["mail"] ?? "N/A",
                    // valueColor: isotheruser ? AppColors.primary : null,
                    isDark: isDark,
                  ),
                ),

                GestureDetector(
                  onTap: isotheruser
                      ? () => ExternalLauncher.call(user["phone"] ?? "")
                      : null,
                  child: _infoTile(
                    icon: Icons.phone_rounded,
                    title: Translate.t("profile.phone"),
                    // valueColor: isotheruser ? AppColors.primary : null,
                    value: user["phone"] ?? "N/A",
                    isDark: isDark,
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: _infoTile(
                        icon: Icons.location_on_rounded,
                        title: Translate.t("profile.address"),
                        value: user["address"] ?? "N/A",
                        isDark: isDark,
                      ),
                    ),
                    // Expanded(
                    //   child: _infoTile(
                    //     icon: Icons.location_city_rounded,
                    //     title: Translate.t("profile.city"),
                    //     value: user["city"] ?? "N/A",
                    //     isDark: isDark,
                    //   ),
                    // ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: _infoTile(
                        icon: Icons.map_rounded,
                        title: Translate.t("profile.state"),
                        value: user["state"] ?? "N/A",
                        isDark: isDark,
                      ),
                    ),

                    Expanded(
                      child: _infoTile(
                        icon: Icons.public_rounded,
                        title: Translate.t("profile.country"),
                        value: user["country"] ?? "N/A",
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                // const SizedBox(height: 5),

                // ADDRESS BOX
                // Container(
                //   width: double.infinity,
                //   padding: const EdgeInsets.all(18),
                //   decoration: BoxDecoration(
                //     color: isDark
                //         ? AppColors.surfaceContainerDark
                //         : AppColors.surfaceContainerLight,
                //     borderRadius: BorderRadius.circular(20),
                //     border: Border.all(
                //       color: isDark
                //           ? AppColors.borderDark
                //           : AppColors.borderLight,
                //     ),
                //   ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Row(
                //         children: [
                //           Icon(
                //             Icons.location_on_rounded,
                //             color: AppColors.primary,
                //             size: 20,
                //           ),
                //           const SizedBox(width: 8),
                //           Text(
                //             Translate.t("profile.address"),
                //             style: TextStyle(
                //               fontSize: 16,
                //               fontWeight: FontWeight.w700,
                //               color: isDark
                //                   ? AppColors.textPrimaryDark
                //                   : AppColors.textPrimaryLight,
                //             ),
                //           ),
                //         ],
                //       ),

                //       const SizedBox(height: 14),

                //       Text(
                //         user["address"] ?? "No address available",
                //         style: TextStyle(
                //           height: 1.6,
                //           fontSize: 14,
                //           color: isDark
                //               ? AppColors.textSecondaryDark
                //               : AppColors.textSecondaryLight,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              // color: isDark
              //     ? AppColors.surfaceContainerDark
              //     : AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),

                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color:
                        valueColor ??
                        (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
