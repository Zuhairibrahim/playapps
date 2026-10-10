import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// خدمة الموافقة على الإعلانات (UMP / CMP) — متطلب Google لأوروبا/بريطانيا.
/// تُستدعى قبل MobileAds.initialize() حسب الترتيب الرسمي من Google:
/// requestConsentInfoUpdate -> loadAndShowConsentFormIfRequired -> initialize.
class AdConsent {
  AdConsent._();

  static AdConsent? _realInstance;
  static AdConsent get instance => _realInstance ??= AdConsent._();

  bool _done = false;
  Future<void>? _pending;

  Future<void> collectConsent() {
    if (_done) return Future.value();
    if (_pending != null) return _pending!;
    final f = _run();
    _pending = f;
    return f;
  }

  Future<void> _run() async {
    try {
      await _collect();
    } catch (_) {}
    _done = true;
  }

  Future<void> _collect() async {
    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentInformation.instance.isConsentFormAvailable().then((available) {
          if (available) {
            ConsentForm.loadAndShowConsentFormIfRequired((_) {
              if (!completer.isCompleted) completer.complete();
            });
          } else {
            if (!completer.isCompleted) completer.complete();
          }
        }).catchError((_) {
          if (!completer.isCompleted) completer.complete();
        });
      },
      (_) {
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
  }

  /// فتح نموذج خيارات الخصوصية عند الحاجة (لعرضه من إعدادات التطبيق).
  Future<void> showPrivacyOptions() async {
    try {
      final status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      if (status == PrivacyOptionsRequirementStatus.required) {
        await ConsentForm.showPrivacyOptionsForm((_) {});
      }
    } catch (_) {}
  }
}
