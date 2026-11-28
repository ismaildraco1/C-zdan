import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cihaza ait tercihler. Hesaba bağlı değildir, çıkış yapınca değişmez.
class SettingsController extends ChangeNotifier {
  static const _hideBalanceKey = 'hideBalance';

  bool _hideBalance = false;

  /// Açıksa portföy tutarları ve miktarları ekranda gizlenir.
  bool get hideBalance => _hideBalance;

  /// İlk ekrandan önce beklenmeli, yoksa gizli bakiye bir an görünür.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hideBalance = prefs.getBool(_hideBalanceKey) ?? false;
    } catch (_) {
      return; // Tercih okunamazsa varsayılanla devam edilir.
    }
    notifyListeners();
  }

  Future<void> setHideBalance(bool value) async {
    if (value == _hideBalance) return;
    _hideBalance = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hideBalanceKey, value);
    } catch (_) {
      // Kaydedilemezse seçim yalnızca bu oturumda geçerli kalır.
    }
  }
}
