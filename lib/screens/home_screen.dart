import 'package:flutter/material.dart';
import '../ads/ad_consent.dart';
import '../core/app_theme.dart';
import '../services/ad_manager.dart';
import '../services/game_settings.dart';
import '../services/sfx.dart';
import '../widgets/aurora_background.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/snake_logo.dart';
import 'game_screen.dart';

/// الشاشة الرئيسية — قائمة فخمة بخلفية حية وإحصائيات اللاعب.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AdManager _ads = AdManager();

  @override
  void initState() {
    super.initState();
    _ads.loadAllAds();
  }

  void _openGame() {
    // إعلان بيني قبل دخول اللعبة (مع احترام الفاصل الزمني في AdManager)
    _ads.showInterstitialAd(
      onDismissed: () {
        if (!mounted) return;
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const GameScreen(),
            transitionsBuilder: (_, anim, _, child) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0).animate(anim),
                child: child,
              ),
            ),
            transitionDuration: const Duration(milliseconds: 420),
          ),
        );
      },
    );
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('إعادة تعيين التقدم؟',
            style: AppTheme.font(size: 19, weight: FontWeight.w800)),
        content: Text(
          'سيتم حذف أفضل نتيجة ومرحلتك الحالية وجميع إحصائياتك. لا يمكن التراجع.',
          style: AppTheme.font(size: 13.5, color: AppTheme.textSecondary, height: 1.7),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: AppTheme.font(size: 15, color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('متأكد', style: AppTheme.font(size: 15, color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await GameSettings.instance.resetProgress();
      setState(() {});
    }
  }

  void _openSettings() {
    Sfx.tap();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = GameSettings.instance;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: AuroraBackground(
          child: SafeArea(
            child: Stack(
              children: [
                // المحتوى الرئيسي
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // ===== يمين: الشعار والإحصائيات =====
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SnakeLogo(size: 110),
                              const SizedBox(height: 10),
                              ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (b) => AppTheme.neonGradient.createShader(b),
                                child: Text(
                                  'الحنش المحترف',
                                  style: AppTheme.font(size: 34, weight: FontWeight.w900),
                                ),
                              ),
                              Text(
                                'PRO SNAKE GAME',
                                style: AppTheme.font(
                                  size: 10,
                                  color: AppTheme.textFaint,
                                  letterSpacing: 5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                alignment: WrapAlignment.center,
                                children: [
                                  StatChip(
                                    icon: Icons.emoji_events_rounded,
                                    label: 'أفضل نتيجة',
                                    value: '${s.highScore}',
                                    color: AppTheme.gold,
                                  ),
                                  StatChip(
                                    icon: Icons.flag_rounded,
                                    label: 'المرحلة',
                                    value: '${s.currentStage}',
                                    color: AppTheme.neon,
                                  ),
                                  StatChip(
                                    icon: Icons.apple_rounded,
                                    label: 'إجمالي التفاح',
                                    value: '${s.totalApples}',
                                    color: AppTheme.danger,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ===== يسار: الأزرار + إعلان أصلي أنيق =====
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              NeonButton(
                                label: 'العب الآن',
                                icon: Icons.play_arrow_rounded,
                                width: 280,
                                height: 64,
                                fontSize: 22,
                                pulse: true,
                                gradient: AppTheme.neonGradient,
                                onPressed: _openGame,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _RoundAction(
                                    icon: Icons.settings_rounded,
                                    onTap: _openSettings,
                                  ),
                                  const SizedBox(width: 12),
                                  _RoundAction(
                                    icon: Icons.restart_alt_rounded,
                                    color: AppTheme.danger,
                                    onTap: _confirmReset,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              // إعلان أصلي بتصميم زجاجي متناسق
                              GlassCard(
                                padding: const EdgeInsets.all(6),
                                borderColor: AppTheme.textFaint,
                                radius: 18,
                                child: SizedBox(
                                  width: 330,
                                  height: 135,
                                  child: NativeAdWidget(adUnitId: AdManager.nativeAdUnitId),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // إعلان بانر سفلي
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: const Center(
                      child: BannerAdWidget(adUnitId: AdManager.bannerAdUnitId),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// زر دائري صغير للإجراءات الثانوية.
class _RoundAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoundAction({
    required this.icon,
    this.color = AppTheme.neon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Sfx.tap();
        onTap();
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surface.withValues(alpha: 0.6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

/// لوحة الإعدادات المنبثقة.
class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  @override
  Widget build(BuildContext context) {
    final s = GameSettings.instance;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.neon.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الإعدادات', style: AppTheme.font(size: 21, weight: FontWeight.w800)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _SettingToggle(
            icon: Icons.music_note_rounded,
            label: 'المؤثرات الصوتية',
            color: AppTheme.neon,
            value: s.soundOn,
            onChanged: (v) async {
              await s.setSound(v);
              setState(() {});
            },
          ),
          _SettingToggle(
            icon: Icons.vibration_rounded,
            label: 'الاهتزاز',
            color: AppTheme.gem,
            value: s.hapticsOn,
            onChanged: (v) async {
              await s.setHaptics(v);
              setState(() {});
            },
          ),
          const SizedBox(height: 12),

          // وضع التحكم
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.touch_app_rounded, color: AppTheme.gold, size: 20),
                    const SizedBox(width: 8),
                    Text('أسلوب التحكم',
                        style: AppTheme.font(size: 14.5, weight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final m in ControlMode.values) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            Sfx.tap();
                            await s.setControlMode(m);
                            setState(() {});
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              gradient: s.controlMode == m ? AppTheme.neonGradient : null,
                              color: s.controlMode == m
                                  ? null
                                  : AppTheme.surfaceHigh.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: s.controlMode == m
                                    ? AppTheme.neonLight
                                    : AppTheme.textFaint.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              switch (m) {
                                ControlMode.swipe => 'سحب',
                                ControlMode.dpad => 'أزرار',
                                ControlMode.both => 'الاثنان',
                              },
                              textAlign: TextAlign.center,
                              style: AppTheme.font(
                                size: 13,
                                weight: FontWeight.w700,
                                color: s.controlMode == m
                                    ? const Color(0xFF04140C)
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (m != ControlMode.both) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // خيارات الخصوصية (UMP)
          GestureDetector(
            onTap: () => AdConsent.instance.showPrivacyOptions(),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderColor: AppTheme.textFaint,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.privacy_tip_rounded,
                          color: AppTheme.textSecondary, size: 20),
                      const SizedBox(width: 10),
                      Text('خيارات الخصوصية والإعلانات',
                          style: AppTheme.font(size: 13.5)),
                    ],
                  ),
                  const Icon(Icons.chevron_left, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingToggle({
    required this.icon,
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTheme.font(size: 15))),
          _LuxSwitch(value: value, color: color, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// مفتاح تبديل فخم مخصص.
class _LuxSwitch extends StatelessWidget {
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _LuxSwitch({required this.value, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Sfx.tap();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 54,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: value ? AppTheme.neonGradient : null,
          color: value ? null : AppTheme.surfaceHigh,
          border: Border.all(
            color: value ? AppTheme.neonLight : AppTheme.textFaint.withValues(alpha: 0.4),
          ),
          boxShadow: value
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }
}
