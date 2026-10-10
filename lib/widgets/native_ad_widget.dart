import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/app_theme.dart';

/// إعلان أصلي بقالب متوسط بتصميم متناسق مع ثيم اللعبة الداكن.
class NativeAdWidget extends StatefulWidget {
  final String adUnitId;

  const NativeAdWidget({
    super.key,
    required this.adUnitId,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (_disposed) return;
    _nativeAd = NativeAd(
      adUnitId: widget.adUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          if (mounted && !_disposed) {
            setState(() => _isLoaded = true);
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          if (mounted && !_disposed) {
            setState(() => _isLoaded = false);
          }
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted && !_disposed) _loadAd();
          });
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: AppTheme.surface,
        cornerRadius: 14.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF04140C),
          backgroundColor: AppTheme.neon,
          style: NativeTemplateFontStyle.bold,
          size: 13.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Color(0xFF9AA6C3),
          size: 12.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Color(0xFF5A6580),
          size: 10.0,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    _disposed = true;
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
