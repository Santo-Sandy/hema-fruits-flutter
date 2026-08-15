import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// / Shimmer Effect Animation
// / Creates a loading animation effect (shimmer)
class ShimmerEffects extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerEffects({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<ShimmerEffects> createState() => _ShimmerEffectsState();
}

class _ShimmerEffectsState extends State<ShimmerEffects>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(
                -1.0 - _animationController.value * 2,
                _animationController.value,
              ),
              end: Alignment(
                1.0 - _animationController.value * 2,
                _animationController.value,
              ),
              colors: [AppColors.beige, AppColors.borderLight, AppColors.beige],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.lighten,
          child: widget.child,
        );
      },
    );
  }
}

class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerEffect({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0, -1.0),
              end: Alignment(3.0, -1.0),
              stops: [0.0, _animationController.value, 1.0],
              colors: [AppColors.beige, AppColors.cream, AppColors.beige],
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

// ─── Shimmer Painter ──────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final bool circle;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 8,
    this.circle = false,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.circle
                ? null
                : BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.28),
                Colors.white.withValues(alpha: 0.10),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Profile Header Skeleton ──────────────────────────────────────────────────

class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar + Name row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar circle
              _ShimmerBox(width: 90, height: 90, circle: true),

              const SizedBox(width: 14),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  _ShimmerBox(width: 140, height: 18, radius: 6),
                  const SizedBox(height: 10),
                  // Role chip
                  _ShimmerBox(width: 90, height: 26, radius: 30),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Credit Balance Card Skeleton ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: icon + labels
                Row(
                  children: [
                    // Icon box
                    _ShimmerBox(width: 36, height: 36, radius: 10),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // "Credit Balance" label
                        _ShimmerBox(width: 90, height: 11, radius: 4),
                        const SizedBox(height: 6),
                        // Balance value
                        _ShimmerBox(width: 70, height: 18, radius: 5),
                      ],
                    ),
                  ],
                ),

                // Right: Add Credits button
                _ShimmerBox(width: 110, height: 34, radius: 30),
              ],
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class MarketplaceListingCardSkeleton extends StatelessWidget {
  final double? height;
  final double? width;

  const MarketplaceListingCardSkeleton({Key? key, this.height, this.width})
    : super(key: key);

  Widget _bone({double? w, double? h, double radius = 6, double? aspectRatio}) {
    Widget box = Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    return aspectRatio != null
        ? AspectRatio(aspectRatio: aspectRatio, child: box)
        : box;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 5),
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Shimmer.fromColors(
            baseColor: AppColors.borderLight,
            highlightColor: AppColors.creamLight,
            period: const Duration(milliseconds: 1600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image placeholder
                      _bone(w: 60, h: 60, radius: 12),
                      const SizedBox(width: 12),
                      // Title + badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _bone(h: 14, radius: 4),
                            const SizedBox(height: 8),
                            _bone(w: 120, h: 14, radius: 4),
                            const SizedBox(height: 8),
                            _bone(w: 90, h: 22, radius: 12),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Like + price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _bone(w: 32, h: 32, radius: 8),
                          const SizedBox(height: 8),
                          _bone(w: 88, h: 34, radius: 8),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Posted by row
                  Row(
                    children: [
                      _bone(w: 16, h: 16, radius: 8),
                      const SizedBox(width: 6),
                      _bone(w: 180, h: 12, radius: 4),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Bottom row: until + qty + icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _bone(w: 16, h: 16, radius: 8),
                          const SizedBox(width: 6),
                          _bone(w: 100, h: 12, radius: 4),
                        ],
                      ),
                      _bone(w: 80, h: 12, radius: 4),
                      _bone(w: 16, h: 16, radius: 4),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
      ],
    );
  }
}

class ProfilePageSkeleton extends StatefulWidget {
  const ProfilePageSkeleton({super.key});

  @override
  State<ProfilePageSkeleton> createState() => _ProfilePageSkeletonState();
}

