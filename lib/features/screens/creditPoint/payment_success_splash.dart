import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';
import 'package:cashew_marketplace/core/utils/formatters.dart';

class PaymentSuccessSplashScreen extends StatefulWidget {
  final double amount;
  final int points;
  final String currency;

  const PaymentSuccessSplashScreen({
    super.key,
    required this.amount,
    required this.points,
    required this.currency,
  });

  @override
  State<PaymentSuccessSplashScreen> createState() =>
      _PaymentSuccessSplashScreenState();
}

class _PaymentSuccessSplashScreenState extends State<PaymentSuccessSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _fadeController;
  late final AnimationController _detailsController;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _detailsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Sequence animations
    _scaleController.forward();
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _detailsController.forward();
      }
    });

    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleController.dispose();
    _fadeController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTextThemes.getgetLightTextTheme(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.success,
              AppColors.success.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Checkmark Icon
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _scaleController,
                  curve: Curves.elasticOut,
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: AppColors.success,
                      size: 64,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title text with fade transition
              FadeTransition(
                opacity: _fadeController,
                child: Column(
                  children: [
                    Text(
                      "Payment Successful!",
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your points have been credited",
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Animated details card
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.4),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _detailsController,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                child: FadeTransition(
                  opacity: _detailsController,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          // Amount Section
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${widget.currency} ${Formatters.formatTomoney(widget.amount.toStringAsFixed(0))}",
                                  style: textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Amount Paid",
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Divider
                          VerticalDivider(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                            thickness: 1,
                          ),

                          // Points Section
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.stars_rounded,
                                  color: Colors.amberAccent,
                                  size: 26,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${widget.points} pts",
                                  style: textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Credits Earned",
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
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
            ],
          ),
        ),
      ),
    );
  }
}
