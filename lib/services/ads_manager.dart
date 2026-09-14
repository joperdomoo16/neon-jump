import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AdsManager {
  static final AdsManager _instance = AdsManager._internal();
  factory AdsManager() => _instance;
  AdsManager._internal();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  
  int _gameOverCount = 0;
  DateTime? _lastInterstitialTime;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Constants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: Constants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
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
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _loadInterstitialAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _loadInterstitialAd();
          },
        );
        _interstitialAd!.show();
        _lastInterstitialTime = DateTime.now();
        _gameOverCount = 0;
      }
    }
  }

  void showRewardedAd({required VoidCallback onReward}) {
    if (_rewardedAd != null) {
      bool rewardEarned = false;

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
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
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        // Just mark the reward as earned; don't act yet
        rewardEarned = true;
      });
      _rewardedAd = null;
    }
  }
}
