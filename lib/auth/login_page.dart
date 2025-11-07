// lib/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 👈 agregado

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 🧠 Función auxiliar para validar dominio permitido
  bool _isAllowedDomain(String email) {
    return email.endsWith('@academicos.udg.mx') || email.endsWith('@alumnos.udg.mx');
  }

  // 🧾 🔥 Función para guardar usuario en Firestore
  Future<void> _guardarUsuarioEnFirestore(User user) async {
    final usersRef = FirebaseFirestore.instance.collection('usuarios');

    await usersRef.doc(user.uid).set({
      'uid': user.uid,
      'nombre': user.displayName ?? 'Sin nombre',
      'email': user.email,
      'foto': user.photoURL,
      'ultimoAcceso': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 🔐 Iniciar sesión con correo y contraseña
  Future<void> _login() async {
    final email = _emailController.text.trim();

    // Verificar dominio
    if (!_isAllowedDomain(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo se permiten correos @academicos.udg.mx o @alumnos.udg.mx')),
      );
      return;
    }

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      // 👇 Guarda el usuario en Firestore si inició sesión correctamente
      final user = cred.user;
      if (user != null) {
        await _guardarUsuarioEnFirestore(user);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // 🧾 Registrar nuevo usuario
  Future<void> _register() async {
    final email = _emailController.text.trim();

    // Verificar dominio
    if (!_isAllowedDomain(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo se permiten correos @academicos.udg.mx o @alumnos.udg.mx')),
      );
      return;
    }

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      // 👇 Guarda el usuario en Firestore al registrarse
      final user = cred.user;
      if (user != null) {
        await _guardarUsuarioEnFirestore(user);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // 🟢 Iniciar sesión con Google
  Future<void> _loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // Cancelado por el usuario

      // Verificar dominio del correo Google
      final email = googleUser.email;
      if (!_isAllowedDomain(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solo se permiten cuentas @academicos.udg.mx o @alumnos.udg.mx')),
        );
        await GoogleSignIn().signOut();
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await FirebaseAuth.instance.signInWithCredential(credential);

      // 👇 Guarda el usuario en Firestore si inicia con Google
      final user = cred.user;
      if (user != null) {
        await _guardarUsuarioEnFirestore(user);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar con Google: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B2239),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'CUT Eats',
              style: TextStyle(
                color: Color(0xFFF6EED9),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            // Campos de texto
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Color(0xFF143657),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Color(0xFF143657),
              ),
              style: const TextStyle(color: Colors.white),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            // Botón de iniciar sesión normal
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF6EED9),
                foregroundColor: const Color(0xFF0B2239),
              ),
              child: const Text('Iniciar sesión'),
            ),

            // Crear cuenta
            TextButton(
              onPressed: _register,
              child: const Text(
                'Crear cuenta',
                style: TextStyle(color: Colors.white70),
              ),
            ),

            // 🔵 Botón Google
            ElevatedButton.icon(
              onPressed: _loginWithGoogle,
              label: const Text('Iniciar sesión con Google'),
            ),
          ],
        ),
      ),
    );
  }
}
