import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard ke liye

class AIBox extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool loading;
  final bool copyable;

  const AIBox({
    super.key,
    required this.text,
    this.isUser = false,
    this.loading = false,
    this.copyable = false, // new param
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(16),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.grey[300] // light gray for user
              : Colors.white.withOpacity(0.1), // transparent AI
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: isUser
                  ? Colors.grey.withOpacity(0.5)
                  : Colors.transparent,
              blurRadius: 6,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            loading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isUser ? Colors.grey[700] : Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.black : Colors.white,
                      fontSize: 16,
                    ),
                  ),
            if (copyable && !loading)
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Copied to clipboard"),
                      duration: const Duration(milliseconds: 800),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    "Copy",
                    style: TextStyle(
                      fontSize: 12,
                      color: isUser ? Colors.black54 : Colors.white70,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}