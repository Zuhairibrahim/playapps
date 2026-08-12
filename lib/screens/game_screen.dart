import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ad_manager.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/native_ad_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int squaresPerRow = 35;
  static const int squaresPerCol = 20;

  List<int> snakePosition = [45, 65, 85, 105];
  List<int> foodPositions = [];

  String direction = "right";
  Timer? gameTimer;

  int currentStage = 1;
  int pointsCollected = 0;
  final List<int> stagePointsRequired = [
    30, 44, 60, 78, 98, 120, 144, 170, 198, 228, 260, 294, 330, 300
  ];

  int get pointsToWin => currentStage <= stagePointsRequired.length
      ? stagePointsRequired[currentStage - 1]
      : 300;

  final AdManager _adManager = AdManager();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _adManager.loadAllAds();
    _adManager.startAutoInterstitial();
    _loadProgress();
  }

  Future<void> _saveProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_stage', currentStage);
  }

  Future<void> _loadProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentStage = prefs.getInt('current_stage') ?? 1;
      startGame(resetPoints: true);
    });
  }

  void startGame({bool resetPoints = false}) {
    snakePosition = [45, 65, 85, 105];
    direction = "right";
    foodPositions.clear();

    if (resetPoints) {
      pointsCollected = 0;
    }

    for (int i = 0; i < 25; i++) {
      generateNewFood();
    }

    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 160), (timer) {
      updateSnake();
      if (pointsCollected >= pointsToWin) {
        timer.cancel();
        _adManager.showInterstitialAd(
          onDismissed: () {
            _adManager.showRewardedInterstitialAd(
              onRewarded: () {},
            );
            showWinDialog();
          },
        );
      }
    });
  }

  void generateNewFood() {
    Random random = Random();
    int newFood = random.nextInt(squaresPerRow * squaresPerCol);
    while (snakePosition.contains(newFood) || foodPositions.contains(newFood)) {
      newFood = random.nextInt(squaresPerRow * squaresPerCol);
    }
    foodPositions.add(newFood);
  }

  void updateSnake() {
    setState(() {
      int head = snakePosition.last;

      int headX = head % squaresPerRow;
      int headY = head ~/ squaresPerRow;

      switch (direction) {
        case 'down':
          headY = (headY + 1) % squaresPerCol;
          break;
        case 'up':
          headY = (headY - 1 + squaresPerCol) % squaresPerCol;
          break;
        case 'left':
          headX = (headX - 1 + squaresPerRow) % squaresPerRow;
          break;
        case 'right':
          headX = (headX + 1) % squaresPerRow;
          break;
      }

      int newHead = headY * squaresPerRow + headX;

      for (int i = 0; i < snakePosition.length - 1; i++) {
        if (snakePosition[i] == newHead) {
          gameTimer?.cancel();
          _adManager.showInterstitialAd(
            onDismissed: () {
              _adManager.showRewardedAd(
                onRewarded: () {},
              );
              showGameOverDialog();
            },
          );
          return;
        }
      }

      snakePosition.add(newHead);

      if (foodPositions.contains(newHead)) {
        foodPositions.remove(newHead);
        pointsCollected++;
        generateNewFood();
      } else {
        snakePosition.removeAt(0);
      }
    });
  }

  void showGameOverDialog() {
    _adManager.loadInterstitialAd();
    _adManager.loadRewardedAd();
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text('انتهت اللعبة!', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('لقد اصطدمت بنفسك في المرحلة $currentStage.\nطولك النهائي: ${snakePosition.length}',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 18)),
              const SizedBox(height: 15),
              SizedBox(
                height: 250,
                child: NativeAdWidget(adUnitId: AdManager.nativeAdUnitId),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _adManager.showInterstitialAd(
                  onDismissed: () {
                    startGame(resetPoints: true);
                  },
                );
              },
              child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.greenAccent, fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void showWinDialog() {
    currentStage++;
    _saveProgress();
    _adManager.loadInterstitialAd();
    _adManager.loadRewardedAd();

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D3F),
          title: const Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 30),
              SizedBox(width: 10),
              Text('أحسنت!', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('لقد اتممت مهمتك بنجاح في المرحلة ${currentStage - 1}!',
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              SizedBox(
                height: 250,
                child: NativeAdWidget(adUnitId: AdManager.nativeAdUnitId),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _adManager.showInterstitialAd(
                    onDismissed: () {
                      _adManager.showRewardedInterstitialAd(
                        onRewarded: () {},
                      );
                      startGame(resetPoints: true);
                    },
                  );
                },
                child: Text('المضي للمرحلة $currentStage', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _adManager.stopAutoInterstitial();
    _adManager.disposeAll();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.yellowAccent, width: 4.0),
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: squaresPerRow * squaresPerCol,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: squaresPerRow),
                itemBuilder: (context, index) {
                  if (snakePosition.contains(index)) {
                    return Padding(
                      padding: const EdgeInsets.all(0.8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: index == snakePosition.last ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            if (index == snakePosition.last)
                              const BoxShadow(color: Colors.white, blurRadius: 6, spreadRadius: 1)
                          ],
                        ),
                      ),
                    );
                  } else if (foodPositions.contains(index)) {
                    return Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: Center(
                        child: Image.asset(
                          'assets/images/apple_real.png',
                          width: 25, height: 25,
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(0.8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF13131F),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: BannerAdWidget(adUnitId: AdManager.bannerAdUnitId),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: BannerAdWidget(adUnitId: AdManager.bannerAdUnitId),
            ),
          ),

          Positioned(
            top: 60,
            left: 10,
            child: SizedBox(
              width: 320,
              height: 300,
              child: NativeAdWidget(adUnitId: AdManager.nativeAdUnitId),
            ),
          ),

          Positioned(
            top: 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    _adManager.showInterstitialAd(
                      onDismissed: () {
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.yellowAccent.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'المرحلة: $currentStage  |  النقاط: $pointsCollected / $pointsToWin',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 20,
            left: 30,
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: FloatingActionButton(
                      heroTag: "up", mini: true, backgroundColor: Colors.white24,
                      onPressed: () {
                        _adManager.showInterstitialAd(
                          onDismissed: () {
                            if (direction != 'down') direction = 'up';
                          },
                        );
                      },
                      child: const Icon(Icons.arrow_upward, color: Colors.white),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FloatingActionButton(
                      heroTag: "down", mini: true, backgroundColor: Colors.white24,
                      onPressed: () {
                        _adManager.showInterstitialAd(
                          onDismissed: () {
                            if (direction != 'up') direction = 'down';
                          },
                        );
                      },
                      child: const Icon(Icons.arrow_downward, color: Colors.white),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FloatingActionButton(
                      heroTag: "right", mini: true, backgroundColor: Colors.white24,
                      onPressed: () {
                        _adManager.showInterstitialAd(
                          onDismissed: () {
                            if (direction != 'left') direction = 'right';
                          },
                        );
                      },
                      child: const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FloatingActionButton(
                      heroTag: "left", mini: true, backgroundColor: Colors.white24,
                      onPressed: () {
                        _adManager.showInterstitialAd(
                          onDismissed: () {
                            if (direction != 'right') direction = 'left';
                          },
                        );
                      },
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
