import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sistema_chats/chat_conversation_page.dart';
import 'package:async/async.dart'; // <-- para StreamZip

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  bool _tieneTienda = false;
  bool _modoTienda = false; // usuario / tienda
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _verificarTienda();
  }

  Future<void> _verificarTienda() async {
    final tiendaDoc =
    await FirebaseFirestore.instance.collection('tiendas').doc(user.uid).get();
    setState(() {
      _tieneTienda = tiendaDoc.exists;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B2239),
      appBar: AppBar(
        backgroundColor: _modoTienda ? const Color(0xFFB21E35) : const Color(0xFF143657),
        title: Text(
          _modoTienda ? "Chats (modo Tienda)" : "Chats",
          style: const TextStyle(
            color: Color(0xFFF6EED9),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_tieneTienda)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: Icon(
                  _modoTienda ? Icons.store : Icons.person,
                  color: const Color(0xFFF6EED9),
                  size: 28,
                ),
                tooltip: "Cambiar modo",
                onPressed: () => setState(() => _modoTienda = !_modoTienda),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<QuerySnapshot>>(
        stream: StreamZip([
          FirebaseFirestore.instance.collection('usuarios').snapshots(),
          FirebaseFirestore.instance.collection('tiendas').snapshots(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final usuariosDocs = snapshot.data![0].docs;
          final tiendasDocs = snapshot.data![1].docs;

          final List<Map<String, dynamic>> usuariosList = [];
          final List<Map<String, dynamic>> tiendasList = [];

          final Set<String> usuariosVistos = {};
          final Set<String> tiendasVistas = {};

          for (var u in usuariosDocs) {
            if (u.id == user.uid) continue;
            if (usuariosVistos.contains(u.id)) continue;

            final data = u.data() as Map<String, dynamic>;
            data["uid"] = u.id;
            data["tipo"] = "usuario";

            usuariosList.add(data);
            usuariosVistos.add(u.id);
          }

          for (var t in tiendasDocs) {
            if (t.id == user.uid) continue;
            if (tiendasVistas.contains(t.id)) continue;

            final data = t.data() as Map<String, dynamic>;
            data["uid"] = t.id;
            data["tipo"] = "tienda";

            tiendasList.add(data);
            tiendasVistas.add(t.id);
          }

          // Selección según modo
          List<Map<String, dynamic>> listaFiltrada =
          _modoTienda ? usuariosList : tiendasList;

          // Filtrar por búsqueda
          if (_searchQuery.isNotEmpty) {
            listaFiltrada = listaFiltrada.where((p) {
              final nombre = (p["nombre"] ?? "").toString().toLowerCase();
              final email = (p["email"] ?? "").toString().toLowerCase();
              return nombre.contains(_searchQuery.toLowerCase()) ||
                  email.contains(_searchQuery.toLowerCase());
            }).toList();
          }

          if (listaFiltrada.isEmpty) {
            return const Center(
              child: Text(
                "No hay personas para chatear.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return Column(
            children: [
              // 🔍 Barra de búsqueda
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Buscar...",
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF143657),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: listaFiltrada.length,
                  itemBuilder: (context, index) {
                    final persona = listaFiltrada[index];
                    final nombre = persona["nombre"] ?? "Sin nombre";
                    final email = persona["email"] ?? "";
                    final esTienda = persona["tipo"] == "tienda";

                    return Card(
                      color: const Color(0xFF143657),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white24,
                          backgroundImage: !esTienda &&
                              persona['foto'] != null &&
                              persona['foto'].toString().isNotEmpty
                              ? NetworkImage(persona['foto'])
                              : null,
                          child: (esTienda ||
                              persona['foto'] == null ||
                              persona['foto'].toString().isEmpty)
                              ? Icon(
                            esTienda ? Icons.store : Icons.person,
                            color: const Color(0xFFF6EED9),
                          )
                              : null,
                        ),
                        title: Text(
                          nombre,
                          style: const TextStyle(
                            color: Color(0xFFF6EED9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          email,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatConversacionPage(
                                currentUserId: user.uid,
                                otherUserId: persona["uid"],
                                otherUserName: nombre,
                                modoTienda: _modoTienda,
                                otherIsTienda: esTienda,
                                otherUserPhoto:
                                !esTienda ? persona['foto'] : null,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
