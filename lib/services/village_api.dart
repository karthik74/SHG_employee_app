import 'api_client.dart';

class VillageApi {
  final ApiClient _client;
  VillageApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  Future<List<dynamic>> fetchVillages({int offset = 0, int limit = 10}) async {
    final decoded = await _client.get('/villages', query: {
      'offset': offset,
      'limit': limit,
      'paged': true,
    });
    if (decoded is Map && decoded['pageItems'] is List) {
      return decoded['pageItems'] as List;
    }
    if (decoded is List) return decoded;
    return const [];
  }

  Future<dynamic> approveVillage(String villageId, {DateTime? activationDate}) {
    final date = activationDate ?? DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final formatted = '${date.day} ${months[date.month - 1]} ${date.year}';
    return _client.post('/villages/$villageId?command=activate', body: {
      'activationDate': formatted,
      'dateFormat': 'dd MMMM yyyy',
      'locale': 'en',
    });
  }
}
