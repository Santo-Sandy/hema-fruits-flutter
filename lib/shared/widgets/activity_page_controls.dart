import 'dart:math' as math;

import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:hema_fruits/shared/theme/app_text_theme.dart';
import 'package:flutter/material.dart';

typedef ActivityDrawerContentBuilder =
    Widget Function(BuildContext context, VoidCallback refresh);

class ActivityPageOption {
  final int value;
  final String label;
  final IconData icon;

  const ActivityPageOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}

class ActivityFilterController extends ChangeNotifier {
  final Map<int, VoidCallback> _openers = {};
  final Map<int, bool> _activeFilters = {};
  int _activePage = 0;
  bool _isDisposed = false;

  void setActivePage(int page) {
    if (_activePage == page) return;
    _activePage = page;
    _notifyIfActive();
  }

  void register(int page, VoidCallback opener) {
    _openers[page] = opener;
    _notifyIfActive();
  }

  void unregister(int page) {
    _openers.remove(page);
    _activeFilters.remove(page);
    _notifyIfActive();
  }

  bool get canOpenFilter => _openers[_activePage] != null;
  bool get hasActiveFilter => _activeFilters[_activePage] ?? false;

  void setPageHasActiveFilter(int page, bool hasActiveFilter) {
    if (_activeFilters[page] == hasActiveFilter) return;
    _activeFilters[page] = hasActiveFilter;
    _notifyIfActive();
  }

  void openFilter() {
    _openers[_activePage]?.call();
  }

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

class ActivitySortController extends ActivityFilterController {}

class ActivityPageToolbar extends StatelessWidget {
  final int selectedPage;
  final List<ActivityPageOption> pages;
  final ValueChanged<int> onPageChanged;
  final ActivityFilterController filterController;
  final ActivitySortController? sortController;
  final bool hasActiveFilter;
  final bool hasActiveSort;