class _ProfilePageSkeletonState extends State<ProfilePageSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _shimmer = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return _SkeletonShimmerScope(
          shimmerValue: _shimmer.value,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonAppBar(),
                _SkeletonHeaderCard(),
                _SkeletonTabRow(),
                const SizedBox(height: 16),
                _SkeletonProductGrid(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Shimmer scope ──────────────────────────────────────────────────────────────

class _SkeletonShimmerScope extends InheritedWidget {
  final double shimmerValue;

  const _SkeletonShimmerScope({
    required this.shimmerValue,
    required super.child,
  });

  static _SkeletonShimmerScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkeletonShimmerScope>()!;

  @override
  bool updateShouldNotify(_SkeletonShimmerScope old) =>
      shimmerValue != old.shimmerValue;
}

// ── Skeleton box ──────────────────────────────────────────────────────────────

class _SkBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const _SkBox({required this.width, required this.height, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final shimmer = _SkeletonShimmerScope.of(context).shimmerValue;
    final base = AppColors.borderLight;
    final highlight = AppColors.backgroundLight;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment(shimmer - 1, 0),
          end: Alignment(shimmer + 1, 0),
          colors: [base, highlight, base],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// ── AppBar ────────────────────────────────────────────────────────────────────

class _SkeletonAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundLight,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 12,
        right: 12,
      ),
      child: Row(
        children: [
          _SkBox(
            width: 36,
            height: 36,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(width: 12),
          _SkBox(width: 140, height: 20),
        ],
      ),
    );
  }
}

// ── Header card ───────────────────────────────────────────────────────────────

class _SkeletonHeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company + GST badge
                Row(
                  children: [
                    _SkBox(
                      width: 20,
                      height: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: _SkBox(width: double.infinity, height: 14),
                    ),
                    const SizedBox(width: 10),
                    _SkBox(
                      width: 80,
                      height: 22,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _contactRow(140),
                const SizedBox(height: 8),
                _contactRow(170),
                const SizedBox(height: 8),
                _contactRow(120),
                const SizedBox(height: 12),
                // Bio
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkBox(
                      width: 15,
                      height: 15,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        children: [
                          const _SkBox(width: double.infinity, height: 12),
                          const SizedBox(height: 5),
                          _SkBox(width: double.infinity * 0.8, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Avatar
          _SkBox(
            width: 100,
            height: 100,
            borderRadius: BorderRadius.circular(50),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(double labelWidth) => Row(
    children: [
      _SkBox(width: 15, height: 15, borderRadius: BorderRadius.circular(3)),
      const SizedBox(width: 6),
      _SkBox(width: labelWidth, height: 13),
    ],
  );
}

// ── Tab row ───────────────────────────────────────────────────────────────────

class _SkeletonTabRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySubtle,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border.all(color: AppColors.primary.withAlpha(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SkBox(
              width: double.infinity,
              height: 38,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(width: 25),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkBox(width: 80, height: 12),
              const SizedBox(height: 5),
              _SkBox(width: 40, height: 14),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Product grid ──────────────────────────────────────────────────────────────

class _SkeletonProductGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => const _SkeletonProductCard(),
    );
  }
}

class _SkeletonProductCard extends StatelessWidget {
  const _SkeletonProductCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Like button
          Align(
            alignment: Alignment.topRight,
            child: _SkBox(
              width: 28,
              height: 28,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(height: 6),
          const _SkBox(width: double.infinity, height: 13),
          const SizedBox(height: 5),
          _SkBox(width: 100, height: 13),
          const SizedBox(height: 8),
          // Location + price chips
          Row(
            children: [
              Expanded(
                child: _SkBox(
                  width: double.infinity,
                  height: 22,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 6),
              _SkBox(
                width: 64,
                height: 22,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _SkBox(width: double.infinity, height: 10),
          const SizedBox(height: 5),
          _SkBox(width: 110, height: 10),
        ],
      ),
    );
  }
}

class MyPostCardSkeleton extends StatefulWidget {
  const MyPostCardSkeleton({super.key});

  @override
  State<MyPostCardSkeleton> createState() => _MyPostCardSkeletonState();
}

class _MyPostCardSkeletonState extends State<MyPostCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    double radius = 6,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.5, 1.0],
              transform: GradientRotation(_animation.value),
              colors: [AppColors.beige, AppColors.cream, AppColors.beige],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: icon + title area
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon placeholder
                _shimmerBox(width: 60, height: 60, radius: 12),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with icon buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _shimmerBox(width: 140, height: 18, radius: 5),
                          Row(
                            children: [
                              _shimmerBox(width: 28, height: 28, radius: 14),
                              const SizedBox(width: 4),
                              _shimmerBox(width: 28, height: 28, radius: 14),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Status badge placeholder
                      _shimmerBox(width: 90, height: 24, radius: 16),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ],
            ),
            // Bottom row: quantity + date + button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _shimmerBox(width: 16, height: 16, radius: 3),
                          const SizedBox(width: 6),
                          _shimmerBox(width: 110, height: 13, radius: 4),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _shimmerBox(width: 16, height: 16, radius: 3),
                          const SizedBox(width: 6),
                          _shimmerBox(width: 130, height: 13, radius: 4),
                        ],
                      ),
                    ],
                  ),
                  // Outlined button placeholder
                  _shimmerBox(width: 88, height: 36, radius: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionItemSkeleton extends StatefulWidget {
  const ActionItemSkeleton({super.key});

  @override
  State<ActionItemSkeleton> createState() => _ActionItemSkeletonState();
}

class _ActionItemSkeletonState extends State<ActionItemSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _box({
    required double width,
    required double height,
    double radius = 6,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            transform: GradientRotation(_animation.value),
            stops: const [0.0, 0.5, 1.0],
            colors: [AppColors.beige, AppColors.cream, AppColors.beige],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon box
          _box(width: 48, height: 48, radius: 12),
          const SizedBox(width: 14),
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(width: 120, height: 13, radius: 4),
                const SizedBox(height: 8),
                _box(width: 180, height: 12, radius: 4),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Time ago
          _box(width: 36, height: 11, radius: 4),
        ],
      ),
    );
  }
}

class OfferCardSkeleton extends StatefulWidget {
  final bool showActions;

  const OfferCardSkeleton({super.key, this.showActions = true});

  @override
  State<OfferCardSkeleton> createState() => _OfferCardSkeletonState();
}

class _OfferCardSkeletonState extends State<OfferCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _box({
    required double width,
    required double height,
    double radius = 6,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            transform: GradientRotation(_animation.value),
            stops: const [0.0, 0.5, 1.0],
            colors: [AppColors.beige, AppColors.cream, AppColors.beige],
          ),
        ),
      ),
    );
  }

  Widget _divider() => Divider(
    color: AppColors.borderLight,
    height: 1,
    indent: 16,
    endIndent: 16,
  );

  Widget _verticalDivider() => Container(
    height: 50,
    width: 1,
    color: AppColors.borderLight,
    margin: const EdgeInsets.symmetric(horizontal: 12),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeaderSkeleton(),
          _divider(),
          _buildDetailsSkeleton(),
          _divider(),
          _buildActionsSkeleton(),
        ],
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _box(width: double.infinity, height: 20, radius: 5),
                ),
                const SizedBox(width: 12),
                _box(width: 70, height: 28, radius: 8),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _box(width: 54, height: 28, radius: 8),
        ],
      ),
    );
  }

  Widget _buildDetailsSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildDetailItemSkeleton()),
          _verticalDivider(),
          Expanded(child: _buildDetailItemSkeleton()),
          _verticalDivider(),
          Expanded(child: _buildDetailItemSkeleton()),
        ],
      ),
    );
  }

  Widget _buildDetailItemSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _box(width: 14, height: 14, radius: 3),
            const SizedBox(width: 6),
            Expanded(
              child: _box(width: double.infinity, height: 11, radius: 4),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _box(width: 80, height: 15, radius: 4),
      ],
    );
  }

  Widget _buildActionsSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _box(width: 80, height: 40, radius: 10),
          if (widget.showActions) ...[
            const SizedBox(width: 12),
            _box(width: 80, height: 40, radius: 10),
            const SizedBox(width: 12),
            _box(width: 90, height: 40, radius: 10),
          ],
        ],
      ),
    );
  }
}

