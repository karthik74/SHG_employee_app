import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../services/api_client.dart';
import '../../services/auth_session.dart';
import '../../services/sakhi_api.dart';

/// Owns all of the state for the Sakhi enrollment / list workflows.
///
/// Wraps the form's `TextEditingController`s, the various status flags,
/// the Aadhaar polling [Timer], the in-memory cached photo files, and the
/// dropdown reference data. Exposes the same set of mutations the original
/// monolithic screen performed; the screen layer is now responsible only for
/// triggering UI side-effects (snackbars, dialogs, navigation) in response to
/// the futures returned by this controller.
class SakhiFormController extends ChangeNotifier {
  SakhiFormController({SakhiApi? api}) : _sakhiApi = api ?? SakhiApi();

  final SakhiApi _sakhiApi;
  SakhiApi get api => _sakhiApi;

  // ---------------- My Sakhis ----------------
  bool _isLoadingSakhis = false;
  bool get isLoadingSakhis => _isLoadingSakhis;

  List<Map<String, String>> _sakhis = [];
  List<Map<String, String>> get sakhis => _sakhis;

  // ---------------- Form controllers ----------------
  final TextEditingController sakhiNameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController aadharNoController = TextEditingController();
  final TextEditingController panNoController = TextEditingController();
  final TextEditingController spouseNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController monthlyIncomeController = TextEditingController();
  final TextEditingController spouseMobileController = TextEditingController();

  // ---------------- Form selections ----------------
  int? selectedOfficeId;
  String? selectedOfficeName;
  int? selectedGramPanchayatId;
  int? occupationId;
  int? spouseOccupationId;

  List<dynamic> gramPanchayats = [];
  List<dynamic> professions = [];

  // ---------------- Submission flag ----------------
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  // ---------------- Aadhaar verification state ----------------
  bool _isAadharVerifying = false;
  bool get isAadharVerifying => _isAadharVerifying;
  set isAadharVerifying(bool value) {
    if (_isAadharVerifying == value) return;
    _isAadharVerifying = value;
    notifyListeners();
  }

  bool _aadharLinkSent = false;
  bool get aadharLinkSent => _aadharLinkSent;

  bool _isFetchingAadhar = false;
  bool get isFetchingAadhar => _isFetchingAadhar;
  set isFetchingAadhar(bool value) {
    if (_isFetchingAadhar == value) return;
    _isFetchingAadhar = value;
    notifyListeners();
  }

  bool _aadharFetched = false;
  bool get aadharFetched => _aadharFetched;

  String? aadharReferenceId;
  String? aadharTransactionId;
  Timer? _aadharPollTimer;
  Timer? get aadharPollTimer => _aadharPollTimer;
  int _aadharPollAttempts = 0;

  // ---------------- Sakhi mobile OTP state ----------------
  bool _sakhiMobileVerified = false;
  bool get sakhiMobileVerified => _sakhiMobileVerified;
  set sakhiMobileVerified(bool value) {
    if (_sakhiMobileVerified == value) return;
    _sakhiMobileVerified = value;
    notifyListeners();
  }

  bool _isSendingSakhiOtp = false;
  bool get isSendingSakhiOtp => _isSendingSakhiOtp;
  set isSendingSakhiOtp(bool value) {
    if (_isSendingSakhiOtp == value) return;
    _isSendingSakhiOtp = value;
    notifyListeners();
  }

  // ---------------- Image files ----------------
  File? sakhiPhoto;
  File? aadharPhoto;
  File? panPhoto;

  void setSakhiPhoto(File? file) {
    sakhiPhoto = file;
    notifyListeners();
  }

  void setAadharPhoto(File? file) {
    aadharPhoto = file;
    notifyListeners();
  }

  void setPanPhoto(File? file) {
    panPhoto = file;
    notifyListeners();
  }

