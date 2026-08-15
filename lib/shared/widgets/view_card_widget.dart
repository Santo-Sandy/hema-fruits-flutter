import 'package:cached_network_image/cached_network_image.dart';
import 'package:hema_fruits/core/config/app_config.dart';
import 'package:hema_fruits/core/constants/app_assets.dart';
import 'package:hema_fruits/core/services/translate.dart';
import 'package:hema_fruits/core/utils/apptoaster.dart';
import 'package:hema_fruits/core/utils/formatters.dart';
import 'package:hema_fruits/core/utils/uri_launcher.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:hema_fruits/shared/theme/app_text_theme.dart';
import 'package:hema_fruits/shared/widgets/view_screen_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TradeHeader extends StatefulWidget {
  final String tradeId;
  final String count;
  final Function(bool isLiked)? onLike;
  final bool? isliked;
  final bool isMyPost;
  final Function() onviewers;
  final Function() onTap;
  final Function()? onuserlist;
  final Widget? trailingAction;

  const TradeHeader({
    super.key,
    required this.tradeId,
    required this.count,
    required this.onviewers,
    this.isliked,
    this.onLike,
    this.onuserlist,
    this.trailingAction,
    required this.onTap,
    required this.isMyPost,
  });

  @override
  State<TradeHeader> createState() => _TradeHeaderState();
}

class _TradeHeaderState extends State<TradeHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    isLiked = widget.isliked ?? false;
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        // borderRadius: BorderRadius.circular(_borderRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 40,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,

            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context, true),
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.tradeId,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // !widget.isMyPost
              //     ? GestureDetector(
              //         onTap: _toggleLike,
              //         child: Container(
              //           decoration: BoxDecoration(
              //             borderRadius: BorderRadius.circular(8),
              //           ),
              //           child: Icon(
              //             isLiked ? Icons.favorite : Icons.favorite_outline,
              //             color: isLiked
              //                 ? AppColors.error
              //                 : AppColors.textSecondary,
              //             size: 20,
              //           ),
              //         ),
              //       )
              //     : const SizedBox.shrink(),
              widget.isMyPost
                  ? GestureDetector(
                      onTap: widget.onviewers,
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.count,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GestureDetector(
                      onTap: widget.onTap,
                      child: Icon(Icons.info, color: Colors.white, size: 24),
                    ),
              // if (widget.trailingAction != null) ...[
              //   const SizedBox(width: 12),
              //   widget.trailingAction!,
              // ],
            ],
          ),
        ],
      ),
    );
  }
}

class ViewedUser {
  final String id;
  final String name;
  final String? profilePicture;

  ViewedUser({required this.id, required this.name, this.profilePicture});

  factory ViewedUser.fromJson(Map<String, dynamic> json) {
    return ViewedUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown User',
      profilePicture: json['profilePicture'],
    );
  }
  Map<String, dynamic> getmap(ViewedUser user) {
    return {
      '_id': user.id,
      'name': user.name,
      'profilePicture': user.profilePicture,
    };
  }
}

class TradeHeaders extends StatefulWidget {
  final String tradeId;
  final String count;
  final String phone;
  final String email;
  final String imageUrl;
  final bool isMyPost;
  final Function() onTap;
  final Function(String)? onReport;
  final Function(String)? onBlock;
  final List<String> reportReasons;

  const TradeHeaders({
    super.key,
    required this.tradeId,
    required this.count,
    required this.email,
    required this.phone,
    required this.imageUrl,
    required this.onTap,
    required this.onReport,
    required this.onBlock,
    required this.isMyPost,
    required this.reportReasons,
  });

  @override
  State<TradeHeaders> createState() => _TradeHeadersState();
}

class _TradeHeadersState extends State<TradeHeaders> {
  ImageProvider? _resolveImage(String url) {
    if (url.isEmpty) return null;
    if (url.startsWith('http')) return CachedNetworkImageProvider(url);
    return CachedNetworkImageProvider('${AppConfig.imageurl}$url');
  }

