import 'package:hema_fruits/core/config/app_config.dart';
import 'package:hema_fruits/core/providers/blocked_user_provider.dart';
import 'package:hema_fruits/core/providers/color_provider.dart';
import 'package:hema_fruits/core/providers/language_provider.dart';
import 'package:hema_fruits/core/providers/notification_provider.dart';
import 'package:hema_fruits/core/providers/swap_user_provider.dart';
import 'package:hema_fruits/core/router/router_config.dart';
import 'package:hema_fruits/core/services/auth_service/auth_service.dart';
import 'package:hema_fruits/core/providers/user_provider.dart';
import 'package:hema_fruits/core/services/notification/fcm_lifecycle_observer.dart';
import 'package:hema_fruits/core/services/notification/fcm_service.dart';
import 'package:hema_fruits/core/services/notification/notification_context_wrapper.dart';
import 'package:hema_fruits/core/services/translate.dart';
import 'package:hema_fruits/core/services/notification/notifiction_service.dart';
import 'package:hema_fruits/core/services/referral/referral_service.dart';
import 'package:hema_fruits/shared/local_storage/hive_service.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:hema_fruits/shared/local_storage/local_storage.dart';
import 'package:hema_fruits/core/services/offline_queue_service.dart';
import 'package:hema_fruits/core/providers/feature_providers.dart';
import 'package:hema_fruits/shared/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'package:hema_fruits/core/providers/ecommerce_provider.dart';

// Global context variables
BuildContext? globalContext;
final Map<String, BuildContext> screenContexts = {};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await HiveService.instance.init();

  await FCMService.initialize();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await LocalStorage.instance.init();
  AppConfig.instance.init();
  await OfflineQueueService.instance.init();

  await ReferralService.instance.initialize();

  await Translate.loadSaved();

  final userData = await SecureStorageService.getUserData();
  runApp(MainApp(initialUser: userData));
}

class MainApp extends StatelessWidget {
  final Map<String, dynamic>? initialUser;
  const MainApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MyApp();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    FcmLifecycleObserver().register();

    Future.delayed(const Duration(milliseconds: 3000), () {
      NotificationNavigationService.consumePending();
    });
  }

  @override
  void dispose() {
    FcmLifecycleObserver().unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => RecentPostProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => MyPostProvider()),
        ChangeNotifierProvider(create: (_) => UserAccountProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => UserProfProvider()),
        ChangeNotifierProvider(create: (_) => ResponseProvider()),
        ChangeNotifierProvider(create: (_) => EditPostProvider()),
        ChangeNotifierProvider(create: (_) => BiddingPostProvider()),
        ChangeNotifierProvider(create: (_) => Settingsprovider()),
        ChangeNotifierProvider(create: (_) => EnquiryProvider()),
        ChangeNotifierProvider(create: (_) => BlockedUserProvider()),
        ChangeNotifierProvider(create: (_) => ColorProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => CountryProvider()),
        ChangeNotifierProvider(create: (_) => EcommCatalogProvider()),
        ChangeNotifierProvider(create: (_) => EcommCartProvider()),
        ChangeNotifierProxyProvider<ProfileProvider, SwapUserProvider>(
          create: (_) => SwapUserProvider(),
          update: (_, userProfileProvider, swapProvider) {
            swapProvider!.updateRole(userProfileProvider.userprofile);
            return swapProvider;
          },
        ),
      ],
      child: Consumer<SwapUserProvider>(
        builder: (_, currentUserRole, __) {
          return NotificationContextWrapper(
            child: MaterialApp.router(
              title: 'Hema Fruits Marketplace',
              routerConfig: appRouter,
              theme: AppTheme.light,

              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                globalContext = context;
                FCMService.registerNotificationProvider(
                  context.read<NotificationProvider>(),
                );
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.noScaling),
                  child: child!,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
