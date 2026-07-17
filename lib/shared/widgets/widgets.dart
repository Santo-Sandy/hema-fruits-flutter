import 'package:cached_network_image/cached_network_image.dart';
import 'package:cashew_marketplace/core/config/app_config.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant { primary, outlined, ghost, danger, secondary }

// ── AppChip ───────────────────────────────────────────────────────────────────
class AppChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final double fontSize;

  const AppChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AppAvatar extends StatefulWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
    this.backgroundColor,
  });

  @override
  State<AppAvatar> createState() => _AppAvatarState();
}

class _AppAvatarState extends State<AppAvatar> {
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    _imageProvider = _buildImageProvider(widget.imageUrl);
  }

  @override
  void didUpdateWidget(AppAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageProvider = _buildImageProvider(widget.imageUrl);
    }
  }

  ImageProvider? _buildImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    if (imageUrl.startsWith('http'))
      return CachedNetworkImageProvider(imageUrl);
    return CachedNetworkImageProvider('${AppConfig.imageurl}$imageUrl');
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor ?? AppColors.primary,
      backgroundImage: _imageProvider,
      child: _imageProvider == null
          ? Text(
              initials,
              style: TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: widget.radius * 0.6,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}
