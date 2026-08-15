import 'package:hema_fruits/core/providers/language_provider.dart';
import 'package:hema_fruits/core/providers/user_provider.dart';
import 'package:hema_fruits/core/services/auth_service/auth_service.dart';
import 'package:hema_fruits/core/services/filter_request.dart';
import 'package:hema_fruits/core/services/translate.dart';
import 'package:hema_fruits/core/utils/responsive/app_breakpoints.dart';
import 'package:hema_fruits/core/utils/responsive/app_spacing.dart';
import 'package:hema_fruits/core/utils/responsive/app_typography.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic> _userData = {};
  bool _loading = true;
  bool _isNotificationEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userData = await SecureStorageService.getUserData();
    final userId = userData['_id'];

    if (mounted && userId != null) {
      final request = FilterRequest(userId: userId);
      await context.read<ProfileProvider>().userprofilefetch(
        endpoint: 'entities/filter/users',
        filterPayload: request.getuserprofile(),
      );
      await getUser(userId);
    }

    final profileData = await SecureStorageService.getUserProfileData();
    if (!mounted) return;
    setState(() {
      _userData = profileData.isNotEmpty ? profileData : userData;
      _loading = false;
    });
  }

  void _showLanguageDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _LanguageBottomSheet(
          currentLang: Translate.currentLang,
          onSelected: (code) async {
            await context.read<LanguageProvider>().changeLanguage(code);
          },
        );
      },
    );
  }

  void _showInitialPageDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _InitialPageBottomSheet(
          currentPage: _userData['initializer_screen'] ?? 'Marketplace',
          onSelected: (code) async {
            final userId = _userData['_id'];
            if (userId == null) return;

            await updateProfile(
              payload: {'initializer_screen': code},
              userId: userId,
            );
            await _loadProfile();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final isWide =
        AppBreakpoints.isTabletContext(context) ||
        AppBreakpoints.isDesktopContext(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        ),
        title: Text(
          Translate.t('profile.Additional'),
          style: AppTypography.responsive(
            context,
            baseSize: 16,
            tabletSize: 18,
            desktopSize: 20,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWide ? 760 : constraints.maxWidth,
                      ),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.xxl,
                        ),
                        children: [
                          _SettingsSection(
                            children: [
                              _SettingsTile(
                                title: Translate.t('profile.initialpage'),
                                subtitle: _initialPageLabel(
                                  _userData['initializer_screen'] ??
                                      'Marketplace',
                                ),
                                icon: Icons.pages_outlined,
                                color: AppColors.accent,
                                onTap: _showInitialPageDialog,
                              ),
                              _SettingsTile(
                                title: Translate.t('profile.language'),
                                subtitle: _languageLabel(Translate.currentLang),
                                icon: Icons.translate,
                                color: AppColors.secondary,
                                onTap: _showLanguageDialog,
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                                child: ListTile(
                                  leading: SizedBox(
                                    width: 38,
                                    height: 38,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.09),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.notifications_outlined,
                                        color: AppColors.accent,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    Translate.t('profile.Notification'),
                                    style: AppTypography.responsive(
                                      context,
                                      baseSize: 14,
                                      tabletSize: 15,
                                      desktopSize: 16,
                                    ).copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  trailing: Switch(
                                    value: _isNotificationEnabled,
                                    onChanged: (value) {
                                      setState(() {
                                        _isNotificationEnabled = value;
                                      });
                                    },
                                    thumbIcon:
                                        WidgetStateProperty.resolveWith<Icon?>((
                                          states,
                                        ) {
                                          if (states.contains(
                                            WidgetState.selected,
                                          )) {
                                            return const Icon(
                                              Icons.check,
                                              size: 14,
                                            );
                                          }
                                          return const Icon(
                                            Icons.close,
                                            size: 14,
                                          );
                                        }),
                                    trackOutlineColor: WidgetStateProperty.all(
                                      Colors.transparent,
                                    ),
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: AppColors.accent,
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor: AppColors.beige,
                                  ),
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _languageLabel(String code) {
    return switch (code) {
      'tamil' => Translate.t('language.tamil'),
      'hindi' => Translate.t('language.hindi'),
      _ => Translate.t('language.english'),
    };
  }

  String _initialPageLabel(String code) {
    return switch (code) {
      'Dashboard' => Translate.t('initialpage.dashboard'),
      'BiddingScreen' => Translate.t('initialpage.biddingscreen'),
      _ => Translate.t('initialpage.marketplace'),
    };
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              title!,
              style:
                  AppTypography.responsive(
                    context,
                    baseSize: 12,
                    tabletSize: 13,
                    desktopSize: 14,
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiaryDark,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 38,
        height: 38,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
      title: Text(
        title,
        style: AppTypography.responsive(
          context,
          baseSize: 14,
          tabletSize: 15,
          desktopSize: 16,
        ).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.responsive(
          context,
          baseSize: 12,
          tabletSize: 13,
          desktopSize: 14,
        ).copyWith(color: AppColors.textHint),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}

class _LanguageBottomSheet extends StatefulWidget {
  final String currentLang;
  final Future<void> Function(String) onSelected;

  const _LanguageBottomSheet({
    required this.currentLang,
    required this.onSelected,
  });

  @override
  State<_LanguageBottomSheet> createState() => _LanguageBottomSheetState();
}

class _LanguageBottomSheetState extends State<_LanguageBottomSheet> {
  late String _selected;
  bool _loading = false;

  List<Map<String, String>> get _languages => [
    {
      'code': 'english',
      'label': 'English',
      'native': Translate.t('language.english'),
    },
    {
      'code': 'tamil',
      'label': 'தமிழ்',
      'native': Translate.t('language.tamil'),
    },
    {
      'code': 'hindi',
      'label': 'हिन्दी',
      'native': Translate.t('language.hindi'),
    },
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentLang;
  }

  @override
  Widget build(BuildContext context) {
    return _PickerSheet(
      title: Translate.t('language.Language'),
      subtitle: Translate.t('language.choose'),
      children: _languages.map((lang) {
        final isSelected = _selected == lang['code'];
        return _PickerOption(
          title: lang['label']!,
          subtitle: lang['native'],
          selected: isSelected,
          loading: _loading,
          onTap: () async {
            final navigator = Navigator.of(context);
            setState(() {
              _selected = lang['code']!;
              _loading = true;
            });
            await widget.onSelected(lang['code']!);
            if (mounted) navigator.pop();
          },
        );
      }).toList(),
    );
  }
}

class _InitialPageBottomSheet extends StatefulWidget {
  final String currentPage;
  final Future<void> Function(String) onSelected;

  const _InitialPageBottomSheet({
    required this.currentPage,
    required this.onSelected,
  });

  @override
  State<_InitialPageBottomSheet> createState() =>
      _InitialPageBottomSheetState();
}

class _InitialPageBottomSheetState extends State<_InitialPageBottomSheet> {
  late String _selected;
  bool _loading = false;

  List<Map<String, String>> get _pages => [
    {'code': 'Marketplace', 'label': Translate.t('initialpage.marketplace')},
    {'code': 'Dashboard', 'label': Translate.t('initialpage.dashboard')},
    {
      'code': 'BiddingScreen',
      'label': Translate.t('initialpage.biddingscreen'),
    },
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentPage;
  }

  @override
  Widget build(BuildContext context) {
    return _PickerSheet(
      title: Translate.t('initialpage.page'),
      subtitle: Translate.t('initialpage.choose'),
      children: _pages.map((page) {
        final isSelected = _selected == page['code'];
        return _PickerOption(
          title: page['label']!,
          selected: isSelected,
          loading: _loading,
          onTap: () async {
            final navigator = Navigator.of(context);
            setState(() {
              _selected = page['code']!;
              _loading = true;
            });
            await widget.onSelected(page['code']!);
            if (mounted) navigator.pop();
          },
        );
      }).toList(),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.beige,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            title,
            style:
                AppTypography.responsive(
                  context,
                  baseSize: 18,
                  tabletSize: 20,
                  desktopSize: 22,
                ).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTypography.responsive(
              context,
              baseSize: 13,
              tabletSize: 14,
              desktopSize: 15,
            ).copyWith(color: AppColors.textHint),
          ),
          SizedBox(height: AppSpacing.xl),
          ...children,
        ],
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.title,
    required this.selected,
    required this.loading,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.creamLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        AppTypography.responsive(
                          context,
                          baseSize: 14,
                          tabletSize: 15,
                          desktopSize: 16,
                        ).copyWith(
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTypography.responsive(
                        context,
                        baseSize: 12,
                        tabletSize: 13,
                        desktopSize: 14,
                      ).copyWith(color: AppColors.textHint),
                    ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.beige, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
