import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:employee_app/services/api_client.dart';

/// Tests for the pure helpers inside `ApiClient`.
///
/// Approach: the spec offered (a) inject a mocked `http.Client` and (b) mark
/// the private helpers `@visibleForTesting`. We chose (b) — it's the
/// lower-disruption change because the existing `ApiClient` is a singleton
/// with a hard-coded internal `http.Client` and no constructor for injection.
/// Adding `@visibleForTesting` static hooks (`buildUriForTesting`,
/// `redactBodyForTesting`, `handleForTesting`) preserves the singleton API
/// while making the pure helpers reachable from tests.
///
/// We do NOT exercise real network methods (`get`, `post`, etc.) here — those
/// would require either a live server or a more invasive refactor to inject
/// `http.Client`. They are documented as out of scope for this test file.
void main() {
  group('redactBodyForTesting', () {
    test('redacts each of the seven sensitive keys at the top level', () {
      final out = ApiClient.redactBodyForTesting({
        'username': 'alice',
        'password': 'hunter2',
        'pin': '0000',
        'otp': '123456',
        'token': 'abc',
        'secret': 'shh',
        'authorization': 'Basic xyz',
        'base64EncodedAuthenticationKey': 'long-base64==',
      }) as Map;

      expect(out['username'], 'alice');
      expect(out['password'], '<redacted>');
      expect(out['pin'], '<redacted>');
      expect(out['otp'], '<redacted>');
      expect(out['token'], '<redacted>');
      expect(out['secret'], '<redacted>');
      expect(out['authorization'], '<redacted>');
      expect(out['base64EncodedAuthenticationKey'], '<redacted>');
    });

    test('matches keys case-insensitively', () {
      final out = ApiClient.redactBodyForTesting({
        'PASSWORD': 'p',
        'Pin': '1',
        'OTP': '2',
        'Token': '3',
        'Secret': '4',
        'Authorization': 'Basic z',
        'Base64EncodedAuthenticationKey': 'k',
      }) as Map;

      expect(out['PASSWORD'], '<redacted>');
      expect(out['Pin'], '<redacted>');
      expect(out['OTP'], '<redacted>');
      expect(out['Token'], '<redacted>');
      expect(out['Secret'], '<redacted>');
      expect(out['Authorization'], '<redacted>');
      expect(out['Base64EncodedAuthenticationKey'], '<redacted>');
    });

    test('leaves non-sensitive keys intact', () {
      final out = ApiClient.redactBodyForTesting({
        'username': 'alice',
        'email': 'a@b.c',
        'count': 7,
        'items': [1, 2, 3],
      }) as Map;

      expect(out['username'], 'alice');
      expect(out['email'], 'a@b.c');
      expect(out['count'], 7);
      expect(out['items'], [1, 2, 3]);
    });

    test('recurses into nested maps', () {
      final out = ApiClient.redactBodyForTesting({
        'user': {
          'name': 'alice',
          'password': 'hunter2',
          'profile': {
            'token': 'inner-tok',
            'displayName': 'Alice',
          },
        },
      }) as Map;

      final user = out['user'] as Map;
      expect(user['name'], 'alice');
      expect(user['password'], '<redacted>');
      final profile = user['profile'] as Map;
      expect(profile['token'], '<redacted>');
      expect(profile['displayName'], 'Alice');
    });

    test('recurses into lists', () {
      final out = ApiClient.redactBodyForTesting({
        'users': [
          {'name': 'a', 'password': 'p1'},
          {'name': 'b', 'password': 'p2'},
        ],
      }) as Map;

      final users = out['users'] as List;
      expect(users, hasLength(2));
      expect((users[0] as Map)['name'], 'a');
      expect((users[0] as Map)['password'], '<redacted>');
      expect((users[1] as Map)['password'], '<redacted>');
    });

    test('decodes JSON-encoded strings and redacts inside them', () {
      final encoded = jsonEncode({
        'username': 'alice',
        'password': 'hunter2',
      });

      final out = ApiClient.redactBodyForTesting(encoded) as Map;
      expect(out['username'], 'alice');
      expect(out['password'], '<redacted>');
    });

    test('returns a non-JSON string unchanged', () {
      final out = ApiClient.redactBodyForTesting('hello world');
      expect(out, 'hello world');
    });

    test('passes scalar values through', () {
      expect(ApiClient.redactBodyForTesting(null), isNull);
      expect(ApiClient.redactBodyForTesting(42), 42);
      expect(ApiClient.redactBodyForTesting(true), true);
    });
  });

  group('ApiException', () {
    test('toString() includes the status code and message', () {
      final ex = ApiException(404, 'Not Found');
      final s = ex.toString();
      expect(s, contains('404'));
      expect(s, contains('Not Found'));
    });

    test('exposes statusCode, message and optional body', () {
      final ex = ApiException(500, 'boom', 'server stack trace');
      expect(ex.statusCode, 500);
      expect(ex.message, 'boom');
      expect(ex.body, 'server stack trace');
    });

    test('body is null when not supplied', () {
      final ex = ApiException(401, 'unauth');
      expect(ex.body, isNull);
    });
  });

  group('handleForTesting', () {
    test('returns parsed JSON on 2xx responses with a JSON body', () {
      final response = http.Response('{"ok": true, "n": 1}', 200);
      final result = ApiClient.handleForTesting(response) as Map;
      expect(result['ok'], isTrue);
      expect(result['n'], 1);
    });

    test('returns null on 2xx with empty body', () {
      final result = ApiClient.handleForTesting(http.Response('', 204));
      expect(result, isNull);
    });

    test('returns the raw string when body is non-JSON on 2xx', () {
      final result =
          ApiClient.handleForTesting(http.Response('not json', 200));
      expect(result, 'not json');
    });

    test('throws ApiException with status and body on non-2xx', () {
      final response = http.Response('{"error":"nope"}', 422);
      expect(
        () => ApiClient.handleForTesting(response),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.body, 'body', '{"error":"nope"}'),
        ),
      );
    });
  });

  group('buildUriForTesting', () {
    setUp(() {
      // buildUri reads EnvConfig.apiBaseUrl, so we have to seed dotenv.
      dotenv.testLoad(fileInput: 'API_BASE_URL=https://example.com/api/\n');
    });

    tearDown(() {
      dotenv.testLoad();
    });

    test('strips a trailing slash from the base URL', () {
      final uri = ApiClient.buildUriForTesting('/things');
      expect(uri.toString(), 'https://example.com/api/things');
    });

    test('prepends a leading slash when the path lacks one', () {
      final uri = ApiClient.buildUriForTesting('things');
      expect(uri.toString(), 'https://example.com/api/things');
    });

    test('keeps the leading slash when the path already has one', () {
      final uri = ApiClient.buildUriForTesting('/things/42');
      expect(uri.toString(), 'https://example.com/api/things/42');
    });

    test('appends query parameters, stringifying non-string values', () {
      final uri = ApiClient.buildUriForTesting('/things', {
        'limit': 10,
        'order': 'asc',
      });
      expect(uri.queryParameters['limit'], '10');
      expect(uri.queryParameters['order'], 'asc');
      expect(uri.path, '/api/things');
    });

    test('omits the query string when no params are supplied', () {
      final uri = ApiClient.buildUriForTesting('/things');
      expect(uri.hasQuery, isFalse);
    });
  });
}
