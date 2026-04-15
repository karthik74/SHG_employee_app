import 'api_client.dart';

class GroupsApi {
  final ApiClient _client;
  GroupsApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  Future<List<dynamic>> fetchGroups({int? officeId}) async {
    final decoded = await _client.get(
      '/groups',
      query: officeId != null ? {'officeId': officeId} : null,
    );
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['pageItems'] is List) {
      return decoded['pageItems'] as List;
    }
    return const [];
  }

  Future<Map<String, dynamic>> fetchGroupAccounts(int groupId) async {
    final decoded = await _client.get('/groups/$groupId/accounts');
    return (decoded is Map<String, dynamic>) ? decoded : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchGroupDetails(int groupId) async {
    final decoded = await _client.get(
      '/groups/$groupId',
      query: {'associations': 'clientMembers'},
    );
    return (decoded is Map<String, dynamic>) ? decoded : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> payload) async {
    final decoded = await _client.post('/groups', body: payload);
    return (decoded is Map<String, dynamic>) ? decoded : <String, dynamic>{};
  }
}
