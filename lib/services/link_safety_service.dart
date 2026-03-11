import 'dart:convert';
import 'package:http/http.dart' as http;

class LinkSafetyResult {
  final String url;
  final String label;
  final int detected;
  final int total;
  final String summary;

  LinkSafetyResult({
    required this.url,
    required this.label,
    required this.detected,
    required this.total,
    required this.summary,
  });

  factory LinkSafetyResult.fromJson(Map<String, dynamic> json) {
    return LinkSafetyResult(
      url: json['url']?.toString() ?? '',
      label: json['label']?.toString() ?? 'unknown',
      detected: json['detected'] is int
          ? json['detected'] as int
          : int.tryParse(json['detected']?.toString() ?? '0') ?? 0,
      total: json['total'] is int
          ? json['total'] as int
          : int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      summary: json['summary']?.toString() ?? '',
    );
  }
}

class LinkSafetyService {
  final String baseUrl;

  LinkSafetyService({required this.baseUrl});

  Future<LinkSafetyResult?> scanUrl(String url) async {
    final response = await http.post(
      Uri.parse('$baseUrl/scan-url'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'url': url}),
    );

    if (response.statusCode != 200) {
      return null;
    }

    return LinkSafetyResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}

String? extractFirstUrl(String text) {
  final regex = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
  final match = regex.firstMatch(text);
  return match?.group(0);
}