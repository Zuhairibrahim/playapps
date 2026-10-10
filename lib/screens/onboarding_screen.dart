import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/game_settings.dart';
import '../services/sfx.dart';
import '../widgets/aurora_background.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/snake_logo.dart';
import 'home_screen.dart';

/// شاشة ترحيب المستخدم — 3 صفحات أنيقة تُعرض عند أول تشغيل.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await GameSettings.instance.setOnboardingSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == 2;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: AuroraBackground(
          child: SafeArea(
            child: Stack(
              children: [
                // تخطي
                Positioned(
                  top: 12,
                  right: 16,
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      'تخطي',
                      style: AppTheme.font(
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),

                Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageCtrl,
                        onPageChanged: (i) {
                          Sfx.tap();
                          setState(() => _page = i);
                        },
                        children: const [
                          _WelcomePage(),
                          _HowToPlayPage(),
                          _FeaturesPage(),
                        ],
                      ),
                    ),

                    // المؤشر + زر المتابعة
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (i) {
                                final active = i == _page;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  margin: const EdgeInsets.symmetric(horizontal: 5),
                                  width: active ? 34 : 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    gradient: active ? AppTheme.neonGradient : null,
                                    color: active
                                        ? null
                                        : AppTheme.textFaint.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: active ? AppTheme.glowNeon : null,
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          NeonButton(
                            label: isLast ? 'ابدأ اللعب' : 'التالي',
                            icon: isLast ? Icons.play_arrow_rounded : null,
                            width: 170,
                            height: 54,
                            fontSize: 17,
                            gradient: isLast ? AppTheme.goldGradient : AppTheme.neonGradient,
                            glowColor: isLast ? AppTheme.gold : AppTheme.neon,
                            textColor: isLast ? const Color(0xFF1A1000) : const Color(0xFF04140C),
                            onPressed: () {
                              if (isLast) {
                                _finish();
                              } else {
                                _pageCtrl.nextPage(
                                  duration: const Duration(milliseconds: 420),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== الصفحة 1: ترحيب ====================
class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SnakeLogo(size: 170),
          const SizedBox(height: 30),
          Text(
            'مرحباً بك في',
            style: AppTheme.font(size: 20, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => AppTheme.neonGradient.createShader(b),
            child: Text(
              'الحنش المحترف',
              style: AppTheme.font(size: 44, weight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Text(
              'تجربة الثعبان الكلاسيكية بتصميم فخم وحديث\nرسومات نيون، مؤثرات جسيمات، ومستويات لا نهائية',
              textAlign: TextAlign.center,
              style: AppTheme.font(size: 14.5, color: AppTheme.textSecondary, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== الصفحة 2: طريقة اللعب ====================
class _HowToPlayPage extends StatelessWidget {
  const _HowToPlayPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'طريقة اللعب',
            style: AppTheme.font(size: 30, weight: FontWeight.w800),
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ControlDemoCard(
                icon: Icons.swipe,
                title: 'السحب',
                desc: 'اسحب إصبعك في أي\nاتجاه لتوجيه الثعبان',
                color: AppTheme.neon,
              ),
              const SizedBox(width: 18),
              _ControlDemoCard(
                icon: Icons.gamepad_rounded,
                title: 'أزرار التحكم',
                desc: 'استخدم أزرار الاتجاهات\nالظاهرة على الشاشة',
                color: AppTheme.gem,
              ),
            ],
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _miniDot(AppTheme.neon, 'تفاحة = نقطة'),
                const SizedBox(width: 14),
                _miniDot(AppTheme.gold, 'ذهبية = 5 نقاط'),
                const SizedBox(width: 14),
                _miniDot(AppTheme.gem, 'جوهرة = 10 نقاط'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'كل ما أكلت أسرع… زاد الكومبو ومضاعفة النقاط!',
            style: AppTheme.font(size: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _miniDot(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [c.withValues(alpha: 0.7), c]),
            boxShadow: [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 8)],
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.font(size: 12.5, color: AppTheme.textPrimary)),
      ],
    );
  }
}

class _ControlDemoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _ControlDemoCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        borderColor: color,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.08)],
              ),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: color, size: 34),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTheme.font(size: 17, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: AppTheme.font(size: 12, color: AppTheme.textSecondary, height: 1.6),
          ),
        ],
      ),
      ),
    );
  }
}

// ==================== الصفحة 3: المميزات ====================
class _FeaturesPage extends StatelessWidget {
  const _FeaturesPage();

  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.all_inclusive_rounded, AppTheme.neon, 'مستويات لا نهائية', 'صعوبة متزايدة مع كل مرحلة'),
      (Icons.bolt_rounded, AppTheme.gold, 'نظام كومبو', 'كُل بسرعة وضاعف نقاطك حتى x5'),
      (Icons.auto_awesome_rounded, AppTheme.gem, 'ذهب وجواهر', 'فواكه نادرة بنقاط مضاعفة'),
      (Icons.favorite_rounded, AppTheme.danger, 'فرصة ثانية', 'أحيِ ثعبانك بمشاهدة إعلان مكافأة'),
      (Icons.celebration_rounded, AppTheme.gold, 'مؤثرات حية', 'جسيمات، توهج، واهتزاز واقعي'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'مميزات فخمة',
            style: AppTheme.font(size: 30, weight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  borderColor: f.$2,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: f.$2.withValues(alpha: 0.15),
                          border: Border.all(color: f.$2.withValues(alpha: 0.4)),
                        ),
                        child: Icon(f.$1, color: f.$2, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.$3, style: AppTheme.font(size: 14.5, weight: FontWeight.w700)),
                            Text(f.$4, style: AppTheme.font(size: 11.5, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
