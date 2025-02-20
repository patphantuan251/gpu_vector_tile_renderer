import 'dart:async';

import 'package:http/http.dart' as http;

// todo: make this better
final _client = http.Client();

Future<http.Response> zonedHttpGet(Uri uri) async {
  final response = await _client.get(uri);

  if (response.statusCode != 200) {
    throw Exception('Failed to fetch: ${response.statusCode}');
  }

  return response;
}
