import 'package:hema_fruits/core/constants/app_assets.dart';
import 'package:hema_fruits/core/providers/color_provider.dart';
import 'package:hema_fruits/core/providers/user_provider.dart';
import 'package:hema_fruits/core/services/filter_request.dart';
import 'package:hema_fruits/core/utils/context_manager.dart';
import 'package:hema_fruits/core/utils/initial_function.dart';
import 'package:hema_fruits/shared/theme/app_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/local_storage/user_data.dart';
import '../../../core/router/router_setup.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    getTheme("69fad8b51405a743ac1ae26a");
    InitialFunction().initialFunction(context);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigate();
    });
  }

  Future<void> getTheme(String id) async {
    try {
      final endpoint = "confirm/theme";
      await context.read<ColorProvider>().fetch(endpoint: endpoint);
    } catch (e) {
      debugPrint('Error getting theme: $e');
    }
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));

    bool? isprofileLocal =
        await SecureStorageService.getprofilestatus() ?? false;
    final String token = await SecureStorageService.getToken() ?? '';
    if (token.isEmpty) {
      bool login = false;
      try {
        login = await InitialFunction.layoutLogin();
      } catch (e) {
        debugPrintStack();
      }
      context.go('/login', extra: login);
      return;
    }
    final userdata = await SecureStorageService.getUserData();
    final filterRequest = FilterRequest(userId: userdata['_id']);
    await context.read<ProfileProvider>().userprofilefetch(
      endpoint: "entities/filter/users",
      filterPayload: filterRequest.getuserprofile(),
    );
    final bool isprofile = userdata['isProfileComplete'] ?? false;

    // if (!isprofileLocal) {
    //   if (token != '' && !isprofile) {
    //     context.go('/profilesetup');
    //     return;
    //   }
    // }
    // if (userdata['initializer_screen'] == "Dashboard") {
    //   context.go(RoutePath.dashboard);
    // } else if (userdata['initializer_screen'] == "BiddingScreen") {
    //   // context.go(RoutePath.home);
    //   context.go(RoutePath.salesBuyBidding);
    // } else if (userdata['initializer_screen'] == "Marketplace") {
    //   context.go(RoutePath.home);
    // } else {
    //   context.go(RoutePath.dashboard);
    // }

    
      context.go(RoutePath.home);
    return;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ContextManager().saveCurrentPage('SplashScreen', context);
    final tt = AppTextThemes.getgetLightTextTheme(context);
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppAssets.backgroundLogo),
                  fit: BoxFit.cover, // or BoxFit.contain, BoxFit.fill, etc.
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    AppAssets.splash,
                    // width: width,
                    height: height,
                    fit: BoxFit.cover,
                  ),
                  // const SizedBox(height: 24),
                  // Text(
                  //   'Hema Fruits',
                  //   style: tt.headlineMedium?.copyWith(
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
