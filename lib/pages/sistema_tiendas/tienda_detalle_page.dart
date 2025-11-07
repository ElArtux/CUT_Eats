// lib/pages/sistema_tiendas/tienda_detalle_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'carrito_modal.dart';

class TiendaDetallePage extends StatefulWidget {
  final Map<String, dynamic> tienda;

  const TiendaDetallePage({super.key, required this.tienda});

  @override
  State<TiendaDetallePage> createState() => _TiendaDetallePageState();
}

class _TiendaDetallePageState extends State<TiendaDetallePage> {
  List<Map<String, dynamic>> productosLocal = [];
  Map<String, int> carrito = {};
  bool cargando = true;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    _cargarCarritoGuardado();
  }

  Future<void> _cargarProductos() async {
    try {
      final tiendaDocProductos = widget.tienda['productos'];
      if (tiendaDocProductos is List && tiendaDocProductos.isNotEmpty) {
        productosLocal = List<Map<String, dynamic>>.generate(tiendaDocProductos.length, (i) {
          final p = tiendaDocProductos[i];
          return {
            'id': 'p$i',
            'nombre': p['nombre'] ?? '',
            'precio': (p['precio'] is num) ? p['precio'] : num.tryParse((p['precio'] ?? '').toString()) ?? 0,
            'descripcion': p['descripcion'] ?? '',
            'imagen': p['imagen'] ?? null,
          };
        });
      } else {
        final tiendaId = widget.tienda['id'] as String?;
        if (tiendaId != null) {
          final snap = await _db.collection('tiendas').doc(tiendaId).collection('productos').get();
          productosLocal = snap.docs.map((d) {
            final data = d.data();
            return {
              'id': d.id,
              'nombre': data['nombre'] ?? '',
              'precio': (data['precio'] is num) ? data['precio'] : num.tryParse((data['precio'] ?? '').toString()) ?? 0,
              'descripcion': data['descripcion'] ?? '',
              'imagen': data['imagen'] ?? null,
            };
          }).toList();
        }
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> _cargarCarritoGuardado() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final tiendaId = widget.tienda['id']?.toString() ?? 'tienda_${widget.tienda['nombre']}';
    final ref = _db.collection('usuarios').doc(user.uid).collection('carritos_guardados').doc(tiendaId);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      final data = snapshot.data();
      if (data != null && data['productos'] is Map<String, dynamic>) {
        final Map<String, int> productosFirebase = {};
        (data['productos'] as Map<String, dynamic>).forEach((key, value) {
          productosFirebase[key] = (value is int) ? value : int.tryParse(value.toString()) ?? 0;
        });
        setState(() {
          carrito = productosFirebase;
        });
      }
    }
  }

  void _agregarAlCarrito(String idProducto) {
    setState(() {
      carrito[idProducto] = (carrito[idProducto] ?? 0) + 1;
    });
  }

  void _abrirCarritoModal() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CarritoModal(
        tienda: widget.tienda,
        carrito: Map.from(carrito),
        productosDisponibles: Map.fromEntries(productosLocal.map((p) => MapEntry(p['id'] as String, p))),
        onCarritoActualizado: (nuevoCarrito) {
          setState(() {
            carrito = nuevoCarrito;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.tienda['nombre'] ?? "Tienda";
    final descripcion = widget.tienda['descripcion'] ?? "";

    // dejamos espacio para FAB + barra de navegación (si existe)
    final bottomPadding = MediaQuery.of(context).padding.bottom + 96.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B2239),
      appBar: AppBar(
        backgroundColor: const Color(0xFF143657),
        title: Text(nombre, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: carrito.isNotEmpty
          ? FloatingActionButton(
        onPressed: _abrirCarritoModal,
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.shopping_cart, color: Colors.black),
      )
          : null,
      body: cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
        children: [
          if (widget.tienda['imagen'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(widget.tienda['imagen'],
                  height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 12),
          Text(nombre,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22)),
          const SizedBox(height: 6),
          Text(descripcion, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 18),
          const Text('Productos',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 10),
          if (productosLocal.isEmpty)
            const Center(
                child:
                Text('No hay productos disponibles', style: TextStyle(color: Colors.white70)))
          else
          // cada fila tendrá altura fija para evitar desbordes
            ...productosLocal.map((p) {
              final id = p['id'] as String;
              final nombreP = p['nombre'] ?? '';
              final precio = p['precio'] ?? 0;
              final descripcionP = p['descripcion'] ?? '';
              final imagen = p['imagen'] as String?;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFF143657),
                    borderRadius: BorderRadius.circular(12)),
                child: SizedBox(
                  height: 88, // altura fija y suficiente para título, subtítulo y botón
                  child: Row(
                    children: [
                      // leading
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 12),
                        child: (imagen != null)
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(imagen, width: 56, height: 56, fit: BoxFit.cover),
                        )
                            : Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.fastfood, color: Colors.white70),
                        ),
                      ),

                      // titulo + subtitulo
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nombreP,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Text(descripcionP,
                                style: const TextStyle(color: Colors.white70),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),

                      // precio + boton (columna compacta)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 84,
                              child: Text(
                                '$precio MXN',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ElevatedButton(
                              onPressed: () => _agregarAlCarrito(id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF6EED9),
                                foregroundColor: const Color(0xFF0B2239),
                                minimumSize: const Size(72, 34),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: const Text('Agregar', textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
