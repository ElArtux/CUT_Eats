// lib/pages/inicio_page.dart
import 'package:flutter/material.dart';
import 'sistema_tiendas/tienda_service.dart';
import 'sistema_tiendas/tienda_detalle_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TiendaService _tiendaService = TiendaService();
  List<Map<String, dynamic>> _tiendas = [];
  List<Map<String, dynamic>> _tiendasFiltradas = [];
  bool _cargando = true;
  bool _viendoCategoria = false;
  String? _categoriaActual;

  @override
  void initState() {
    super.initState();
    _cargarTiendas();
  }

  Future<void> _cargarTiendas() async {
    final data = await _tiendaService.obtenerTiendas();
    setState(() {
      _tiendas = data;
      _tiendasFiltradas = data;
      _cargando = false;
    });
  }

  void _buscarTiendas(String query) async {
    if (query.isEmpty) {
      setState(() {
        _tiendasFiltradas = _tiendas;
        _viendoCategoria = false;
      });
    } else {
      final data = await _tiendaService.buscarTiendas(query);
      setState(() {
        _tiendasFiltradas = data;
        _viendoCategoria = true;
      });
    }
  }

  void _filtrarPorCategoria(String categoria) async {
    final data = await _tiendaService.filtrarPorCategoria(categoria);
    setState(() {
      _categoriaActual = categoria;
      _tiendasFiltradas = data;
      _viendoCategoria = true;
    });
  }

  void _volverCategorias() {
    setState(() {
      _viendoCategoria = false;
      _categoriaActual = null;
      _tiendasFiltradas = _tiendas;
    });
  }

  // --- Horarios ---
  bool _estaAbierta(Map<String, dynamic> tienda) {
    try {
      final horarios = tienda['horarios'] as Map<String, dynamic>?;
      if (horarios == null) return false;

      final now = DateTime.now().toUtc().subtract(const Duration(hours: 6));
      final diaKey = _diaKey(now.weekday);

      final diaInfo = horarios[diaKey] as Map<String, dynamic>?;
      if (diaInfo == null) return false;

      final abierto = diaInfo['abierto'] as bool? ?? false;
      if (!abierto) return false;

      final abre = diaInfo['abre'] as Map<String, dynamic>?;
      final cierra = diaInfo['cierra'] as Map<String, dynamic>?;
      if (abre == null || cierra == null) return false;

      final inicioMin = _toMinutes(abre);
      final finMin = _toMinutes(cierra);
      final ahoraMin = now.hour * 60 + now.minute;

      if (finMin < inicioMin) {
        return (ahoraMin >= inicioMin && ahoraMin <= 1440) ||
            (ahoraMin >= 0 && ahoraMin <= finMin);
      } else {
        return ahoraMin >= inicioMin && ahoraMin <= finMin;
      }
    } catch (e) {
      return false;
    }
  }

  int _toMinutes(Map<String, dynamic> t) {
    final hour = (t['hour'] ?? 0) as int;
    final minute = (t['minute'] ?? 0) as int;
    final period = (t['period'] ?? 'AM').toString().toUpperCase();
    int h = hour % 12;
    if (period == 'PM') h += 12;
    return h * 60 + minute;
  }

  static String _diaKey(int weekday) {
    switch (weekday) {
      case 1:
        return 'lunes';
      case 2:
        return 'martes';
      case 3:
        return 'miercoles';
      case 4:
        return 'jueves';
      case 5:
        return 'viernes';
      case 6:
        return 'sabado';
      case 7:
      default:
        return 'domingo';
    }
  }

  String _resumenHorarioDeTienda(Map<String, dynamic> tienda) {
    final horarios = tienda['horarios'] as Map<String, dynamic>?;
    if (horarios == null) return 'No definido';
    final now = DateTime.now().toUtc().subtract(const Duration(hours: 6));
    final key = _diaKey(now.weekday);
    final info = horarios[key] as Map<String, dynamic>?;
    if (info == null) return 'No definido';
    if (info['abierto'] != true) return 'Cerrado hoy';
    final abre = info['abre'] as Map<String, dynamic>?;
    final cierra = info['cierra'] as Map<String, dynamic>?;
    if (abre == null || cierra == null) return 'Horario incompleto';

    String fmt(Map<String, dynamic> t) {
      final h = (t['hour'] as int).toString().padLeft(2, '0');
      final m = (t['minute'] as int).toString().padLeft(2, '0');
      final p = t['period'] as String;
      return '$h:$m $p';
    }

    return '${fmt(abre)} - ${fmt(cierra)}';
  }

  // --- Icono por categoría ---
  IconData _iconoPorCategoria(String? categoria) {
    switch (categoria) {
      case "Comida":
        return Icons.fastfood;
      case "Postres":
        return Icons.cake;
      case "Tecnología":
        return Icons.devices;
      default:
        return Icons.store;
    }
  }

  // --- Tarjeta de categoría ---
  Widget _buildCategoryCard(IconData icon, String title,
      ValueChanged<String> onTap) {
    return GestureDetector(
      onTap: () => onTap(title),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF6EED9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: const Color(0xFF0B2239)),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0B2239),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B2239),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _viendoCategoria ? (_categoriaActual ?? "Resultados") : "CUT Eats",
          style: const TextStyle(
            color: Color(0xFFF6EED9),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        leading: _viendoCategoria
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _volverCategorias,
        )
            : null,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: _buscarTiendas,
              decoration: InputDecoration(
                hintText: "Buscar restaurantes o artículos...",
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
            const SizedBox(height: 24),

            // Botones de categorías
            if (!_viendoCategoria) ...[
              const Text(
                "Categorías populares",
                style: TextStyle(
                  color: Color(0xFFF4ECD7),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Explora nuestros productos destacados",
                style: TextStyle(
                  color: Color(0xFFB8C1CB),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCategoryCard(
                      Icons.fastfood, "Comida", _filtrarPorCategoria),
                  _buildCategoryCard(
                      Icons.cake, "Postres", _filtrarPorCategoria),
                  _buildCategoryCard(
                      Icons.devices, "Tecnología", _filtrarPorCategoria),
                  _buildCategoryCard(
                      Icons.more_horiz, "Más+", _filtrarPorCategoria),
                ],
              ),
              const SizedBox(height: 24),
            ],

            const Text(
              "Tiendas disponibles",
              style: TextStyle(
                color: Color(0xFFF4ECD7),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            if (_tiendasFiltradas.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    "No se encontraron tiendas.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
            else
              Column(
                children: _tiendasFiltradas.map((tienda) {
                  final abierta = _estaAbierta(tienda);

                  // Valores para la tarjeta
                  final nombre = tienda['nombre'] ?? 'Sin nombre';
                  final descripcion = tienda['descripcion'] ?? '';
                  final portadaUrl = (tienda['portadaUrl'] ?? '').toString();
                  final categoria = tienda['categoria'] as String?;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TiendaDetallePage(tienda: tienda),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF143657),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      // Fixed height card so all shops measure the same
                      child: SizedBox(
                        height: 112, // altura fija uniforme
                        child: Row(
                          children: [
                            // Imagen/ícono (lado izquierdo)
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                              child: Container(
                                width: 112,
                                height: 112,
                                color: const Color(0xFF0E2D44),
                                child: (portadaUrl.isNotEmpty)
                                    ? Image.network(
                                  portadaUrl,
                                  fit: BoxFit.cover,
                                  width: 112,
                                  height: 112,
                                  errorBuilder: (context, error, stackTrace) {
                                    // fallback a icono por categoría si falla la carga
                                    return Center(
                                      child: Icon(_iconoPorCategoria(categoria),
                                          color: Colors.white70, size: 40),
                                    );
                                  },
                                )
                                    : Center(
                                  child: Icon(
                                    _iconoPorCategoria(categoria),
                                    color: const Color(0xFFF6EED9),
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Texto (nombre, desc corta, horario)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      nombre,
                                      style: const TextStyle(
                                        color: Color(0xFFF6EED9),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      descripcion,
                                      style: const TextStyle(
                                          color: Colors.white70),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _resumenHorarioDeTienda(tienda),
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: abierta ? Colors.greenAccent : Colors
                                      .redAccent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  abierta ? "Abierto" : "Cerrado",
                                  style: const TextStyle(color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
