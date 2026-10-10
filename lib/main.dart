// ============================================================================
//  © 2026 Zuhair Ibrahim — ALL RIGHTS RESERVED | جميع الحقوق محفوظة © زهير إبراهيم
//  Project: PlayApps — ألعاب ومتعة
//  This code contains a proprietary embedded copyright fingerprint.
//  Selling, redistributing, or removing this notice is strictly forbidden.
//  ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads/ad_consent.dart';
import 'core/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/ad_manager.dart';
import 'services/game_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ترتيب Google الرسمي: موافقة -> تهيئة الإعلانات
  await AdConsent.instance.collectConsent();
  await MobileAds.instance.initialize();

  // تحميل إعدادات اللاعب المحلية
  await GameSettings.instance.load();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: AppTheme.bgDeep,
  ));

  runApp(const SnakeLuxApp());
}

class SnakeLuxApp extends StatefulWidget {
  const SnakeLuxApp({super.key});

  @override
  State<SnakeLuxApp> createState() => _SnakeLuxAppState();
}

class _SnakeLuxAppState extends State<SnakeLuxApp> with WidgetsBindingObserver {
  final AdManager _adManager = AdManager();
  AppLifecycleState _lastState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _adManager.loadAllAds();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _adManager.disposeAll();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // إعلان "فتح التطبيق" عند العودة من الخلفية
    if (state == AppLifecycleState.resumed &&
        _lastState == AppLifecycleState.paused) {
      _adManager.showAppOpenAdIfAvailable();
    }
    _lastState = state;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'لعبة الحنش المحترف',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppTheme.bgDeep,
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.neon,
          secondary: AppTheme.gold,
          surface: AppTheme.surface,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.transparent,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
