import 'api_client.dart';

class GramPanchayatApi {
  final ApiClient _client;
  GramPanchayatApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  Future<List<dynamic>> fetchPanchayats({int? officeId}) async {
    final decoded = await _client.get(
      '/grampanchayats',
      query: officeId != null ? {'officeId': officeId} : null,
    );
    if (decoded is Map && decoded['pageItems'] is List) {
      return decoded['pageItems'] as List;
    }
    if (decoded is List) return decoded;
    return const [];
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final decoded = await _client.post('/grampanchayats', body: payload);
    return (decoded is Map<String, dynamic>) ? decoded : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> payload) async {
    final decoded = await _client.put('/grampanchayats/$id', body: payload);
    return (decoded is Map<String, dynamic>) ? decoded : <String, dynamic>{};
  }
}
