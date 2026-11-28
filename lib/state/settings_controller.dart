import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cihaza ait tercihler. Hesaba bağlı değildir, çıkış yapınca değişmez.
class SettingsController extends ChangeNotifier {
  static const _hideBalanceKey = 'hideBalance';
  static const _mergeSameKindKey = 'mergeSameKind';

  bool _hideBalance = false;
  bool _mergeSameKind = false;

  /// Açıksa portföy tutarları ve miktarları ekranda gizlenir.
  bool get hideBalance => _hideBalance;

  /// Açıksa aynı türdeki kayıtlar portföyde tek satırda gösterilir. Yalnızca
  /// görünümü değiştirir; kayıtlar ayrı ayrı saklanmaya devam eder.
  bool get mergeSameKind => _mergeSameKind;

  /// İlk ekrandan önce beklenmeli, yoksa gizli bakiye bir an görünür.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hideBalance = prefs.getBool(_hideBalanceKey) ?? false;
      _mergeSameKind = prefs.getBool(_mergeSameKindKey) ?? false;
    } catch (_) {
      return; // Tercih okunamazsa varsayılanla devam edilir.
    }
    notifyListeners();
  }

  Future<void> setHideBalance(bool value) async {
    if (value == _hideBalance) return;
    _hideBalance = value;
    notifyListeners();
    await _save(_hideBalanceKey, value);
  }

  Future<void> setMergeSameKind(bool value) async {
    if (value == _mergeSameKind) return;
    _mergeSameKind = value;
    notifyListeners();
    await _save(_mergeSameKindKey, value);
  }

  Future<void> _save(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {
      // Kaydedilemezse seçim yalnızca bu oturumda geçerli kalır.
    }
  }
}
