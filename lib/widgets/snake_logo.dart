import 'dart:math';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// شعار الثعبان النيون — يرسم ثعباناً يتموّج بلطف مع تفاحة متوهجة.
class SnakeLogo extends StatefulWidget {
  final double size;
  final bool animate;

  const SnakeLogo({super.key, this.size = 120, this.animate = true});

  @override
  State<SnakeLogo> createState() => _SnakeLogoState();
}

class _SnakeLogoState extends State<SnakeLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
          size: Size(widget.size, widget.size),
          painter: _SnakeLogoPainter(t: _ctrl.value * 2 * pi),
        );
      },
    );
  }
}

class _SnakeLogoPainter extends CustomPainter {
  final double t;

  _SnakeLogoPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bodyWidth = w * 0.16;

    // مسار الثعبان المتموج على شكل S داخل دائرة
    final path = Path();
    final List<Offset> centers = [];
    for (int i = 0; i <= 40; i++) {
      final p = i / 40;
      final angle = pi * 0.75 + p * pi * 1.5 + 0.08 * sin(t);
      final radius = (w * 0.34) * (1.05 - 0.35 * p);
      // موجة إضافية على نصف القطر
      final wave = (w * 0.035) * sin(t * 2 + p * 6);
      centers.add(Offset(
        w / 2 + cos(angle) * (radius + wave),
        h / 2 + sin(angle) * (radius + wave) * 0.9,
      ));
    }
    path.moveTo(centers[0].dx, centers[0].dy);
    for (final c in centers.skip(1)) {
      path.lineTo(c.dx, c.dy);
    }

    // توهج خارجي
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromLTWH(0, 0, w, h)));

    Paint glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bodyWidth * 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppTheme.neon.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawPath(path, glow);

    // الجسم المتدرج
    final rect = Rect.fromLTWH(0, 0, w, h);
    Paint body = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bodyWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        colors: [AppTheme.neonLight, AppTheme.neon, AppTheme.neonDark],
      ).createShader(rect);
    canvas.drawPath(path, body);

    // خط بطن فاتح
    Paint belly = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bodyWidth * 0.32
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawPath(path, belly);

    // الرأس (بداية المسار)
    final head = centers.first;
    final next = centers[3];
    final dir = (next - head) / ((next - head).distance);

    Paint headPaint = Paint()
      ..shader = RadialGradient(
        colors: [AppTheme.neonLight, AppTheme.neon],
      ).createShader(Rect.fromCircle(center: head, radius: bodyWidth * 0.95));
    canvas.drawCircle(head, bodyWidth * 0.95, headPaint);

    // هالة الرأس
    Paint headGlow = Paint()
      ..color = AppTheme.neonLight.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(head, bodyWidth * 1.15, headGlow);

    // العيون — تنظر باتجاه الحركة
    final perp = Offset(-dir.dy, dir.dx);
    for (final side in [-1.0, 1.0]) {
      final eye = head + perp * side * bodyWidth * 0.45 + dir * bodyWidth * 0.25;
      canvas.drawCircle(eye, bodyWidth * 0.28, Paint()..color = Colors.white);
      canvas.drawCircle(
        eye + dir * bodyWidth * 0.10,
        bodyWidth * 0.14,
        Paint()..color = const Color(0xFF06110B),
      );
    }

    // التفاحة الذهبية أمام الرأس
    final apple = head + dir * w * 0.30;
    final pulse = 0.5 + 0.5 * sin(t * 3);
    Paint appleGlow = Paint()
      ..color = AppTheme.gold.withValues(alpha: 0.30 + 0.2 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(apple, w * 0.09 + pulse * 2, appleGlow);

    Paint appleBody = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [const Color(0xFFFFE08A), AppTheme.gold, AppTheme.goldDark],
      ).createShader(Rect.fromCircle(center: apple, radius: w * 0.085));
    canvas.drawCircle(apple, w * 0.085, appleBody);

    // ورقة التفاحة
    final leaf = Path()
      ..moveTo(apple.dx, apple.dy - w * 0.085)
      ..quadraticBezierTo(
        apple.dx + w * 0.05, apple.dy - w * 0.14,
        apple.dx + w * 0.02, apple.dy - w * 0.17,
      )
      ..quadraticBezierTo(
        apple.dx - w * 0.02, apple.dy - w * 0.12,
        apple.dx, apple.dy - w * 0.085,
      );
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF2ECC71));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SnakeLogoPainter old) => true;
}
