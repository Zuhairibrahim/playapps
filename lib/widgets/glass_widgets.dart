import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/sfx.dart';

/// بطاقة زجاجية فخمة.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color borderColor;
  final double radius;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderColor = AppTheme.neon,
    this.radius = 22,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor.withValues(alpha: 0.35), width: 1.2),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// زر نيون فخم بتدرج وتوهج ونبض اختياري.
class NeonButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Gradient gradient;
  final Color glowColor;
  final Color textColor;
  final double width;
  final double height;
  final double fontSize;
  final bool pulse;
  final VoidCallback onPressed;

  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.gradient,
    this.icon,
    this.glowColor = AppTheme.neon,
    this.textColor = const Color(0xFF04140C),
    this.width = 260,
    this.height = 58,
    this.fontSize = 20,
    this.pulse = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    if (widget.pulse) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = widget.pulse ? Curves.easeInOut.transform(_pulse.value) : 0.0;
        return GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            Sfx.tap();
            widget.onPressed();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 110),
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(widget.height / 2),
                boxShadow: [
                  BoxShadow(
                    color: widget.glowColor.withValues(alpha: 0.30 + 0.35 * glow),
                    blurRadius: 18 + 16 * glow,
                    spreadRadius: 1 + 2 * glow,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: widget.textColor, size: widget.fontSize + 6),
            const SizedBox(width: 10),
          ],
          Text(
            widget.label,
            style: AppTheme.font(
              size: widget.fontSize,
              weight: FontWeight.w800,
              color: widget.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// شريحة إحصائيات صغيرة بأيقونة.
class StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppTheme.neon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderColor: color,
      radius: 18,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTheme.font(size: 17, weight: FontWeight.w800, color: Colors.white),
              ),
              Text(
                label,
                style: AppTheme.font(size: 10.5, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
