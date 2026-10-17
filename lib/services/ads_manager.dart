import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/constants.dart';

class AdsManager {
  static final AdsManager _instance = AdsManager._internal();
  factory AdsManager() => _instance;
  AdsManager._internal();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isLoadingInterstitial = false;
  bool _isLoadingRewarded = false;
  bool _adsInitialized = false;

  bool get isAdsInitialized => _adsInitialized;
  
  int _gameOverCount = 0;
  DateTime? _lastInterstitialTime;

  /// Inicia el flujo oficial de UMP de Google AdMob para recopilar el consentimiento
  /// del usuario según las normativas del RGPD (Europa) y normativas estatales de EE. UU.
  Future<void> gatherConsent({VoidCallback? onConsentComplete}) async {
    if (kIsWeb) {
      onConsentComplete?.call();
      return;
    }

    final params = ConsentRequestParameters();

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () {
          ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
            if (formError != null) {
              debugPrint('⚠️ [UMP] Form error: ${formError.errorCode}: ${formError.message}');
            }

            if (await ConsentInformation.instance.canRequestAds()) {
              initializeMobileAdsSdk();
            }
            onConsentComplete?.call();
          });
        },
        (FormError error) {
          debugPrint('⚠️ [UMP] ConsentInfoUpdate error: ${error.errorCode}: ${error.message}');
          onConsentComplete?.call();
        },
      );

      // Si el usuario ya dio su consentimiento en una sesión anterior, inicializar de inmediato
      if (await ConsentInformation.instance.canRequestAds()) {
        initializeMobileAdsSdk();
      }
    } catch (e) {
      debugPrint('⚠️ [UMP] Consent gathering exception: $e');
      onConsentComplete?.call();
    }
  }

  /// Inicializa el SDK de MobileAds una sola vez cuando se tiene autorización de consentimiento.
  Future<void> initializeMobileAdsSdk() async {
    if (_adsInitialized || kIsWeb) return;
    _adsInitialized = true;

    try {
      await MobileAds.instance.initialize();
      _loadInterstitialAd();
      _loadRewardedAd();
      debugPrint('✅ [AdMob] SDK inicializado con éxito bajo consentimiento UMP.');
    } catch (e) {
      debugPrint('⚠️ [AdMob] Error al inicializar MobileAds: $e');
    }
  }

  /// Comprueba si la plataforma exige mostrar el botón de "Opciones de privacidad"
  /// (obligatorio para usuarios en el EEE/Reino Unido/Suiza o estados regulados de EE. UU.)
  Future<bool> isPrivacyOptionsRequired() async {
    if (kIsWeb) return false;
    try {
      final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('⚠️ [UMP] Error consultando PrivacyOptionsRequirementStatus: $e');
      return false;
    }
  }

  /// Despliega el formulario de opciones de privacidad de UMP para permitir al usuario
  /// cambiar o retirar su consentimiento en cualquier momento sin reiniciar la app.
  void showPrivacyOptionsForm({void Function(FormError?)? onDismissed}) {
    if (kIsWeb) return;
    try {
      ConsentForm.showPrivacyOptionsForm((formError) {
        if (formError != null) {
          debugPrint('⚠️ [UMP] Error en formulario de opciones de privacidad: ${formError.message}');
        }
        onDismissed?.call(formError);
      });
    } catch (e) {
      debugPrint('⚠️ [UMP] Excepción al mostrar opciones de privacidad: $e');
      onDismissed?.call(null);
    }
  }

  void _loadInterstitialAd() {
    if (kIsWeb || !_adsInitialized) return;
    if (_isLoadingInterstitial || _interstitialAd != null) return;
    _isLoadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: Constants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingInterstitial = false;
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _isLoadingInterstitial = false;
          _interstitialAd = null;
          // Reintentar tras un retraso de 30 segundos
          Future.delayed(const Duration(seconds: 30), () {
            if (_adsInitialized) _loadInterstitialAd();
          });
        },
      ),
    );
  }

  void _loadRewardedAd() {
    if (kIsWeb || !_adsInitialized) return;
    if (_isLoadingRewarded || _rewardedAd != null) return;
    _isLoadingRewarded = true;
    RewardedAd.load(
      adUnitId: Constants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingRewarded = false;
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          _isLoadingRewarded = false;
          _rewardedAd = null;
          // Reintentar tras un retraso de 30 segundos
          Future.delayed(const Duration(seconds: 30), () {
            if (_adsInitialized) _loadRewardedAd();
          });
        },
      ),
    );
  }

  void showInterstitialAdIfAppropriate() {
    _gameOverCount++;
    if (_gameOverCount >= 2) {
      bool canShow = true;
      if (_lastInterstitialTime != null) {
        final diff = DateTime.now().difference(_lastInterstitialTime!);
        if (diff.inSeconds < 60) {
          canShow = false;
        }
      }

      if (canShow && _interstitialAd != null) {
        final adToShow = _interstitialAd!;
        _interstitialAd = null; // Clear immediately to avoid duplicate show attempts
        adToShow.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _loadInterstitialAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _loadInterstitialAd();
          },
        );
        adToShow.show();
        _lastInterstitialTime = DateTime.now();
        _gameOverCount = 0;
      }
    }
  }

  void showRewardedAd({required VoidCallback onReward}) {
    if (_rewardedAd != null) {
      bool rewardEarned = false;
      final adToShow = _rewardedAd!;
      _rewardedAd = null; // Clear immediately

      adToShow.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadRewardedAd();
          // Only revive AFTER the ad is fully closed
          if (rewardEarned) {
            onReward();
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadRewardedAd();
        },
      );
      adToShow.show(onUserEarnedReward: (ad, reward) {
        rewardEarned = true;
      });
    } else {
      _loadRewardedAd();
    }
  }
}
