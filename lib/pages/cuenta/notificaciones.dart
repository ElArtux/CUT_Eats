// lib/pages/cuenta/notificaciones.dart
import 'package:flutter/material.dart';

class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  bool general = true;
  bool mensajes = true;
  bool promociones = true;
  bool nuevosProductos = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B2239),
      appBar: AppBar(
        backgroundColor: const Color(0xFF143657),
        title: const Text(
          "Notificaciones",
          style: TextStyle(
            color: Color(0xFFF6EED9),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 🔔 Notificaciones generales
          SwitchListTile(
            activeColor: const Color(0xFFF6EED9),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white24,
            title: const Text(
              "Notificaciones generales",
              style: TextStyle(color: Colors.white),
            ),
            value: general,
            onChanged: (value) {
              setState(() {
                general = value;
                if (!general) {
                  mensajes = false;
                  promociones = false;
                  nuevosProductos = false;
                } else {
                  mensajes = true;
                  promociones = true;
                  nuevosProductos = true;
                }
              });
            },
          ),

          // 💬 Mensajes
          SwitchListTile(
            activeColor: const Color(0xFFF6EED9),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white24,
            title: const Text("Mensajes", style: TextStyle(color: Colors.white)),
            value: mensajes,
            onChanged: general
                ? (value) => setState(() => mensajes = value)
                : null,
          ),

          // 🏷️ Promociones y ofertas de tiendas favoritas
          SwitchListTile(
            activeColor: const Color(0xFFF6EED9),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white24,
            title: const Text(
              "Promociones y ofertas (tiendas favoritas)",
              style: TextStyle(color: Colors.white),
            ),
            value: promociones,
            onChanged: general
                ? (value) => setState(() => promociones = value)
                : null,
          ),

          // 🆕 Nuevos productos de tiendas favoritas
          SwitchListTile(
            activeColor: const Color(0xFFF6EED9),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white24,
            title: const Text(
              "Nuevos productos (tiendas favoritas)",
              style: TextStyle(color: Colors.white),
            ),
            value: nuevosProductos,
            onChanged: general
                ? (value) => setState(() => nuevosProductos = value)
                : null,
          ),
        ],
      ),
    );
  }
}
