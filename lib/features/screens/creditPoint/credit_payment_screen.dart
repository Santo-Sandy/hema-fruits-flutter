import 'package:cashew_marketplace/core/providers/user_provider.dart';
import 'package:cashew_marketplace/core/services/auth_service/auth_service.dart';
import 'package:cashew_marketplace/core/services/feature_services.dart';
import 'package:cashew_marketplace/core/services/filter_request.dart';
import 'package:cashew_marketplace/core/services/paymentService/cashfree_service.dart';
import 'package:cashew_marketplace/core/services/translate.dart';
import 'package:cashew_marketplace/core/utils/context_manager.dart';
import 'package:cashew_marketplace/core/utils/formatters.dart';
import 'package:cashew_marketplace/shared/widgets/custom.dart';
import 'payment_success_splash.dart';
import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';
import 'package:cashew_marketplace/shared/widgets/custom_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CreditRechargePage extends StatefulWidget {
  final int currentBalance;
  final VoidCallback? onPaymentSuccess;

  const CreditRechargePage({
    super.key,
    this.currentBalance = 12000,
    this.onPaymentSuccess,
  });

  @override
  State<CreditRechargePage> createState() => _CreditRechargePageState();
}

class _CreditRechargePageState extends State<CreditRechargePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  double get _pointsPerRupee {
    final money = (settings['MoneyRatio'] ?? 1).toDouble();
    final points = (settings['PointRatio'] ?? 0).toDouble();
    if (money == 0) return 0;
    return points / money;
  }

  static const List<int> _quickAmounts = [50, 100, 250, 500];

  double _rupees = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Map<String, dynamic> user = {};
  Map<String, dynamic> settings = {};
  Map<String, dynamic> userData = {};
  int currentBalance = 0;
  bool isloading = false;
  int selectedAmount = 0;
  String pricevalue = '';
  int rupees = 0;
  String userId = "";
  String currency = "₹";
  double _lastPaidAmount = 0;
  int _lastPointsEarned = 0;

  late final CashfreeService cashfree;
  final ApiDioPostService api = ApiDioPostService();
  final ApiDioGetService apis = ApiDioGetService();

  @override
  void initState() {
    super.initState();
    getuserprofile();
    cashfree = CashfreeService();
    cashfree.init(onSuccess: _onPaymentSuccess, onError: _onPaymentError);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(() => setState(() {}));
  }

  Future<void> _onPaymentSuccess(String orderId) async {
    try {
      final res = await apis.getdata(endpoint: "payments/verify/$orderId");
      if (res['status'] == 200) {
        if (mounted) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  PaymentSuccessSplashScreen(
                    amount: _lastPaidAmount,
                    points: _lastPointsEarned,
                    currency: currency,
                  ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          ).then((_) {
            getuserprofile();
            if (mounted) {
              context.pop();
            }
          });
        }
      }
    } catch (e) {
      debugPrintStack();
    }

    // Verify with backend here
  }

  void _onPaymentError(CFErrorResponse error, String orderId) {
    debugPrint("Payment Failed: ${error.getMessage()}");
  }

  Future<void> getuserprofile() async {
    userData = await SecureStorageService.getUserData();
    final userId = userData['_id'];
    FilterRequest request = FilterRequest(userId: userId);
    final setting = await context.read<Settingsprovider>().settingsfetch(
      endpoint: "entities/filter/settings",
      filterPayload: {},
    );
    setState(() {
      settings = setting;
      pricevalue =
          '$currency ${Formatters.formatTomoney(settings['MoneyRatio'])} = ${Formatters.formatTomoney(settings['PointRatio'])} Pts';
    });
    context.read<ProfileProvider>().userprofilefetch(
      endpoint: "entities/filter/users",
      filterPayload: request.getuserprofile(),
    );
    await getUser(userId);
    userData = await SecureStorageService.getUserProfileData();
    setState(() {
      user = userData;
      currentBalance = user['points'] ?? 0;
    });
  }

  void _onTextChanged() {
    final val = double.tryParse(_controller.text.replaceAll(',', '')) ?? 0;
    if (val != _rupees) {
      setState(() => _rupees = val);
      if (val > 0) {
        _pulseController.forward().then((_) => _pulseController.reverse());
      }
    }
  }

  void _applyQuick(int amount) {
    final current = int.tryParse(_controller.text.replaceAll(',', '')) ?? 0;
    if (current < 99999999) {
      _controller.text = Formatters.formatTomoney(
        (current + amount).toString(),
      );
    }
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  // Points = rupees × 2
  // {settings['MoneyRatio']} = ${settings['PointRatio']}
  // (newAmount / plan.MoneyRatio) * plan.PointRatio)
  int get _pointsEarned {
    final moneyRatio = (settings['MoneyRatio'] ?? 0).toDouble();
    final pointRatio = (settings['PointRatio'] ?? 0).toDouble();
    if (moneyRatio <= 0) return 0;
    return ((_rupees / moneyRatio) * pointRatio).floor();
  }

  bool get _canProceed {
    final minAmount = (settings['MoneyRatio'] ?? 0).toDouble();
    return _rupees >= minAmount && _rupees > 0;
  }

  String _formatNumber(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  String _formatRupee(double v) =>
      '$currency ${v.toStringAsFixed(v % 1 == 0 ? 0 : 2)}';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ContextManager().saveCurrentPage('CreditRecharge', context);
    final tt = AppTextThemes.getgetLightTextTheme(context);
    final phone = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          Translate.t("creditScreen.title"),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // ── Green header band ──────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  decoration: BoxDecoration(
                    // gradient: LinearGradient(
                    //   colors: [
                    //     AppColors.primaryDark,
                    //     AppColors.primary,
                    //     AppColors.primaryLight,
                    //   ],
                    //   begin: Alignment.topLeft,
                    //   end: Alignment.bottomRight,
                    //   stops: [0.0, 0.5, 1.0],
                    // ),
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Current balance pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.toll_rounded,
                              color: AppColors.accent,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${Translate.t("creditScreen.current_points")} : ${_formatNumber(currentBalance)} Pts',
                              style: AppTextThemes.getgetLightTextTheme(context)
                                  .bodyLarge!
                                  .copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter',
                                  ),
                            ),
                          ],
                        ),
                      ),

                      // const SizedBox(height: 20),
                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //     horizontal: 14,
                      //     vertical: 10,
                      //   ),
                      //   decoration: BoxDecoration(
                      //     color: Colors.white,
                      //     borderRadius: BorderRadius.circular(14),
                      //     border: Border.all(color: AppColors.borderLight),
                      //     boxShadow: [
                      //       BoxShadow(
                      //         color: Colors.black.withValues(alpha: 0.03),
                      //         blurRadius: 6,
                      //         offset: const Offset(0, 2),
                      //       ),
                      //     ],
                      //   ),
                      //   child: Column(
                      //     mainAxisSize: MainAxisSize.min,
                      //     children: [
                      //       Text(
                      //         pricevalue,
                      //         maxLines: 1,
                      //         overflow: TextOverflow.ellipsis,
                      //         style: AppTextThemes.getgetLightTextTheme(context)
                      //             .titleMedium
                      //             ?.copyWith(
                      //               fontFamily: 'Inter',
                      //               color: AppColors.primary,
                      //               fontWeight: FontWeight.w800,
                      //               letterSpacing: 0.2,
                      //             ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      // const SizedBox(height: 10),
                      // ── Live summary card ──
                      // AnimatedBuilder(
                      //   animation: _pulseAnimation,
                      //   builder: (context, child) => Transform.scale(
                      //     scale: _pulseAnimation.value,
                      //     child: child,
                      //   ),
                      //   child: Row(
                      //     children: [
                      //       Expanded(
                      //         child: Container(
                      //           width: phone ? double.infinity : 600,
                      //           padding: const EdgeInsets.symmetric(
                      //             horizontal: 20,
                      //             vertical: 16,
                      //           ),
                      //           decoration: BoxDecoration(
                      //             color: AppColors.primary,
                      //             borderRadius: BorderRadius.circular(16),
                      //             border: Border.all(
                      //               color: AppColors.border,
                      //               width: 1,
                      //             ),
                      //           ),
                      //           child: Row(
                      //             mainAxisAlignment:
                      //                 MainAxisAlignment.spaceAround,
                      //             children: [
                      //               _PriceStat(
                      //                 label: Translate.t("creditScreen.you_pay"),
                      //                 value: _rupees > 0
                      //                     ? '$currency ${Formatters.formatTomoney(_rupees)}'
                      //                     : '$currency  0',
                      //                 icon: Icons.payments_rounded,
                      //               ),
                      //               // Container(
                      //               //   width: 1,
                      //               //   height: 40,
                      //               //   color: Colors.white.withValues(alpha: 0.3),
                      //               // ),
                      //               // _PriceStat(
                      //               //   label: Translate.t("creditScreen.you_get"),
                      //               //   value: _pointsEarned > 0
                      //               //       ? '${_formatNumber(_pointsEarned)} pts'
                      //               //       : '0 pts',
                      //               //   icon: Icons.stars_rounded,
                      //               // ),
                      //               // Container(
                      //               //   width: 1,
                      //               //   height: 40,
                      //               //   color: Colors.white.withValues(alpha: 0.3),
                      //               // ),
                      //               // _PriceStat(
                      //               //   label: Translate.t("creditScreen.rate"),
                      //               //   value: pricevalue,
                      //               //   icon: Icons.swap_horiz_rounded,
                      //               // ),
                      //             ],
                      //           ),
                      //         ),
                      //       ),
                      //       const SizedBox(width: 8),
                      //       Icon(
                      //         Icons.arrow_forward,
                      //         fontWeight: FontWeight.bold,
                      //         color: AppColors.primary,
                      //       ),
                      //       const SizedBox(width: 8),
                      //       Expanded(
                      //         child: Container(
                      //           width: phone ? double.infinity : 600,
                      //           padding: const EdgeInsets.symmetric(
                      //             horizontal: 20,
                      //             vertical: 16,
                      //           ),
                      //           decoration: BoxDecoration(
                      //             color: AppColors.primary,
                      //             borderRadius: BorderRadius.circular(16),
                      //             border: Border.all(
                      //               color: AppColors.border,
                      //               width: 1,
                      //             ),
                      //           ),
                      //           child: Row(
                      //             mainAxisAlignment:
                      //                 MainAxisAlignment.spaceAround,
                      //             children: [
                      //               // _PriceStat(
                      //               //   label: Translate.t("creditScreen.you_pay"),
                      //               //   value: _rupees > 0
                      //               //       ? '$currency ${Formatters.formatTomoney(_rupees)}'
                      //               //       : '$currency  0',
                      //               //   icon: Icons.payments_rounded,
                      //               // ),
                      //               // Container(
                      //               //   width: 1,
                      //               //   height: 40,
                      //               //   color: Colors.white.withValues(alpha: 0.3),
                      //               // ),
                      //               _PriceStat(
                      //                 label: Translate.t("creditScreen.you_get"),
                      //                 value: _pointsEarned > 0
                      //                     ? '${_formatNumber(_pointsEarned)} pts'
                      //                     : '0 pts',
                      //                 icon: Icons.stars_rounded,
                      //               ),
                      //               // Container(
                      //               //   width: 1,
                      //               //   height: 40,
                      //               //   color: Colors.white.withValues(alpha: 0.3),
                      //               // ),
                      //               // _PriceStat(
                      //               //   label: Translate.t("creditScreen.rate"),
                      //               //   value: pricevalue,
                      //               //   icon: Icons.swap_horiz_rounded,
                      //               // ),
                      //             ],
                      //           ),
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                ),

                // ── Scrollable body ───────────────────────────────
                Expanded(
                  child: Container(
                    width: phone ? null : 600,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Label ──
                        Text(
                          Translate.t("creditScreen.enter_amount"),
                          style: tt.titleSmall?.copyWith(
                            color: AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Translate.t("creditScreen.minimum_info")
                              .replaceAll(
                                "{{min}}",
                                "$currency ${Formatters.formatTomoney(settings['MoneyRatio']) ?? 0}",
                              )
                              .replaceAll(
                                "{{points}}",
                                "${Formatters.formatTomoney(settings['PointRatio']) ?? 0}",
                              ),
                          style: tt.bodySmall?.copyWith(
                            color: AppColors.textTertiaryLight,
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          autofocus: true,
                          controller: _controller,
                          focusNode: _focusNode,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            CommaInputFormatter(),
                            MaxValueInputFormatter(999999),
                          ],
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            prefix: Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: _focusNode.hasFocus ? 26 : 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                                child: Text('$currency '),
                              ),
                            ),
                            hintText: '0',
                            hintStyle: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              color: AppColors.textHintLight,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                            ),
                          ),
                          onTap: () => setState(() {}),
                          onChanged: (_) => setState(() {}),
                        ),

                        // ── Live points preview ──
                        // AnimatedSwitcher(
                        //   duration: const Duration(milliseconds: 200),
                        //   child: _rupees >= 50
                        //       ? Padding(
                        //           key: ValueKey(_pointsEarned),
                        //           padding: const EdgeInsets.only(top: 10),
                        //           child: Row(
                        //             mainAxisAlignment: MainAxisAlignment.center,
                        //             children: [
                        //               const Icon(
                        //                 Icons.stars_rounded,
                        //                 size: 14,
                        //                 color: AppColors.primary,
                        //               ),
                        //               const SizedBox(width: 5),
                        //               Text(
                        //                 '${_formatRupee(_rupees)} = ${_formatNumber(_pointsEarned)} credit points',
                        //                 style: const TextStyle(
                        //                   fontSize: 13,
                        //                   color: AppColors.primary,
                        //                   fontWeight: FontWeight.w600,
                        //                   fontFamily: 'Inter',
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         )
                        //       : Padding(
                        //           key: const ValueKey(0),
                        //           padding: const EdgeInsets.only(top: 10),
                        //           child: Row(
                        //             mainAxisAlignment: MainAxisAlignment.center,
                        //             children: [
                        //               Icon(
                        //                 Icons.info_outline_rounded,
                        //                 size: 13,
                        //                 color: AppColors.textHintLight,
                        //               ),
                        //               const SizedBox(width: 5),
                        //               Text(
                        //                 'Enter $currency 50 or more to recharge',
                        //                 style: TextStyle(
                        //                   fontSize: 12,
                        //                   color: AppColors.textHintLight,
                        //                   fontFamily: 'Inter',
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        // ),
                        const SizedBox(height: 10),

                        Text(
                          Translate.t("creditScreen.quick_add"),
                          style: tt.titleSmall?.copyWith(
                            color: AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: _quickAmounts.map((amt) {
                            final pts = (amt * _pointsPerRupee).floor();
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: amt == _quickAmounts.last ? 0 : 10,
                                ),
                                child: _QuickChip(
                                  currency: currency,
                                  rupees: amt,
                                  points: pts,
                                  isSelected: _rupees == amt.toDouble(),
                                  onTap: () => _applyQuick(amt),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 32),

                        // ── Order summary ──
                        // if (_rupees >= 50) ...[
                        //   Text(
                        //     'Order Summary',
                        //     style: theme.textTheme.titleSmall?.copyWith(
                        //       color: AppColors.textPrimaryLight,
                        //       fontWeight: FontWeight.w700,
                        //     ),
                        //   ),
                        //   const SizedBox(height: 12),
                        //   Container(
                        //     width: double.infinity,
                        //     padding: const EdgeInsets.all(18),
                        //     decoration: BoxDecoration(
                        //       color: Colors.white,
                        //       borderRadius: BorderRadius.circular(14),
                        //       border: Border.all(color: AppColors.borderLight),
                        //       boxShadow: [
                        //         BoxShadow(
                        //           color: AppColors.shadowLighter,
                        //           blurRadius: 8,
                        //           offset: const Offset(0, 2),
                        //         ),
                        //       ],
                        //     ),
                        //     child: Column(
                        //       children: [
                        //         _SummaryRow(
                        //           label: 'Amount Paid',
                        //           value: _formatRupee(_rupees),
                        //         ),
                        //         const SizedBox(height: 10),
                        //         const _SummaryRow(
                        //           label: 'Rate',
                        //           value: '$currency 50 = 100 pts',
                        //         ),
                        //         const SizedBox(height: 10),
                        //         const Divider(color: AppColors.borderLight),
                        //         const SizedBox(height: 10),
                        //         _SummaryRow(
                        //           label: 'Credits Earned',
                        //           value: '${_formatNumber(_pointsEarned)} pts',
                        //           isTotal: true,
                        //         ),
                        //         const SizedBox(height: 10),
                        //         _SummaryRow(
                        //           label: 'New Balance',
                        //           value:
                        //               '${_formatNumber(currentBalance + _pointsEarned)} pts',
                        //           valueColor: AppColors.primary,
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        //   const SizedBox(height: 24),
                        // ],
                      ],
                    ),
                  ),
                ),

                // ── Sticky continue button ─────────────────────────
                Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    border: Border(
                      top: BorderSide(color: AppColors.borderLight, width: 1),
                    ),
                  ),
                  child: AnimatedOpacity(
                    opacity: _canProceed ? 1.0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: SizedBox(
                      width: phone ? double.infinity : 600,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _canProceed
                            ? () => _onContinue(context)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          disabledBackgroundColor: AppColors.accent.withAlpha(
                            80,
                          ),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _canProceed
                                  ? Translate.t("creditScreen.pay_get")
                                        .replaceAll(
                                          "{{amount}}",
                                          _formatRupee(_rupees),
                                        )
                                        .replaceAll(
                                          "{{points}}",
                                          _formatNumber(_pointsEarned),
                                        )
                                  : Translate.t(
                                      "creditScreen.enter_minimum",
                                    ).replaceAll(
                                      "{{min}}",
                                      "$currency ${settings['MoneyRatio'] ?? 2}",
                                    ),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                                letterSpacing: 0.2,
                              ),
                            ),
                            if (_canProceed) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          isloading ? Positioned(child: PaymentProcessingLoader()) : SizedBox(),
        ],
      ),
    );
  }

  Future<void> _handleBuy() async {
    rupees = int.tryParse(_controller.text.replaceAll(',', '').trim()) ?? 0;
    if (rupees <= 0) return;
    _lastPaidAmount = rupees.toDouble();
    _lastPointsEarned = _pointsEarned;
    setState(() => isloading = true);
    try {
      final userData = await SecureStorageService.getUserData();
      userId = userData['_id']?.toString() ?? '';
      final res = await api.getdata(
        endpoint: 'payments/order',
        data: {
          'amount': rupees,
          'userId': userId,
          'phone': userData['phone'],
          'email': userData['email'],
          'currency': "INR",
        },
      );
      if (res['status'] == 200 || res['status'] == 201) {
        _controller.clear();
        final response = res['response'];
        final responses = await cashfree.pay(
          orderId: response['orderId'] ?? "",
          paymentSessionId: response['paymentSessionId'] ?? "",
        );
        // final filterRequest = FilterRequest(userId: user['_id']);
        // context.read<ProfileProvider>().userprofilefetch(
        //   endpoint: "entities/filter/users",
        //   filterPayload: filterRequest.getuserprofile(),
        // );
        // context.pop();
      } else {
        _showSnackBar('Payment failed.', AppColors.error);
      }
    } catch (e) {
      _showSnackBar('failded to load', AppColors.error);
    } finally {
      await Future.delayed(const Duration(seconds: 1));

      setState(() => isloading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  void _onContinue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PaymentConfirmSheet(
        rupees: _rupees,
        currency: currency,
        points: _pointsEarned,
        onConfirm: () {
          Navigator.pop(context);
          _handleBuy();
          widget.onPaymentSuccess?.call();
        },
      ),
    );
  }
}

