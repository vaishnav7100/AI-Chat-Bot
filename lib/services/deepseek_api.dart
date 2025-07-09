import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> sendMessageToBackend(String message) async {
  final response = await http.post(
    Uri.parse('https://ai-chat-backend.vaishnav7100.workers.dev'), // Cloudflare Worker URL
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      "message": message,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    // Safely extract the message content
    return data['choices'][0]['message']['content'] ?? 'No response content';
  } else {
    throw Exception(
      'Backend error: ${response.statusCode}\n${response.body}',
    );
  }
}
