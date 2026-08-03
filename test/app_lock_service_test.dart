import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pj1/services/app_lock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('verifyPin succeeds only with the exact stored pin', () async {
    final service = AppLockService.instance;
    expect(await service.hasPin('user-1'), isFalse);

    await service.setPin('user-1', '1234');
    expect(await service.hasPin('user-1'), isTrue);

    expect(await service.verifyPin('user-1', '1234'), isTrue);
    expect(await service.verifyPin('user-1', '0000'), isFalse);
  });

  test('pins are stored per user and hashed', () async {
    final service = AppLockService.instance;
    await service.setPin('user-1', '1234');
    await service.setPin('user-2', '5678');

    // A different user's pin must not unlock user-1.
    expect(await service.verifyPin('user-1', '5678'), isFalse);
    expect(await service.verifyPin('user-2', '1234'), isFalse);

    // The stored value must not be the raw pin.
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('app_lock.pin.user-1');
    expect(raw, isNotNull);
    expect(raw, isNot('1234'));
  });

  test('clearPin removes the stored pin', () async {
    final service = AppLockService.instance;
    await service.setPin('user-1', '1234');
    await service.clearPin('user-1');

    expect(await service.hasPin('user-1'), isFalse);
    expect(await service.verifyPin('user-1', '1234'), isFalse);
  });
}
