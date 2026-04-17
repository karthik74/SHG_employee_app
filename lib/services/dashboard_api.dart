import 'api_client.dart';

class DashboardApi {
  final ApiClient _client;
  DashboardApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  Future<Map<String, dynamic>> fetchSummary() async {
    final decoded = await _client.get('/dashboard/summary');
    return (decoded is Map<String, dynamic>) ? decoded : <String, dynamic>{};
  }

  Future<Map<String, num>> fetchShgDashboard({required int officeId}) async {
    final decoded = await _client.get(
      '/runreports/shgdashboard',
      query: {'R_officeId': officeId},
    );
    final result = <String, num>{};
    if (decoded is Map) {
      final headers = decoded['columnHeaders'];
      final data = decoded['data'];
      if (headers is List && data is List && data.isNotEmpty) {
        final firstRow = data.first;
        final row = firstRow is Map ? firstRow['row'] : null;
        if (row is List) {
          for (var i = 0; i < headers.length && i < row.length; i++) {
            final name = headers[i] is Map ? headers[i]['columnName']?.toString() : null;
            final raw = row[i];
            if (name == null) continue;
            num value = 0;
            if (raw is num) {
              value = raw;
            } else if (raw != null) {
              value = num.tryParse(raw.toString()) ?? 0;
            }
            result[name] = value;
          }
        }
      }
    }
    return result;
  }
}
