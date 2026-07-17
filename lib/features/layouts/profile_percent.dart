import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

class ProfilePercent extends StatelessWidget {
  final double percent;
  final Map<String, dynamic> userData;
  final double? radius;
  const ProfilePercent({
    super.key,
    required this.percent,
    required this.userData,
    this.radius,
  });

  Color _getProgressColor(double percentage) {
    if (percentage <= 25) {
      return AppColors.error;
    } else if (percentage <= 50) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Progress Border
        SizedBox(
          width: 96,
          height: 96,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percent / 100),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(_getProgressColor(percent)),
                strokeCap: StrokeCap.round,
              );
            },
          ),
        ),

        // Profile Image
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.background.withValues(alpha: 0.8),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppAvatar(
            imageUrl: userData['profilePicture'],
            name: userData['name'],
            radius: radius ?? 42,
          ),
        ),

        // Percentage Badge
        Positioned(
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getProgressColor(percent),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              "${percent.toInt()}%",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
