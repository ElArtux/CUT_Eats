// lib/pages/sistema_chats/chat_conversation_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatConversacionPage extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;
  final bool modoTienda;
  final bool otherIsTienda;
  final String? otherUserPhoto;

  const ChatConversacionPage({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
    required this.modoTienda,
    required this.otherIsTienda,
    this.otherUserPhoto,
  });

  @override
  State<ChatConversacionPage> createState() => _ChatConversacionPageState();
}

class _ChatConversacionPageState extends State<ChatConversacionPage> {
  final TextEditingController _controller = TextEditingController();
  String chatId = "";

  String _buildKey(bool isTienda, String uid) {
    return "${isTienda ? 'tienda' : 'usuario'}_$uid";
  }

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final myKey = _buildKey(widget.modoTienda, widget.currentUserId);
    final otherKey = _buildKey(widget.otherIsTienda, widget.otherUserId);

    final keys = [myKey, otherKey]..sort();
    chatId = keys.join("__");

    final ref = FirebaseFirestore.instance.collection("chats").doc(chatId);

    final exists = await ref.get();
    if (!exists.exists) {
      await ref.set({
        "participants": keys,
        "lastMessage": "",
        "lastUpdated": FieldValue.serverTimestamp(),
      });
    }

    setState(() {});
  }

  Future<void> _enviarMensaje() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final myKey = _buildKey(widget.modoTienda, widget.currentUserId);

    final ref = FirebaseFirestore.instance.collection("chats").doc(chatId);

    await ref.collection("mensajes").add({
      "texto": text,
      "emisorKey": myKey,
      "fecha": FieldValue.serverTimestamp(),
    });

    await ref.update({
      "lastMessage": text,
      "lastUpdated": FieldValue.serverTimestamp(), // 👈 actualiza hora
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (chatId.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B2239),
      appBar: AppBar(
        backgroundColor: widget.modoTienda
            ? const Color(0xFFB21E35)
            : const Color(0xFF143657),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              backgroundImage: widget.otherUserPhoto != null &&
                  widget.otherUserPhoto!.isNotEmpty
                  ? NetworkImage(widget.otherUserPhoto!)
                  : null,
              child: (widget.otherUserPhoto == null ||
                  widget.otherUserPhoto!.isEmpty)
                  ? Icon(
                widget.otherIsTienda ? Icons.store : Icons.person,
                color: const Color(0xFFF6EED9),
              )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              widget.otherUserName,
              style: const TextStyle(
                color: Color(0xFFF6EED9),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("chats")
                  .doc(chatId)
                  .collection("mensajes")
                  .orderBy("fecha", descending: true)
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
                    final isMine = msg["emisorKey"] ==
                        _buildKey(widget.modoTienda, widget.currentUserId);

                    DateTime? fecha;
                    if (msg["fecha"] != null) {
                      final ts = msg["fecha"] as Timestamp;
                      fecha = ts.toDate().subtract(const Duration(hours: 6));
                    }
                    final fechaStr = fecha != null
                        ? DateFormat("dd/MM/yyyy HH:mm").format(fecha)
                        : "";

                    return Align(
                      alignment:
                      isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMine
                              ? const Color(0xDDE7D8FF)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(msg["texto"]),
                            if (fechaStr.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  fechaStr,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              color: const Color(0xFF143657),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Escribe un mensaje...",
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _enviarMensaje(),
                    ),
                  ),
                  IconButton(
                    onPressed: _enviarMensaje,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
