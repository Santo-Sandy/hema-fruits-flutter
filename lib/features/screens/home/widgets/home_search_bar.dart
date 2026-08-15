import 'package:flutter/material.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';

class HomeSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onVoiceSearch;
  final VoidCallback? onCameraSearch;

  const HomeSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onVoiceSearch,
    this.onCameraSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: "Search quality fruits, RCN, Kernels...",
            hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF616161)),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.mic_none_rounded, color: Color(0xFF616161)),
                  onPressed: onVoiceSearch,
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF616161)),
                  onPressed: onCameraSearch,
                ),
              ],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }
}
