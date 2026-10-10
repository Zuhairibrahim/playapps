import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// نظام الألوان والتصميم الفخم للعبة — ثيم نيون داكن مع لمسات ذهبية.
class AppTheme {
  AppTheme._();

  // ===== الألوان الأساسية =====
  static const Color bg = Color(0xFF05070F);
  static const Color bgDeep = Color(0xFF02030A);
  static const Color surface = Color(0xFF0D1220);
  static const Color surfaceHigh = Color(0xFF141B2E);

  // نيون أخضر (هوية الثعبان)
  static const Color neon = Color(0xFF22E88B);
  static const Color neonDark = Color(0xFF0E9F6E);
  static const Color neonLight = Color(0xFF7CFFC4);

  // ذهبي فخم
  static const Color gold = Color(0xFFFFC83D);
  static const Color goldDark = Color(0xFFB97E12);

  // جوهرة سماوية
  static const Color gem = Color(0xFF22D3EE);

  // خطر
  static const Color danger = Color(0xFFFF4D6D);

  // نصوص
  static const Color textPrimary = Color(0xFFF4F7FF);
  static const Color textSecondary = Color(0xFF9AA6C3);
  static const Color textFaint = Color(0xFF5A6580);

  // ===== التدرجات =====
  static const LinearGradient neonGradient = LinearGradient(
    colors: [neonLight, neon, neonDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFE08A), gold, goldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A1024), bg, bgDeep],
  );

  // ===== الخطوط =====
  static TextStyle font({
    double size = 16,
    FontWeight weight = FontWeight.w500,
    Color color = textPrimary,
    double? letterSpacing,
    double height = 1.2,
  }) {
    return GoogleFonts.cairo(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // ===== زجاجية =====
  static List<BoxShadow> get glowNeon => [
        BoxShadow(
          color: neon.withValues(alpha: 0.35),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get glowGold => [
        BoxShadow(
          color: gold.withValues(alpha: 0.35),
          blurRadius: 24,
          offset: const Offset(0, 4),
        ),
      ];

  static BoxDecoration glass({Color borderColor = neon, double radius = 22}) {
    return BoxDecoration(
      color: surface.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor.withValues(alpha: 0.35),
        width: 1.2,
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0.0),
        ],
      ),
    );
  }
}

/// وضع التحكم المفضل.
enum ControlMode { swipe, dpad, both }
