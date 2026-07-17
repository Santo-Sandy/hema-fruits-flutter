import 'dart:async';
import 'package:cashew_marketplace/core/utils/context_manager.dart';
import 'package:flutter/material.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';

class FirstLoginRewardScreen extends StatefulWidget {
  final int rewardPoints;
  final VoidCallback onSubscribe;
  final VoidCallback onSkip;
  final VoidCallback? onAutoDismiss;
  final Duration timerDuration;

  const FirstLoginRewardScreen({
    Key? key,
    this.rewardPoints = 2500,
    required this.onSubscribe,
    required this.onSkip,
    this.onAutoDismiss,
    this.timerDuration = const Duration(seconds: 5),
  }) : super(key: key);

  @override
  State<FirstLoginRewardScreen> createState() => _FirstLoginRewardScreenState();
}

class _FirstLoginRewardScreenState extends State<FirstLoginRewardScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _floatController;
  late AnimationController _confettiController;

  Timer? _countdownTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();

    _secondsRemaining = widget.timerDuration.inSeconds;

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController.forward();
    _scaleController.forward();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _floatController.forward();
      _confettiController.forward();
    });

    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scaleController.dispose();
    _fadeController.dispose();
    _floatController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      }

      if (_secondsRemaining <= 0) {
        timer.cancel();
        if (widget.onAutoDismiss != null) {
          widget.onAutoDismiss!();
        } else {
          widget.onSkip();
        }
      }
    });
  }

  void _skip() {
    _countdownTimer?.cancel();
    widget.onSkip();
  }

  void _subscribe() {
    _countdownTimer?.cancel();
    widget.onSubscribe();
  }

  @override
  Widget build(BuildContext context) {
    ContextManager().saveCurrentPage('FirstLoginReward', context);
    return WillPopScope(
      onWillPop: () async {
        _skip();
        return false;
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              _buildConfetti(),

              /// TOP BAR (Skip button)
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 10),
                    child: GestureDetector(
                      onTap: _skip,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Skip",
                          style: AppTextThemes.getLightTextTheme.labelMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              /// MAIN CONTENT
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _fadeController,
                      child: ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _scaleController,
                          curve: Curves.elasticOut,
                        ),
                        child: _buildCard(),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          /// Subscribe Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _subscribe,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Explore More   >>>",
                                style: AppTextThemes.getLightTextTheme.labelLarge
                                    ?.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            "Closing in $_secondsRemaining sec",
                            style: AppTextThemes.getLightTextTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events, color: AppColors.primary, size: 48),

          const SizedBox(height: 16),

          Text(
            "Welcome Bonus!",
            style: AppTextThemes.getLightTextTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text("You've earned", style: AppTextThemes.getLightTextTheme.bodyMedium),

          const SizedBox(height: 20),

          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0),
              end: const Offset(0, -0.2),
            ).animate(_floatController),
            child: Text(
              "${widget.rewardPoints}",
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "CREDIT POINTS",
            style: AppTextThemes.getLightTextTheme.labelMedium?.copyWith(
              letterSpacing: 1.5,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfetti() {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _confettiController,
        curve: Curves.easeOut,
      ),
      child: Center(
        child: Stack(
          children: List.generate(10, (i) {
            return Transform.translate(
              offset: Offset((i - 5) * 25.0, (i % 2 == 0 ? -80 : 80)),
              child: Opacity(
                opacity: 0.3,
                child: Icon(Icons.celebration, color: Colors.white, size: 28),
              ),
            );
          }),
        ),
      ),
    );
  }
}