class EnquiryCardCompactSkeleton extends StatefulWidget {
  const EnquiryCardCompactSkeleton({super.key});

  @override
  State<EnquiryCardCompactSkeleton> createState() =>
      _EnquiryCardCompactSkeletonState();
}

class _EnquiryCardCompactSkeletonState extends State<EnquiryCardCompactSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _box({
    required double width,
    required double height,
    double radius = 6,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            transform: GradientRotation(_animation.value),
            stops: const [0.0, 0.5, 1.0],
            colors: [AppColors.beige, AppColors.cream, AppColors.beige],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeaderSkeleton(),
          const Divider(height: 1),
          _buildContentSkeleton(),
        ],
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(width: 140, height: 14, radius: 4),
                const SizedBox(height: 6),
                _box(width: 100, height: 11, radius: 4),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status badge
          _box(width: 72, height: 24, radius: 6),
        ],
      ),
    );
  }

  Widget _buildContentSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name
          _box(width: 120, height: 14, radius: 4),
          const SizedBox(height: 12),
          // 3 compact tiles
          Row(
            children: [
              Expanded(child: _buildTileSkeleton(isHighlight: false)),
              const SizedBox(width: 10),
              Expanded(child: _buildTileSkeleton(isHighlight: false)),
              const SizedBox(width: 10),
              Expanded(child: _buildTileSkeleton(isHighlight: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTileSkeleton({required bool isHighlight}) {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 10, left: 5),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlight
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _box(width: 14, height: 14, radius: 3),
              const SizedBox(width: 4),
              Expanded(
                child: _box(width: double.infinity, height: 10, radius: 3),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _box(width: 60, height: 13, radius: 4),
        ],
      ),
    );
  }
}

