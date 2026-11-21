import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/post_model.dart';
import 'api_client.dart';
import 'session.dart';

class PostService {
  /// Lista las publicaciones. Con [mias] = true solo las del usuario en sesión.
  Future<List<PostModel>> obtenerPosts({bool mias = false}) async {
    final uri = Uri.parse('$apiBaseUrl/blog').replace(
      queryParameters: mias ? {'mias': 'true'} : null,
    );

    final respuesta = await enviar(
      () => http.get(uri, headers: Sesion.headers),
    );

    if (respuesta.statusCode != 200) lanzarError(respuesta);

    final datos = decodificar(respuesta) as List<dynamic>;
    return datos
        .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<PostModel> agregarPost({
    required String titulo,
    required String descripcion,
    String? imagen,
    String? tags,
  }) async {
    final respuesta = await enviar(
      () => http.post(
        Uri.parse('$apiBaseUrl/blog'),
        headers: Sesion.headers,
        body: jsonEncode({
          'titulo': titulo.trim(),
          'descripcion': descripcion.trim(),
          'img': (imagen ?? '').trim().isEmpty ? null : imagen!.trim(),
          'tags': (tags ?? '').trim().isEmpty ? null : tags!.trim(),
        }),
      ),
    );

    if (respuesta.statusCode != 200 && respuesta.statusCode != 201) {
      lanzarError(respuesta);
    }
    return PostModel.fromJson(decodificar(respuesta) as Map<String, dynamic>);
  }

  Future<void> eliminarPost(int id) async {
    final respuesta = await enviar(
      () => http.delete(
        Uri.parse('$apiBaseUrl/blog/$id'),
        headers: Sesion.headers,
      ),
    );

    if (respuesta.statusCode != 200) lanzarError(respuesta);
  }

  /// Califica con 1–5 estrellas (o cambia la calificación). Devuelve el post
  /// actualizado con el nuevo promedio.
  Future<PostModel> valorar(int postId, int estrellas) async {
    final datos = await pedirApi(
      'PUT',
      '/blog/$postId/valoracion',
      cuerpo: {'estrellas': estrellas},
    );
    return PostModel.fromJson(datos as Map<String, dynamic>);
  }

  Future<PostModel> quitarValoracion(int postId) async {
    final datos = await pedirApi('DELETE', '/blog/$postId/valoracion');
    return PostModel.fromJson(datos as Map<String, dynamic>);
  }

  Future<PostModel> obtenerPost(int postId) async {
    final datos = await pedirApi('GET', '/blog/$postId');
    return PostModel.fromJson(datos as Map<String, dynamic>);
  }
}