  Future<void> showReportBottomSheet(BuildContext context) async {
    final TextEditingController customReasonController =
        TextEditingController();

    final List<String> reportReasons = [...widget.reportReasons];

    int selectedIndex = -1;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isOtherSelected = selectedIndex == reportReasons.length - 1;

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Drag Handle
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Title
                    Text(
                      Translate.t("view.report_user"),
                      style: AppTextThemes.getLightTextTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      Translate.t("view.report_notice"),
                      style: AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Radio Options
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Column(
                              children: List.generate(reportReasons.length, (
                                index,
                              ) {
                                final isSelected = selectedIndex == index;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.borderLight,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    color: isSelected
                                        ? AppColors.primary.withValues(
                                            alpha: 0.06,
                                          )
                                        : AppColors.surface,
                                  ),
                                  child: RadioListTile<int>(
                                    value: index,
                                    groupValue: selectedIndex,
                                    activeColor: AppColors.primary,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    title: Text(
                                      reportReasons[index],
                                      style: AppTextThemes
                                          .getLightTextTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    onChanged: (value) {
                                      setModalState(() {
                                        selectedIndex = value!;
                                      });
                                    },
                                  ),
                                );
                              }),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: isOtherSelected
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: TextFormField(
                                        controller: customReasonController,
                                        maxLines: 4,
                                        decoration: InputDecoration(
                                          hintText: Translate.t(
                                            "view.report_custom",
                                          ),
                                          filled: true,
                                          fillColor: AppColors.surface,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppColors.borderLight,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppColors.borderLight,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppColors.primary,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    /// Custom Reason Field
                    const SizedBox(height: 28),

                    /// Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () async {
                          if (selectedIndex == -1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Please select a reason'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          final reason = isOtherSelected
                              ? customReasonController.text.trim()
                              : reportReasons[selectedIndex];

                          if (isOtherSelected && reason.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Please enter reason'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(context);

                          widget.onReport?.call(reason);
                        },
                        child: Text(
                          Translate.t("view.report"),
                          style: AppTextThemes.getLightTextTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBlockDialog(BuildContext context) {
    TextEditingController reason = TextEditingController();
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(Translate.t("view.block_user")),
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(Translate.t("view.block_notice")),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextFormField(
                  controller: reason,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: Translate.t("view.report_custom"),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                if (reason.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please enter reason'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                context.pop();
                widget.onBlock?.call(reason.text) ?? () {};
              },
              child: Text(Translate.t("view.block")),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Material(
      color: AppColors.primaryDark,
      child: InkWell(
        // onTap: widget.onTap,
        borderRadius: BorderRadius.circular(_borderRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: _cardPadding / 2),
          child: Row(
            children: [
              // ===== Back Button =====
              _BackButton(onTap: () => Navigator.of(context).pop()),

              // const SizedBox(width: 10),

              // ===== Main Content =====
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _MainContent(
                        onTap: widget.onTap,
                        tradeId: widget.tradeId,
                        phone: widget.phone,
                        email: widget.email,
                        imageUrl: widget.imageUrl,
                        isMobile: isMobile,
                      ),
                    ),

                    const SizedBox(width: _spacing),

                    // ===== Actions Menu =====
                    Align(
                      alignment: AlignmentGeometry.topRight,
                      child: _ActionsMenu(
                        onTap: widget.onTap,
                        onReport: () {
                          showReportBottomSheet(context);
                        },
                        onBlock: () {
                          _showBlockDialog(context);
                        },
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
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.arrow_back_ios, size: 24, color: Colors.white),
        ),
      ),
    );
  }
}

// ===== Main Content =====
class _MainContent extends StatelessWidget {
  final String tradeId;
  final String phone;
  final String email;
  final String imageUrl;
  final bool isMobile;
  final VoidCallback? onTap;

  const _MainContent({
    required this.tradeId,
    required this.phone,
    required this.email,
    required this.onTap,
    required this.imageUrl,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        // Header with Avatar + Title
        GestureDetector(
          onTap: onTap,
          child: _HeaderRow(
            tradeId: tradeId,
            imageUrl: imageUrl,
            isMobile: isMobile,
            phone: phone,
            email: email,
          ),
        ),
      ],
    );
  }
}

// ===== Header Row (Avatar + Title) =====
class _HeaderRow extends StatelessWidget {
  final String tradeId;
  final String imageUrl;
  final String phone;
  final String email;
  final bool isMobile;

  const _HeaderRow({
    required this.tradeId,
    required this.phone,
    required this.email,
    required this.imageUrl,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
        _Avatar(imageUrl: imageUrl, tradeId: tradeId),

        const SizedBox(width: _spacing),

        // Title
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tradeId,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              _ContactInfo(phone: phone, email: email),
            ],
          ),
        ),
      ],
    );
  }
}

// ===== Avatar Component =====
class _Avatar extends StatelessWidget {
  final String imageUrl;
  final String tradeId;

  const _Avatar({required this.imageUrl, required this.tradeId});

  ImageProvider? _resolveImage() {
    if (imageUrl.isEmpty) return null;
    try {
      if (imageUrl.startsWith('http')) {
        return CachedNetworkImageProvider(imageUrl);
      }
      return CachedNetworkImageProvider('${AppConfig.imageurl}$imageUrl');
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.surfaceDark
        : AppColors.borderLight;
    final image = _resolveImage();

    return CircleAvatar(
      radius: _avatarRadius,
      backgroundColor: backgroundColor ?? AppColors.primary,
      backgroundImage: image,
      child: image == null
          ? Text(
              tradeId.isNotEmpty ? tradeId[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}

// ===== Contact Info Component =====
class _ContactInfo extends StatelessWidget {
  final String phone;
  final String email;

  const _ContactInfo({required this.phone, required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        _ContactRow(
          icon: Icons.phone_outlined,
          text: phone,
          onTap: () => ExternalLauncher.call(phone),
        ),
        _ContactRow(
          icon: Icons.mail_outline,
          text: email,
          onTap: () => ExternalLauncher.email(email),
        ),
      ],
    );
  }
}

// ===== Contact Row Component =====
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _ContactRow({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: _contactIconSize, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,

              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
                color: Colors.white,
                fontSize: _contactTextSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Actions Menu =====
class _ActionsMenu extends StatefulWidget {
  final VoidCallback? onReport;
  final VoidCallback? onBlock;
  final VoidCallback? onTap;

  const _ActionsMenu({
    required this.onReport,
    required this.onBlock,
    required this.onTap,
  });

  @override
  State<_ActionsMenu> createState() => _ActionsMenuState();
}

class _ActionsMenuState extends State<_ActionsMenu> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      tooltip: 'More options',
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      color: AppColors.background,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      position: PopupMenuPosition.under,
      icon: Icon(Icons.more_vert_rounded, size: 24, color: Colors.white),
      onSelected: (value) {
        switch (value) {
          case 'view':
            widget.onTap?.call();
            break;
          case 'report':
            widget.onReport?.call();
            break;
          case 'block':
            widget.onBlock?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'view',
          child: _MenuItem(
            icon: Icons.remove_red_eye_outlined,
            label: 'View Profile',
            color: AppColors.success,
          ),
        ),
        PopupMenuItem<String>(
          value: 'report',
          child: _MenuItem(
            icon: Icons.flag_outlined,
            label: 'Report',
            color: AppColors.accent,
          ),
        ),
        PopupMenuItem<String>(
          value: 'block',
          child: _MenuItem(
            icon: Icons.block_rounded,
            label: 'Block',
            color: AppColors.error,
          ),
        ),
      ],
    );
  }
}

// ===== Menu Item Component =====
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: _spacing),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class MyPostActionMenu extends StatelessWidget {
  final bool canUpdate;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const MyPostActionMenu({
    super.key,
    required this.canUpdate,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      tooltip: 'More options',
      icon: Icon(
        Icons.more_vert_rounded,
        size: 24,
        color: AppColors.textPrimary,
      ),
      onSelected: (value) {
        if (value == 'update') {
          if (canUpdate) {
            onUpdate();
          }
          return;
        }
        if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'update',
          enabled: canUpdate,
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: canUpdate ? AppColors.accent : AppColors.textHint,
              ),
              const SizedBox(width: 10),
              Text(
                'Edit',
                style: TextStyle(
                  color: canUpdate ? AppColors.textPrimary : AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              const SizedBox(width: 10),
              Text('Delete', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }
}

const double _avatarRadius = 30;
const double _cardPadding = 16;
const double _spacing = 12;
const double _borderRadius = 16;
const double _contactIconSize = 18;
const double _contactTextSize = 13;

class MakeOfferForm extends StatefulWidget {
  final TextEditingController quantityController;
  final TextEditingController priceController;
  final TextEditingController remarksController;
  final String minQuantity;
  final String maxQuantity;
  final String sellingprice;
  final bool negotiatePrice;
  final String currency;

  final VoidCallback onTap;
  final Function(double totalPrice)? onTotalChanged;

  const MakeOfferForm({
    super.key,
    required this.quantityController,
    required this.maxQuantity,
    required this.priceController,
    required this.remarksController,
    required this.minQuantity,
    required this.sellingprice,
    required this.currency,
    required this.negotiatePrice,
    required this.onTap,
    this.onTotalChanged,
  });

  @override
  State<MakeOfferForm> createState() => _MakeOfferFormState();
}

class _MakeOfferFormState extends State<MakeOfferForm> {
  double totalPrice = 0;
  bool iserror = false;
  bool _isQuantityValid = false;

  @override
  void initState() {
    super.initState();
    widget.priceController.text = widget.sellingprice;
    widget.quantityController.addListener(_calculateTotal);
    widget.priceController.addListener(_calculateTotal);
    widget.quantityController.addListener(_validateQuantity);
  }

  double parseFormattedNumber(String value) {
    return double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
  }

  void _validateQuantity() {
    final quantity = parseFormattedNumber(widget.quantityController.text);
    final minQty = parseFormattedNumber(widget.minQuantity);
    final maxQty = parseFormattedNumber(widget.maxQuantity);

    setState(() {
      _isQuantityValid =
          quantity >= minQty && quantity <= maxQty && quantity > 0;
      iserror = !_isQuantityValid;
    });
  }

  void _calculateTotal() {
    final quantity = parseFormattedNumber(widget.quantityController.text);
    final price = parseFormattedNumber(widget.priceController.text);

    setState(() {
      totalPrice = quantity * price;
    });

    widget.onTotalChanged?.call(totalPrice);
  }

  void _submit() {
    if (!_isQuantityValid) {
      final minQty = parseFormattedNumber(widget.minQuantity);
      final maxQty = parseFormattedNumber(widget.maxQuantity);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Quantity must be between $minQty and $maxQty"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    widget.onTap();
  }

  @override
  void dispose() {
    widget.quantityController.removeListener(_calculateTotal);
    widget.priceController.removeListener(_calculateTotal);
    widget.quantityController.removeListener(_validateQuantity);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedTotal = NumberFormat("#,##0.00").format(totalPrice);
    final currency = widget.currency ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quantity and Price Row
          _buildQuantityPriceRow(),
          const SizedBox(height: 16),

          // Total Value Card
          // _buildTotalValueCard(formattedTotal, currency),
          // const SizedBox(height: 20),

          // Remarks Section
          _buildRemarksSection(),
          const SizedBox(height: 24),

          // Submit Button
          _buildSubmitButton(),
        ],
      ),
    );
  }

  static String formatToKg(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    final formatter = NumberFormat('#,##0', 'en_IN');
    return "${formatter.format(number)} kg";
  }

  Widget _buildQuantityPriceRow() {
    return Row(
      children: [
        // Quantity Field
        Expanded(
          child: _buildInputField(
            controller: widget.quantityController,
            label: Translate.t("enquiry.Quantity"),
            hint: 'Min: ${formatToKg(widget.minQuantity)}',
            icon: Icons.inventory_2_outlined,
            suffix: 'kg',
            keyboardType: TextInputType.number,
            readOnly: false,
            isValid: _isQuantityValid,

            isedit: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              KgInputFormatter(),
              MaxValueInputFormatter(99999999),
            ],
          ),
        ),
        if (widget.negotiatePrice) ...[
          const SizedBox(width: 12),

          // Price Field
          Expanded(
            child: _buildInputField(
              controller: widget.priceController,
              label: Translate.t("enquiry.Price"),

              hint: Formatters.formatTomoney(widget.sellingprice),
              icon: Icons.local_offer_outlined,
              prefix: widget.currency,
              suffix: '/kg',
              keyboardType: TextInputType.number,
              readOnly: !widget.negotiatePrice,

              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                MaxValueInputFormatter(99999999),
                // KgInputFormatter(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? prefix,
    String? suffix,
    bool isedit = false,
    required TextInputType keyboardType,
    required bool readOnly,
    required List<TextInputFormatter> inputFormatters,
    bool isValid = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextThemes.getLightTextTheme.labelMedium?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimaryLight,
          ),

          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            suffixText: suffix,
            hintStyle: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: label == 'Quantity' && !isValid
                    ? AppColors.error
                    : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: label == 'Quantity' && !isValid
                    ? AppColors.error
                    : AppColors.primary,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.borderLight.withValues(alpha: 0.5),
              ),
            ),
            filled: true,
            fillColor: readOnly
                ? AppColors.primarySubtle.withValues(alpha: 0.5)
                : AppColors.surfaceLight,
          ),
        ),
        isedit
            ? iserror
                  ? Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Text(
                        "Valid quantity from ${formatToKg(widget.minQuantity)} to ${formatToKg(widget.maxQuantity)}.",
                        maxLines: 2,
                        style: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                          fontSize: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                  : const SizedBox.shrink()
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildTotalValueCard(String formattedTotal, String currency) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calculate_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${Translate.t("enquiry.Estimated")}: ",
                      maxLines: 2,
                      style: AppTextThemes.getLightTextTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                // const SizedBox(height: 4),
                // Text(
                //   'AMOUNT',
                //   style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                //     color: AppColors.textSecondaryLight,
                //   ),
                // ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              child: Text(
                '$currency $formattedTotal',
                style: AppTextThemes.getLightTextTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.messenger_outline, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              Translate.t("enquiry.Special"),
              style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              Translate.t("enquiry.Optional"),
              style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.remarksController,
          maxLines: 3,
          minLines: 3,
          style: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
            color: AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: Translate.t("enquiry.term"),
            hintStyle: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isQuantityValid ? _submit : null,
        icon: const Icon(Icons.send_outlined, size: 18),
        label: Text(
          Translate.t("button.submit"),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isQuantityValid
              ? AppColors.accent
              : AppColors.accent.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: AppColors.accent.withValues(alpha: 0.3),
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class ResponseItem extends StatelessWidget {
  final IconData avatar;
  final Color avatarBg;
  final String senderName;
  final String timestamp;
  final String status;
  final Color statusColor;
  final String quantity;
  final String price;
  final String total;
  final String? img;
  final String currency;
  final Color totalColor;
  final Function()? onconfirm;
  final Function()? onreject;
  final Function()? onview;
  final String enquiriesRemark;
  final String responseRemark;
  final bool isrejected;
  final bool noview;
  final bool showActions;

  ResponseItem({
    required this.avatar,
    required this.avatarBg,
    required this.senderName,
    required this.onconfirm,
    required this.onreject,
    this.onview,
    this.img,
    this.noview = false,
    required this.timestamp,
    required this.status,
    required this.currency,
    required this.statusColor,
    required this.quantity,
    required this.price,
    required this.enquiriesRemark,
    required this.responseRemark,
    required this.isrejected,
    required this.total,
    required this.totalColor,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Avatar and Status
          _buildHeader(),
          const SizedBox(height: 16),

          // Details Grid (QTY, PRICE, TOTAL)
          _buildDetailsGrid(),
          const SizedBox(height: 16),

          // Remarks Section
          _buildRemarksSection(),

          _buildOfferActions(
            onview: onview,
            onreject: onreject,
            onconfirm: onconfirm,
            showActions: showActions,
          ),
        ],
      ),
    );
  }

  Widget _buildOfferActions({
    Function()? onview,
    required Function()? onreject,
    required Function()? onconfirm,
    required bool showActions,
  }) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // View button (always shown)
          // !noview
          //     ? Flexible(
          //         child: Container(
          //           height: 40,
          //           child: ElevatedButton.icon(
          //             onPressed: onview,
          //             icon: const Icon(Icons.visibility_outlined, size: 16),
          //             label: const Text('View'),
          //             style: ElevatedButton.styleFrom(
          //               backgroundColor: AppColors.surfaceLight,
          //               foregroundColor: AppColors.accent,
          //               padding: const EdgeInsets.symmetric(
          //                 vertical: 5,
          //                 horizontal: 10,
          //               ),
          //               shape: RoundedRectangleBorder(
          //                 borderRadius: BorderRadius.circular(10),
          //                 side: BorderSide(color: AppColors.accent, width: 1.5),
          //               ),
          //             ),
          //           ),
          //         ),
          //       )
          //     : const SizedBox.shrink(),

          // Reject button (conditional)
          if (showActions) ...[
            const SizedBox(width: 12),
            Flexible(
              child: Container(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: onreject,
                  icon: const Icon(Icons.close_outlined, size: 16),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: AppColors.error, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Confirm button (conditional)
          if (showActions) ...[
            const SizedBox(width: 12),
            Flexible(
              child: Container(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: onconfirm,
                  icon: const Icon(Icons.check_outlined, size: 16),
                  label: const Text('Confirm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: avatarBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: avatarBg.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: img == null
              ? Icon(avatar, color: Colors.white, size: 22)
              : Container(
                  padding: EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppColors.primary,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: AppColors.primary,
                      image: img != null
                          ? DecorationImage(
                              image: img!.startsWith('http')
                                  ? CachedNetworkImageProvider(img!)
                                  : CachedNetworkImageProvider(
                                      '${AppConfig.imageurl}${img!}',
                                    ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: img != null
                        ? null
                        : Text(
                            senderName[0],
                            style: TextStyle(
                              color: AppColors.textPrimaryLight,
                              fontSize: 30 * 0.6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
        ),
        const SizedBox(width: 12),

        // Sender Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                senderName.split(' ')[0],
                style: AppTextThemes.getLightTextTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                timestamp,
                style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),

        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            status,
            style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DetailColumn(
              label: Translate.t("response.QUANTITY"),
              value: quantity,
              icon: Icons.inventory_2_outlined,
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: AppColors.borderLight,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: _DetailColumn(
              label: Translate.t("enquiry.Price"),
              value: '${currency} ${price}',
              icon: Icons.local_offer_outlined,
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: AppColors.borderLight,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: _DetailColumn(
              label: Translate.t("enquiry.total"),
              value: '${currency} ${total}',
              valueColor: totalColor,
              icon: Icons.calculate_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enquiries Remark
        _buildRemarkCard(
          label: Translate.t("enquiry.b_remark"),
          value: enquiriesRemark != ""
              ? enquiriesRemark
              : Translate.t("enquiry.no"),
          icon: Icons.comment_outlined,
          iconColor: AppColors.primary,
          backgroundColor: AppColors.primary.withValues(alpha: 0.06),
        ),
        const SizedBox(height: 12),

        // Response Remark (only if rejected/has response)
        if (isrejected)
          _buildRemarkCard(
            label: Translate.t("enquiry.s_remark"),
            value: responseRemark,
            icon: Icons.reply_outlined,
            iconColor: statusColor,
            backgroundColor: statusColor.withValues(alpha: 0.06),
          ),
      ],
    );
  }

  Widget _buildRemarkCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: iconColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                  color: iconColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
              color: AppColors.textPrimaryLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  const _DetailColumn({
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                label,
                style: AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextThemes.getLightTextTheme.titleSmall?.copyWith(
            color: valueColor ?? AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int size;
  final bool isonlytext;

  const ExpandableText({
    super.key,
    required this.text,
    this.style,
    this.isonlytext = false,
    this.size = 12,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool isExpanded = false;
  bool islarge = false;

  @override
  Widget build(BuildContext context) {
    widget.text.length > 100 ? islarge = true : islarge = false;
    return widget.isonlytext
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row(
              //   children: [
              //     Icon(Icons.description),
              //     Text(
              //       "description",
              //       style: AppTextThemes.getLightTextTheme.labelMedium,
              //     ),
              //   ],
              // ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                  child: Text(
                    widget.text,
                    maxLines: !isExpanded ? 2 : 100,
                    overflow: TextOverflow.ellipsis,
                    style:
                        widget.style ??
                        AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiaryLight,
                          letterSpacing: 0.3,
                        ),
                  ),
                ),
              ),

              // const SizedBox(height: 4),
              islarge
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          isExpanded = !isExpanded;
                        });
                      },
                      child: Text(
                        isExpanded ? "View Less" : "View More",
                        style: AppTextThemes.getLightTextTheme.labelSmall
                            ?.copyWith(
                              fontSize: widget.size!.toDouble(),
                              color: AppColors.textHintDark,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                      ),
                    )
                  : SizedBox(),
            ],
          )
        : Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notes_rounded),
                    const SizedBox(width: 4),
                    Text(
                      "Notes",
                      style: AppTextThemes.getLightTextTheme.labelMedium,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                    child: Text(
                      widget.text,
                      maxLines: !isExpanded ? 2 : 100,
                      overflow: TextOverflow.ellipsis,
                      style:
                          widget.style ??
                          AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textTertiaryLight,
                            letterSpacing: 0.3,
                          ),
                    ),
                  ),
                ),

                // const SizedBox(height: 4),
                islarge
                    ? GestureDetector(
                        onTap: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                        },
                        child: Text(
                          isExpanded ? "View Less" : "View More",
                          style: AppTextThemes.getLightTextTheme.labelSmall
                              ?.copyWith(
                                fontSize: widget.size!.toDouble(),
                                color: AppColors.textHintDark,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                        ),
                      )
                    : SizedBox(),
              ],
            ),
          );
  }
}
