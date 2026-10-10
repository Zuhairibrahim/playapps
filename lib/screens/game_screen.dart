// ============================================================================
//  © 2026 Zuhair Ibrahim — ALL RIGHTS RESERVED | جميع الحقوق محفوظة © زهير إبراهيم
//  GAME SOURCE — OWNERSHIP PROTECTED | كود اللعبة محمي بحقوق الملكية
//  This game source code is proprietary. Selling, reselling, redistributing
//  or republishing it (modified or not) is strictly forbidden (see LICENSE).
//  It contains embedded ownership keys that must NOT be removed or altered.
//  بيع أو توزيع أو إعادة نشر هذا الكود ممنوع منعاً باتاً — إزالة مفاتيح
//  الملكية بداخله مخالفة قانونية تعرّض المخالف للمساءلة و DMCA.
// ============================================================================

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';
import '../services/ad_manager.dart';
import '../services/game_settings.dart';
import '../services/sfx.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/native_ad_widget.dart';
import '../core/ownership/ownership_guard.dart';

// ============================================================
//  نموذج بيانات اللعبة
// ============================================================

enum _FoodKind { apple, golden, gem }

class _Food {
  final int cell;
  final _FoodKind kind;
  final double bornAt;
  final double? expiresAt;

  const _Food(this.cell, this.kind, this.bornAt, {this.expiresAt});
}

class _Particle {
  Offset pos; // بإحداثيات الخلايا
  Offset vel;
  Color color;
  double life; // 1 -> 0
  double maxLife;
  double size;
  bool gravity;

  _Particle({
    required this.pos,
    required this.vel,
    required this.color,
    required this.life,
    required this.size,
    this.gravity = false,
  }) : maxLife = life;
}

