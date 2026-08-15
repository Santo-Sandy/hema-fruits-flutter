import 'dart:async';

import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/core/services/offline_queue_service.dart';
import 'package:hema_fruits/core/utils/responsive/app_breakpoints.dart';
import 'package:hema_fruits/features/layouts/tablet_sidebar.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_header.dart';
import 'app_footer.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  static const _tabPaths = [
    RoutePath.home,
    RoutePath.dashboard,
    RoutePath.myActivity,
    RoutePath.salesBuyBidding,
  ];

  static const _lockedPaths = [
    RoutePath.personalInfo,
    RoutePath.businessInfo,
    RoutePath.newPost,
  ];

  Future<void> _showExitDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to exit this screen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.go(RoutePath.home);
    }
  }

  void _handleTabTap(
    int index, {
    int homeTabIndex = 0,
    int activityTabIndex = 0,
  }) {
    final location = GoRouterState.of(context).uri.toString();
    final bool isLockedScreen = _lockedPaths.any(
      (p) => location == p || location.startsWith(p),
    );
    if (isLockedScreen) {
      _showExitDialog();
      return;
    }
    if (index == 0) {
      context.go('${_tabPaths[index]}?tab=$homeTabIndex');
    } else if (index == 2) {
      context.go('${_tabPaths[index]}?tab=$activityTabIndex');
    } else {
      context.go(_tabPaths[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    final bool isLockedScreen = _lockedPaths.any(
      (p) => location == p || location.startsWith(p),
    );

    int tabIndex = -1;
    for (int i = _tabPaths.length - 1; i >= 0; i--) {
      if (location == _tabPaths[i] ||
          location.startsWith('${_tabPaths[i]}/') ||
          location.startsWith('${_tabPaths[i]}?')) {
        tabIndex = i;
        break;
      }
    }

    final bool keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final bool isDesktopOrTablet =
        AppBreakpoints.isTabletContext(context) ||
        AppBreakpoints.isDesktopContext(context);

    return PopScope(
      canPop: !isLockedScreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isLockedScreen) _showExitDialog();
      },
      child: Scaffold(
        appBar: const AppHeader(),
        body: Row(
          children: [
            if (MediaQuery.of(context).size.width > 768)
              TabletSidebar(
                currentIndex: tabIndex,
                onTap: (index) => _handleTabTap(index),
              ),
            Flexible(
              fit: FlexFit.tight,
              child: Column(
                children: [
                  // const _ConnectivityBanner(),
                  Flexible(fit: FlexFit.tight, child: widget.child),
                  if (MediaQuery.of(context).size.width <= 768 && !keyboardOpen)
                    AppFooter(
                      currentIndex: tabIndex,
                      onTap: (index, {homeTabIndex, activityTabIndex}) =>
                          _handleTabTap(
                            index,
                            homeTabIndex: homeTabIndex ?? 0,
                            activityTabIndex: activityTabIndex ?? 0,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Connectivity + upload banner ──────────────────────────────────────────────

enum _BannerState { hidden, offline, backOnline, uploading }

class _ConnectivityBanner extends StatefulWidget {
  const _ConnectivityBanner();

  @override
  State<_ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<_ConnectivityBanner> {
  _BannerState _state = _BannerState.hidden;
  int _uploadCount = 0;
  StreamSubscription<ConnectivityResult>? _connSub;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _init();
    OfflineQueueService.uploadState.addListener(_onUploadStateChanged);
  }

  Future<void> _init() async {
    final result = await Connectivity().checkConnectivity();
    if (!mounted) return;
    if (result == ConnectivityResult.none) {
      setState(() => _state = _BannerState.offline);
    }
    _connSub = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    if (!mounted) return;
    if (result == ConnectivityResult.none) {
      _hideTimer?.cancel();
      setState(() => _state = _BannerState.offline);
    } else {
      if (_state == _BannerState.offline) {
        setState(() => _state = _BannerState.backOnline);
        _hideTimer?.cancel();
        _hideTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _state = _BannerState.hidden);
        });
      }
    }
  }

  void _onUploadStateChanged() {
    if (!mounted) return;
    final upload = OfflineQueueService.uploadState.value;
    if (upload.uploading) {
      _hideTimer?.cancel();
      setState(() {
        _state = _BannerState.uploading;
        _uploadCount = upload.count;
      });
    } else if (_state == _BannerState.uploading) {
      setState(() => _state = _BannerState.hidden);
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _hideTimer?.cancel();
    OfflineQueueService.uploadState.removeListener(_onUploadStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _BannerState.hidden) return const SizedBox.shrink();

    final Color bg;
    final IconData icon;
    final String label;
    final bool tappable;

    switch (_state) {
      case _BannerState.offline:
        bg = AppColors.error;
        icon = Icons.wifi_off_rounded;
        label = 'You are offline';
        tappable = false;
        break;
      case _BannerState.backOnline:
        bg = AppColors.success;
        icon = Icons.wifi_rounded;
        label = 'Back online';
        tappable = false;
        break;
      case _BannerState.uploading:
        bg = AppColors.warning;
        icon = Icons.cloud_upload_outlined;
        label =
            'Uploading $_uploadCount pending item${_uploadCount == 1 ? '' : 's'}...';
        tappable = true;
        break;
      case _BannerState.hidden:
        return const SizedBox.shrink();
    }

    final content = Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          if (_state == _BannerState.uploading)
            const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else
            Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (tappable)
            const Icon(Icons.chevron_right, color: Colors.white, size: 16),
        ],
      ),
    );

    if (!tappable) return content;
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(RouteName.offlineQueue),
      child: content,
    );
  }
}
