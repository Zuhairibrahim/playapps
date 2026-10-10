import 'package:flutter/services.dart';
import 'game_settings.dart';

/// مؤثرات صوتية واهتزاز — بدون ملفات خارجية، باستخدام أصوات النظام.
class Sfx {
  Sfx._();

  static void eat() {
    if (!GameSettings.instance.soundOn) return;
    SystemSound.play(SystemSoundType.click);
  }

  static void golden() {
    if (!GameSettings.instance.soundOn) return;
    SystemSound.play(SystemSoundType.click);
  }

  static void gem() {
    if (!GameSettings.instance.soundOn) return;
    SystemSound.play(SystemSoundType.alert);
  }

  static void death() {
    if (!GameSettings.instance.soundOn) return;
    SystemSound.play(SystemSoundType.alert);
  }

  static void win() {
    if (!GameSettings.instance.soundOn) return;
    SystemSound.play(SystemSoundType.alert);
  }

  static void click() {
    if (!GameSettings.instance.soundOn) return;
    SystemSound.play(SystemSoundType.click);
  }

  // ===== الاهتزاز =====
  static void tap() {
    if (!GameSettings.instance.hapticsOn) return;
    HapticFeedback.selectionClick();
  }

  static void impact() {
    if (!GameSettings.instance.hapticsOn) return;
    HapticFeedback.lightImpact();
  }

  static void heavy() {
    if (!GameSettings.instance.hapticsOn) return;
    HapticFeedback.heavyImpact();
  }
}
