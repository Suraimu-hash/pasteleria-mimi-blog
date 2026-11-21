import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'session.dart';

class UserService {
  Future<List<UserModel>> obtenerUsuarios() async {
    final respuesta = await enviar(
      () => http.get(
        Uri.parse('$apiBaseUrl/usuarios'),
        headers: Sesion.headers,
      ),
    );

    if (respuesta.statusCode != 200) lanzarError(respuesta);

    final datos = decodificar(respuesta) as List<dynamic>;
    return datos
        .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Registro de usuarios. Sin sesión (o con un cliente) la API siempre crea
  /// cuentas de cliente; solo un administrador puede crear otro administrador.
  Future<UserModel> agregarUsuario(UserModel usuario) async {
    final respuesta = await enviar(
      () => http.post(
        Uri.parse('$apiBaseUrl/usuarios'),
        headers: Sesion.headers,
        body: jsonEncode(usuario.toJsonCrear()),
      ),
    );

    if (respuesta.statusCode != 201) lanzarError(respuesta);
    return UserModel.fromJson(decodificar(respuesta) as Map<String, dynamic>);
  }

  Future<UserModel> actualizarUsuario(UserModel usuario) async {
    final respuesta = await enviar(
      () => http.put(
        Uri.parse('$apiBaseUrl/usuarios/${usuario.id}'),
        headers: Sesion.headers,
        body: jsonEncode({
          'nom_usr': usuario.nombre,
          'mail': usuario.correo,
          'dir_usr': usuario.direccion,
          'tip_usu': usuario.tipoUsuario,
        }),
      ),
    );

    if (respuesta.statusCode != 200) lanzarError(respuesta);
    return UserModel.fromJson(decodificar(respuesta) as Map<String, dynamic>);
  }

  Future<void> eliminarUsuario(int id) async {
    final respuesta = await enviar(
      () => http.delete(
        Uri.parse('$apiBaseUrl/usuarios/$id'),
        headers: Sesion.headers,
      ),
    );

    if (respuesta.statusCode != 200 && respuesta.statusCode != 204) {
      lanzarError(respuesta);
    }
  }
}
