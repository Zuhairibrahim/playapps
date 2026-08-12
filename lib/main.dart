import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/game_screen.dart';
import 'services/ad_manager.dart';
import 'widgets/banner_ad_widget.dart';
import 'widgets/native_ad_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  MobileAds.instance.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const SnakeIoApp());
}

class SnakeIoApp extends StatefulWidget {
  const SnakeIoApp({super.key});

  @override
  State<SnakeIoApp> createState() => _SnakeIoAppState();
}

class _SnakeIoAppState extends State<SnakeIoApp> {
  final AdManager _adManager = AdManager();

  @override
  void initState() {
    super.initState();
    _adManager.loadAllAds();
  }

  @override
  void dispose() {
    _adManager.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snake.io',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF12121A),
        fontFamily: 'Cairo',
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.electric_bolt, size: 80, color: Colors.greenAccent),
            SizedBox(width: 30),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Snake.io',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Mobile Experience',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 20),
                CircularProgressIndicator(color: Colors.greenAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AdManager _adManager = AdManager();

  @override
  void initState() {
    super.initState();
    _adManager.loadAppOpenAd();
    _adManager.showAppOpenAdIfAvailable();
    _adManager.loadInterstitialAd();
    _adManager.loadRewardedAd();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videogame_asset, size: 50, color: Colors.greenAccent),
                      SizedBox(width: 15),
                      Text(
                        'Snake.io Mobile',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 250,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 5,
                      ),
                      onPressed: () {
                        _adManager.showInterstitialAd(
                          onDismissed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const GameScreen()),
                            );
                          },
                        );
                      },
                      child: const Text(
                        'ابدأ اللعب',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: BannerAdWidget(adUnitId: AdManager.bannerAdUnitId),
            ),
          ),

          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: BannerAdWidget(adUnitId: AdManager.bannerAdUnitId),
            ),
          ),

          Positioned(
            top: 70,
            right: 10,
            child: SizedBox(
              width: 320,
              height: 300,
              child: NativeAdWidget(adUnitId: AdManager.nativeAdUnitId),
            ),
          ),
        ],
      ),
    );
  }
}
