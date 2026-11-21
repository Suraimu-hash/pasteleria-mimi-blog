import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'api_client.dart';
import 'session.dart';

class AuthService {
  String? validarLogin({
    required String usuario,
    required String password,
  }) {
    if (usuario.trim().isEmpty || password.isEmpty) {
      return 'Ingresa tu correo y contraseña';
    }

    return null;
  }

  String? validarRegistro({
    required String nombre,
    required String correo,
    required String password,
    required String confirmarPassword,
  }) {
    if (nombre.isEmpty ||
        correo.isEmpty ||
        password.isEmpty ||
        confirmarPassword.isEmpty) {
      return 'Completa todos los campos';
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo)) {
      return 'Ingresa un correo válido';
    }

    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    if (password != confirmarPassword) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  /// Inicia sesión: guarda el token JWT y devuelve los datos del usuario.
  Future<Map<String, dynamic>> autenticar({
    required String correo,
    required String password,
  }) async {
    final respuesta = await enviar(
      () => http.post(
        Uri.parse('$apiBaseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'mail': correo.trim().toLowerCase(),
          'password': password,
        }),
      ),
    );

    if (respuesta.statusCode == 200) {
      final datos = decodificar(respuesta) as Map<String, dynamic>;
      final usuario = Map<String, dynamic>.from(datos['usuario'] as Map);
      Sesion.iniciar(datos['access_token'] as String, usuario);
      return usuario;
    }

    if (respuesta.statusCode == 401) {
      throw Exception('Correo o contraseña incorrectos');
    }

    throw Exception(mensajeDeError(respuesta));
  }
}
