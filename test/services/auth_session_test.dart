import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:employee_app/services/auth_session.dart';

/// Keys this class is documented to own. Used to assert `clear()` only deletes
/// these and leaves unrelated SharedPreferences entries intact.
const _ownedPrefsKeys = <String>{
  'auth_token',
  'auth_user',
  'auth_user_id',
  'auth_staff_id',
  'auth_office_id',
  'auth_office_name',
  'auth_perms',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // AuthSession is a singleton so we have to reset its in-memory state between
  // tests by re-init-ing against a fresh, empty backing store. (There is no
  // public reset method; calling `clear()` followed by `init()` against fresh
  // mocks is equivalent.)
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await AuthSession.instance.clear();
  });

  group('init()', () {
    test('on a clean state leaves all fields null/empty', () async {
      await AuthSession.instance.init();

      final s = AuthSession.instance;
      expect(s.base64Token, isNull);
      expect(s.username, isNull);
      expect(s.userId, isNull);
      expect(s.staffId, isNull);
      expect(s.officeId, isNull);
      expect(s.officeName, isNull);
      expect(s.permissions, isEmpty);
      expect(s.isLoggedIn, isFalse);
      expect(s.authorizationHeader, isNull);
    });

    test('migrates a legacy plaintext token from SharedPreferences', () async {
      // Pre-seed: legacy plaintext token in SharedPreferences, secure storage
      // empty.
      SharedPreferences.setMockInitialValues({'auth_token': 'abc123'});
      FlutterSecureStorage.setMockInitialValues({});

      await AuthSession.instance.init();

      // 1. The token is now loaded into the singleton.
      expect(AuthSession.instance.base64Token, 'abc123');

      // 2. The token has been written to secure storage.
      const secure = FlutterSecureStorage();
      expect(await secure.read(key: 'auth_token'), 'abc123');

      // 3. The legacy plaintext copy has been removed from SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
    });

    test('prefers the secure-storage token over a legacy prefs token',
        () async {
      // Both present — secure storage wins, no migration is performed.
      SharedPreferences.setMockInitialValues({'auth_token': 'legacy'});
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'secure'});

      await AuthSession.instance.init();

      expect(AuthSession.instance.base64Token, 'secure');
      // Legacy key is left untouched (we only delete it during migration).
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'legacy');
    });
  });

  group('saveFromAuthResponse() / clear()', () {
    test('populates fields and persists them', () async {
      await AuthSession.instance.saveFromAuthResponse({
        'base64EncodedAuthenticationKey': 'tok-xyz',
        'username': 'alice',
        'userId': 42,
        'staffId': 7,
        'officeId': 3,
        'officeName': 'HQ',
        'permissions': ['READ', 'WRITE'],
      });

      final s = AuthSession.instance;
      expect(s.base64Token, 'tok-xyz');
      expect(s.username, 'alice');
      expect(s.userId, 42);
      expect(s.staffId, 7);
      expect(s.officeId, 3);
      expect(s.officeName, 'HQ');
      expect(s.permissions, ['READ', 'WRITE']);
      expect(s.isLoggedIn, isTrue);

      // Token landed in secure storage, not SharedPreferences.
      const secure = FlutterSecureStorage();
      expect(await secure.read(key: 'auth_token'), 'tok-xyz');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull,
          reason: 'token must NOT be persisted to SharedPreferences');
      expect(prefs.getString('auth_user'), 'alice');
      expect(prefs.getInt('auth_user_id'), 42);
      expect(prefs.getInt('auth_staff_id'), 7);
      expect(prefs.getInt('auth_office_id'), 3);
      expect(prefs.getString('auth_office_name'), 'HQ');
      expect(prefs.getStringList('auth_perms'), ['READ', 'WRITE']);
    });

    test('parses staffId from a nested staff.id object', () async {
      await AuthSession.instance.saveFromAuthResponse({
        'base64EncodedAuthenticationKey': 't',
        'staff': {'id': 99},
      });
      expect(AuthSession.instance.staffId, 99);
    });

    test('clear() removes only the seven owned keys', () async {
      // Seed an unrelated preference that must NOT be wiped.
      SharedPreferences.setMockInitialValues({
        'unrelated_key': 'keep me',
        'another_app_setting': 'also keep',
      });
      FlutterSecureStorage.setMockInitialValues({});

      // Re-fetch the singleton because setMockInitialValues replaces the
      // backing store.
      await AuthSession.instance.saveFromAuthResponse({
        'base64EncodedAuthenticationKey': 'tok',
        'username': 'alice',
        'userId': 1,
        'staffId': 2,
        'officeId': 3,
        'officeName': 'HQ',
        'permissions': ['X'],
      });

      // Sanity: all owned keys exist now.
      final prefsBefore = await SharedPreferences.getInstance();
      for (final k in _ownedPrefsKeys) {
        // 'auth_token' is the only one that lives in secure storage, not prefs.
        if (k == 'auth_token') continue;
        expect(prefsBefore.getKeys(), contains(k),
            reason: 'expected $k to be set after saveFromAuthResponse');
      }

      await AuthSession.instance.clear();

      // In-memory state is wiped.
      expect(AuthSession.instance.isLoggedIn, isFalse);
      expect(AuthSession.instance.username, isNull);

      // Secure storage cleared of the token.
      const secure = FlutterSecureStorage();
      expect(await secure.read(key: 'auth_token'), isNull);

      // Only the owned keys are removed from prefs.
      final prefsAfter = await SharedPreferences.getInstance();
      final remaining = prefsAfter.getKeys();
      expect(remaining, contains('unrelated_key'));
      expect(remaining, contains('another_app_setting'));
      expect(prefsAfter.getString('unrelated_key'), 'keep me');
      expect(prefsAfter.getString('another_app_setting'), 'also keep');
      for (final k in _ownedPrefsKeys) {
        expect(remaining, isNot(contains(k)),
            reason: 'clear() must remove owned key $k');
      }
    });
  });

  group('authorizationHeader', () {
    test('returns "Basic <token>" when logged in', () async {
      await AuthSession.instance.saveFromAuthResponse({
        'base64EncodedAuthenticationKey': 'abcDEF==',
      });
      expect(AuthSession.instance.authorizationHeader, 'Basic abcDEF==');
    });

    test('returns null when not logged in', () async {
      // Fresh setUp guarantees cleared state.
      expect(AuthSession.instance.authorizationHeader, isNull);
    });
  });

  group('isLoggedIn', () {
    test('is true after save and false after clear', () async {
      expect(AuthSession.instance.isLoggedIn, isFalse);

      await AuthSession.instance.saveFromAuthResponse({
        'base64EncodedAuthenticationKey': 'tok',
      });
      expect(AuthSession.instance.isLoggedIn, isTrue);

      await AuthSession.instance.clear();
      expect(AuthSession.instance.isLoggedIn, isFalse);
    });
  });
}