class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  Widget _box({
    double width = double.infinity,
    double height = 12,
    double radius = 6,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.beige,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 8),
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.beige),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER (Avatar + Name + Time + Status)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Avatar
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.beige,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),

                  /// Name + Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(width: 140, height: 14),
                        const SizedBox(height: 6),
                        _box(width: 100, height: 10),
                      ],
                    ),
                  ),

                  /// Status badge
                  _box(width: 70, height: 20, radius: 10),
                ],
              ),

              const SizedBox(height: 12),

              /// ENQUIRY REMARK
              _box(width: double.infinity, height: 12),
              const SizedBox(height: 6),
              _box(width: 220, height: 12),

              const SizedBox(height: 10),

              /// RESPONSE REMARK
              _box(width: double.infinity, height: 12),
              const SizedBox(height: 6),
              _box(width: 180, height: 12),

              const SizedBox(height: 14),

              /// PRICE DETAILS (3 columns)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_priceBlock(), _priceBlock(), _priceBlock()],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _box(width: 60, height: 10),
        const SizedBox(height: 6),
        _box(width: 50, height: 14),
      ],
    );
  }
}

class ViewScreenSkeleton extends StatefulWidget {
  const ViewScreenSkeleton({super.key});

  @override
  State<ViewScreenSkeleton> createState() => _ViewScreenSkeletonState();
}

class _ViewScreenSkeletonState extends State<ViewScreenSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _box({
    double width = double.infinity,
    double height = 12,
    double radius = 6,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            transform: GradientRotation(_animation.value),
            stops: const [0.0, 0.5, 1.0],
            colors: [AppColors.beige, AppColors.cream, AppColors.beige],
          ),
        ),
      ),
    );
  }

  Widget _tile() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            transform: GradientRotation(_animation.value),
            stops: const [0.0, 0.5, 1.0],
            colors: [
              AppColors.borderLight,
              AppColors.cream,
              AppColors.borderLight,
            ],
          ),
        ),
        child: Column(
          children: [
            _box(width: 80, height: 10),
            const SizedBox(height: 6),
            _box(width: 60, height: 14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge + price row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _box(width: 70, height: 24, radius: 12),
              _box(width: 100, height: 24, radius: 6),
            ],
          ),
          const SizedBox(height: 16),
          // Product title
          _box(width: 200, height: 18),
          const SizedBox(height: 8),
          _box(width: 140, height: 13),
          const SizedBox(height: 16),
          // Origin + location row
          Row(
            children: [
              _box(width: 16, height: 16, radius: 4),
              const SizedBox(width: 8),
              _box(width: 120, height: 13),
              const SizedBox(width: 24),
              _box(width: 16, height: 16, radius: 4),
              const SizedBox(width: 8),
              _box(width: 100, height: 13),
            ],
          ),
          const SizedBox(height: 16),
          // Dates row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(width: 80, height: 10),
                    const SizedBox(height: 6),
                    _box(width: 100, height: 13),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(width: 80, height: 10),
                    const SizedBox(height: 6),
                    _box(width: 100, height: 13),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats tiles
          Row(
            children: [
              Expanded(child: _tile()),
              const SizedBox(width: 12),
              Expanded(child: _tile()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _tile()),
              const SizedBox(width: 12),
              Expanded(child: _tile()),
            ],
          ),
          const SizedBox(height: 20),
          // Description lines
          _box(width: double.infinity, height: 12),
          const SizedBox(height: 8),
          _box(width: double.infinity, height: 12),
          const SizedBox(height: 8),
          _box(width: 200, height: 12),
          const SizedBox(height: 24),
          // Action buttons
          Row(
            children: [
              Expanded(child: _box(height: 44, radius: 12)),
              const SizedBox(width: 12),
              Expanded(child: _box(height: 44, radius: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class TradeHeadersSkeleton extends StatefulWidget {
  const TradeHeadersSkeleton({super.key});

  @override
  State<TradeHeadersSkeleton> createState() => _TradeHeadersSkeletonState();
}

class _TradeHeadersSkeletonState extends State<TradeHeadersSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _animation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _skeletonBox({
    required double width,
    required double height,
    double radius = 8,
    BoxShape shape = BoxShape.rectangle,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: shape == BoxShape.rectangle
                ? BorderRadius.circular(radius)
                : null,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              transform: GradientRotation(_animation.value),
              colors: [AppColors.beige, AppColors.cream, AppColors.beige],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _skeletonBox(width: 24, height: 24, radius: 6),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Row(
                children: [
                  // Avatar
                  _skeletonBox(width: 60, height: 60, shape: BoxShape.circle),

                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _skeletonBox(width: 140, height: 16),

                        const SizedBox(height: 10),

                        _skeletonBox(width: 180, height: 12),

                        const SizedBox(height: 8),

                        _skeletonBox(width: 220, height: 12),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Menu Icon
                  _skeletonBox(width: 24, height: 24, radius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
