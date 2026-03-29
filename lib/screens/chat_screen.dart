import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/ai_service.dart';
import '../widgets/ai_box.dart';
import 'study_helper_screen.dart';
import 'login_screen.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ChatScreen({super.key, required this.userId, required this.userName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode messageFocusNode = FocusNode();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = false;
  String currentChatId = "";

  @override
  void initState() {
    super.initState();
    createFreshChat();
  }

  /// CREATE NEW CHAT
  Future<void> createFreshChat() async {
    currentChatId = "chat_${DateTime.now().millisecondsSinceEpoch}";

    await firestore
        .collection("chats")
        .doc(widget.userId)
        .collection("all_chats")
        .doc(currentChatId)
        .set({
      "createdAt": DateTime.now().millisecondsSinceEpoch,
      "title": "New Chat",
    });

    setState(() {});
  }

  /// MESSAGE STREAM
  Stream<QuerySnapshot> getMessagesStream() {
    if (currentChatId.isEmpty) return const Stream.empty();

    return firestore
        .collection("chats")
        .doc(widget.userId)
        .collection("all_chats")
        .doc(currentChatId)
        .collection("messages")
        .orderBy("time", descending: false)
        .snapshots();
  }

  /// SCROLL
  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// SEND MESSAGE (TITLE AUTO SAVE ADDED)
  Future<void> sendMessage() async {
    if (currentChatId.isEmpty) await createFreshChat();

    String text = controller.text.trim();
    if (text.isEmpty) return;

    controller.clear();

    /// SAVE USER MESSAGE
    await firestore
        .collection("chats")
        .doc(widget.userId)
        .collection("all_chats")
        .doc(currentChatId)
        .collection("messages")
        .add({
      "text": text,
      "isUser": true,
      "time": DateTime.now().millisecondsSinceEpoch,
    });

    /// 🔥 FIRST MESSAGE = CHAT TITLE
    final chatDoc = firestore
        .collection("chats")
        .doc(widget.userId)
        .collection("all_chats")
        .doc(currentChatId);

    final chatSnapshot = await chatDoc.get();

    if (chatSnapshot.exists) {
      final data = chatSnapshot.data();
      if (data?["title"] == "New Chat") {
        await chatDoc.update({"title": text});
      }
    }

    setState(() => isLoading = true);

    try {
      String aiReply = await AIService.sendMessage(text);

      await firestore
          .collection("chats")
          .doc(widget.userId)
          .collection("all_chats")
          .doc(currentChatId)
          .collection("messages")
          .add({
        "text": aiReply,
        "isUser": false,
        "time": DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      await firestore
          .collection("chats")
          .doc(widget.userId)
          .collection("all_chats")
          .doc(currentChatId)
          .collection("messages")
          .add({
        "text": "Error getting response",
        "isUser": false,
        "time": DateTime.now().millisecondsSinceEpoch,
      });
    }

    setState(() => isLoading = false);
    scrollToBottom();

    Future.delayed(const Duration(milliseconds: 100), () {
      messageFocusNode.requestFocus();
    });
  }

  /// OPEN OLD CHAT
  Future<void> openOldChat(String chatId) async {
    currentChatId = chatId;
    setState(() {});
    Navigator.pop(context);
  }

  /// 🔴 LOGOUT FUNCTION
  Future<void> logoutUser() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) =>  LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    messageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),

      /// DRAWER
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.65,
        child: Drawer(
          backgroundColor: const Color(0xFF111111),
          child: Column(
            children: [
              const SizedBox(height: 50),

              Text(
                "STORNIX AI\n${widget.userName}",
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),

              const Divider(color: Colors.grey),

              /// STUDY HELPER
              ListTile(
                leading: const Icon(Icons.school, color: Colors.white),
                title: const Text("Study Helper",
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StudyHelperScreen()),
                  );
                },
              ),

              /// NEW CHAT
              ListTile(
                leading: const Icon(Icons.add, color: Colors.white),
                title:
                    const Text("New Chat", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  await createFreshChat();
                  Navigator.pop(context);
                },
              ),

              const Divider(color: Colors.grey),

              /// OLD CHATS
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Old Chats",
                  style:
                      TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection("chats")
                      .doc(widget.userId)
                      .collection("all_chats")
                      .orderBy("createdAt", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final chats = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final data = chats[index].data() as Map<String, dynamic>;
                        final chatId = chats[index].id;
                        final title = data["title"] ?? "Chat";

                        return ListTile(
                          leading: const Icon(Icons.chat, color: Colors.white),
                          title: Text(title,
                              style: const TextStyle(color: Colors.white)),
                          onTap: () => openOldChat(chatId),
                        );
                      },
                    );
                  },
                ),
              ),

              const Divider(color: Colors.grey),

              /// 🔴 LOGOUT BUTTON
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Logout",
                    style: TextStyle(color: Colors.red)),
                onTap: logoutUser,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      /// APP BAR
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "STORNIX",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      /// BODY SAME AS BEFORE
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getMessagesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  scrollToBottom();
                });

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];

                    return AIBox(
                      text: data["text"] ?? "",
                      isUser: data["isUser"] ?? false,
                      copyable: true,
                    );
                  },
                );
              },
            ),
          ),

          /// MESSAGE BOX
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFF0F0F0F),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: controller,
                      focusNode: messageFocusNode,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Ask STORNIX AI...",
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: sendMessage,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}