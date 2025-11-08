// lib/pages/carritos_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sistema_tiendas/tienda_detalle_page.dart'; // Ajusta ruta si es necesario

class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  bool cargando = true;
  List<Map<String, dynamic>> carritos = [];

  @override
  void initState() {
    super.initState();
    _cargarCarritos();
  }

  Future<void> _cargarCarritos() async {
    setState(() => cargando = true);
    if (user == null) {
      setState(() {
        carritos = [];
        cargando = false;
      });
      return;
    }

    final snap = await _db
        .collection('usuarios')
        .doc(user!.uid)
        .collection('carritos_guardados')
        .orderBy('guardadoEn', descending: true)
        .get();

    final data = snap.docs.map((d) {
      final info = d.data();
      return {
        'docId': d.id,
        'tienda': (info['tienda'] is Map) ? Map<String, dynamic>.from(info['tienda']) : <String, dynamic>{},
        'productos': (info['productos'] is Map) ? Map<String, dynamic>.from(info['productos']) : <String, dynamic>{},
        'guardadoEn': info['guardadoEn'],
      };
    }).toList();

    setState(() {
      carritos = data;
      cargando = false;
    });
  }

  Future<void> _eliminarCarrito(String docId) async {
    if (user == null) return;
    await _db
        .collection('usuarios')
        .doc(user!.uid)
        .collection('carritos_guardados')
        .doc(docId)
        .delete();
    await _cargarCarritos();
  }

  int _totalProductos(Map<String, dynamic> productos) {
    return productos.values.fold<int>(
      0,
          (int sum, dynamic v) {
        final intCantidad = (v is int) ? v : int.tryParse(v.toString()) ?? 0;
        return sum + intCantidad;
      },
    );
  }

  Future<void> _abrirTienda(Map<String, dynamic> tiendaEnCarrito) async {
    final id = tiendaEnCarrito['id']?.toString();
    Map<String, dynamic> tiendaFinal = Map<String, dynamic>.from(tiendaEnCarrito);

    if (id != null && id.isNotEmpty) {
      try {
        final doc = await _db.collection('tiendas').doc(id).get();
        if (doc.exists && doc.data() != null) {
          tiendaFinal = {...doc.data() as Map<String, dynamic>, 'id': doc.id};
        } else {
          tiendaFinal['id'] = id;
        }
      } catch (e) {
        tiendaFinal['id'] = id;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TiendaDetallePage(tienda: tiendaFinal)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B2239),
      appBar: AppBar(
        backgroundColor: const Color(0xFF143657),
        title: const Text(
          'Mis carritos',
          style: TextStyle(
            color: Color(0xFFF6EED9),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFF6EED9)),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : carritos.isEmpty
          ? const Center(
        child: Text(
          'No tienes carritos guardados',
          style: TextStyle(color: Colors.white70),
        ),
      )
          : RefreshIndicator(
        onRefresh: _cargarCarritos,
        color: Colors.white,
        backgroundColor: const Color(0xFF143657),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: carritos.length,
          itemBuilder: (context, index) {
            final c = carritos[index];
            final tienda = Map<String, dynamic>.from(c['tienda'] ?? {});
            final productos = Map<String, dynamic>.from(c['productos'] ?? {});
            final docId = c['docId'] as String? ?? '';
            final nombre = (tienda['nombre']?.toString() ?? tienda['id']?.toString() ?? 'Tienda');
            final total = _totalProductos(productos);

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF143657),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                onTap: () => _abrirTienda(tienda),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2239),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : 'T',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  nombre,
                  style: const TextStyle(
                    color: Color(0xFFF6EED9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '$total producto${total == 1 ? '' : 's'} guardado${total == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF143657),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          'Eliminar carrito',
                          style: TextStyle(
                            color: Color(0xFFF6EED9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: const Text(
                          '¿Eliminar este carrito guardado?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _eliminarCarrito(docId);
                    }
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
