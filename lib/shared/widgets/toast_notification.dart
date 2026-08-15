import 'package:hema_fruits/core/utils/Responsive/responsivea_context.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_theme.dart';

enum ToastType {
  stocks,
  requirements,
  quotes,
  stock_quotes,
  res_quotes,
  res_stock_quotes,
  general,
}

class ToastNotification extends StatefulWidget {
  final String title;
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;
  final bool showProgressBar;

  const ToastNotification({
    super.key,
    required this.title,
    required this.message,
    this.type = ToastType.general,
    this.duration = const Duration(seconds: 4),
    this.onDismiss,
    this.onAction,
    this.actionLabel,
    this.showProgressBar = true,
  });

  @override
  State<ToastNotification> createState() => _ToastNotificationState();
}

class _ToastNotificationState extends State<ToastNotification>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _progressController;
  late Future<void> _dismissTimer;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();

    // Slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Scale animation for icon
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Progress animation
    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _slideController.forward();
    _scaleController.forward();
    _startDismissTimer();
  }

  void _startDismissTimer() {
    _progressController.forward();
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  Future<void> _dismiss() async {
    // await _slideController.reverse();
    if (mounted) {
      widget.onDismiss?.call();
    }
  }

  Future<void> _handleAction() async {
    if (_isTapped) return;
    _isTapped = true;
    widget.onAction?.call();
    await _dismiss();
  }

  IconData _getIcon() {
    switch (widget.type) {
      case ToastType.stocks:
      case ToastType.requirements:
        return Icons.inventory_2_outlined;
      case ToastType.quotes:
      case ToastType.stock_quotes:
        return Icons.question_answer_sharp;
      case ToastType.res_quotes:
      case ToastType.res_stock_quotes:
        return Icons.message_outlined;
      case ToastType.general:
      default:
        return Icons.info;
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return SlideTransition(
      position: _slideAnimation,
      child: Dismissible(
        key: const Key("toast"),
        direction: DismissDirection.up,
        onDismissed: (_) {
          _dismiss();
        },
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy < -10) {
              _dismiss();
            }
          },
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < -300) {
              _dismiss();
            }
          },
          onTap: () {
            if (_isTapped) return;
            _isTapped = true;
            _dismiss();
            widget.onAction?.call();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            constraints: BoxConstraints(maxWidth: 460),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(color: AppColors.accent, width: 2),
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  // border: Border.all(
                  //   color: AppColors.borderDark.withValues(alpha: 0.3),
                  //   width: 1,
                  // ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.borderDark.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Animated icon
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getIcon(),
                                color: AppColors.accent,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  style: AppTextThemes.getLightTextTheme.titleSmall
                                      ?.copyWith(
                                        color: textColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.message,
                                  style: AppTextThemes.getLightTextTheme.bodySmall
                                      ?.copyWith(
                                        color: secondaryTextColor,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                    // if (widget.onAction != null &&
                    //     widget.actionLabel != null) ...[
                    //   Padding(
                    //     padding: const EdgeInsets.symmetric(horizontal: 16),
                    //     child: Divider(
                    //       color: AppColors.borderDark.withValues(alpha: 0.15),
                    //       height: 1,
                    //     ),
                    //   ),
                    //   TextButton(
                    //     onPressed: _handleAction,
                    //     style: TextButton.styleFrom(
                    //       foregroundColor: AppColors.accent,
                    //       minimumSize: const Size(double.infinity, 40),
                    //     ),
                    //     child: Text(
                    //       widget.actionLabel!,
                    //       style: const TextStyle(
                    //         fontWeight: FontWeight.w600,
                    //         fontSize: 13,
                    //       ),
                    //     ),
                    //   ),
                    // ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ActiveToast {
  final OverlayEntry entry;
  bool isDismissed = false;

  ActiveToast(this.entry);

  void dismiss() {
    if (!isDismissed) {
      isDismissed = true;
      try {
        entry.remove();
      } catch (e) {
        debugPrint("ActiveToast: Error removing overlay entry: $e");
      }
    }
  }
}

class ToastService {
  static final ToastService _instance = ToastService._internal();

  factory ToastService() {
    return _instance;
  }

  ToastService._internal();

  ActiveToast? _activeToast;

  void show({
    required BuildContext context,
    required String title,
    required String message,
    ToastType type = ToastType.general,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
    VoidCallback? onAction,
    String? actionLabel,
    bool showProgressBar = true,
  }) {
    dismiss();

    final overlayState = Overlay.of(context);

    late ActiveToast activeToast;
    final entry = OverlayEntry(
      builder: (context) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ToastNotification(
              title: title,
              message: message,
              type: type,
              duration: duration,
              onDismiss: () {
                activeToast.dismiss();
                if (_activeToast == activeToast) {
                  _activeToast = null;
                }
                onDismiss?.call();
              },
              onAction: onAction,
              actionLabel: actionLabel,
              showProgressBar: showProgressBar,
            ),
          ),
        );
      },
    );

    activeToast = ActiveToast(entry);
    _activeToast = activeToast;
    overlayState.insert(entry);
  }

  void dismiss() {
    if (_activeToast != null) {
      _activeToast!.dismiss();
      _activeToast = null;
    }
  }

  void success({
    required BuildContext context,
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: ToastType.stocks,
      duration: duration,
      onDismiss: onDismiss,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  void error({
    required BuildContext context,
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: ToastType.quotes,
      duration: duration,
      onDismiss: onDismiss,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  void warning({
    required BuildContext context,
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: ToastType.res_quotes,
      duration: duration,
      onDismiss: onDismiss,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  void info({
    required BuildContext context,
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: ToastType.general,
      duration: duration,
      onDismiss: onDismiss,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }
}

class AnimatedToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback onDismiss;

  const AnimatedToastWidget({
    super.key,
    required this.message,
    required this.icon,
    required this.color,
    required this.onDismiss,
  });

  @override
  State<AnimatedToastWidget> createState() => _AnimatedToastWidgetState();
}

class _AnimatedToastWidgetState extends State<AnimatedToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 2),
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fade = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();

    // Auto dismiss
    Future.delayed(const Duration(seconds: 2), () async {
      await _controller.reverse();
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: context.v(80)),
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(maxWidth: 140),
                padding: EdgeInsets.symmetric(
                  horizontal: context.h(16),
                  vertical: context.v(14),
                ),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(context.h(14)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(80),
                      blurRadius: context.h(8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: context.h(14),
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
}
