import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'app/socket/websocket.dart';
import 'app/utils/colors.dart';
import 'app/utils/router/router.dart';
import 'app/utils/theme_provider.dart';
import 'core/easy_loading_config.dart';
import 'feature/dashboard/transaction_cache.dart';
import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin localNotifications =
FlutterLocalNotificationsPlugin();

Future<void> initLocalNotifications() async {
  const AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
  InitializationSettings(android: androidInit);

  await localNotifications.initialize(initSettings);
}

void listenForForegroundMessages() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });
}

// ==================== MAIN ENTRY ====================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await MediaStore.ensureInitialized();
  MediaStore.appFolder = "Bia";
  await initLocalNotifications();
  listenForForegroundMessages();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Hive.initFlutter();

  runApp(const ProviderScope(child: AppSocketListener(child: MyApp())));
}


// NOTE: navigatorKey is defined in feature/auth/interceptor/interceptor.dart
// and wired into GoRouter in app/utils/router/router.dart.

// ==================== MAIN APP ====================

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      await runFunctionOnAppClose();
    }
  }

  Future<void> runFunctionOnAppClose() async {
    debugPrint("Running cleanup before app closes...");
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) {
        // ✅ Initialize EasyLoadingConfig HERE after ScreenUtil is ready
        // Use a flag to ensure it only runs once
        _initializeEasyLoadingOnce();

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1)),
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeMode,
            routerConfig: AppRouter.router,
            builder: EasyLoading.init(),
          ),
        );
      },
    );
  }
  bool _isEasyLoadingInitialized = false;

// In main.dart, inside _initializeEasyLoadingOnce():

  void _initializeEasyLoadingOnce() {
    if (!_isEasyLoadingInitialized) {
      _isEasyLoadingInitialized = true;
      EasyLoadingConfig.initialize(
        logoPath: 'assets/svg/logo-b.png',
        logoSize: 40.h,        // ← Change from 6 to 3 (or 3.5)
        pulseColor: primaryColor,
        maskOpacity: 0.7,
        dismissOnTap: false,
        userInteractions: false,
      );
    }
  }
}