import 'dart:math';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// خلفية "أورورا" حية: نجوم متلألئة + سُدُم نيون متحركة + شبكة خفيفة.
class AuroraBackground extends StatefulWidget {
  final Widget child;
  final bool showGrid;

  const AuroraBackground({super.key, required this.child, this.showGrid = true});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _AuroraPainter(t: _ctrl.value * 2 * pi, showGrid: widget.showGrid),
          child: widget.child,
        );
      },
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t;
  final bool showGrid;
  final Random _rng = Random(7);

  _AuroraPainter({required this.t, required this.showGrid});

  @override
  void paint(Canvas canvas, Size size) {
    // خلفية متدرجة
    final rect = Offset.zero & size;
    Paint bg = Paint()..shader = AppTheme.bgGradient.createShader(rect);
    canvas.drawRect(rect, bg);

    // سُدُم نيون متحركة (دوائر ضوئية ضبابية)
    _nebula(canvas, size,
        center: Offset(size.width * (0.22 + 0.06 * sin(t)), size.height * (0.3 + 0.08 * cos(t * 0.7))),
        radius: size.width * 0.38, color: AppTheme.neonDark.withValues(alpha: 0.16));
    _nebula(canvas, size,
        center: Offset(size.width * (0.8 + 0.05 * cos(t * 0.8)), size.height * (0.75 + 0.07 * sin(t * 0.9))),
        radius: size.width * 0.32, color: const Color(0xFF3B4EDE).withValues(alpha: 0.13));
    _nebula(canvas, size,
        center: Offset(size.width * (0.55 + 0.07 * sin(t * 0.5 + 2)), size.height * (0.15 + 0.05 * cos(t * 0.6))),
        radius: size.width * 0.22, color: AppTheme.goldDark.withValues(alpha: 0.07));

    // شبكة خفيفة جداً
    if (showGrid) {
      Paint grid = Paint()
        ..color = Colors.white.withValues(alpha: 0.025)
        ..strokeWidth = 1;
      const cell = 64.0;
      for (double x = 0; x < size.width; x += cell) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      }
      for (double y = 0; y < size.height; y += cell) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
    }

    // نجوم متلألئة
    for (int i = 0; i < 70; i++) {
      double x = _rng.nextDouble() * size.width;
      double y = _rng.nextDouble() * size.height;
      double base = _rng.nextDouble();
      double twinkle = 0.25 + 0.75 * (0.5 + 0.5 * sin(t * (1 + base * 2) + i));
      double r = 0.6 + base * 1.6;
      Paint star = Paint()
        ..color = Colors.white.withValues(alpha: 0.10 + 0.35 * twinkle * base)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
      canvas.drawCircle(Offset(x, y), r, star);
    }
  }

  void _nebula(Canvas canvas, Size size,
      {required Offset center, required double radius, required Color color}) {
    Paint p = Paint()
      ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    canvas.drawCircle(center, radius, p);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => true;
}
