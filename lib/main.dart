import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'dashboardscreen.dart';
import 'discover_screen.dart';
import 'firebase_options.dart';
import 'Movie_Details.dart';
import 'profile_lists_screen.dart';
import 'services/app_settings.dart';
import 'splashscreen.dart';
import 'TVShows_Details.dart';
import 'TVShows_Model.dart';
import 'Upcomming_Movies_model.dart';

/// Global navigator key — used to navigate from notification tap outside widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Local notifications plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Android notification channel for FCM
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'cineverse_high_importance',
  'CineVerse Notifications',
  description: 'Notifications from CineVerse',
  importance: Importance.high,
);

/// Background message handler — must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Navigate based on notification data payload
/// Expected data keys:
///   screen: 'home' | 'discover' | 'reviews' | 'watchlist' | 'favorites'
///   mediaId, mediaType: for direct movie/show navigation
void _handleNotificationNavigation(Map<String, dynamic> data) {
  final screen = data['screen'] as String?;
  final mediaId = int.tryParse(data['mediaId'] ?? '');
  final mediaType = data['mediaType'] as String?;
  final mediaTitle = data['mediaTitle'] as String? ?? '';
  final posterPath = data['posterPath'] as String? ?? '';

  final context = navigatorKey.currentContext;
  if (context == null) return;

  final user = FirebaseAuth.instance.currentUser;
  final username = user?.displayName ?? user?.email ?? 'User';

  // If we have a mediaId, go directly to that movie/show detail screen
  if (mediaId != null && mediaType != null) {
    if (mediaType == 'movie') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => Moviedetails(
            movie: UpcomingMovies.fromJson({
              'id': mediaId,
              'title': mediaTitle,
              'original_title': mediaTitle,
              'poster_path': posterPath,
              'backdrop_path': '',
              'overview': '',
              'release_date': data['releaseDate'] ?? '',
              'vote_average': 0.0,
              'vote_count': 0,
              'popularity': 0.0,
              'genre_ids': [],
              'adult': false,
              'video': false,
            }),
          ),
        ),
      );
      return;
    } else if (mediaType == 'tv') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => TVShowsDetails(
            tvshowsdetails: PopularTvShows.fromJson({
              'id': mediaId,
              'name': mediaTitle,
              'original_name': mediaTitle,
              'poster_path': posterPath,
              'backdrop_path': '',
              'overview': '',
              'first_air_date': data['releaseDate'] ?? '',
              'vote_average': 0.0,
              'vote_count': 0,
              'popularity': 0.0,
              'genre_ids': [],
              'origin_country': [],
              'original_language': 'en',
              'adult': false,
            }),
          ),
        ),
      );
      return;
    }
  }

  // Otherwise navigate by screen name
  switch (screen) {
    case 'discover':
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const DiscoverScreen()),
      );
      break;
    case 'reviews':
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ProfileListsScreen(
            listType: 'reviews',
            title: 'My Reviews',
          ),
        ),
      );
      break;
    case 'watchlist':
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ProfileListsScreen(
            listType: 'watchlist',
            title: 'Watchlist',
          ),
        ),
      );
      break;
    case 'favorites':
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ProfileListsScreen(
            listType: 'favorites',
            title: 'Favorites',
          ),
        ),
      );
      break;
    case 'home':
    default:
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(username: username),
        ),
        (route) => false,
      );
      break;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Local Notifications setup ──────────────────────────────────────────────
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
    // Foreground notification tap handler
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      final payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        _handleNotificationNavigation({'screen': payload});
      }
    },
  );

  // ── FCM setup ──────────────────────────────────────────────────────────────
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Foreground: show banner + store payload for tap navigation
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;
    final screen = message.data['screen'] ?? 'home';

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: screen, // passed to onDidReceiveNotificationResponse on tap
      );
    }
  });

  // Background/killed: app opened via notification tap
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationNavigation(message.data);
  });

  // Killed state: check if app was launched from a notification
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    // Delay slightly to ensure navigator is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationNavigation(initialMessage.data);
    });
  }

  // ── Settings sync ──────────────────────────────────────────────────────────
  await AppSettings.syncFromFirestore();

  // Print FCM token for testing (remove before production)
  final fcmToken = await FirebaseMessaging.instance.getToken();
  debugPrint('🔔 FCM Token: $fcmToken');

  // ── UI setup ───────────────────────────────────────────────────────────────
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.navBg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CineVerse',
      navigatorKey: navigatorKey, // global key for notification navigation
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: AppTheme.accent,
          surface: AppTheme.surface,
          background: AppTheme.background,
        ),
        scaffoldBackgroundColor: AppTheme.background,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.background,
          elevation: 0,
          iconTheme: IconThemeData(color: AppTheme.textPrimary),
          titleTextStyle: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const splashscreen(),
    );
  }
}
