import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {

  static const apiKey =
      "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";

  /// 🔥 SMART SYSTEM MESSAGE (MULTI LANGUAGE + MEMORY FRIENDLY)
  static const systemMessage = {
    "role": "system",
    "content": """
You are STORNIX AI, a smart AI assistant inside a mobile app.

IMPORTANT RULES:

1. Always understand the previous message before answering.
2. If the user says "translate in Hindi", translate your LAST answer.
3. If the user asks a follow-up question, continue from the previous answer.
4. Answer ALL types of questions (study, coding, daily life, etc).
5. If the user asks in Hindi → reply in Hindi.
6. If the user asks in English → reply in English.
7. If the user asks in Hinglish → reply in Hinglish.
8. If the question is study related → answer in exam format.
9. If the question is normal → answer normally.
10. Always use simple language.
"""
  };

  /// 🔥 STREAM MESSAGE WITH MEMORY (MAIN CHAT AI)
  static Stream<String> streamMessageWithMemory(
      List<Map<String, String>> chatHistory) async* {

    final request = http.Request(
      "POST",
      Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
    );

    request.headers.addAll({
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    });

    final messages = [
      systemMessage,
      ...chatHistory
    ];

    request.body = jsonEncode({
      "model": "openai/gpt-3.5-turbo",
      "stream": true,
      "messages": messages
    });

    final response = await request.send();

    await for (var chunk in response.stream.transform(utf8.decoder)) {
      for (var line in chunk.split("\n")) {

        if (line.startsWith("data: ")) {

          final data = line.replaceFirst("data: ", "");

          if (data == "[DONE]") return;

          try {
            final jsonData = jsonDecode(data);

            final content =
                jsonData["choices"][0]["delta"]["content"];

            if (content != null) yield content;

          } catch (_) {}
        }
      }
    }
  }

  /// 🔥 NORMAL MESSAGE (WITHOUT MEMORY)
  static Future<String> sendMessage(String message) async {

    final response = await http.post(
      Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "openai/gpt-3.5-turbo",
        "messages": [
          systemMessage,
          {"role": "user", "content": message}
        ]
      }),
    );

    final data = jsonDecode(response.body);

    return data["choices"][0]["message"]["content"];
  }

  /// 🔥 STUDY HELPER MODE (SMART AUTO DETECT)
  static Future<String> studyHelper(String question) async {

    final prompt = """
If the question is related to study, exams, maths, programming, physics, chemistry, theory or engineering subjects → answer in exam format.

If it is not study related → answer normally.

Question:
$question
""";

    return await sendMessage(prompt);
  }
}