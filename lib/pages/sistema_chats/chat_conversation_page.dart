// lib/pages/chat_conversacion_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatConversacionPage extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  const ChatConversacionPage({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
  });

  @override
  State<ChatConversacionPage> createState() => _ChatConversacionPageState();
}

class _ChatConversacionPageState extends State<ChatConversacionPage> {
  final TextEditingController _controller = TextEditingController();

  String getChatId() {
    // Generar un ID único de chat entre ambos usuarios
    final ids = [widget.currentUserId, widget.otherUserId];
    ids.sort();
    return ids.join('_');
  }

  void _enviarMensaje() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    final chatId = getChatId();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('mensajes')
        .add({
      'texto': texto,
      'emisorId': widget.currentUserId,
      'fecha': FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chatId = getChatId();

    return Scaffold(
      backgroundColor: const Color(0xFF0B2239),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.otherUserPhoto != null
                  ? NetworkImage(widget.otherUserPhoto!)
                  : null,
              child: widget.otherUserPhoto == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(widget.otherUserName, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: const Color(0xFF143657),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('mensajes')
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final mensajes = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: mensajes.length,
                  itemBuilder: (context, index) {
                    final msg = mensajes[index];
                    final isMe = msg['emisorId'] == widget.currentUserId;

                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                          isMe ? Colors.blueAccent : Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['texto'] ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF143657),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _enviarMensaje,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
