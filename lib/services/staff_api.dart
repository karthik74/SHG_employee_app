import 'api_client.dart';

class StaffApi {
  final ApiClient _client;
  StaffApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  Future<Map<String, dynamic>> fetchStaff(int staffId) async {
    final decoded = await _client.get('/staff/$staffId');
    return (decoded is Map<String, dynamic>) ? decoded : <String, dynamic>{};
  }
}
