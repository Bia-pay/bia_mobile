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
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'app/socket/websocket.dart';
import 'app/utils/colors.dart';
import 'app/utils/router/router.dart';
import 'app/utils/theme_provider.dart';
import 'app/utils/image.dart';
import 'core/easy_loading_config.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/fallback_localization_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/services/session_service.dart';
import 'firebase_options.dart';
import 'dart:io';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("🔥 Handling a background message: ${message.messageId}");
  
  // Only show manually if it's a data-only message, as the OS automatically
  // displays notifications that contain a notification payload in the background.
  if (message.notification == null) {
    _showNotification(message);
  }
}

final FlutterLocalNotificationsPlugin localNotifications =
FlutterLocalNotificationsPlugin();

/// Helper to show notifications consistently across foreground/background
Future<void> _showNotification(RemoteMessage message) async {
  final notification = message.notification;
  final data = message.data;

  // If there's a notification object, use it. Otherwise, look for data keys.
  final title = notification?.title ?? data['title'] ?? 'New Notification';
  final body = notification?.body ?? data['body'] ?? 'You have a new update';

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'default_channel',
    'Default',
    channelDescription: 'Default notification channel',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await localNotifications.show(
    message.hashCode,
    title,
    body,
    platformDetails,
  );
}

Future<void> initLocalNotifications() async {
  const AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );

  await localNotifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      debugPrint('🔔 Notification tapped: ${response.payload}');
      // Handle navigation here if payload is present
    },
  );

  // Create the Android notification channel explicitly
  if (Platform.isAndroid) {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'default_channel',
      'Default',
      description: 'Default notification channel',
      importance: Importance.max,
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    debugPrint('📱 Created Android Notification Channel: default_channel');
  }
}

void listenForForegroundMessages() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("🟢 Message received in foreground!");
    
    // On iOS, if setForegroundNotificationPresentationOptions is set to alert,
    // the system automatically displays the notification if a notification payload is present.
    // Therefore, only manually trigger a notification on Android, or for data-only messages.
    if (Platform.isAndroid || message.notification == null) {
      _showNotification(message);
    }
  });
}

void setupNotificationTapHandlers() {
  // Handle tap when app is in background but not terminated
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('🔔 FCM Notification tapped (background)!');
    // Handle navigation
  });

  // Check if app was opened from a terminated state via a notification
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      debugPrint('🔔 FCM Notification tapped (terminated)!');
      // Handle navigation
    }
  });
}

// ==================== MAIN ENTRY ====================

/// Fires immediately so the splash screen appears in <200ms.
/// All heavy initialisation (Firebase, FCM) is deferred to the background.
void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    // Initialize Hive and open local storage boxes before building the widget tree
    // to prevent synchronous race conditions / HiveError.
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox("authBox"),
      Hive.openBox("appBox"),
      Hive.openBox("transactionCacheBox"),
    ]);
  } catch (e) {
    debugPrint("⚠️ Hive initialization error: $e");
  }

  // ✅ Step 1 — Run the app so the splash screen renders
  runApp(const ProviderScope(child: AppSocketListener(child: MyApp())));

  // ✅ Step 2 — Initialize heavier network-bound services (Firebase, FCM) in the background.
  _initAllServicesInBackground();
}

/// Runs all heavy initialisation off the critical path.
Future<void> _initAllServicesInBackground() async {
  try {
    if (Platform.isAndroid) {
      await MediaStore.ensureInitialized();
      MediaStore.appFolder = "Bia";
    }

    // Firebase is the heaviest init — run it in the background.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final authBox = Hive.box("authBox");
    // All secondary services (FCM, notifications) need Firebase to be ready.
    await _initSecondaryServices(authBox);
  } catch (e) {
    debugPrint("⚠️ Background initialization error: $e");
  }
}

/// FCM token, notification channels, and permission requests.
Future<void> _initSecondaryServices(Box authBox) async {
  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await initLocalNotifications();
    listenForForegroundMessages();
    setupNotificationTapHandlers();

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // APNS token check on iOS to avoid apns-token-not-set exception
    if (Platform.isIOS) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null) {
        debugPrint("⚠️ APNS token not ready yet on iOS. Skipping immediate FCM token fetch.");
        return;
      }
    }

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await authBox.put('fcmToken', fcmToken);
      debugPrint("🔥 Background FCM Token stored: $fcmToken");
    }
  } catch (e) {
    debugPrint("⚠️ Secondary initialization error: $e");
  }
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
    
    // Listen for route changes to manage inactivity timer
    AppRouter.router.routerDelegate.addListener(_onRouteChanged);

    // Initialize the session service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String currentLocation = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
      ref.read(sessionServiceProvider.notifier).init(currentLocation);
    });
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final String location = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
    ref.read(sessionServiceProvider.notifier).handleRouteChange(location);
  }


  @override
  void dispose() {
    AppRouter.router.routerDelegate.removeListener(_onRouteChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    
    // Get the current location to decide if we should track inactivity on resume
    final String currentLocation = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
    
    // Handle inactivity timer on lifecycle changes
    ref.read(sessionServiceProvider.notifier).handleAppLifecycle(state, currentLocation);
    
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
    final locale = ref.watch(appLocaleProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) {
        _initializeEasyLoadingOnce();

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            final String path = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
            ref.read(sessionServiceProvider.notifier).resetTimer(path);
          },
          onPanDown: (_) {
            final String path = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
            ref.read(sessionServiceProvider.notifier).resetTimer(path);
          },
          onScaleStart: (_) {
            final String path = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
            ref.read(sessionServiceProvider.notifier).resetTimer(path);
          },
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) {
              final String path = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
              ref.read(sessionServiceProvider.notifier).resetTimer(path);
            },
            onPointerMove: (_) {
              final String path = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
              ref.read(sessionServiceProvider.notifier).resetTimer(path);
            },
            child: MediaQuery(


              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)),
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: lightTheme,
                darkTheme: darkTheme,
                themeMode: themeMode,
                locale: locale,
                supportedLocales: const [
                  Locale('en'),
                  Locale('ha'),
                  Locale('pcm'),
                ],
                localizationsDelegates: const [
                  FallbackMaterialLocalizationsDelegate(),
                  FallbackCupertinoLocalizationsDelegate(),
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                routerConfig: AppRouter.router,
                builder: EasyLoading.init(),
              ),
            ),
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
        logoPath: appLogoPng,
        logoSize: 50.0,
        pulseColor: primaryColor,
        maskOpacity: 0.7,
        dismissOnTap: false,
        userInteractions: false,
      );
    }
  }
}