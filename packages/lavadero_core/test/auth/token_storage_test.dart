import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';

void main() {
  late Map<String, String> backingStore;
  late TokenStorage tokenStorage;

  setUp(() {
    backingStore = {};
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform(backingStore);
    tokenStorage = TokenStorage(storage: const FlutterSecureStorage());
  });

  test('hasSession is false when nothing stored', () async {
    expect(await tokenStorage.hasSession(), isFalse);
  });

  test('saveTokens persists both tokens and hasSession becomes true',
      () async {
    await tokenStorage.saveTokens(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
    );

    expect(await tokenStorage.readAccessToken(), 'access-1');
    expect(await tokenStorage.readRefreshToken(), 'refresh-1');
    expect(await tokenStorage.hasSession(), isTrue);
  });

  test('clear removes both tokens', () async {
    await tokenStorage.saveTokens(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
    );
    await tokenStorage.clear();

    expect(await tokenStorage.readAccessToken(), isNull);
    expect(await tokenStorage.readRefreshToken(), isNull);
    expect(await tokenStorage.hasSession(), isFalse);
  });
}
