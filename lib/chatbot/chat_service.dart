import 'dart:convert';
import 'package:http/http.dart' as http;
import 'chat_message.dart';
import 'system_prompt.dart';

class ChatService {
  static const String _apiKey = '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';
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';
  static const double _temperature = 0.6;
  static const int _maxTokens = 500;
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxHistoryMessages = 10;

  Future<String> sendMessage(
    List<ChatMessage> history, {
    String? reportContext,
  }) async {
    try {
      final systemPrompt = ShieldBotPrompt.buildSystemPrompt(
        reportContext: reportContext,
      );

      // Build messages list: system + last N messages
      final messages = <Map<String, dynamic>>[
        {'role': 'system', 'content': systemPrompt},
      ];

      // Only keep last N messages to save tokens
      final recentHistory = history.length > _maxHistoryMessages
          ? history.sublist(history.length - _maxHistoryMessages)
          : history;

      for (final msg in recentHistory) {
        if (msg.role != 'system') {
          messages.add(msg.toApiMap());
        }
      }

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': _model,
              'messages': messages,
              'temperature': _temperature,
              'max_tokens': _maxTokens,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null && content.toString().isNotEmpty) {
          return content.toString();
        }
        return 'I received an empty response. Please try again. 🔄';
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error']?['message'] ?? 'Unknown error';
        return '⚠️ API Error (${response.statusCode}): $errorMsg';
      }
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return '⏱️ Request timed out. Please check your connection and try again.';
      }
      return '❌ Connection error: ${e.toString().replaceAll('Exception: ', '')}';
    }
  }
}
