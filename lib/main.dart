import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/socket/websocket.dart';
import 'app/utils/colors.dart';
import 'app/utils/router/router.dart';
import 'app/utils/theme_provider.dart';
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

  await initLocalNotifications();   // 👈 REQUIRED
  listenForForegroundMessages();    // 👈 REQUIRED

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Hive.initFlutter();

  runApp(const ProviderScope(child: AppSocketListener(child: MyApp())));
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1)),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,

          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,

          routerConfig: AppRouter.router,

          builder: EasyLoading.init(),
        ),
      ),
    );
  }
}