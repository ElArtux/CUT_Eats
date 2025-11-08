// lib/mi_tienda/crear_tienda_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'horario_editor.dart'; // <-- archivo separado (ver abajo)

class CrearTiendaPage extends StatefulWidget {
  const CrearTiendaPage({super.key});

  @override
  State<CrearTiendaPage> createState() => _CrearTiendaPageState();
}

class _CrearTiendaPageState extends State<CrearTiendaPage> {
  final _formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser;

  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  String? _categoria;

  List<Map<String, TextEditingController>> productos = [
    {
      'nombre': TextEditingController(),
      'descripcion': TextEditingController(),
      'precio': TextEditingController(),
    }
  ];

  File? _imagenPortada;
  String? _portadaUrl;   // URL guardada en Firestore
  String? _portadaId;    // ID del archivo en Storage
  final ImagePicker _picker = ImagePicker();
  bool _cargando = true;
  bool _modoEdicion = false;
  String? _tiendaId;

  // Horarios: Map<dia, {'abierto':bool,'abre':{...}?, 'cierra':{...}?}>
  Map<String, Map<String, dynamic>> _horarios = {};

  @override
  void initState() {
    super.initState();
    _initHorariosDefault();
    _cargarTiendaSiExiste();
  }

  void _initHorariosDefault() {
    const dias = [
      'lunes',
      'martes',
      'miercoles',
      'jueves',
      'viernes',
      'sabado',
      'domingo'
    ];
    for (final d in dias) {
      _horarios[d] = {'abierto': false, 'abre': null, 'cierra': null};
    }
  }

  // Convierte el mapa que viene de Firestore en la estructura esperada
  Map<String, Map<String, dynamic>> _mapToHorarios(dynamic raw) {
    final result = <String, Map<String, dynamic>>{};
    final dias = [
      'lunes',
      'martes',
      'miercoles',
      'jueves',
      'viernes',
      'sabado',
      'domingo'
    ];
    // init defaults
    for (final d in dias) {
      result[d] = {'abierto': false, 'abre': null, 'cierra': null};
    }

    if (raw is Map) {
      raw.forEach((k, v) {
        final key = k.toString();
        if (v is Map) {
          final abierto = v['abierto'] ?? false;
          Map<String, dynamic>? abre;
          Map<String, dynamic>? cierra;
          if (v['abre'] is Map) {
            abre = Map<String, dynamic>.from((v['abre'] as Map).map((kk, vv) => MapEntry(kk.toString(), vv)));
          }
          if (v['cierra'] is Map) {
            cierra = Map<String, dynamic>.from((v['cierra'] as Map).map((kk, vv) => MapEntry(kk.toString(), vv)));
          }
          result[key] = {'abierto': abierto, 'abre': abre, 'cierra': cierra};
        }
      });
    }
    return result;
  }

