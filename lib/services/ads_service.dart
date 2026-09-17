import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ---------------------------------------------------------------------------
// AD UNIT ID'LERİ
//
// Şu anda Google'ın RESMİ TEST ID'leri kullanılıyor — bunlarla gerçek reklam
// gösterilir ama tıklamalar sayılmaz, para kazanmazsın. Test amaçlı
// güvenlidir, hesabının askıya alınmasına yol açmaz.
//
// AdMob panelinden kendi Ad Unit ID'lerini alınca SADECE bu dört satırı
// değiştirmen yeterli. Kodun geri kalanına dokunmana gerek yok.
// ---------------------------------------------------------------------------

const String _androidTestRewardedId = 'ca-app-pub-3940256099942544/5224354917';
const String _iosTestRewardedId = 'ca-app-pub-3940256099942544/1712485313';

// TODO: AdMob'dan aldığın gerçek Ad Unit ID'lerini buraya yaz, sonra
// yukarıdaki satırlar yerine bunları kullan (aşağıdaki getter'lar otomatik
// olarak gerçek ID boşsa test ID'sine düşer, yani hemen doldurmasan da kod
// çalışmaya devam eder).
const String _androidRealRewardedId = 'ca-app-pub-9125013882382987/9335513628';
const String _iosRealRewardedId = ''; // ör: 'ca-app-pub-1234567890123456/0987654321'

String get _rewardedAdUnitId {
  if (Platform.isAndroid) {
    return _androidRealRewardedId.isNotEmpty ? _androidRealRewardedId : _androidTestRewardedId;
  } else if (Platform.isIOS) {
    return _iosRealRewardedId.isNotEmpty ? _iosRealRewardedId : _iosTestRewardedId;
  }
  // Desteklenmeyen platform (web/masaüstü) — test ID'siyle devam et, zaten
  // reklam orada gösterilmeyecek.
  return _androidTestRewardedId;
}

/// Ödüllü (rewarded) reklamları yükleyip gösteren servis.
///
/// Kullanım: kullanıcı "Reklam İzle" butonuna bastığında [showRewardedAd]
/// çağrılır. Reklam gösterilip sonuna kadar izlenirse [onReward] tetiklenir
/// — sadece o zaman hakkı veriyoruz, videoyu atlarsa hiçbir şey vermiyoruz.
class AdsService {
  AdsService._internal();
  static final AdsService instance = AdsService._internal();
  factory AdsService() => instance;

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  static Future<void> initialize() async {
    // google_mobile_ads web platformunu desteklemiyor. Web'de bu çağrı
    // MissingPluginException fırlatıp main()'i durdurup uygulamayı bembeyaz
    // ekranda bırakıyordu — bu yüzden web'de tamamen atlıyoruz.
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
  }

  /// Bir sonraki gösterim için reklamı önceden yüklemeye başlar. Kullanıcı
  /// butona bastığı anda beklemesin diye, ekran açılır açılmaz veya bir
  /// reklam gösterildikten hemen sonra çağırmak en iyisi.
  void preloadAd() {
    if (kIsWeb) return; // Web'de reklam desteklenmiyor.
    if (_rewardedAd != null || _isLoading) return;
    _isLoading = true;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          debugPrint('Ödüllü reklam yüklendi.');
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _rewardedAd = null;
          debugPrint('Ödüllü reklam yüklenemedi: $error');
        },
      ),
    );
  }

  bool get isAdReady => _rewardedAd != null;

  /// Reklamı gösterir. Kullanıcı videoyu sonuna kadar izlerse [onReward]
  /// çağrılır (hakkı burada ver). İzlemeden kapatırsa hiçbir şey olmaz.
  /// [onAdNotReady] reklam henüz yüklenmediyse çağrılır — bu durumda UI
  /// tarafında kullanıcıya "reklam hazırlanıyor, birazdan tekrar dene"
  /// gibi bir mesaj gösterebilirsin.
  Future<void> showRewardedAd({
    required VoidCallback onReward,
    required VoidCallback onAdNotReady,
  }) async {
    if (kIsWeb) {
      // Web'de reklam SDK'sı hiç mevcut değil — nazikçe "hazır değil" de.
      onAdNotReady();
      return;
    }

    final ad = _rewardedAd;
    if (ad == null) {
      onAdNotReady();
      preloadAd(); // Bir dahaki sefere hazır olsun diye şimdi yüklemeyi dene.
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        preloadAd(); // Bir sonraki gösterim için hemen yeni reklam yükle.
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        debugPrint('Reklam gösterilemedi: $error');
        onAdNotReady();
        preloadAd();
      },
    );

    await ad.show(
      onUserEarnedReward: (ad, reward) {
        onReward();
      },
    );
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}