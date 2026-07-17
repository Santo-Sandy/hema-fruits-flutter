import 'package:cached_network_image/cached_network_image.dart';
import 'package:cashew_marketplace/shared/models/blocked_user_model.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

// ─── User Avatar Widget ───────────────────────────────────
class BlockedUserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;

  const BlockedUserAvatar({
    Key? key,
    this.avatarUrl,
    required this.name,
    this.size = 48,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.headerGradient,
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: avatarUrl != null && avatarUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl!,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                errorWidget: (_, __, ___) => _buildInitials(name),
                progressIndicatorBuilder: (_, child, progress) {
                  return Center(
                    child: SizedBox(
                      width: size * 0.4,
                      height: size * 0.4,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
            )
          : _buildInitials(name),
    );
  }

  Widget _buildInitials(String name) {
    final initials = name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join()
        .substring(0, name.isEmpty ? 0 : 2.clamp(0, 2))
        .padRight(2, '?');

    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.35,
        ),
      ),
    );
  }
}

// ─── User Info Section ───────────────────────────────────
class BlockedUserInfo extends StatelessWidget {
  final String name;
  final String email;
  final DateTime blockedAt;
  final String? reason;

  const BlockedUserInfo({
    Key? key,
    required this.name,
    required this.email,
    required this.blockedAt,
    this.reason,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // const SizedBox(height: 4),
          // Text(
          //   email,
          //   style: TextStyle(
          //     color: AppColors.textSecondary,
          //     fontSize: 12,
          //   ),
          //   maxLines: 1,
          //   overflow: TextOverflow.ellipsis,
          // ),
          if (reason != null && reason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                reason!,
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Blocked ${_formatTimeAgo(blockedAt)}',
            style: TextStyle(color: AppColors.textHint, fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).toStringAsFixed(0)}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).toStringAsFixed(0)}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    }
    return 'Just now';
  }
}

// ─── Action Button (Unblock) ──────────────────────────────
class UnblockActionButton extends StatefulWidget {
  final String userId;
  final VoidCallback onUnblock;
  final bool isLoading;

  const UnblockActionButton({
    Key? key,
    required this.userId,
    required this.onUnblock,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<UnblockActionButton> createState() => _UnblockActionButtonState();
}

class _UnblockActionButtonState extends State<UnblockActionButton> {
  @override
  Widget build(BuildContext context) {
    return widget.isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          )
        : GestureDetector(
            onTap: widget.onUnblock,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Text(
                'Unblock',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
  }
}

// ─── Blocked User Card (Composite) ────────────────────────
class BlockedUserCard extends StatelessWidget {
  final BlockedUser user;
  final VoidCallback onUnblock;
  final bool isUnblocking;

  const BlockedUserCard({
    Key? key,
    required this.user,
    required this.onUnblock,
    this.isUnblocking = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          BlockedUserAvatar(
            avatarUrl: user.avatarUrl,
            name: user.name,
            size: 48,
          ),
          const SizedBox(width: 12),
          BlockedUserInfo(
            name: user.name,
            email: user.email,
            blockedAt: user.blockedAt,
            reason: user.reason,
          ),
          const SizedBox(width: 12),
          UnblockActionButton(
            userId: user.id,
            onUnblock: onUnblock,
            isLoading: isUnblocking,
          ),
        ],
      ),
    );
  }
}

// ─── Empty State Widget ───────────────────────────────────
class EmptyBlockedUsersState extends StatelessWidget {
  const EmptyBlockedUsersState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppColors.success.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Blocked Users',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t blocked anyone yet',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Loading Skeleton ──────────────────────────────────────
class BlockedUserCardSkeleton extends StatelessWidget {
  const BlockedUserCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.borderLight.withOpacity(0.3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 150,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
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
