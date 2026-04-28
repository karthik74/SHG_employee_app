import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access to runtime configuration.
///
/// Values are sourced in this order:
///   1. Compile-time `--dart-define=KEY=value` (preferred for release builds).
///   2. In debug/profile builds only, `dotenv` (`.env` file) as a developer
///      convenience.
///
/// Production/release builds MUST NOT depend on a runtime `.env` file. The
/// `.env` file is no longer bundled as an asset and may be absent.
class EnvConfig {
  // --- Compile-time defines (set via `flutter build ... --dart-define=...`).
  // `String.fromEnvironment` is `const` and resolves at build time. An empty
  // string indicates the define was not provided.
  static const String _defApiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const String _defTenantId =
      String.fromEnvironment('TENANT_ID', defaultValue: '');
  static const String _defDevMode =
      String.fromEnvironment('DEV_MODE', defaultValue: '');

  /// Returns the value of [key], preferring the compile-time define.
  /// Falls back to dotenv only in non-release builds.
  static String? _lookup(String key, String compileTimeValue) {
    if (compileTimeValue.isNotEmpty) return compileTimeValue;
    if (!kReleaseMode) {
      try {
        final v = dotenv.maybeGet(key);
        if (v != null && v.isNotEmpty) return v;
      } catch (_) {
        // dotenv not initialized — fine in release-like flows.
      }
    }
    return null;
  }

  static String _required(String key, String compileTimeValue) {
    final value = _lookup(key, compileTimeValue);
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing required env var: $key. '
        'Provide it via --dart-define=$key=... at build time '
        '(or via .env in debug builds).',
      );
    }
    return value;
  }

  static String get apiBaseUrl => _required('API_BASE_URL', _defApiBaseUrl);
  static String get tenantId => _required('TENANT_ID', _defTenantId);

  /// Whether dev-mode behaviors (e.g. relaxed TLS in debug only) are enabled.
  ///
  /// Defaults to [kDebugMode] when unspecified. Note: callers should still
  /// guard sensitive dev-only behavior with `!kReleaseMode` themselves —
  /// this flag alone must never be enough to weaken security in a release
  /// build.
  static bool get isDevMode {
    final raw = _lookup('DEV_MODE', _defDevMode);
    if (raw == null || raw.isEmpty) return kDebugMode;
    return raw.toLowerCase() == 'true';
  }
}
