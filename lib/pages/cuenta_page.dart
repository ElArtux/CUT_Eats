import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../mi_tienda/crear_tienda_page.dart';
import 'cuenta/notificaciones.dart';

class CuentaPage extends StatelessWidget {
  const CuentaPage({super.key});

  Future<void> _confirmarCerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF143657),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "¿Cerrar sesión?",
            style: TextStyle(
              color: Color(0xFFF6EED9),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "¿Estás seguro de que quieres cerrar sesión?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Cerrar sesión"),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      _cerrarSesion(context);
    }
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión cerrada con éxito ✅'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0B2239),
      appBar: AppBar(
        backgroundColor: const Color(0xFF143657),
        title: const Text(
          "Mi Cuenta",
          style: TextStyle(
            color: Color(0xFFF6EED9),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFF6EED9),
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Color(0xFF0B2239),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Center(
                child: Text(
                  user?.email ?? "Usuario anónimo",
                  style: const TextStyle(
                    color: Color(0xFFF6EED9),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                "Configuración",
                style: TextStyle(
                  color: Color(0xFFF6EED9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              _buildOptionTile(Icons.email, "Correo electrónico", user?.email ?? "Sin correo"),
              _buildOptionTile(
                Icons.storefront,
                "Tu tienda",
                "Crea o administra tu tienda",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CrearTiendaPage()),
                  );
                },
              ),
              _buildOptionTile(
                Icons.notifications,
                "Notificaciones",
                "Preferencias de alertas",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificacionesPage()),
                  );
                },
              ),
              _buildOptionTile(Icons.help_outline, "Centro de ayuda", ""),
              _buildOptionTile(Icons.info_outline, "Sobre CUT Eats", ""),
              const SizedBox(height: 20),

              Center(
                child: TextButton.icon(
                  onPressed: () => _confirmarCerrarSesion(context),
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text(
                    "Cerrar sesión",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF143657),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFF6EED9)),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFF6EED9),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle, style: const TextStyle(color: Colors.white70))
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        onTap: onTap,
      ),
    );
  }
}
