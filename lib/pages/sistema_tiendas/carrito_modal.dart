// lib/pages/sistema_tiendas/carrito_modal.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CarritoModal extends StatefulWidget {
  final Map<String, dynamic> tienda;
  final Map<String, int> carrito; // idProducto -> cantidad
  final Map<String, Map<String, dynamic>> productosDisponibles; // id -> producto info
  final Function(Map<String, int>) onCarritoActualizado;

  const CarritoModal({
    super.key,
    required this.tienda,
    required this.carrito,
    required this.productosDisponibles,
    required this.onCarritoActualizado,
  });

  @override
  State<CarritoModal> createState() => _CarritoModalState();
}

class _CarritoModalState extends State<CarritoModal> {
  late Map<String, int> carritoTemp;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    carritoTemp = Map.from(widget.carrito);
  }

  void _aumentar(String id) {
    setState(() => carritoTemp[id] = (carritoTemp[id] ?? 0) + 1);
  }

  void _disminuir(String id) {
    setState(() {
      final current = carritoTemp[id] ?? 0;
      if (current > 1) carritoTemp[id] = current - 1;
    });
  }

  void _eliminar(String id) {
    setState(() {
      carritoTemp.remove(id);
    });
  }

  Future<void> _vaciarCarritoConfirm() async {
    final res = await showDialog<bool>(context: context, builder: (_) {
      return AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text('¿Seguro que deseas eliminar todos los productos del carrito?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Vaciar')),
        ],
      );
    });

    if (res != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final tiendaId = widget.tienda['id']?.toString() ?? 'tienda_${widget.tienda['nombre']}';
      final ref = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('carritos_guardados')
          .doc(tiendaId);

      final snapshot = await ref.get();
      if (snapshot.exists) await ref.delete();
    }

    setState(() {
      carritoTemp.clear();
    });
    widget.onCarritoActualizado({});
    Navigator.pop(context);
  }

  Future<void> _guardarCarritoEnFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión para guardar carrito'))
      );
      return;
    }

    setState(() => guardando = true);

    final tiendaId = widget.tienda['id']?.toString() ?? 'tienda_${widget.tienda['nombre']}';
    final ref = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('carritos_guardados')
        .doc(tiendaId);

    if (carritoTemp.isEmpty) {
      final snapshot = await ref.get();
      if (snapshot.exists) await ref.delete();
    } else {
      await ref.set({
        'productos': carritoTemp,
        'tienda': {
          'id': widget.tienda['id'],
          'nombre': widget.tienda['nombre'],
        },
        'guardadoEn': FieldValue.serverTimestamp(),
      });
    }

    widget.onCarritoActualizado(carritoTemp);
    setState(() => guardando = false);
    Navigator.pop(context);
  }

  Future<void> _hacerPedidoConfirm() async {
    final res = await showDialog<bool>(context: context, builder: (_) {
      return AlertDialog(
        title: const Text('Enviar pedido'),
        content: const Text('¿Deseas enviar tu solicitud de pedido ahora?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Enviar')),
        ],
      );
    });

    if (res != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión para enviar el pedido'))
      );
      return;
    }

    setState(() => guardando = true);

    final chatId = '${user.uid}_${widget.tienda['id']}';

    // Construir mensaje con detalle del carrito
    String mensaje = 'Pedido:\n';
    double total = 0;
    carritoTemp.forEach((id, cantidad) {
      final producto = widget.productosDisponibles[id];
      final nombre = producto != null ? producto['nombre'] ?? 'Producto' : 'Producto';
      final precio = producto != null ? (producto['precio'] ?? 0) : 0;
      total += precio * cantidad;
      mensaje += '- $nombre x$cantidad\n';
    });
    mensaje += 'Total: $total MXN';

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    await chatRef.set({
      'participantes': [user.uid, widget.tienda['id']],
      'tienda': {
        'id': widget.tienda['id'],
        'nombre': widget.tienda['nombre'],
      },
      'ultimoMensaje': mensaje,
      'fechaUltimoMensaje': FieldValue.serverTimestamp(),
    });

    await chatRef.collection('mensajes').add({
      'texto': mensaje,
      'emisorId': user.uid,
      'fecha': FieldValue.serverTimestamp(),
    });

    widget.onCarritoActualizado({});
    setState(() => guardando = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido enviado y chat creado'))
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiendaNombre = widget.tienda['nombre'] ?? 'Tienda';

    return Dialog(
      backgroundColor: const Color(0xFF143657),
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.maxFinite,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Carrito - $tiendaNombre', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
            ]),
            const SizedBox(height: 8),
            if (carritoTemp.isEmpty)
              const Padding(padding: EdgeInsets.all(12), child: Text('El carrito está vacío', style: TextStyle(color: Colors.white70)))
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: carritoTemp.keys.map((id) {
                    final producto = widget.productosDisponibles[id];
                    final nombre = producto != null ? producto['nombre'] ?? 'Producto' : 'Producto';
                    final precio = producto != null ? (producto['precio'] ?? 0) : 0;
                    final cantidad = carritoTemp[id] ?? 0;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF0B2239), borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(nombre, style: const TextStyle(color: Colors.white)),
                        subtitle: Text('${precio * cantidad} MXN  (x$cantidad)', style: const TextStyle(color: Colors.white70)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(onPressed: () => _disminuir(id), icon: const Icon(Icons.remove, color: Colors.white70)),
                          IconButton(onPressed: () => _aumentar(id), icon: const Icon(Icons.add, color: Colors.white70)),
                          IconButton(onPressed: () => _eliminar(id), icon: const Icon(Icons.delete, color: Colors.redAccent)),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(onPressed: _vaciarCarritoConfirm, icon: const Icon(Icons.delete_forever, color: Colors.redAccent)),
              ElevatedButton(
                onPressed: guardando ? null : _guardarCarritoEnFirebase,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
                child: guardando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar carrito'),
              ),
              ElevatedButton(
                onPressed: carritoTemp.isEmpty || guardando ? null : _hacerPedidoConfirm,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                child: const Text('Hacer pedido'),
              ),
            ])
          ]),
        ),
      ),
    );
  }
}
