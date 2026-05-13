import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/screen/splash_screen.dart';
import 'core/theme/theme.dart';
import 'core/utils/Navigation_service.dart';
import 'core/utils/orientation_lock.dart';
import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// NOTE: Channel ID bumped to _v2 because Android notification channels are
// immutable after first creation. The previous channel was created without
// explicit sound settings on user devices, so we need a new ID to apply
// playSound + enableVibration cleanly.
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel_v2',
  'High Importance Notifications',
  description: 'Used for important notifications.',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

// Background handler MUST be a top-level function.
// Runs in a separate isolate, so it re-initializes Firebase and the local
// notifications plugin. If the FCM payload contains a `notification` block
// the OS already shows a banner — but for data-only payloads we surface
// one ourselves so the user still sees something while the app is killed.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (message.notification != null) return;

  final data = message.data;
  final title = (data['title'] as String?) ?? 'Notification';
  final body = (data['message'] as String?) ?? (data['body'] as String?) ?? '';
  if (title.isEmpty && body.isEmpty) return;

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  final androidDetails = AndroidNotificationDetails(
    channel.id,
    channel.name,
    channelDescription: channel.description,
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    playSound: true,
    enableVibration: true,
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    NotificationDetails(android: androidDetails),
    payload: data['notification_id'] as String?,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  OrientationLock.setDefault();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      theme: AppTheme.theme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
