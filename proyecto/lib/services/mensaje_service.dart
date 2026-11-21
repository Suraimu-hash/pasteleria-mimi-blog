import '../models/mensaje_model.dart';
import 'api_client.dart';

/// Mensajería interna entre usuarios registrados.
class MensajeService {
  Future<List<ConversacionModel>> obtenerConversaciones() async {
    final datos = await pedirApi('GET', '/mensajes/conversaciones') as List<dynamic>;
    return datos
        .map((j) => ConversacionModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<ContactoModel>> obtenerContactos() async {
    final datos = await pedirApi('GET', '/contactos') as List<dynamic>;
    return datos
        .map((j) => ContactoModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Mensajes con [usuarioId]. Con [despuesDe] solo trae los más nuevos.
  Future<List<MensajeModel>> obtenerMensajes(int usuarioId, {int despuesDe = 0}) async {
    final datos = await pedirApi(
      'GET',
      '/mensajes/$usuarioId',
      query: despuesDe > 0 ? {'despues_de': '$despuesDe'} : null,
    ) as List<dynamic>;
    return datos
        .map((j) => MensajeModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<MensajeModel> enviarMensaje(int usuarioId, String texto) async {
    final datos = await pedirApi(
      'POST',
      '/mensajes/$usuarioId',
      cuerpo: {'texto': texto.trim()},
    );
    return MensajeModel.fromJson(datos as Map<String, dynamic>);
  }

  Future<int> contarNoLeidos() async {
    final datos = await pedirApi('GET', '/mensajes/no-leidos') as Map<String, dynamic>;
    return (datos['no_leidos'] as num?)?.toInt() ?? 0;
  }
}
