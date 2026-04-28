import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class VersionInfo {
  final String versionName;
  final bool forceUpdate;
  final String url;

  VersionInfo({
    required this.versionName,
    required this.forceUpdate,
    required this.url,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      versionName: json['versionName']?.toString() ?? '',
      forceUpdate: json['forceUpdate']?.toString().toLowerCase() == 'true',
      url: json['url']?.toString() ?? '',
    );
  }
}

class VersionApi {
  VersionApi._();
  static final VersionApi instance = VersionApi._();

  Future<VersionInfo> fetchVersionControl() async {
    final base = EnvConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    final uri = Uri.parse('$base/versions/versionControl');
    final resp = await http.get(uri, headers: {
      'Fineract-Platform-TenantId': EnvConfig.tenantId,
      'Content-Type': 'application/json',
    }).timeout(const Duration(seconds: 15));

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Version check failed (${resp.statusCode})');
    }

    final decoded = jsonDecode(resp.body);
    final body = (decoded is Map && decoded['body'] is Map)
        ? Map<String, dynamic>.from(decoded['body'] as Map)
        : Map<String, dynamic>.from(decoded as Map);
    return VersionInfo.fromJson(body);
  }
}
