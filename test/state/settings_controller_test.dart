import 'package:cuzdan/state/settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('ilk açılışta bakiye görünür', () async {
    final settings = SettingsController();
    await settings.load();
    expect(settings.hideBalance, isFalse);
  });

  test('gizleme seçimi sonraki açılışta korunur', () async {
    final first = SettingsController();
    await first.load();
    await first.setHideBalance(true);

    final second = SettingsController();
    await second.load();
    expect(second.hideBalance, isTrue);
  });

  test('birleştirme ilk açılışta kapalıdır ve seçim korunur', () async {
    final first = SettingsController();
    await first.load();
    expect(first.mergeSameKind, isFalse);
    await first.setMergeSameKind(true);

    final second = SettingsController();
    await second.load();
    expect(second.mergeSameKind, isTrue);
    expect(second.hideBalance, isFalse);
  });

  test('değişiklik dinleyicilere kaydı beklemeden bildirilir', () {
    final settings = SettingsController();
    var calls = 0;
    settings.addListener(() => calls++);

    settings.setHideBalance(true);
    expect(settings.hideBalance, isTrue);
    expect(calls, 1);

    settings.setHideBalance(true);
    expect(calls, 1);
  });
}
