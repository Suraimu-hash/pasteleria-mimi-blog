import '../utils/formato.dart';

class ReaccionResumen {
  final String tipo;
  final int total;
  final bool mia;

  ReaccionResumen({required this.tipo, required this.total, required this.mia});

  factory ReaccionResumen.fromJson(Map<String, dynamic> json) {
    return ReaccionResumen(
      tipo: json['tipo'] as String,
      total: (json['total'] as num).toInt(),
      mia: json['mia'] as bool? ?? false,
    );
  }
}

class ComentarioModel {
  final int id;
  final String comentario;
  final String? sticker;
  final String fecha;
  final int usuarioId;
  final int blogId;
  final String nombreUsuario;
  final List<ReaccionResumen> reacciones;

  ComentarioModel({
    required this.id,
    required this.comentario,
    this.sticker,
    required this.fecha,
    required this.usuarioId,
    required this.blogId,
    required this.nombreUsuario,
    this.reacciones = const [],
  });

  String get fechaFormateada => formatearFecha(fecha);

  factory ComentarioModel.fromJson(Map<String, dynamic> json) {
    return ComentarioModel(
      id: json['id_com'] as int,
      comentario: json['comentario'] as String? ?? '',
      sticker: json['sticker'] as String?,
      fecha: json['fecha'] as String,
      usuarioId: json['usr_id'] as int,
      blogId: json['blog_id'] as int,
      nombreUsuario: json['nombre_usuario'] as String? ?? '',
      reacciones: ((json['reacciones'] as List<dynamic>?) ?? [])
          .map((r) => ReaccionResumen.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
