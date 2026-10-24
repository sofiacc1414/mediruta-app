import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mediruta_app/shared/core/theme/modo_oscuro_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('arranca apagado si no hay preferencia guardada', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final notifier = ModoOscuroNotifier(prefs);

    expect(notifier.state, isFalse);
  });

  test('arranca con el valor ya guardado', () async {
    SharedPreferences.setMockInitialValues({'modo_oscuro': true});
    final prefs = await SharedPreferences.getInstance();

    final notifier = ModoOscuroNotifier(prefs);

    expect(notifier.state, isTrue);
  });

  test('cambiar() actualiza el estado y persiste', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifier = ModoOscuroNotifier(prefs);

    await notifier.cambiar(true);

    expect(notifier.state, isTrue);
    expect(prefs.getBool('modo_oscuro'), isTrue);
  });
}
