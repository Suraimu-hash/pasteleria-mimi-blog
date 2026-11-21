import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/comentario_model.dart';
import 'api_client.dart';
import 'session.dart';

class ComentarioService {
  Future<List<ComentarioModel>> obtenerComentarios(int blogId) async {
    final respuesta = await enviar(
      () => http.get(
        Uri.parse('$apiBaseUrl/blog/$blogId/comentarios'),
        headers: Sesion.headers,
      ),
    );

    if (respuesta.statusCode != 200) lanzarError(respuesta);

    final datos = decodificar(respuesta) as List<dynamic>;
    return datos
        .map((json) => ComentarioModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Comentario con texto, con sticker o con ambos.
  Future<ComentarioModel> agregarComentario(
    int blogId,
    String texto, {
    String? sticker,
  }) async {
    final respuesta = await enviar(
      () => http.post(
        Uri.parse('$apiBaseUrl/blog/$blogId/comentarios'),
        headers: Sesion.headers,
        body: jsonEncode({'comentario': texto.trim(), 'sticker': sticker}),
      ),
    );

    if (respuesta.statusCode != 201) lanzarError(respuesta);
    return ComentarioModel.fromJson(
      decodificar(respuesta) as Map<String, dynamic>,
    );
  }

  Future<void> eliminarComentario(int comentarioId) async {
    final respuesta = await enviar(
      () => http.delete(
        Uri.parse('$apiBaseUrl/comentarios/$comentarioId'),
        headers: Sesion.headers,
      ),
    );

    if (respuesta.statusCode != 200) lanzarError(respuesta);
  }

  /// Pone o quita (toggle) una reacción. Devuelve el comentario actualizado.
  Future<ComentarioModel> reaccionar(int comentarioId, String tipo) async {
    final datos = await pedirApi(
      'POST',
      '/comentarios/$comentarioId/reacciones',
      cuerpo: {'tipo': tipo},
    );
    return ComentarioModel.fromJson(datos as Map<String, dynamic>);
  }
}
