import 'package:flutter_test/flutter_test.dart';

import 'package:employee_app/services/version_api.dart';

void main() {
  group('VersionInfo.fromJson', () {
    test('parses a flat response', () {
      final v = VersionInfo.fromJson({
        'versionName': '1.0.4',
        'forceUpdate': 'true',
        'url': 'https://play.google.com/store/apps/details?id=com.example',
      });
      expect(v.versionName, '1.0.4');
      expect(v.forceUpdate, isTrue);
      expect(v.url,
          'https://play.google.com/store/apps/details?id=com.example');
    });

    test('parses forceUpdate from the literal string "true"', () {
      final v = VersionInfo.fromJson({
        'versionName': '2.0',
        'forceUpdate': 'true',
        'url': 'x',
      });
      expect(v.forceUpdate, isTrue);
    });

    test('treats forceUpdate other than "true" as false', () {
      final v = VersionInfo.fromJson({
        'versionName': '2.0',
        'forceUpdate': 'false',
        'url': 'x',
      });
      expect(v.forceUpdate, isFalse);
    });

    test('case-insensitively accepts "TRUE"', () {
      final v = VersionInfo.fromJson({
        'versionName': '2.0',
        'forceUpdate': 'TRUE',
        'url': 'x',
      });
      expect(v.forceUpdate, isTrue);
    });

    test('defaults gracefully when fields are missing', () {
      final v = VersionInfo.fromJson(<String, dynamic>{});
      expect(v.versionName, '');
      expect(v.url, '');
      expect(v.forceUpdate, isFalse);
    });

    test('defaults gracefully when fields are explicitly null', () {
      final v = VersionInfo.fromJson({
        'versionName': null,
        'forceUpdate': null,
        'url': null,
      });
      expect(v.versionName, '');
      expect(v.url, '');
      expect(v.forceUpdate, isFalse);
    });

    test('coerces non-string scalar fields via toString()', () {
      // Some servers send versionName as a number.
      final v = VersionInfo.fromJson({
        'versionName': 1.04,
        'forceUpdate': 'false',
        'url': 'x',
      });
      expect(v.versionName, '1.04');
    });
  });

  // The wrapped `{"body": {...}}` shape is unwrapped inside
  // VersionApi.fetchVersionControl() before VersionInfo.fromJson is called.
  // We exercise that unwrapping logic indirectly here by constructing the
  // payload the same way the production code does.
  group('VersionApi response unwrapping', () {
    Map<String, dynamic> unwrap(dynamic decoded) {
      return (decoded is Map && decoded['body'] is Map)
          ? Map<String, dynamic>.from(decoded['body'] as Map)
          : Map<String, dynamic>.from(decoded as Map);
    }

    test('handles the bare object shape', () {
      final body = unwrap({
        'versionName': '1.0',
        'forceUpdate': 'true',
        'url': 'u',
      });
      final v = VersionInfo.fromJson(body);
      expect(v.versionName, '1.0');
      expect(v.forceUpdate, isTrue);
      expect(v.url, 'u');
    });

    test('handles the {"body": {...}} envelope shape', () {
      final body = unwrap({
        'body': {
          'versionName': '1.0',
          'forceUpdate': 'true',
          'url': 'u',
        },
      });
      final v = VersionInfo.fromJson(body);
      expect(v.versionName, '1.0');
      expect(v.forceUpdate, isTrue);
      expect(v.url, 'u');
    });
  });
}
