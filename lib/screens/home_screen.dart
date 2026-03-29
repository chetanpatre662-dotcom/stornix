import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'study_helper_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Study Helper"),
      ),

      body: ListView(
        children: [

          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text("AI Chat"),
            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.school),
            title: const Text("Study Helper"),
            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudyHelperScreen(),
                ),
              );
            },
          ),

        ],
      ),
    );
  }
}