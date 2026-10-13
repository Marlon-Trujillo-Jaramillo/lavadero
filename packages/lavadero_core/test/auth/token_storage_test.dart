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

  test('saveTokens never writes concurrently (web key-generation race)',
      () async {
    final storage = _ConcurrencyProbeStorage();
    await TokenStorage(storage: storage).saveTokens(
      accessToken: 'a',
      refreshToken: 'r',
    );

    expect(storage.maxInFlightWrites, 1);
    expect(storage.values.length, 2);
  });

  test('an unreadable token is treated as no session and storage is cleared',
      () async {
    final storage = _ConcurrencyProbeStorage()..failReads = true;
    final tokens = TokenStorage(storage: storage);

    expect(await tokens.readAccessToken(), isNull);
    expect(await tokens.hasSession(), isFalse);
    expect(storage.deletedKeys, isNotEmpty);
  });
}

/// Simula el almacenamiento web: cada escritura es asíncrona, y registra
/// cuántas hubo en vuelo a la vez.
class _ConcurrencyProbeStorage extends FlutterSecureStorage {
  _ConcurrencyProbeStorage();

  final Map<String, String> values = {};
  final List<String> deletedKeys = [];
  int _inFlight = 0;
  int maxInFlightWrites = 0;
  bool failReads = false;

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _inFlight++;
    if (_inFlight > maxInFlightWrites) maxInFlightWrites = _inFlight;
    await Future<void>.delayed(Duration.zero);
    values[key] = value!;
    _inFlight--;
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failReads) throw StateError('OperationError');
    return values[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    deletedKeys.add(key);
    values.remove(key);
  }
}
