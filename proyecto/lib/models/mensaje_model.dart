import '../utils/formato.dart';

class MensajeModel {
  final int id;
  final String texto;
  final String fecha;
  final bool leido;
  final int remitenteId;
  final int destinatarioId;

  MensajeModel({
    required this.id,
    required this.texto,
    required this.fecha,
    required this.leido,
    required this.remitenteId,
    required this.destinatarioId,
  });

  String get hora => formatearHoraChat(fecha);

  factory MensajeModel.fromJson(Map<String, dynamic> json) {
    return MensajeModel(
      id: json['id_msg'] as int,
      texto: json['texto'] as String,
      fecha: json['fecha'] as String,
      leido: json['leido'] as bool? ?? false,
      remitenteId: json['remitente_id'] as int,
      destinatarioId: json['destinatario_id'] as int,
    );
  }
}

class ConversacionModel {
  final int usuarioId;
  final String nombre;
  final bool esAdmin;
  final String ultimoMensaje;
  final String fecha;
  final int noLeidos;

  ConversacionModel({
    required this.usuarioId,
    required this.nombre,
    required this.esAdmin,
    required this.ultimoMensaje,
    required this.fecha,
    required this.noLeidos,
  });

  String get hora => formatearHoraChat(fecha);

  factory ConversacionModel.fromJson(Map<String, dynamic> json) {
    return ConversacionModel(
      usuarioId: json['usuario_id'] as int,
      nombre: json['nombre'] as String,
      esAdmin: json['es_admin'] as bool? ?? false,
      ultimoMensaje: json['ultimo_mensaje'] as String? ?? '',
      fecha: json['fecha'] as String,
      noLeidos: (json['no_leidos'] as num?)?.toInt() ?? 0,
    );
  }
}

class ContactoModel {
  final int id;
  final String nombre;
  final bool esAdmin;

  ContactoModel({required this.id, required this.nombre, required this.esAdmin});

  factory ContactoModel.fromJson(Map<String, dynamic> json) {
    return ContactoModel(
      id: json['id_usr'] as int,
      nombre: json['nom_usr'] as String,
      esAdmin: (json['tip_usu'] as num?)?.toInt() == 1,
    );
  }
}
