import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _base64Token;
  String? _username;
  int? _userId;
  int? _staffId;
  int? _officeId;
  String? _officeName;
  List<String> _permissions = const [];

  bool get isLoggedIn => _base64Token != null && _base64Token!.isNotEmpty;
  String? get base64Token => _base64Token;
  String? get username => _username;
  int? get userId => _userId;
  int? get staffId => _staffId;
  int? get officeId => _officeId;
  String? get officeName => _officeName;
  List<String> get permissions => _permissions;

  String? get authorizationHeader =>
      _base64Token == null ? null : 'Basic $_base64Token';

  static const _keyToken = 'auth_token';
  static const _keyUser = 'auth_user';
  static const _keyUserId = 'auth_user_id';
  static const _keyStaffId = 'auth_staff_id';
  static const _keyOfficeId = 'auth_office_id';
  static const _keyOfficeName = 'auth_office_name';
  static const _keyPerms = 'auth_perms';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Try to load token from secure storage.
    _base64Token = await _secureStorage.read(key: _keyToken);

    // 2. Migration: if secure storage has no token but SharedPreferences
    //    has a legacy one, copy it over and remove the plaintext copy.
    if (_base64Token == null || _base64Token!.isEmpty) {
      final legacyToken = prefs.getString(_keyToken);
      if (legacyToken != null && legacyToken.isNotEmpty) {
        await _secureStorage.write(key: _keyToken, value: legacyToken);
        await prefs.remove(_keyToken);
        _base64Token = legacyToken;
      }
    }

    // 3. Load the rest of the (non-sensitive) fields from SharedPreferences.
    _username = prefs.getString(_keyUser);
    _userId = prefs.getInt(_keyUserId);
    _staffId = prefs.getInt(_keyStaffId);
    _officeId = prefs.getInt(_keyOfficeId);
    _officeName = prefs.getString(_keyOfficeName);
    _permissions = prefs.getStringList(_keyPerms) ?? const [];
  }

  Future<void> saveFromAuthResponse(Map<String, dynamic> response) async {
    _base64Token = response['base64EncodedAuthenticationKey']?.toString();
    _username = response['username']?.toString();
    _userId = response['userId'] is int ? response['userId'] as int : null;
    final staff = response['staffId'] ?? response['staff']?['id'];
    _staffId = staff is int ? staff : (staff is String ? int.tryParse(staff) : null);
    _officeId = response['officeId'] is int ? response['officeId'] as int : null;
    _officeName = response['officeName']?.toString();
    final perms = response['permissions'];
    _permissions = (perms is List) ? perms.map((e) => e.toString()).toList() : const [];

    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();

    // Token goes to secure storage (Android Keystore / iOS Keychain).
    if (_base64Token != null) {
      await _secureStorage.write(key: _keyToken, value: _base64Token!);
    } else {
      await _secureStorage.delete(key: _keyToken);
    }

    if (_username != null) await prefs.setString(_keyUser, _username!);
    if (_userId != null) await prefs.setInt(_keyUserId, _userId!);
    if (_staffId != null) await prefs.setInt(_keyStaffId, _staffId!);
    if (_officeId != null) await prefs.setInt(_keyOfficeId, _officeId!);
    if (_officeName != null) await prefs.setString(_keyOfficeName, _officeName!);
    await prefs.setStringList(_keyPerms, _permissions);
  }

  Future<void> clear() async {
    _base64Token = null;
    _username = null;
    _userId = null;
    _staffId = null;
    _officeId = null;
    _officeName = null;
    _permissions = const [];

    // Delete only the token from secure storage.
    await _secureStorage.delete(key: _keyToken);

    // Remove only the seven auth keys this class owns from SharedPreferences
    // (do NOT call prefs.clear() — that would wipe unrelated app preferences).
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyStaffId);
    await prefs.remove(_keyOfficeId);
    await prefs.remove(_keyOfficeName);
    await prefs.remove(_keyPerms);
  }
}