  Future<void> _cargarTiendaSiExiste() async {
    if (user == null) return;
    final doc =
    await FirebaseFirestore.instance.collection('tiendas').doc(user!.uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _modoEdicion = true;
        _tiendaId = doc.id;
        _nombreController.text = data['nombre'] ?? '';
        _descripcionController.text = data['descripcion'] ?? '';
        _categoria = data['categoria'];
        _portadaUrl = data['portadaUrl'];
        _portadaId = data['portadaId'];

        // Horarios (conversión segura)
        _horarios = _mapToHorarios(data['horarios']);

        final List<dynamic> productosData = data['productos'] ?? [];
        productos = productosData.map((p) {
          return {
            'nombre': TextEditingController(text: p['nombre']),
            'descripcion': TextEditingController(text: p['descripcion']),
            'precio': TextEditingController(text: p['precio']?.toString() ?? ''),
          };
        }).toList();
      });
    }
    setState(() => _cargando = false);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    for (var p in productos) {
      for (var controller in p.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagenPortada = File(pickedFile.path);
      });
    }
  }

  void _agregarProducto() {
    setState(() {
      productos.add({
        'nombre': TextEditingController(),
        'descripcion': TextEditingController(),
        'precio': TextEditingController(),
      });
    });
  }

  void _eliminarProducto(int index) {
    if (productos.length > 1) {
      setState(() {
        productos.removeAt(index);
      });
    }
  }

  // Abre el diálogo de horarios (archivo separado) y espera el resultado
  Future<void> _editarHorarios() async {
    final result = await showHorarioEditorDialog(context, _horarios);
    if (result != null) {
      setState(() {
        _horarios = result;
      });
    }
  }

  Future<void> _guardarTiendaConfirmacion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF143657),
        title: Text(
          _modoEdicion ? "¿Guardar cambios?" : "¿Crear tienda?",
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          _modoEdicion
              ? "¿Deseas actualizar la información de tu tienda?"
              : "¿Deseas crear tu tienda con estos datos?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
            const Text("Cancelar", style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text("Confirmar", style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      _guardarTienda();
    }
  }

  Future<void> _guardarTienda() async {
    if (!_formKey.currentState!.validate()) return;

    // Si hay nueva imagen seleccionada, subirla a Storage
    if (_imagenPortada != null) {
      final uid = user!.uid;
      final nombreArchivo = "portada_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final ref = FirebaseStorage.instance.ref().child("tiendas/$uid/$nombreArchivo");

      await ref.putFile(_imagenPortada!);
      final url = await ref.getDownloadURL();

      _portadaId = nombreArchivo;
      _portadaUrl = url;
    }

    final tiendaData = {
      'nombre': _nombreController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'categoria': _categoria,
      'productos': productos.map((p) {
        return {
          'nombre': p['nombre']!.text.trim(),
          'descripcion': p['descripcion']!.text.trim(),
          'precio': p['precio']!.text.trim(),
        };
      }).toList(),
      'horarios': _horarios,
      'uid': user!.uid,
      'creado': FieldValue.serverTimestamp(),
      'portadaId': _portadaId,
      'portadaUrl': _portadaUrl,
    };

    try {
      await FirebaseFirestore.instance
          .collection('tiendas')
          .doc(user!.uid)
          .set(tiendaData, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_modoEdicion
                ? "Tienda actualizada con éxito ✅"
                : "Tienda creada con éxito ✅")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar tienda: $e")),
      );
    }
  }


  Future<void> _eliminarTiendaConfirmacion() async {
    final primeraConfirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF143657),
        title: const Text("¿Eliminar tienda?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "¿Seguro que deseas eliminar tu tienda? Esta acción no se puede deshacer.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
            const Text("Cancelar", style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Continuar", style: TextStyle(color: Colors.orangeAccent)),
          ),
        ],
      ),
    );

    if (primeraConfirmacion != true) return;

    final segundaConfirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF143657),
        title: const Text("Confirmar eliminación", style: TextStyle(color: Colors.white)),
        content: const Text(
          "¿Estás seguro? Se eliminar definitivamente la tienda.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (segundaConfirmacion == true) {
      await _eliminarTienda();
    }
  }

  Future<void> _eliminarTienda() async {
    try {
      await FirebaseFirestore.instance.collection('tiendas').doc(user!.uid).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tienda eliminada con éxito 🗑️")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al eliminar tienda: $e")),
      );
    }
  }

  static String _nombreDia(String dia) {
    switch (dia) {
      case 'lunes':
        return 'Lunes';
      case 'martes':
        return 'Martes';
      case 'miercoles':
        return 'Miércoles';
      case 'jueves':
        return 'Jueves';
      case 'viernes':
        return 'Viernes';
      case 'sabado':
        return 'Sábado';
      case 'domingo':
        return 'Domingo';
      default:
        return dia;
    }
  }

  static String formatTimeLocal(Map<String, dynamic>? t) {
    if (t == null) return '--:--';
    final h = (t['hour'] as int).toString().padLeft(2, '0');
    final m = (t['minute'] as int).toString().padLeft(2, '0');
    final p = (t['period'] as String);
    return '$h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B2239),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B2239),
      appBar: AppBar(
        backgroundColor: const Color(0xFF143657),
        title: Text(_modoEdicion ? "Editar Tienda" : "Crear Tienda",
            style: const TextStyle(color: Color(0xFFF6EED9), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildImagenPortada(),
              const SizedBox(height: 20),
              _buildTextField("Nombre de la tienda", _nombreController),
              _buildTextField("Descripción", _descripcionController, maxLines: 2),
              DropdownButtonFormField<String>(
                value: _categoria,
                decoration: _inputDecoration("Categoría"),
                dropdownColor: const Color(0xFF1E456B),
                items: const [
                  DropdownMenuItem(value: "Comida", child: Text("Comida", style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: "Postres", child: Text("Postres", style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: "Tecnología", child: Text("Tecnología", style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: "Otro", child: Text("Otro", style: TextStyle(color: Colors.white))),
                ],
                onChanged: (value) => setState(() => _categoria = value),
                validator: (value) => value == null ? "Selecciona una categoría" : null,
              ),
              const SizedBox(height: 20),
              const Text("Productos", style: TextStyle(color: Color(0xFFF6EED9), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Column(children: [for (int i = 0; i < productos.length; i++) _buildProductoCard(i)]),
              Center(
                child: TextButton.icon(
                  onPressed: _agregarProducto,
                  icon: const Icon(Icons.add, color: Color(0xFFF6EED9)),
                  label: const Text("Agregar producto", style: TextStyle(color: Color(0xFFF6EED9))),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _editarHorarios,
                  icon: const Icon(Icons.access_time),
                  label: const Text('Editar horario'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF6EED9),
                    foregroundColor: const Color(0xFF0B2239),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: const Text('Resumen horarios:', style: TextStyle(color: Color(0xFFF6EED9), fontWeight: FontWeight.bold)),
              ),
              ..._horarios.entries.map((e) {
                final display = (e.value['abierto'] == true)
                    ? '${formatTimeLocal(e.value['abre'])} - ${formatTimeLocal(e.value['cierra'])}'
                    : 'Cerrado';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(_nombreDia(e.key), style: const TextStyle(color: Colors.white70)),
                    Text(display, style: const TextStyle(color: Colors.white70)),
                  ]),
                );
              }).toList(),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF6EED9),
                    foregroundColor: const Color(0xFF0B2239),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _guardarTiendaConfirmacion,
                  icon: const Icon(Icons.save),
                  label: Text(_modoEdicion ? "Guardar cambios" : "Guardar Tienda", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              if (_modoEdicion) ...[
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _eliminarTiendaConfirmacion,
                    icon: const Icon(Icons.delete),
                    label: const Text("Eliminar Tienda"),
                  ),
                ),
              ],
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildImagenPortada() {
    return Center(
      child: GestureDetector(
        onTap: _seleccionarImagen,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF143657),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: _imagenPortada == null
                  ? const Center(child: Icon(Icons.add_a_photo, color: Colors.white70, size: 40))
                  : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_imagenPortada!, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            if (_imagenPortada != null)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  onPressed: () => setState(() => _imagenPortada = null),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(label),
        validator: (value) => value == null || value.isEmpty ? "Campo requerido" : null,
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF143657),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
    );
  }

  Widget _buildProductoCard(int index) {
    final producto = productos[index];
    final puedeEliminar = productos.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E456B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white30, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Producto ${index + 1}",
                  style: const TextStyle(color: Color(0xFFF6EED9), fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              if (puedeEliminar) IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _eliminarProducto(index)),
            ],
          ),
          _buildTextField("Nombre del producto", producto['nombre']!),
          _buildTextField("Descripción", producto['descripcion']!, maxLines: 2),
          _buildTextField("Precio", producto['precio']!),
        ],
      ),
    );
  }
}