  const ActivityPageToolbar({
    super.key,
    required this.selectedPage,
    required this.pages,
    required this.onPageChanged,
    required this.filterController,
    this.sortController,
    this.hasActiveFilter = false,
    this.hasActiveSort = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        filterController,
        if (sortController != null) sortController!,
      ]),
      builder: (context, _) {
        final hasActive = filterController.hasActiveFilter || hasActiveFilter;
        final width = MediaQuery.sizeOf(context).width;
        final dropdownMaxWidth = math.max(132.0, width - 148.0);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: dropdownMaxWidth),
                child: _ActivityPageDropdown(
                  selectedPage: selectedPage,
                  pages: pages,
                  onPageChanged: onPageChanged,
                ),
              ),
              const SizedBox(width: 10),
              const Spacer(),
              _ActivityToolbarIconButton(
                icon: Icons.swap_vert,
                isActive:
                    (sortController?.hasActiveFilter ?? false) || hasActiveSort,
                onTap: sortController?.canOpenFilter == true
                    ? sortController!.openFilter
                    : null,
              ),
              // const SizedBox(width: 8),
              _ActivityToolbarIconButton(
                icon: Icons.filter_alt_outlined,
                isActive: hasActive,
                onTap: filterController.canOpenFilter
                    ? filterController.openFilter
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityPageDropdown extends StatelessWidget {
  final int selectedPage;
  final List<ActivityPageOption> pages;
  final ValueChanged<int> onPageChanged;

  const _ActivityPageDropdown({
    required this.selectedPage,
    required this.pages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentPage = pages.firstWhere(
      (page) => page.value == selectedPage,
      orElse: () => pages.first,
    );

    return PopupMenuButton<int>(
      onSelected: onPageChanged,
      onOpened: pages.length > 1 ? null : () {},
      color: AppColors.surfaceLight,
      elevation: 6,
      shadowColor: AppColors.primary.withAlpha(40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.borderLight.withAlpha(80), width: 1),
      ),
      offset: const Offset(0, 46),
      itemBuilder: (context) => pages.map((page) {
        final isSelected = page.value == selectedPage;
        return PopupMenuItem<int>(
          value: page.value,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withAlpha(20)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  page.icon,
                  size: 17,
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  page.label,
                  style: AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          // color: AppColors.background.withAlpha(16),
          // borderRadius: BorderRadius.circular(24),
          border: pages.length > 1
              ? Border.all(color: Colors.white.withAlpha(80), width: 1.3)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(currentPage.icon, size: 24, color: Colors.white),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                currentPage.label,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: AppTextThemes.getLightTextTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (pages.length > 1) ...[
              const SizedBox(width: 5),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 22,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;

  const _ActivityToolbarIconButton({
    required this.icon,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 42,
        decoration: BoxDecoration(
          // color: Colors.white.withAlpha(10),
          // borderRadius: BorderRadius.circular(24),
          // border: Border.all(
          //   color: isActive ? Colors.white : Colors.white,
          //   width: 1.3,
          // ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: isActive ? 28 : 24,
              color: isActive ? Colors.white : Colors.white,
            ),
            if (isActive)
              Positioned(
                top: 9,
                right: 10,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ActivityDrawerSectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const ActivityDrawerSectionLabel({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class ActivityDrawerField extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const ActivityDrawerField({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ActivityDrawerSectionLabel(icon: icon, label: label),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class ActivityActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const ActivityActiveFilterChip({
    super.key,
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      deleteIcon: Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
      onDeleted: onRemove,
      backgroundColor: AppColors.primary.withAlpha(14),
      deleteButtonTooltipMessage: '',
      side: BorderSide(color: AppColors.primary.withAlpha(60)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class ActivityActiveFilters extends StatelessWidget {
  final List<Widget> chips;

  const ActivityActiveFilters({super.key, required this.chips});

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ActivityDrawerSectionLabel(
          icon: Icons.check_circle_outline_rounded,
          label: "Active Filters",
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: chips),
      ],
    );
  }
}

class ActivityFilterDrawer extends StatefulWidget {
  final String title;
  final Widget? child;
  final ActivityDrawerContentBuilder? contentBuilder;
  final VoidCallback? onReset;
  final IconData headerIcon;

  const ActivityFilterDrawer({
    super.key,
    required this.title,
    this.child,
    this.contentBuilder,
    this.onReset,
    this.headerIcon = Icons.filter_alt_outlined,
  }) : assert(child != null || contentBuilder != null);

  @override
  State<ActivityFilterDrawer> createState() => _ActivityFilterDrawerState();

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    Widget? child,
    ActivityDrawerContentBuilder? contentBuilder,
    VoidCallback? onReset,
    IconData headerIcon = Icons.filter_alt_outlined,
  }) {
    assert(child != null || contentBuilder != null);

    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ActivityFilterDrawer(
          title: title,
          onReset: onReset,
          headerIcon: headerIcon,
          child: child,
          contentBuilder: contentBuilder,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }
}

class _ActivityFilterDrawerState extends State<ActivityFilterDrawer> {
  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final drawerChild =
        widget.contentBuilder?.call(context, _refresh) ?? widget.child!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;
    final drawerWidth = isMobile
        ? screenWidth * 0.70
        : math.min(screenWidth * 0.92, 420.0);
    final media = MediaQuery.of(context);
    final topInset = media.padding.top + 62;
    final bottomInset = screenWidth <= 768 ? media.padding.bottom + 80 : 0.0;

    return Padding(
      padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          elevation: 0,
          color: AppColors.surfaceLight,
          child: Container(
            width: drawerWidth,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(-6, 0),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            widget.headerIcon,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.title,
                          style: AppTextThemes.getLightTextTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.2,
                              ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                            size: 22,
                          ),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: drawerChild,
                    ),
                  ),
                  _ActivityDrawerActions(
                    onReset: widget.onReset == null
                        ? null
                        : () {
                            widget.onReset!();
                            _refresh();
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityDrawerActions extends StatelessWidget {
  final VoidCallback? onReset;

  const _ActivityDrawerActions({this.onReset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text("Reset"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text("Apply"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
