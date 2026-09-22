import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AdsManager {
  static final AdsManager _instance = AdsManager._internal();
  factory AdsManager() => _instance;
  AdsManager._internal();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isLoadingInterstitial = false;
  bool _isLoadingRewarded = false;
  
  int _gameOverCount = 0;
  DateTime? _lastInterstitialTime;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  void _loadInterstitialAd() {
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
          // Retry after delay (e.g. offline to online transition)
          Future.delayed(const Duration(seconds: 30), () => _loadInterstitialAd());
        },
      ),
    );
  }

  void _loadRewardedAd() {
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
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), () => _loadRewardedAd());
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
