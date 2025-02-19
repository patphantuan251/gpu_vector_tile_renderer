import 'dart:async';

import 'package:http/http.dart' as http;

http.Client get zonedHttpClient {
  return http.Client();
}

Future<http.Response> zonedHttpGet(Uri uri) async {
  final response = await zonedHttpClient.get(uri);

  if (response.statusCode != 200) {
    throw Exception('Failed to fetch: ${response.statusCode}');
  }

  return response;
}
