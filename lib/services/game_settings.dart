import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';

/// إعدادات اللاعب وإحصائياته — تُحفظ محلياً وتُقرأ فوراً بدون انتظار Future.
class GameSettings {
  GameSettings._();
  static GameSettings instance = GameSettings._();

  SharedPreferences? _prefs;

  // ===== الإعدادات =====
  bool soundOn = true;
  bool hapticsOn = true;
  ControlMode controlMode = ControlMode.both;

  // ===== الإحصائيات =====
  int highScore = 0;
  int bestStage = 1;
  int totalApples = 0;
  int gamesPlayed = 0;
  bool onboardingSeen = false;
  int currentStage = 1;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    soundOn = p.getBool('sound_on') ?? true;
    hapticsOn = p.getBool('haptics_on') ?? true;
    controlMode = ControlMode
        .values[p.getInt('control_mode') ?? ControlMode.both.index];
    highScore = p.getInt('high_score') ?? 0;
    bestStage = p.getInt('best_stage') ?? 1;
    totalApples = p.getInt('total_apples') ?? 0;
    gamesPlayed = p.getInt('games_played') ?? 0;
    onboardingSeen = p.getBool('onboarding_seen') ?? false;
    currentStage = p.getInt('current_stage') ?? 1;
  }

  Future<void> _set(String key, Object value) async {
    await _prefs?.set(key, value);
  }

  Future<void> setSound(bool v) async {
    soundOn = v;
    await _set('sound_on', v);
  }

  Future<void> setHaptics(bool v) async {
    hapticsOn = v;
    await _set('haptics_on', v);
  }

  Future<void> setControlMode(ControlMode m) async {
    controlMode = m;
    await _set('control_mode', m.index);
  }

  Future<void> setOnboardingSeen() async {
    onboardingSeen = true;
    await _set('onboarding_seen', true);
  }

  Future<void> setStage(int stage) async {
    currentStage = stage;
    if (stage > bestStage) {
      bestStage = stage;
      await _set('best_stage', stage);
    }
    await _set('current_stage', stage);
  }

  /// تسجيل نهاية جولة — يُحدّث أفضل نتيجة وعدد الجولات والتفاح الكلي.
  Future<void> recordRun({required int score, required int apples}) async {
    gamesPlayed++;
    totalApples += apples;
    if (score > highScore) highScore = score;
    await _set('games_played', gamesPlayed);
    await _set('total_apples', totalApples);
    await _set('high_score', highScore);
  }

  /// إضافة نتيجة إضافية (مكافأة مضاعفة النقاط) وتحديث الرقم القياسي.
  Future<void> addScore(int s) async {
    if (s > highScore) {
      highScore = s;
      await _set('high_score', s);
    }
  }

  /// إعادة تعريف كل التقدم (مع طلب تأكيد قبل الاستدعاء من الواجهة).
  Future<void> resetProgress() async {
    currentStage = 1;
    highScore = 0;
    bestStage = 1;
    totalApples = 0;
    gamesPlayed = 0;
    await _set('current_stage', 1);
    await _set('high_score', 0);
    await _set('best_stage', 1);
    await _set('total_apples', 0);
    await _set('games_played', 0);
  }
}

extension _PrefsSet on SharedPreferences {
  Future<void> set(String key, Object value) async {
    if (value is bool) await setBool(key, value);
    if (value is int) await setInt(key, value);
    if (value is double) await setDouble(key, value);
    if (value is String) await setString(key, value);
  }
}