  void attachMobileListener() {
    mobileController.addListener(() {
      if (_sakhiMobileVerified) {
        _sakhiMobileVerified = false;
        notifyListeners();
      }
    });
  }

  /// Mark the Aadhaar verification UI as needing a re-send when the user
  /// edits the Aadhaar number. Mirrors the behaviour of the original onChanged
  /// handler exactly: only resets state if either flag is currently set.
  void onAadharNumberChanged() {
    if (_aadharLinkSent || _aadharFetched) {
      _aadharLinkSent = false;
      _aadharFetched = false;
      notifyListeners();
    }
  }

  // ---------------- Sakhi list ----------------
  Future<void> fetchSakhis() async {
    _isLoadingSakhis = true;
    notifyListeners();
    try {
      final items = await _sakhiApi.fetchSakhis(
        officeId: AuthSession.instance.officeId,
      );
      _sakhis = items.map<Map<String, String>>((item) {
        final statusEnum = item['statusEnum'];
        String status = 'Active';
        if (statusEnum == 100) status = 'Pending';
        if (statusEnum == 200) status = 'Active';

        return {
          'id': item['resourceId']?.toString() ?? item['id']?.toString() ?? 'N/A',
          'code': item['sakhiCode']?.toString() ?? '-',
          'name': item['sakhiName']?.toString() ?? 'Unknown',
          'mobile': item['mobileNumber']?.toString() ?? 'N/A',
          'branch': item['officeName']?.toString() ?? item['branchName']?.toString() ?? 'Main Branch',
          'status': status,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading sakhis: $e');
    } finally {
      _isLoadingSakhis = false;
      notifyListeners();
    }
  }

  // ---------------- Template / dropdown data ----------------
  Future<void> loadTemplateData() async {
    final userOfficeId = AuthSession.instance.officeId;
    final userOfficeName = AuthSession.instance.officeName;
    if (userOfficeId != null) {
      selectedOfficeId = userOfficeId;
      selectedOfficeName = userOfficeName;
      notifyListeners();
    }

    try {
      if (userOfficeId != null) {
        final office = await _sakhiApi.fetchOfficeById(userOfficeId);
        if (office.isNotEmpty) {
          selectedOfficeId = (office['id'] is int) ? office['id'] as int : userOfficeId;
          selectedOfficeName = office['name']?.toString() ?? userOfficeName;
          notifyListeners();
        }

        final panchayats = await _sakhiApi.fetchGramPanchayats(userOfficeId);
        gramPanchayats = panchayats;
        if (panchayats.isNotEmpty) {
          selectedGramPanchayatId = panchayats[0]['id'] is int ? panchayats[0]['id'] as int : null;
        }
        notifyListeners();
      }

      final template = await _sakhiApi.fetchSakhiTemplate();
      professions = template['professionOptions'] ?? [];
      if (professions.isNotEmpty) {
        occupationId = professions[0]['id'];
        spouseOccupationId = professions[0]['id'];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading template data: $e');
    }
  }

  void setSelectedGramPanchayatId(int? value) {
    selectedGramPanchayatId = value;
    notifyListeners();
  }

  void setOccupationId(int? value) {
    occupationId = value;
    notifyListeners();
  }

  void setSpouseOccupationId(int? value) {
    spouseOccupationId = value;
    notifyListeners();
  }

  // ---------------- Aadhaar polling ----------------
  /// Mark that an Aadhaar verification link has been launched (or attempted),
  /// recording the reference/transaction ids returned by the server. The
  /// caller is responsible for then invoking [startAadharAutoFetch] when a
  /// browser launch was successful.
  void markAadharLinkSent({
    required bool launched,
    required String? refId,
    required String? txnId,
  }) {
    _aadharLinkSent = launched;
    aadharReferenceId = refId;
    aadharTransactionId = txnId;
    _aadharFetched = false;
    notifyListeners();
  }

  void startAadharAutoFetch(Future<void> Function() onTick) {
    _aadharPollTimer?.cancel();
    _aadharPollAttempts = 0;
    _aadharPollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_aadharFetched) {
        timer.cancel();
        return;
      }
      _aadharPollAttempts++;
      if (_aadharPollAttempts > 36) {
        timer.cancel();
        return;
      }
      await onTick();
    });
  }

  void cancelAadharPolling() {
    _aadharPollTimer?.cancel();
  }

  void markAadharFetched() {
    _aadharPollTimer?.cancel();
    _aadharFetched = true;
    _isFetchingAadhar = false;
    notifyListeners();
  }

  void applyAadharData(Map data) {
    final name = data['name']?.toString();
    final dob = data['dob']?.toString();
    final address = data['address']?.toString();
    if (name != null && name.isNotEmpty) sakhiNameController.text = name;
    if (dob != null && dob.isNotEmpty) dobController.text = dob;
    if (address != null && address.isNotEmpty) addressController.text = address;
    notifyListeners();
  }

  // ---------------- Submission helpers ----------------
  Map<String, dynamic> buildPayload() => {
        'officeId': selectedOfficeId,
        'gramPanchayatId': selectedGramPanchayatId,
        'sakhiName': sakhiNameController.text.trim(),
        'dob': dobController.text.trim(),
        'mobileNumber': mobileController.text.trim(),
        'aadharNo': aadharNoController.text.trim(),
        'panNo': panNoController.text.trim(),
        'spouseName': spouseNameController.text.trim(),
        'spouseOccupation': spouseOccupationId,
        'occupation': occupationId,
        'address': addressController.text.trim(),
        'monthlyIncome': monthlyIncomeController.text.trim(),
        'spouseMobile': spouseMobileController.text.trim(),
        'dateFormat': 'dd-MM-yyyy',
        'locale': 'en',
      };

  /// Reset the in-memory tokens after a successful submission. Mirrors the
  /// original `_resetFormTokens()` method one-for-one. Note the original did
  /// **not** reset the dropdown selections or the cached lookup lists; we
  /// preserve that behaviour exactly.
  void resetFormTokens() {
    _sakhiMobileVerified = false;
    sakhiNameController.clear();
    dobController.clear();
    mobileController.clear();
    aadharNoController.clear();
    panNoController.clear();
    spouseNameController.clear();
    addressController.clear();
    monthlyIncomeController.clear();
    spouseMobileController.clear();
    sakhiPhoto = null;
    aadharPhoto = null;
    panPhoto = null;
    _aadharLinkSent = false;
    _aadharFetched = false;
    aadharReferenceId = null;
    aadharTransactionId = null;
    _aadharPollTimer?.cancel();
    notifyListeners();
  }

  String extractErrorMessage(Object e) {
    if (e is ApiException) {
      final body = e.body;
      if (body != null && body.isNotEmpty) {
        try {
          final decoded = jsonDecode(body);
          if (decoded is Map) {
            final errors = decoded['errors'];
            if (errors is List && errors.isNotEmpty) {
              final first = errors.first;
              if (first is Map) {
                final msg = first['defaultUserMessage']?.toString()
                    ?? first['developerMessage']?.toString();
                if (msg != null && msg.isNotEmpty) return msg;
              }
            }
            final top = decoded['defaultUserMessage']?.toString()
                ?? decoded['developerMessage']?.toString();
            if (top != null && top.isNotEmpty) return top;
          }
        } catch (_) {}
      }
      return e.message;
    }
    return e.toString();
  }

  @override
  void dispose() {
    _aadharPollTimer?.cancel();
    sakhiNameController.dispose();
    dobController.dispose();
    mobileController.dispose();
    aadharNoController.dispose();
    panNoController.dispose();
    spouseNameController.dispose();
    addressController.dispose();
    monthlyIncomeController.dispose();
    spouseMobileController.dispose();
    super.dispose();
  }
}
