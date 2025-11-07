import 'package:cloud_firestore/cloud_firestore.dart';

class TiendaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔹 Obtiene todas las tiendas
  Future<List<Map<String, dynamic>>> obtenerTiendas() async {
    final snapshot = await _db.collection('tiendas').get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  /// 🔹 Busca tiendas por nombre o descripción (no sensible a mayúsculas)
  Future<List<Map<String, dynamic>>> buscarTiendas(String query) async {
    final lower = query.toLowerCase();
    final snapshot = await _db.collection('tiendas').get();
    return snapshot.docs
        .map((doc) => {...doc.data(), 'id': doc.id})
        .where((tienda) {
      final nombre = (tienda['nombre'] ?? '').toString().toLowerCase();
      final descripcion = (tienda['descripcion'] ?? '').toString().toLowerCase();
      return nombre.contains(lower) || descripcion.contains(lower);
    })
        .toList();
  }

  /// 🔹 Filtra tiendas por categoría
  Future<List<Map<String, dynamic>>> filtrarPorCategoria(String categoria) async {
    final snapshot = await _db
        .collection('tiendas')
        .where('categoria', isEqualTo: categoria)
        .get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }
}