class _PriceStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _PriceStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextThemes.getLightTextTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final int rupees;
  final int points;
  final String currency;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickChip({
    required this.rupees,
    required this.points,
    required this.currency,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight, width: 1),
        ),
        child: Column(
          children: [
            Text(
              '+ $currency $rupees',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 3),
            // Text(
            //   '= $points pts',
            //   style: TextStyle(
            //     fontSize: 11,
            //     fontWeight: FontWeight.w500,
            //     color: isSelected
            //         ? AppColors.primaryDark
            //         : AppColors.textTertiaryLight,
            //     fontFamily: 'Inter',
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class _PaymentConfirmSheet extends StatelessWidget {
  final double rupees;
  final String currency;
  final int points;
  final VoidCallback onConfirm;

  const _PaymentConfirmSheet({
    required this.rupees,
    required this.currency,
    required this.points,
    required this.onConfirm,
  });

  String _formatNumber(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.toll_rounded, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 14),

          Text(
            Translate.t("creditScreen.confirm_purchase"),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),

          // Amount → Points visual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      '$currency ${rupees.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      'You Pay',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiaryLight,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${_formatNumber(points)} Pts',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      'You Get',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiaryLight,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    Translate.t("creditScreen.cancel"),
                    style: TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(
                    '${Translate.t("creditScreen.pay_button")} $currency${rupees.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
