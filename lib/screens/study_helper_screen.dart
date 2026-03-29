import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/ai_service.dart';

class StudyHelperScreen extends StatefulWidget {
  const StudyHelperScreen({super.key});

  @override
  State<StudyHelperScreen> createState() => _StudyHelperScreenState();
}

class _StudyHelperScreenState extends State<StudyHelperScreen> {
  final TextEditingController questionController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  String response = "";
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndNetwork();
  }

  /// PERMISSIONS + INTERNET CHECK
  Future<void> _checkPermissionsAndNetwork() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.location,
    ].request();

    List<String> denied = [];
    statuses.forEach((permission, status) {
      if (!status.isGranted) denied.add(permission.toString().split('.').last);
    });

    if (denied.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Permissions denied: ${denied.join(', ')}. Please allow them in settings.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection!'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  /// ASK AI
  Future<void> askAI(String query) async {
    if (query.isEmpty) return;

    setState(() {
      loading = true;
      response = "";
      questionController.text = query;
    });

    String fullResponse = "";
    try {
      fullResponse = await AIService.studyHelper(query);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        response = "Error getting response";
        loading = false;
      });
      return;
    }

    List<String> words = fullResponse.split(' ');
    for (var word in words) {
      await Future.delayed(const Duration(milliseconds: 15));
      if (!mounted) return;
      setState(() {
        response += '$word ';
      });
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    }

    if (!mounted) return;
    setState(() {
      loading = false;
    });
  }

  @override
  void dispose() {
    questionController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> topics = [
      "Math Basics",
      "Physics Laws",
      "Programming",
      "Chemistry",
      "History"
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "STUDY HELPER AI",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [

            /// INPUT BOX
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: questionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Ask any study question...",
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      onSubmitted: (value) => askAI(value),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => askAI(questionController.text),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// TOPIC BUTTONS
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      askAI("Explain ${topics[index]} for students");
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        topics[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            /// RESPONSE BOX
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : SingleChildScrollView(
                        controller: scrollController,
                        child: Text(
                          response,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}