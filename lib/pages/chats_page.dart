// lib/pages/chats_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sistema_chats/chat_conversation_page.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0B2239),
      appBar: AppBar(
        title: const Text('Chats', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF143657),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No hay usuarios registrados aún.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final users = snapshot.data!.docs.where((doc) => doc.id != currentUserId).toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user['foto'] != null
                      ? NetworkImage(user['foto'])
                      : null,
                  child: user['foto'] == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                title: Text(
                  user['nombre'] ?? 'Usuario sin nombre',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  user['email'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatConversacionPage(
                        currentUserId: currentUserId,
                        otherUserId: user['uid'],
                        otherUserName: user['nombre'] ?? '',
                        otherUserPhoto: user['foto'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
