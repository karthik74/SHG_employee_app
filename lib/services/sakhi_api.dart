import 'dart:io';
import 'api_client.dart';

class SakhiApi {
  final ApiClient _client;
  SakhiApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  Future<List<dynamic>> fetchSakhis({int? officeId}) async {
    final decoded = await _client.get(
      '/sakhi',
      query: officeId != null ? {'officeId': officeId} : null,
    );
    if (decoded is Map && decoded['pageItems'] is List) {
      return decoded['pageItems'] as List;
    }
    if (decoded is List) return decoded;
    return const [];
  }

  Future<List<dynamic>> fetchOffices() async {
    final decoded = await _client.get('/offices');
    if (decoded is List) return decoded;
    return const [];
  }

  Future<Map<String, dynamic>> fetchOfficeById(int officeId) async {
    final decoded = await _client.get('/offices/$officeId');
    return (decoded is Map<String, dynamic>) ? decoded : <String, dynamic>{};
  }

  Future<List<dynamic>> fetchGramPanchayats(int officeId) async {
    final decoded = await _client.get('/grampanchayats', query: {'officeId': officeId});
    if (decoded is List) return decoded;
    return const [];
  }

  Future<Map<String, dynamic>> fetchSakhiTemplate() async {
    final decoded = await _client.get('/sakhi/template');
    return (decoded is Map<String, dynamic>) ? decoded : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> createSakhi(Map<String, dynamic> payload) async {
    final decoded = await _client.post('/sakhi', body: payload);
    return (decoded is Map<String, dynamic>) ? decoded : <String, dynamic>{};
  }

  Future<void> uploadSakhiImage(String resourceId, File file) async {
    await _client.uploadFile('/sakhi/$resourceId/images', file);
  }

  Future<void> uploadAadhar(String resourceId, File file) async {
    await _client.uploadFile('/sakhi/$resourceId/aadhar', file);
  }

  Future<void> uploadPan(String resourceId, File file) async {
    await _client.uploadFile('/sakhi/$resourceId/pan', file);
  }

  Future<void> sendOtp(String mobileNumber) async {
    await _client.post('/ExternalApi/sendotp', body: {
      'mobileNumber': mobileNumber,
    });
  }

  Future<bool> verifyOtp(String mobileNumber, String otp) async {
    final decoded = await _client.post('/ExternalApi/verifyotp', body: {
      'mobileNumber': mobileNumber,
      'otp': otp,
    });
    if (decoded is Map && decoded['verification'] != null) {
      return decoded['verification']
          .toString()
          .toLowerCase()
          .contains('success');
    }
    return false;
  }

  Future<bool> verifyPan(String panNumber) async {
    final decoded = await _client.post('/sakhi/verify-pan', body: {'pan': panNumber});
    if (decoded is Map && decoded['status'] != null) {
      return decoded['status'].toString().toUpperCase() == 'APPROVED';
    }
    return false;
  }

  Future<Map<String, dynamic>> generateAadharLink(String aadharNumber) async {
    final decoded = await _client.post(
      '/goldloans/aadharlink',
      body: {'aadharNumber': aadharNumber},
    );
    return (decoded is Map<String, dynamic>) ? decoded : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> downloadAadhar({
    required String referenceId,
    required String transactionId,
  }) async {
    final decoded = await _client.post(
      '/goldloans/downloadaadhar',
      body: {
        'reference_id': referenceId,
        'transaction_id': transactionId,
      },
    );
    return (decoded is Map<String, dynamic>) ? decoded : <String, dynamic>{};
  }
}
