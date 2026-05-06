// lib/core/network/sse_client.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class SSEClient {
  Stream<Map<String, dynamic>> connect({
    required String url,
    required String token,
  }) async* {
    final request = http.Request('GET', Uri.parse(url));

    request.headers.addAll({
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Authorization': 'Bearer $token',
    });

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('SSE failed: ${response.statusCode}');
    }

    final stream = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in stream) {
      if (line.startsWith('data:')) {
        final jsonString = line.substring(5).trim();

        if (jsonString.isEmpty) continue;

        yield jsonDecode(jsonString);
      }
    }
  }
}