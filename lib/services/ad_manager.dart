import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  // معرّفات إعلانات تجريبية (وهمية) رسمية من Google
  static const String appId = 'ca-app-pub-3940256099942544~3347511713';
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String rewardedInterstitialAdUnitId = 'ca-app-pub-3940256099942544/5354046614';
  static const String nativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';
  static const String appOpenAdUnitId = 'ca-app-pub-3940256099942544/9257395921';

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;
  AppOpenAd? _appOpenAd;
  BannerAd? _homeBannerAd;

  bool _isInterstitialReady = false;
  bool _isRewardedReady = false;
  bool _isRewardedInterstitialReady = false;
  bool _isAppOpenReady = false;

  Timer? _autoInterstitialTimer;
  int _autoAdCounter = 0;

  // ===================== App Open Ad =====================
  void loadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          _appOpenAd = ad;
          _isAppOpenReady = true;
          _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (AppOpenAd ad) {
              ad.dispose();
              _appOpenAd = null;
              _isAppOpenReady = false;
            },
            onAdFailedToShowFullScreenContent: (AppOpenAd ad, AdError error) {
              ad.dispose();
              _appOpenAd = null;
              _isAppOpenReady = false;
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isAppOpenReady = false;
        },
      ),
    );
  }

  void showAppOpenAdIfAvailable() {
    if (_isAppOpenReady && _appOpenAd != null) {
      _appOpenAd!.show();
    }
  }

  // ===================== Interstitial Ad =====================
  void loadInterstitialAd({VoidCallback? onAdDismissed}) {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialReady = false;
              onAdDismissed?.call();
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialReady = false;
              onAdDismissed?.call();
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isInterstitialReady = false;
          Future.delayed(const Duration(seconds: 3), () => loadInterstitialAd());
        },
      ),
    );
  }

  void showInterstitialAd({VoidCallback? onDismissed}) {
    if (_isInterstitialReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialReady = false;
          onDismissed?.call();
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialReady = false;
          onDismissed?.call();
          loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
    } else {
      onDismissed?.call();
      loadInterstitialAd();
    }
  }

  // ===================== Rewarded Ad =====================
  void loadRewardedAd({VoidCallback? onRewarded}) {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isRewardedReady = true;
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedReady = false;
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedReady = false;
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isRewardedReady = false;
          Future.delayed(const Duration(seconds: 3), () => loadRewardedAd());
        },
      ),
    );
  }

  void showRewardedAd({VoidCallback? onRewarded}) {
    if (_isRewardedReady && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          ad.dispose();
          _rewardedAd = null;
          _isRewardedReady = false;
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          ad.dispose();
          _rewardedAd = null;
          _isRewardedReady = false;
          loadRewardedAd();
        },
      );
      _rewardedAd!.show(
        onUserEarnedReward: (Ad ad, RewardItem reward) {
          onRewarded?.call();
        },
      );
    }
  }

  // ===================== Rewarded Interstitial Ad =====================
  void loadRewardedInterstitialAd() {
    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          _rewardedInterstitialAd = ad;
          _isRewardedInterstitialReady = true;
          _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
              ad.dispose();
              _rewardedInterstitialAd = null;
              _isRewardedInterstitialReady = false;
              loadRewardedInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (RewardedInterstitialAd ad, AdError error) {
              ad.dispose();
              _rewardedInterstitialAd = null;
              _isRewardedInterstitialReady = false;
              loadRewardedInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isRewardedInterstitialReady = false;
          Future.delayed(const Duration(seconds: 3), () => loadRewardedInterstitialAd());
        },
      ),
    );
  }

  void showRewardedInterstitialAd({VoidCallback? onRewarded}) {
    if (_isRewardedInterstitialReady && _rewardedInterstitialAd != null) {
      _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
          ad.dispose();
          _rewardedInterstitialAd = null;
          _isRewardedInterstitialReady = false;
          loadRewardedInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (RewardedInterstitialAd ad, AdError error) {
          ad.dispose();
          _rewardedInterstitialAd = null;
          _isRewardedInterstitialReady = false;
          loadRewardedInterstitialAd();
        },
      );
      _rewardedInterstitialAd!.show(
        onUserEarnedReward: (Ad ad, RewardItem reward) {
          onRewarded?.call();
        },
      );
    }
  }

  // ===================== Auto Interstitial (كل 5 ثواني) =====================
  void startAutoInterstitial({VoidCallback? onDismissed}) {
    _autoAdCounter = 0;
    _autoInterstitialTimer?.cancel();
    _autoInterstitialTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _autoAdCounter++;
      if (_autoAdCounter % 2 == 0) {
        showInterstitialAd(onDismissed: onDismissed);
      } else {
        showRewardedInterstitialAd();
      }
    });
  }

  void stopAutoInterstitial() {
    _autoInterstitialTimer?.cancel();
    _autoInterstitialTimer = null;
  }

  // ===================== تحميل كل الإعلانات =====================
  void loadAllAds() {
    loadInterstitialAd();
    loadRewardedAd();
    loadRewardedInterstitialAd();
    loadAppOpenAd();
  }

  // ===================== تنظيف الكل =====================
  void disposeAll() {
    stopAutoInterstitial();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _rewardedInterstitialAd?.dispose();
    _appOpenAd?.dispose();
    _homeBannerAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
    _rewardedInterstitialAd = null;
    _appOpenAd = null;
    _homeBannerAd = null;
  }
}

typedef VoidCallback = void Function();
