import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:employee_app/config/env_config.dart';

/// NOTE: `String.fromEnvironment` defaults are compile-time constants. When
/// `flutter test` is invoked without `--dart-define=API_BASE_URL=...` (the
/// expected case for unit tests), the compile-time defaults resolve to the
/// empty string and `_lookup` falls through to the dotenv map. Every test
/// here therefore drives behavior through `dotenv.testLoad`, which is the
/// only source of values during a normal `flutter test` run.
///
/// We also assume `kReleaseMode` is false during `flutter test` (it is — the
/// test harness runs in profile/debug mode), so the dotenv branch in
/// `_lookup` is reachable.
void main() {
  // Make doubly sure no other test module left dotenv populated.
  setUp(() {
    dotenv.testLoad();
  });

  tearDown(() {
    dotenv.testLoad();
  });

  group('EnvConfig.apiBaseUrl', () {
    test('returns the value when dotenv provides it', () {
      dotenv.testLoad(fileInput: 'API_BASE_URL=https://example.com/api\n');
      expect(EnvConfig.apiBaseUrl, 'https://example.com/api');
    });

    test('throws StateError when no source provides it', () {
      // Empty dotenv + no --dart-define means no source has the key.
      dotenv.testLoad();
      expect(() => EnvConfig.apiBaseUrl, throwsA(isA<StateError>()));
    });
  });

  group('EnvConfig.tenantId', () {
    test('returns the value when dotenv provides it', () {
      dotenv.testLoad(fileInput: 'TENANT_ID=default\n');
      expect(EnvConfig.tenantId, 'default');
    });

    test('throws StateError when no source provides it', () {
      dotenv.testLoad();
      expect(() => EnvConfig.tenantId, throwsA(isA<StateError>()));
    });
  });

  group('EnvConfig.isDevMode', () {
    test('returns false when DEV_MODE="false"', () {
      dotenv.testLoad(fileInput: 'DEV_MODE=false\n');
      expect(EnvConfig.isDevMode, isFalse);
    });

    test('returns true when DEV_MODE="true"', () {
      dotenv.testLoad(fileInput: 'DEV_MODE=true\n');
      expect(EnvConfig.isDevMode, isTrue);
    });

    test('defaults to kDebugMode when no source sets DEV_MODE', () {
      dotenv.testLoad();
      expect(EnvConfig.isDevMode, kDebugMode);
    });
  });
}
