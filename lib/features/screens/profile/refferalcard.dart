import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cashew_marketplace/core/constants/app_assets.dart';
import 'package:cashew_marketplace/core/providers/user_provider.dart';
import 'package:cashew_marketplace/core/repositories/settings_repository.dart';
import 'package:cashew_marketplace/core/services/referral/referral_service.dart';
import 'package:cashew_marketplace/core/services/translate.dart';
import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ReferFriendCard extends StatefulWidget {
  const ReferFriendCard({super.key});

  @override
  State<ReferFriendCard> createState() => _ReferFriendCardState();
}

class _ReferFriendCardState extends State<ReferFriendCard> {
  bool _termsExpanded = false;

  // ── Referral data state ───────────────────────────────────────────────────
  ReferralDetails? _referralDetails;
  bool _isLoadingDetails = false;
  String? _loadError;
  Map<String, dynamic> Settings = {};

  @override
  void initState() {
    super.initState();
    _loadReferralDetails();
  }

  /// Fetches the user's referral link + code via the service layer.
  /// Uses the service's session cache so multiple rebuilds don't re-fire.
  Future<void> _loadReferralDetails() async {
    setState(() {
      _isLoadingDetails = true;
      _loadError = null;
    });

    try {
      loadSettings();
      final userData = await SecureStorageService.getUserData();
      final userId = userData['_id']?.toString() ?? '';
      if (userId.isEmpty) throw Exception('User ID not available');

      final details = await ReferralService.instance.fetchMyReferral(userId);
      if (mounted) {
        setState(() {
          _referralDetails = details;
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      debugPrint('[ReferFriendCard] Failed to load referral details: $e');
      if (mounted) {
        setState(() {
          _loadError = 'Could not load referral info. Tap to retry.';
          _isLoadingDetails = false;
        });
      }
    }
  }

  void loadSettings() async {
    try {
      final setting = await context.read<Settingsprovider>().settingsfetch(
        endpoint: "entities/filter/settings",
        filterPayload: {},
      );
      if (setting.isNotEmpty) {
        await SettingsLocalRepository.instance.clearAdminSettings();
        await SettingsLocalRepository.instance.saveAdminSettings(setting);
      }
      setState(() {
        Settings = setting;
      });
    } catch (e) {
      debugPrint("$e");
    } finally {
      try {
        final settingrepo = SettingsLocalRepository.instance.getAdminSettings();
        setState(() {
          Settings = settingrepo;
        });
      } catch (e) {
        debugPrintStack();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight.withAlpha(30),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(theme, colorScheme),
              _buildTerms(theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      color: colorScheme.primary,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Pill badge ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.card_giftcard_rounded,
                      size: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      Translate.t("referral.refferal_reward"),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              _buildReferralCodeChip(theme),
            ],
          ),

          const SizedBox(height: 8),

          // ── Points row + Share button ───────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translate.t("referral.invite_friend"),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        Settings['refferal_points']?.toString() ?? '0',
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Pts',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IntrinsicWidth(child: _buildShareButton(theme, colorScheme)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Referral code chip ────────────────────────────────────────────────────

  Widget _buildReferralCodeChip(ThemeData theme) {
    if (_isLoadingDetails) {
      return Container(
        height: 32,
        alignment: Alignment.centerLeft,
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return GestureDetector(
        onTap: _loadReferralDetails,
        child: Text(
          _loadError!,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }

    final code = _referralDetails?.referralCode ?? '';
    if (code.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _copyToClipboard(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${Translate.t("referral.your_code")}: ',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              code,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white.withAlpha(200),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.copy_rounded,
              size: 14,
              color: Colors.white.withAlpha(200),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Referral code "$code" copied!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Share button ──────────────────────────────────────────────────────────

  Future<void> _shareReferralLink() async {
    try {
      final userData = await SecureStorageService.getUserData();
      final userId = userData['_id']?.toString() ?? '';
      if (userId.isEmpty) throw Exception('User ID not available');

      // Prefer already-loaded details; fallback to a fresh fetch (uses cache).
      final details =
          _referralDetails ??
          await ReferralService.instance.fetchMyReferral(userId);

      if (details == null || details.referralLink.isEmpty) {
        throw Exception('Referral link not available');
      }

      await shareReferral(
        userData['name'] ?? "Marketplace",
        details.referralLink,
      );
      // await SharePlus.instance.share(
      //   ShareParams(
      //     files: [XFile(AppAssets.sharereffer)],
      //     title: "Refered by ${userData['name'] ?? "Marketplace"}",
      //     text: 'Join using my referral link:\n${details.referralLink}',
      //     subject: 'Referral Link',
      //   ),
      // );
    } catch (e) {
      debugPrint('[ReferFriendCard] Share error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not share referral link. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildShareButton(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withAlpha(40),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isLoadingDetails ? null : _shareReferralLink,
        icon: const Icon(Icons.share_rounded),
        label: Text(Translate.t("referral.share_referral")),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.secondary,
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> shareReferral(String name, String referralLink) async {
    final byteData = await rootBundle.load(AppAssets.sharereffer);

    final tempDir = await getTemporaryDirectory();

    final file = File('${tempDir.path}/sharereffer.png');

    await file.writeAsBytes(byteData.buffer.asUint8List());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        title: 'Referred by $name',
        text: 'Referred by $name \nJoin using my referral link:\n$referralLink',
        subject: 'Referral Link',
      ),
    );
  }
  // ── Terms & Conditions ────────────────────────────────────────────────────

  Widget _buildTerms(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _termsExpanded = !_termsExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    Translate.t("referral.terms_conditions"),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _termsExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _termsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 0.5,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TermsItem(
                    'Points are credited after your friend completes their first post.',
                  ),
                  SizedBox(height: 4),
                  _TermsItem(
                    'Referral points expire 90 days after being credited.',
                  ),
                  SizedBox(height: 4),
                  _TermsItem('One reward per unique referred account.'),
                  SizedBox(height: 4),
                  _TermsItem('Offer may be withdrawn or modified at any time.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widget ─────────────────────────────────────────────────────────────

class _TermsItem extends StatelessWidget {
  final String text;
  const _TermsItem(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
