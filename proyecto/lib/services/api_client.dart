import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'session.dart';

/// La sesión expiró o el token ya no es válido.
class SesionExpirada implements Exception {
  @override
  String toString() => 'Tu sesión expiró. Inicia sesión de nuevo.';
}

const String _sinConexion =
    'No se pudo conectar con el servidor. Verifica que la API esté encendida.';

/// Ejecuta una petición HTTP con tiempo límite y errores de red legibles.
Future<http.Response> enviar(Future<http.Response> Function() peticion) async {
  try {
    return await peticion().timeout(const Duration(seconds: 10));
  } on TimeoutException {
    throw Exception(_sinConexion);
  } catch (_) {
    throw Exception(_sinConexion);
  }
}

/// Decodifica el cuerpo como UTF-8 (para que los acentos se vean bien).
dynamic decodificar(http.Response r) {
  if (r.bodyBytes.isEmpty) return null;
  return jsonDecode(utf8.decode(r.bodyBytes));
}

String mensajeDeError(http.Response r) {
  try {
    final datos = decodificar(r);
    if (datos is Map && datos['detail'] != null) {
      final detalle = datos['detail'];
      if (detalle is String) return detalle;
      if (detalle is List && detalle.isNotEmpty && detalle.first is Map) {
        return (detalle.first as Map)['msg'].toString();
      }
    }
  } catch (_) {
    // el cuerpo no era JSON
  }
  return 'Error del servidor (HTTP ${r.statusCode})';
}

/// Lanza la excepción adecuada para una respuesta que no fue exitosa.
Never lanzarError(http.Response r) {
  if (r.statusCode == 401 && Sesion.activa) {
    Sesion.cerrar();
    throw SesionExpirada();
  }
  throw Exception(mensajeDeError(r));
}

/// Atajo para los módulos nuevos: hace la petición con la sesión actual,
/// revisa el código de respuesta y devuelve el JSON ya decodificado.
Future<dynamic> pedirApi(
  String metodo,
  String ruta, {
  Object? cuerpo,
  Map<String, String>? query,
}) async {
  var uri = Uri.parse('$apiBaseUrl$ruta');
  if (query != null && query.isNotEmpty) uri = uri.replace(queryParameters: query);
  final body = cuerpo == null ? null : jsonEncode(cuerpo);
  final headers = Sesion.headers;

  final respuesta = await enviar(() {
    switch (metodo) {
      case 'POST':
        return http.post(uri, headers: headers, body: body);
      case 'PUT':
        return http.put(uri, headers: headers, body: body);
      case 'DELETE':
        return http.delete(uri, headers: headers, body: body);
      default:
        return http.get(uri, headers: headers);
    }
  });

  if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
    lanzarError(respuesta);
  }
  return decodificar(respuesta);
}
