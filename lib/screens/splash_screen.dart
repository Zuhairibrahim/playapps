import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/aurora_background.dart';
import '../widgets/snake_logo.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import '../services/game_settings.dart';

/// شاشة البداية — ثعبان نيون متحرك مع اسم اللعبة بتأثير لمعان.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      final seen = GameSettings.instance.onboardingSeen;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => seen
              ? const HomeScreen()
              : const OnboardingScreen(),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: AuroraBackground(
        child: Center(
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _ctrl,
              curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
            ),
            child: ScaleTransition(
              scale: Tween(begin: 0.7, end: 1.0).animate(
                CurvedAnimation(
                  parent: _ctrl,
                  curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SnakeLogo(size: 150),
                  const SizedBox(height: 28),
                  _ShimmerText(
                    text: 'الحنش المحترف',
                    style: AppTheme.font(size: 40, weight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _ctrl,
                      curve: const Interval(0.3, 0.6),
                    ),
                    child: Text(
                      'PRO SNAKE GAME',
                      style: AppTheme.font(
                        size: 13,
                        weight: FontWeight.w600,
                        color: AppTheme.textFaint,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 46),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _ctrl,
                      curve: const Interval(0.45, 0.75),
                    ),
                    child: const SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(
                        color: AppTheme.neon,
                        strokeWidth: 2.6,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// نص بلمعان متحرك يعبر عليه ضوء ذهبي/أخضر.
class _ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _ShimmerText({required this.text, required this.style});

  @override
  State<_ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<_ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
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
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final dx = bounds.width * (_ctrl.value * 2 - 0.5);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                AppTheme.neonLight,
                AppTheme.neon,
                Colors.white,
                AppTheme.gold,
                AppTheme.neonLight,
              ],
              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
            ).createShader(Rect.fromLTWH(dx, 0, bounds.width, bounds.height));
          },
          child: child,
        );
      },
      child: Text(widget.text, style: widget.style),
    );
  }
}
