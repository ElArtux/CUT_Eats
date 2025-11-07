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
    // fold con tipos explícitos para evitar el error de types
    return productos.values.fold<int>(
      0,
          (int sum, dynamic v) {
        final intCantidad = (v is int) ? v : int.tryParse(v.toString()) ?? 0;
        return sum + intCantidad;
      },
    );
  }

  Future<void> _abrirTienda(Map<String, dynamic> tiendaEnCarrito) async {
    // Si el carrito guarda un id de tienda, intentamos obtener la tienda completa desde 'tiendas/{id}'
    final id = tiendaEnCarrito['id']?.toString();
    Map<String, dynamic> tiendaFinal = Map<String, dynamic>.from(tiendaEnCarrito);

    if (id != null && id.isNotEmpty) {
      try {
        final doc = await _db.collection('tiendas').doc(id).get();
        if (doc.exists && doc.data() != null) {
          tiendaFinal = {...doc.data() as Map<String, dynamic>, 'id': doc.id};
        } else {
          // si no existe doc, aseguramos que el mapa tenga el id
          tiendaFinal['id'] = id;
        }
      } catch (e) {
        // si falla la consulta dejamos el mapa tal cual vino
        tiendaFinal['id'] = id;
      }
    }

    // Navegamos a TiendaDetallePage con el map completo (TiendaDetallePage carga el carrito guardado por sí sola)
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
        title: const Text('Mis carritos', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : carritos.isEmpty
          ? const Center(child: Text('No tienes carritos guardados', style: TextStyle(color: Colors.white70)))
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                title: Text(nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        title: const Text('Eliminar carrito'),
                        content: const Text('¿Eliminar este carrito guardado?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
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