// ============================================================
//  شاشة اللعبة
// ============================================================

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ===== اللوحة =====
  static const int cols = 35;
  static const int rows = 20;
  static const List<int> stageGoals = [
    30, 44, 60, 78, 98, 120, 144, 170, 198, 228, 260, 294, 330, 320
  ];

  // ===== حالة المحرك =====
  List<int> snake = [];
  List<int> prevSnake = [];
  final Map<int, _Food> foods = {};
  String dir = 'right';
  String queuedDir = 'right';
  double stepMs = 170;
  double accumulator = 0;
  double interp = 0;
  double gameTime = 0;
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  final Random rng = Random();

  bool running = false;
  bool paused = false;
  bool dying = false;
  double deathT = 0;
  bool won = false;
  double reviveInvincible = 0;
  bool reviveUsed = false;

  // ===== النقاط =====
  int stage = 1;
  int goal = 30;
  int points = 0;
  int score = 0;
  int applesEaten = 0;
  int combo = 0;
  int maxCombo = 0;
  double lastEatTime = -99;
  int get comboMult => min(5, 1 + combo ~/ 4);

  // ===== المؤثرات =====
  final List<_Particle> particles = [];
  double shake = 0;
  double _goldenTimer = 0;
  double _gemTimer = 0;

  // ===== التحكم =====
  late final FocusNode _focusNode;

  final AdManager _ads = AdManager();

  // ===== مفتاح الملكية داخل كود اللعبة (لا يُحذف ولا يُعدّل) =====
  // Embedded game ownership key — integral license part (see LICENSE).
  static const String kGameOwnershipKey =
      'OWNER:Zuhair-Ibrahim|PROJECT:playapps-game|YEAR:2026|'
      'LICENSE:ALL-RIGHTS-RESERVED|SIG:ZI-2026-PLA-PROPRIETARY';

  /// بصمة مشفّرة إضافية داخل اللعبة (ترميز Char Codes).
  static const List<int> _gameSeal = <int>[
    79,87,78,69,82,58,90,117,104,97,105,114,45,73,98,114,97,104,105,109,
    124,83,73,71,58,90,73,45,50,48,50,54,45,80,76,65,45,80,82,79,80,82,
    73,69,84,65,82,89
  ];

  // ============================================================
  //  دورة الحياة
  // ============================================================

  @override
  void initState() {
    super.initState();
    // فحص تكامل مفاتيح الملكية — جزء لا يتجزأ من شروط الترخيص (LICENSE)
    assert(
      kGameOwnershipKey.endsWith(ownershipSignature()) &&
          String.fromCharCodes(_gameSeal).contains('Zuhair-Ibrahim') &&
          ownershipSealsIntact(),
      'Game ownership keys must remain intact — see LICENSE',
    );
    WidgetsBinding.instance.addObserver(this);
    _focusNode = FocusNode();
    stage = GameSettings.instance.currentStage;
    goal = _goalFor(stage);
    stepMs = _speedFor(stage);
    _ads.loadAllAds();
    _resetBoard();
    Future.microtask(() => _showStartOverlay());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.dispose();
    _focusNode.dispose();
    _ads.stopAutoInterstitial();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && running && !paused && !dying) {
      _openPause();
    }
  }

  int _goalFor(int s) => s <= stageGoals.length ? stageGoals[s - 1] : 320;
  double _speedFor(int s) => max(80.0, 175.0 - (s - 1) * 7.0);

  // ============================================================
  //  المحرك
  // ============================================================

  void _resetBoard() {
    snake = [45, 65, 85, 105];
    prevSnake = List<int>.from(snake);
    foods.clear();
    particles.clear();
    dir = 'right';
    queuedDir = 'right';
    accumulator = 0;
    interp = 0;
    dying = false;
    deathT = 0;
    won = false;
    points = 0;
    score = 0;
    applesEaten = 0;
    combo = 0;
    maxCombo = 0;
    lastEatTime = -99;
    reviveUsed = false;
    reviveInvincible = 0;
    shake = 0;
    for (int i = 0; i < 20; i++) {
      _spawnFood(_FoodKind.apple);
    }
  }

  void _startRun() {
    _resetBoard();
    stepMs = _speedFor(stage);
    goal = _goalFor(stage);
    _ticker?.dispose();
    _lastTick = Duration.zero;
    accumulator = 0;
    running = true;
    paused = false;
    setState(() {});
    _ticker = createTicker(_onTick)..start();
    _focusNode.requestFocus();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.5) return;
    if (!running || paused || won) return;

    if (dying) {
      deathT += dt / 0.9;
      shake = max(0, shake - dt * 2.2);
      _updateParticles(dt);
      if (deathT >= 1) {
        deathT = 1;
        _ticker?.stop();
        _onDeathFinished();
      }
      setState(() {});
      return;
    }

    gameTime += dt;
    reviveInvincible = max(0, reviveInvincible - dt);

    // منطق ثابت الخطوة + تراكم للتحديث الناعم
    accumulator += dt * 1000;
    while (accumulator >= stepMs) {
      accumulator -= stepMs;
      _step();
      if (dying || won) break;
    }
    interp = dying ? 1.0 : (accumulator / stepMs).clamp(0.0, 1.0);

    // ظهور الذهبي والجواهر
    _goldenTimer += dt;
    _gemTimer += dt;
    if (_goldenTimer > 7) {
      _goldenTimer = 0;
      if (foods.values.where((f) => f.kind == _FoodKind.golden).length < 2) {
        _spawnFood(_FoodKind.golden);
      }
    }
    if (_gemTimer > 13) {
      _gemTimer = 0;
      if (!foods.values.any((f) => f.kind == _FoodKind.gem)) {
        _spawnFood(_FoodKind.gem);
      }
    }

    // انتهاء صلاحية الأطعمة الخاصة
    foods.removeWhere((_, f) {
      if (f.expiresAt != null && gameTime > f.expiresAt!) return true;
      return false;
    });

    shake = max(0, shake - dt * 2.2);
    _updateParticles(dt);
    setState(() {});
  }

  void _step() {
    dir = queuedDir;
    int head = snake.last;
    int hx = head % cols;
    int hy = head ~/ cols;

    switch (dir) {
      case 'up':
        hy = (hy - 1 + rows) % rows;
      case 'down':
        hy = (hy + 1) % rows;
      case 'left':
        hx = (hx - 1 + cols) % cols;
      case 'right':
        hx = (hx + 1) % cols;
    }
    int newHead = hy * cols + hx;

    // اصطدام بالجسد (الذيل يتحرك بعيداً لذا نتجاهله إن لم ننمُ)
    final eating = foods.containsKey(newHead);
    for (int i = 0; i < snake.length - (eating ? 0 : 1); i++) {
      if (snake[i] == newHead) {
        _die();
        return;
      }
    }

    prevSnake = List<int>.from(snake);
    snake.add(newHead);

    if (eating) {
      _eat(foods.remove(newHead)!, newHead);
    } else {
      snake.removeAt(0);
    }
  }

  void _eat(_Food food, int cell) {
    // الكومبو
    if (gameTime - lastEatTime < 2.2) {
      combo++;
    } else {
      combo = 1;
    }
    lastEatTime = gameTime;
    maxCombo = max(maxCombo, combo);
    final mult = comboMult;

    final base = switch (food.kind) {
      _FoodKind.apple => 1,
      _FoodKind.golden => 5,
      _FoodKind.gem => 10,
    };
    final gained = base * mult;
    points += gained;
    score += gained;
    applesEaten++;

    // مؤثرات
    final color = switch (food.kind) {
      _FoodKind.apple => AppTheme.neonLight,
      _FoodKind.golden => AppTheme.gold,
      _FoodKind.gem => AppTheme.gem,
    };
    _burst(cell, color, food.kind == _FoodKind.apple ? 10 : 22);
    if (food.kind == _FoodKind.apple) {
      Sfx.eat();
      Sfx.impact();
    } else if (food.kind == _FoodKind.golden) {
      Sfx.golden();
      Sfx.impact();
    } else {
      Sfx.gem();
      Sfx.heavy();
      shake = max(shake, 0.35);
    }

    if (food.kind == _FoodKind.apple) {
      _spawnFood(_FoodKind.apple);
    }

    if (points >= goal) {
      _win();
    }
  }

  void _die() {
    if (reviveInvincible > 0) return;
    dying = true;
    deathT = 0;
    shake = 1;
    Sfx.death();
    Sfx.heavy();
    // انفجار على طول الجسد
    for (int i = 0; i < snake.length; i += 2) {
      _burst(snake[i], AppTheme.neon, 4, spread: 1.6);
    }
  }

  void _onDeathFinished() {
    running = false;
    GameSettings.instance.recordRun(score: score, apples: applesEaten);

    // إعلان بيني عند كل خسارة (مع احترام الفاصل الزمني في AdManager)
    _ads.showInterstitialAd(onDismissed: _showGameOverDialog);
  }

  void _win() {
    won = true;
    running = false;
    _ticker?.stop();
    Sfx.win();
    Sfx.heavy();
    GameSettings.instance.recordRun(score: score, apples: applesEaten);
    GameSettings.instance.setStage(stage + 1);
    // احتفال
    for (int i = 0; i < 8; i++) {
      _burst(
        rng.nextInt(cols * rows),
        [AppTheme.neonLight, AppTheme.gold, AppTheme.gem, Colors.white][i % 4],
        16,
        spread: 3,
      );
    }
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _showWinDialog();
    });
  }

  void _revive() {
    reviveUsed = true;
    // قصّ الثعبان للنصف والاستمرار
    if (snake.length > 8) {
      snake = snake.sublist(snake.length ~/ 2);
    }
    prevSnake = List<int>.from(snake);
    dying = false;
    deathT = 0;
    reviveInvincible = 2.5;
    combo = 0;
    accumulator = 0;
    running = true;
    _lastTick = Duration.zero;
    _ticker?.start();
    _focusNode.requestFocus();
  }

  // ============================================================
  //  الأطعمة والجسيمات
  // ============================================================

  void _spawnFood(_FoodKind kind) {
    if (foods.length > 60) return;
    int cell = rng.nextInt(cols * rows);
    while (snake.contains(cell) || foods.containsKey(cell)) {
      cell = rng.nextInt(cols * rows);
    }
    foods[cell] = _Food(
      cell,
      kind,
      gameTime,
      expiresAt: switch (kind) {
        _FoodKind.apple => null,
        _FoodKind.golden => gameTime + 10,
        _FoodKind.gem => gameTime + 7,
      },
    );
  }

  void _burst(int cell, Color color, int count, {double spread = 1.0}) {
    final x = cell % cols + 0.5;
    final y = cell ~/ cols + 0.5;
    for (int i = 0; i < count; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = (0.8 + rng.nextDouble() * 3.2) * spread;
      particles.add(_Particle(
        pos: Offset(x, y),
        vel: Offset(cos(angle), sin(angle)) * speed,
        color: color,
        life: 0.5 + rng.nextDouble() * 0.5,
        size: 0.06 + rng.nextDouble() * 0.10,
        gravity: true,
      ));
    }
  }

  void _updateParticles(double dt) {
    particles.removeWhere((p) {
      p.life -= dt;
      if (p.life <= 0) return true;
      p.pos += p.vel * dt;
      if (p.gravity) p.vel += const Offset(0, 2.4) * dt;
      return false;
    });
  }

  // ============================================================
  //  التحكم
  // ============================================================

  void _setDir(String d) {
    const opposites = {
      'up': 'down', 'down': 'up', 'left': 'right', 'right': 'left',
    };
    if (opposites[d] == dir) return;
    queuedDir = d;
  }

  void _onSwipe(DragUpdateDetails d) {
    final delta = d.delta;
    if (delta.distance < 4) return;
    if (delta.dx.abs() > delta.dy.abs()) {
      _setDir(delta.dx > 0 ? 'right' : 'left');
    } else {
      _setDir(delta.dy > 0 ? 'down' : 'up');
    }
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      _setDir('up');
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyS) {
      _setDir('down');
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyA) {
      _setDir('left');
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      _setDir('right');
    } else if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.escape) {
      if (running && !dying && !won) {
        paused ? _resume() : _openPause();
      }
    }
    // لا نُرجع قيمة — KeyboardListener يتوقع ValueChanged<KeyEvent>
  }

  // ============================================================
  //  الواجهات المنبثقة
  // ============================================================

  void _showStartOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => _LuxDialog(
        icon: Icons.play_arrow_rounded,
        iconColor: AppTheme.neon,
        title: 'المرحلة $stage',
        subtitle: 'اجمع $goal نقطة لإكمال المرحلة',
        child: NeonButton(
          label: 'انطلق!',
          width: 220,
          height: 54,
          pulse: true,
          gradient: AppTheme.neonGradient,
          onPressed: () {
            Navigator.pop(ctx);
            _startRun();
          },
        ),
      ),
    );
  }

  void _openPause() {
    if (!running || dying || won) return;
    paused = true;
    _ticker?.stop();
    Sfx.tap();
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (ctx) => _LuxDialog(
        icon: Icons.pause_circle_rounded,
        iconColor: AppTheme.gold,
        title: 'إيقاف مؤقت',
        subtitle: 'المرحلة $stage • النقاط $points/$goal',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 300,
              height: 110,
              child: NativeAdWidget(adUnitId: AdManager.nativeAdUnitId),
            ),
            const SizedBox(height: 12),
            NeonButton(
              label: 'استئناف',
              icon: Icons.play_arrow_rounded,
              width: 230,
              height: 50,
              gradient: AppTheme.neonGradient,
              onPressed: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 10),
            NeonButton(
              label: 'إعادة المحاولة',
              icon: Icons.restart_alt_rounded,
              width: 230,
              height: 46,
              fontSize: 15,
              gradient: LinearGradient(
                colors: [AppTheme.surfaceHigh, AppTheme.surface],
              ),
              textColor: AppTheme.textPrimary,
              glowColor: AppTheme.textFaint,
              onPressed: () {
                Navigator.pop(ctx);
                _startRun();
              },
            ),
            const SizedBox(height: 10),
            NeonButton(
              label: 'القائمة الرئيسية',
              icon: Icons.home_rounded,
              width: 230,
              height: 46,
              fontSize: 15,
              gradient: LinearGradient(
                colors: [AppTheme.surfaceHigh, AppTheme.surface],
              ),
              textColor: AppTheme.textPrimary,
              glowColor: AppTheme.textFaint,
              onPressed: () {
                Navigator.pop(ctx);
                // إعلان بيني عند الخروج (مع احترام الفاصل الزمني)
                _ads.showInterstitialAd(
                  onDismissed: () {
                    if (mounted) Navigator.pop(context);
                  },
                );
              },
            ),
          ],
        ),
      ),
    ).then((_) {
      if (mounted && !dying && !won) _resume();
    });
  }

  void _resume() {
    if (!paused) return;
    paused = false;
    _lastTick = Duration.zero;
    accumulator = 0;
    _ticker?.start();
    _focusNode.requestFocus();
  }

  void _showGameOverDialog() {
    if (!mounted) return;
    final s = GameSettings.instance;
    final isRecord = score > 0 && score >= s.highScore;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (ctx) => _LuxDialog(
        icon: Icons.heart_broken_rounded,
        iconColor: AppTheme.danger,
        title: 'انتهت الجولة!',
        subtitle: isRecord
            ? 'رقم قياسي جديد! $score نقطة'
            : 'اصطدمت بنفسك في المرحلة $stage',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatsRow(
              score: score,
              apples: applesEaten,
              combo: maxCombo,
              length: snake.length,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 300,
              height: 120,
              child: NativeAdWidget(adUnitId: AdManager.nativeAdUnitId),
            ),
            const SizedBox(height: 12),
            if (!reviveUsed)
              NeonButton(
                label: 'أحيِ ثعبانك (إعلان)',
                icon: Icons.favorite_rounded,
                width: 250,
                height: 48,
                fontSize: 15,
                pulse: true,
                gradient: AppTheme.goldGradient,
                glowColor: AppTheme.gold,
                textColor: const Color(0xFF1A1000),
                onPressed: () {
                  Navigator.pop(ctx);
                  _ads.showRewardedAd(onRewarded: _revive);
                },
              ),
            if (!reviveUsed) const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NeonButton(
                  label: 'إعادة',
                  icon: Icons.refresh_rounded,
                  width: 140,
                  height: 46,
                  fontSize: 15,
                  gradient: AppTheme.neonGradient,
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startRun();
                  },
                ),
                const SizedBox(width: 10),
                NeonButton(
                  label: 'الرئيسية',
                  icon: Icons.home_rounded,
                  width: 140,
                  height: 46,
                  fontSize: 15,
                  gradient: LinearGradient(
                    colors: [AppTheme.surfaceHigh, AppTheme.surface],
                  ),
                  textColor: AppTheme.textPrimary,
                  glowColor: AppTheme.textFaint,
                  onPressed: () {
                    Navigator.pop(ctx);
                    // إعلان بيني عند العودة للقائمة (مع احترام الفاصل الزمني)
                    _ads.showInterstitialAd(
                      onDismissed: () {
                        if (mounted) Navigator.pop(context);
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showWinDialog() {
    // النجوم: 1 أساسي + نقاط إضافية للطول والكومبو
    int stars = 1;
    if (snake.length >= goal) stars++;
    if (maxCombo >= 8) stars++;
    if (score >= goal * 2) stars = 3;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (ctx) => _LuxDialog(
        icon: Icons.emoji_events_rounded,
        iconColor: AppTheme.gold,
        title: 'أُكملت المرحلة $stage!',
        subtitle: 'انطلق الآن نحو المرحلة ${stage + 1}',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StarsRow(stars: stars),
            const SizedBox(height: 12),
            _StatsRow(
              score: score,
              apples: applesEaten,
              combo: maxCombo,
              length: snake.length,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 300,
              height: 120,
              child: NativeAdWidget(adUnitId: AdManager.nativeAdUnitId),
            ),
            const SizedBox(height: 12),
            // مكافأة مضاعفة النقاط — إعلان مكافأة بيني
            NeonButton(
              label: 'ضاعف نقاطك ×2 (إعلان)',
              icon: Icons.auto_awesome_rounded,
              width: 260,
              height: 48,
              fontSize: 14.5,
              pulse: true,
              gradient: AppTheme.goldGradient,
              glowColor: AppTheme.gold,
              textColor: const Color(0xFF1A1000),
              onPressed: () {
                Navigator.pop(ctx);
                _ads.showRewardedInterstitialAd(
                  onRewarded: () {
                    score *= 2;
                    GameSettings.instance.addScore(score);
                    Sfx.win();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('مبروك! نقاطك الآن $score',
                              style: AppTheme.font(size: 14)),
                          backgroundColor: AppTheme.surface,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            NeonButton(
              label: 'المستوى التالي',
              icon: Icons.arrow_forward_rounded,
              width: 260,
              height: 52,
              gradient: AppTheme.neonGradient,
              onPressed: () {
                Navigator.pop(ctx);
                // إعلان بيني قبل المستوى التالي (مع احترام الفاصل الزمني)
                _ads.showInterstitialAd(
                  onDismissed: () {
                    if (!mounted) return;
                    stage++;
                    goal = _goalFor(stage);
                    _startRun();
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                // إعلان بيني عند العودة للقائمة (مع احترام الفاصل الزمني)
                _ads.showInterstitialAd(
                  onDismissed: () {
                    if (mounted) Navigator.pop(context);
                  },
                );
              },
              child: Text('العودة للقائمة الرئيسية',
                  style: AppTheme.font(size: 13, color: AppTheme.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  البناء
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final settings = GameSettings.instance;
    final showDpad = settings.controlMode == ControlMode.dpad ||
        settings.controlMode == ControlMode.both;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _openPause();
          },
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHud(),
                Expanded(
                  child: KeyboardListener(
                    focusNode: _focusNode,
                    onKeyEvent: _onKey,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final boardW = min(
                          constraints.maxWidth,
                          constraints.maxHeight * cols / rows,
                        );
                        return Stack(
                          children: [
                            // ساحة اللعب
                            Center(
                              child: GestureDetector(
                                onPanUpdate:
                                    settings.controlMode == ControlMode.dpad
                                        ? null
                                        : _onSwipe,
                                onTap: _focusNode.requestFocus,
                                child: SizedBox(
                                  width: boardW,
                                  height: boardW * rows / cols,
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      painter: _GamePainter(
                                        snake: snake,
                                        prevSnake: prevSnake,
                                        foods: foods,
                                        particles: particles,
                                        interp: interp,
                                        dying: dying,
                                        deathT: deathT,
                                        won: won,
                                        shake: shake,
                                        gameTime: gameTime,
                                        invincible: reviveInvincible > 0,
                                        blinkPhase: reviveInvincible,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // أزرار الاتجاهات
                            if (showDpad)
                              Positioned(
                                bottom: 14,
                                left: 18,
                                child: _DPad(onDir: _setDir),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                // بانر سفلي فقط — لتجربة لعب انغماسية
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: const Center(
                    child: BannerAdWidget(adUnitId: AdManager.bannerAdUnitId),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHud() {
    final progress = (points / goal).clamp(0.0, 1.0);
    final showCombo = comboMult > 1 && !dying;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          // إيقاف مؤقت
          _HudIcon(
            icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            onTap: () => paused ? _resume() : _openPause(),
          ),
          const SizedBox(width: 10),

          // شريط تقدم المرحلة
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المرحلة $stage',
                      style: AppTheme.font(size: 13, weight: FontWeight.w800),
                    ),
                    Text(
                      '$points / $goal',
                      style: AppTheme.font(
                        size: 12.5,
                        color: AppTheme.textSecondary,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Container(
                        height: 14,
                        color: AppTheme.surfaceHigh.withValues(alpha: 0.9),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.neon,
                                AppTheme.neonLight,
                                AppTheme.gold,
                              ],
                            ),
                            boxShadow: AppTheme.glowNeon,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.neon.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // النقاط
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            radius: 14,
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppTheme.gold, size: 19),
                const SizedBox(width: 7),
                Text(
                  '$score',
                  style: AppTheme.font(size: 16, weight: FontWeight.w800),
                ),
              ],
            ),
          ),

          // الكومبو
          AnimatedScale(
            scale: showCombo ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: showCombo
                  ? Padding(
                      key: ValueKey(comboMult),
                      padding: const EdgeInsets.only(right: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 7),
                        radius: 14,
                        borderColor: AppTheme.gold,
                        child: Row(
                          children: [
                            const Icon(Icons.bolt_rounded,
                                color: AppTheme.gold, size: 19),
                            const SizedBox(width: 6),
                            Text(
                              'x$comboMult',
                              style: AppTheme.font(
                                size: 15,
                                weight: FontWeight.w900,
                                color: AppTheme.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(width: 0),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  عناصر HUD
// ============================================================

class _HudIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HudIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surface.withValues(alpha: 0.7),
          border: Border.all(color: AppTheme.neon.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: AppTheme.neonLight, size: 22),
      ),
    );
  }
}

class _DPad extends StatelessWidget {
  final ValueChanged<String> onDir;

  const _DPad({required this.onDir});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 130,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _dirBtn(Icons.arrow_upward_rounded, 'up'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dirBtn(Icons.arrow_back_rounded, 'left'),
              const SizedBox(width: 8),
              _dirBtn(Icons.arrow_forward_rounded, 'right'),
            ],
          ),
          _dirBtn(Icons.arrow_downward_rounded, 'down'),
        ],
      ),
    );
  }

  Widget _dirBtn(IconData icon, String d) {
    return GestureDetector(
      onTap: () {
        Sfx.tap();
        onDir(d);
      },
      child: Container(
        margin: const EdgeInsets.all(3),
        width: 44,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.neon.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(color: AppTheme.neon.withValues(alpha: 0.12), blurRadius: 8),
          ],
        ),
        child: Icon(icon, color: AppTheme.neonLight, size: 20),
      ),
    );
  }
}

// ============================================================
//  مربعات الحوار الفخمة
// ============================================================

class _LuxDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  const _LuxDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        padding: const EdgeInsets.all(22),
        borderColor: iconColor,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 460, maxWidth: 380),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [
                      iconColor.withValues(alpha: 0.3),
                      iconColor.withValues(alpha: 0.08),
                    ]),
                    border: Border.all(color: iconColor.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.35),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: iconColor, size: 34),
                ),
                const SizedBox(height: 14),
                Text(title,
                    style: AppTheme.font(size: 21, weight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTheme.font(size: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int score;
  final int apples;
  final int combo;
  final int length;

  const _StatsRow({
    required this.score,
    required this.apples,
    required this.combo,
    required this.length,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _stat(Icons.stars_rounded, '$score', 'النقاط', AppTheme.gold),
        _stat(Icons.apple_rounded, '$apples', 'تفاحة', AppTheme.danger),
        _stat(Icons.bolt_rounded, 'x${max(1, combo)}', 'أقصى كومبو', AppTheme.gem),
        _stat(Icons.straighten_rounded, '$length', 'الطول', AppTheme.neon),
      ],
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      radius: 14,
      borderColor: color,
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.font(size: 14, weight: FontWeight.w800)),
          Text(label, style: AppTheme.font(size: 9.5, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  final int stars;

  const _StarsRow({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final earned = i < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            earned ? Icons.star_rounded : Icons.star_outline_rounded,
            color: earned ? AppTheme.gold : AppTheme.textFaint,
            size: 46,
            shadows: earned
                ? [Shadow(color: AppTheme.gold.withValues(alpha: 0.8), blurRadius: 18)]
                : null,
          ),
        );
      }),
    );
  }
}

// ============================================================
//  الرسّام — محرك العرض الحديث
// ============================================================

class _GamePainter extends CustomPainter {
  final List<int> snake;
  final List<int> prevSnake;
  final Map<int, _Food> foods;
  final List<_Particle> particles;
  final double interp;
  final bool dying;
  final double deathT;
  final bool won;
  final double shake;
  final double gameTime;
  final bool invincible;
  final double blinkPhase;

  static const int cols = _GameScreenState.cols;
  static const int rows = _GameScreenState.rows;

  _GamePainter({
    required this.snake,
    required this.prevSnake,
    required this.foods,
    required this.particles,
    required this.interp,
    required this.dying,
    required this.deathT,
    required this.won,
    required this.shake,
    required this.gameTime,
    required this.invincible,
    required this.blinkPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / cols;
    final rnd = Random(42);

    // اهتزاز الشاشة
    if (shake > 0.01) {
      canvas.translate(
        (rnd.nextDouble() - 0.5) * shake * 14,
        (rnd.nextDouble() - 0.5) * shake * 14,
      );
    }

    _paintBackground(canvas, size, cell);
    _paintFoods(canvas, size, cell);
    _paintSnake(canvas, size, cell);
    _paintParticles(canvas, size, cell);
  }

  // ---------- الخلفية ----------
  void _paintBackground(Canvas canvas, Size size, double cell) {
    final rect = Offset.zero & size;

    // تدرج داكن
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1024), Color(0xFF060A18), Color(0xFF03050F)],
        ).createShader(rect),
    );

    // توهجات نيون خفيفة تتنفس
    final breath = 0.5 + 0.5 * sin(gameTime * 0.7);
    for (final (i, c) in [
      AppTheme.neonDark,
      const Color(0xFF2E3B8F),
      AppTheme.goldDark,
    ].indexed) {
      final center = Offset(
        size.width * (0.2 + 0.3 * i),
        size.height * (0.3 + 0.25 * ((i + 1) % 2)),
      );
      canvas.drawCircle(
        center,
        size.width * 0.28,
        Paint()
          ..shader = RadialGradient(colors: [
            c.withValues(alpha: 0.05 + 0.03 * breath),
            c.withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(
            center: center,
            radius: size.width * 0.28,
          )),
      );
    }

    // الشبكة
    final grid = Paint()
      ..color = AppTheme.neon.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    for (int x = 0; x <= cols; x++) {
      canvas.drawLine(Offset(x * cell, 0), Offset(x * cell, size.height), grid);
    }
    for (int y = 0; y <= rows; y++) {
      canvas.drawLine(Offset(0, y * cell), Offset(size.width, y * cell), grid);
    }

    // إطار متوهج
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppTheme.neon.withValues(alpha: 0.25),
    );

    // فينيت
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.1,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
        ).createShader(rect),
    );
  }

  // ---------- الأطعمة ----------
  void _paintFoods(Canvas canvas, Size size, double cell) {
    foods.forEach((_, f) {
      final cx = (f.cell % cols + 0.5) * cell;
      final cy = (f.cell ~/ cols + 0.5) * cell;
      final center = Offset(cx, cy);

      // نبض ووميض قرب الانتهاء
      double pulse = 0.5 + 0.5 * sin(gameTime * 3 + f.cell);
      double alpha = 1.0;
      if (f.expiresAt != null) {
        final remaining = f.expiresAt! - gameTime;
        if (remaining < 2) {
          alpha = 0.35 + 0.65 * (sin(gameTime * 12) > 0 ? 1 : 0.2);
        }
      }

      final Color color;
      final double r;
      switch (f.kind) {
        case _FoodKind.apple:
          color = AppTheme.neonLight;
          r = cell * 0.34;
        case _FoodKind.golden:
          color = AppTheme.gold;
          r = cell * 0.42;
        case _FoodKind.gem:
          color = AppTheme.gem;
          r = cell * 0.40;
      }

      // هالة
      canvas.drawCircle(
        center,
        r * (1.6 + 0.5 * pulse),
        Paint()
          ..color = color.withValues(alpha: 0.16 * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );

      if (f.kind == _FoodKind.gem) {
        // جوهرة معينية دوّارة
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(gameTime * 1.4);
        final diamond = Path()
          ..moveTo(0, -r)
          ..lineTo(r * 0.72, 0)
          ..lineTo(0, r)
          ..lineTo(-r * 0.72, 0)
          ..close();
        canvas.drawPath(
          diamond,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: alpha),
                color.withValues(alpha: alpha),
                const Color(0xFF0E7490).withValues(alpha: alpha),
              ],
            ).createShader(Rect.fromCircle(center: center, radius: r)),
        );
        canvas.drawPath(
          diamond,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = Colors.white.withValues(alpha: 0.5 * alpha),
        );
        canvas.restore();
      } else {
        // تفاحة / تفاحة ذهبية
        final body = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.4),
            colors: [
              Colors.white.withValues(alpha: 0.9 * alpha),
              color.withValues(alpha: alpha),
              (f.kind == _FoodKind.golden ? AppTheme.goldDark : AppTheme.neonDark)
                  .withValues(alpha: alpha),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: r * (0.92 + pulse * 0.1)));
        canvas.drawCircle(center, r * (0.92 + pulse * 0.1), body);

        // لمعة
        canvas.drawCircle(
          center + Offset(-r * 0.3, -r * 0.35),
          r * 0.22,
          Paint()..color = Colors.white.withValues(alpha: 0.75 * alpha),
        );

        // ورقة
        final leaf = Path()
          ..moveTo(center.dx, center.dy - r)
          ..quadraticBezierTo(
            center.dx + r * 0.7, center.dy - r * 1.5,
            center.dx + r * 0.35, center.dy - r * 1.75,
          )
          ..quadraticBezierTo(
            center.dx - r * 0.2, center.dy - r * 1.3,
            center.dx, center.dy - r,
          );
        canvas.drawPath(
          leaf,
          Paint()..color = const Color(0xFF2ECC71).withValues(alpha: alpha),
        );

        // بريق حول الذهبية
        if (f.kind == _FoodKind.golden) {
          for (int s = 0; s < 4; s++) {
            final ang = gameTime * 1.8 + s * pi / 2;
            final spark = Offset(
              center.dx + cos(ang) * r * 1.9,
              center.dy + sin(ang) * r * 1.9,
            );
            canvas.drawCircle(
              spark,
              1.6 + pulse,
              Paint()..color = Colors.white.withValues(alpha: 0.7 * alpha * pulse),
            );
          }
        }
      }
    });
  }

  // ---------- الثعبان ----------
  void _paintSnake(Canvas canvas, Size size, double cell) {
    if (snake.isEmpty) return;

    // مواضع مستوّاة (تحريك ناعم بين الخطوات)
    final List<Offset> pts = [];
    final n = snake.length;
    for (int i = 0; i < n; i++) {
      final cur = _center(snake[i], cell);
      final prev = i < prevSnake.length ? _center(prevSnake[i], cell) : cur;
      // عند الالتفاف عبر الحواف لا نستوفي (قفزة)
      if ((cur - prev).distance > cell * 1.8) {
        pts.add(cur);
      } else {
        pts.add(Offset.lerp(prev, cur, dying ? 1.0 : interp)!);
      }
    }

    // وميض الحصانة بعد الإحياء
    double alpha = 1.0;
    if (invincible) {
      alpha = sin(blinkPhase * 18) > 0 ? 1.0 : 0.25;
    }
    if (dying) {
      alpha = 1.0 - deathT * 0.85;
    }

    final head = pts.last;
    final tail = pts.first;
    final bodyW = cell * 0.74;

    // تقسيم المسار عند القفزات (الالتفاف عبر الحواف)
    final List<Path> paths = [];
    Path cur = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      if ((pts[i] - pts[i - 1]).distance > cell * 2.5) {
        paths.add(cur);
        cur = Path()..moveTo(pts[i].dx, pts[i].dy);
      } else {
        cur.lineTo(pts[i].dx, pts[i].dy);
      }
    }
    paths.add(cur);

    // التدرج من الرأس للذيل
    final bodyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = bodyW
      ..shader = LinearGradient(
        begin: Alignment(head.dx / size.width, head.dy / size.height),
        end: Alignment(tail.dx / size.width, tail.dy / size.height),
        colors: [
          AppTheme.neonLight.withValues(alpha: alpha),
          AppTheme.neon.withValues(alpha: alpha),
          AppTheme.neonDark.withValues(alpha: alpha * 0.85),
        ],
      ).createShader(Offset.zero & size);

    // التوهج
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = bodyW * 1.5
      ..color = AppTheme.neon.withValues(alpha: 0.14 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

    for (final p in paths) {
      canvas.drawPath(p, glowPaint);
    }
    for (final p in paths) {
      canvas.drawPath(p, bodyPaint);
    }

    // خط البطن الفاتح
    final belly = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = bodyW * 0.28
      ..color = Colors.white.withValues(alpha: 0.28 * alpha);
    for (final p in paths) {
      canvas.drawPath(p, belly);
    }

    // حراشف خفيفة
    final scalePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.10 * alpha);
    for (int i = 2; i < pts.length - 1; i += 2) {
      final d = pts[i] - pts[i - 1];
      if (d.distance < 1 || d.distance > cell * 2.5) continue;
      final perp = Offset(-d.dy, d.dx) / d.distance;
      canvas.drawLine(
        pts[i] - perp * bodyW * 0.30,
        pts[i] + perp * bodyW * 0.30,
        scalePaint,
      );
    }

    _paintHead(canvas, pts, cell, alpha, bodyW);
  }

  void _paintHead(
      Canvas canvas, List<Offset> pts, double cell, double alpha, double bodyW) {
    final head = pts.last;
    Offset dirVec;
    if (pts.length > 1) {
      final d = head - pts[pts.length - 2];
      dirVec = d.distance > 0.1 ? d / d.distance : const Offset(1, 0);
    } else {
      dirVec = const Offset(1, 0);
    }
    final perp = Offset(-dirVec.dy, dirVec.dx);

    // الرأس
    canvas.drawCircle(
      head,
      bodyW * 0.62,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.3),
          colors: [
            Colors.white.withValues(alpha: alpha),
            AppTheme.neonLight.withValues(alpha: alpha),
            AppTheme.neon.withValues(alpha: alpha),
          ],
        ).createShader(Rect.fromCircle(center: head, radius: bodyW * 0.62)),
    );

    // هالة الرأس
    canvas.drawCircle(
      head,
      bodyW * 0.95,
      Paint()
        ..color = AppTheme.neonLight.withValues(alpha: 0.2 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    if (dying) return; // لا عيون عند الموت — احتراماً للمشهد

    // اللسان المتذبذب
    final flick = sin(gameTime * 6);
    if (flick > 0.25 && !dying) {
      final tip = head + dirVec * (bodyW * 0.62 + cell * 0.34 * flick);
      final fork1 = tip + dirVec * cell * 0.12 + perp * cell * 0.1;
      final fork2 = tip + dirVec * cell * 0.12 - perp * cell * 0.1;
      final tongue = Paint()
        ..color = const Color(0xFFFF4D6D).withValues(alpha: alpha)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(head + dirVec * bodyW * 0.5, tip, tongue);
      canvas.drawLine(tip, fork1, tongue);
      canvas.drawLine(tip, fork2, tongue);
    }

    // العيون
    for (final side in [-1.0, 1.0]) {
      final eye = head + perp * side * bodyW * 0.30 + dirVec * bodyW * 0.22;
      canvas.drawCircle(eye, bodyW * 0.20, Paint()..color = Colors.white);
      canvas.drawCircle(
        eye + dirVec * bodyW * 0.08,
        bodyW * 0.11,
        Paint()..color = const Color(0xFF06110B),
      );
      // لمعة العين
      canvas.drawCircle(
        eye - dirVec * bodyW * 0.02 - const Offset(1, 1),
        bodyW * 0.045,
        Paint()..color = Colors.white70,
      );
    }
  }

  // ---------- الجسيمات ----------
  void _paintParticles(Canvas canvas, Size size, double cell) {
    for (final p in particles) {
      final t = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(p.pos.dx * cell, p.pos.dy * cell),
        p.size * cell * (0.4 + 0.6 * t),
        Paint()
          ..color = p.color.withValues(alpha: t)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
    }
  }

  Offset _center(int cellIndex, double cell) {
    return Offset(
      (cellIndex % cols + 0.5) * cell,
      (cellIndex ~/ cols + 0.5) * cell,
    );
  }

  @override
  bool shouldRepaint(covariant _GamePainter old) => true;
}
