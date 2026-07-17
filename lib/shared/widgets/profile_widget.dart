import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cashew_marketplace/core/config/app_config.dart';
import 'package:cashew_marketplace/core/services/translate.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Returns a full image URL from a storage_name or a full URL.
ImageProvider resolveImageProvider(String? value) {
  if (value == null || value.isEmpty) return const AssetImage('');
  if (value.startsWith('http')) return CachedNetworkImageProvider(value);
  return CachedNetworkImageProvider('${AppConfig.imageurl}$value');
}

class ProfileAvatarWidget extends StatefulWidget {
  final Function(String)? onImagePicked;
  final Function()? onTap;
  final String? imageUrl;
  final String? initialImageUrl;
  File? selectedImage;

  ProfileAvatarWidget({
    Key? key,
    this.onTap,
    this.onImagePicked,
    this.imageUrl,
    required this.selectedImage,
    this.initialImageUrl,
  }) : super(key: key);

  @override
  State<ProfileAvatarWidget> createState() => _ProfileAvatarWidgetState();
}

class _ProfileAvatarWidgetState extends State<ProfileAvatarWidget> {
  final String _userInitial = 'S';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              InkWell(
                onTap: widget.onTap,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.backgroundLight,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowDark,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    backgroundImage: widget.selectedImage != null
                        ? FileImage(widget.selectedImage!) as ImageProvider
                        : (widget.imageUrl != null &&
                              widget.imageUrl!.isNotEmpty)
                        ? resolveImageProvider(widget.imageUrl)
                        : null,
                    child:
                        (widget.imageUrl == null || widget.imageUrl!.isEmpty) &&
                            widget.selectedImage == null
                        ? Text(
                            _userInitial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _handleImagePick,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowDark,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.textPrimaryDark,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _handleImagePick,
            child: Text(
              Translate.t("profile_info.upload_profile"),
              style: AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleImagePick() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Profile Picture'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onImagePicked?.call('image_path');
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }
}

class ReferralCodePage extends StatefulWidget {
  const ReferralCodePage({
    super.key,
    required this.onSubmit,
    required this.onCancel,
  });

  final Future<void> Function(String referralCode) onSubmit;
  final Future<void> Function() onCancel;

  @override
  State<ReferralCodePage> createState() => _ReferralCodePageState();
}

class _ReferralCodePageState extends State<ReferralCodePage> {
  final _controller = TextEditingController();

  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    await widget.onSubmit(_controller.text);
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),

          Icon(
            Icons.card_giftcard_rounded,
            size: 72,
            color: theme.colorScheme.primary,
          ),

          const SizedBox(height: 24),

          Text(
            "Have a Referral Code?",
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            "Enter the 8-character referral code shared by your friend to receive your referral rewards.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),

          const SizedBox(height: 36),

          TextFormField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              letterSpacing: 4,
              fontWeight: FontWeight.w600,
            ),
            inputFormatters: [
              LengthLimitingTextInputFormatter(8),
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              UpperCaseTextFormatter(),
            ],
            decoration: const InputDecoration(
              hintText: "XXXXXXXX",
              border: OutlineInputBorder(),
              counterText: "",
            ),
            validator: (value) {
              final code = value?.trim() ?? "";

              if (code.isEmpty) {
                return "Please enter your referral code";
              }

              if (code.length != 8) {
                return "Referral code must be exactly 8 characters";
              }

              return null;
            },
          ),

          const SizedBox(height: 28),

          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Continue"),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: _loading ? null : widget.onCancel,
            child: const Text("Skip"),
          ),
        ],
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
