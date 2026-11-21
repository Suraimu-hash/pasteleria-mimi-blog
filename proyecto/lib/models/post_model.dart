import '../utils/formato.dart';

class PostModel {
  final int id;
  final String titulo;
  final String descripcion;
  final String imagen;
  final String tags;
  final String fecha;
  final int autorId;
  final String autor;
  final int numComentarios;
  final double promedioEstrellas;
  final int numValoraciones;
  final int? miValoracion;

  PostModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.imagen,
    required this.tags,
    required this.fecha,
    required this.autorId,
    required this.autor,
    required this.numComentarios,
    this.promedioEstrellas = 0,
    this.numValoraciones = 0,
    this.miValoracion,
  });

  String get fechaFormateada => formatearFecha(fecha);

  /// Etiquetas separadas por coma -> lista limpia.
  List<String> get listaTags => tags
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id_blog'] as int,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      imagen: json['img'] as String? ?? '',
      tags: json['tags'] as String? ?? '',
      fecha: json['fecha'] as String? ?? '',
      autorId: json['usr_id'] as int,
      autor: json['autor'] as String? ?? '',
      numComentarios: json['num_comentarios'] as int? ?? 0,
      promedioEstrellas:
          (json['promedio_estrellas'] as num?)?.toDouble() ?? 0,
      numValoraciones: json['num_valoraciones'] as int? ?? 0,
      miValoracion: (json['mi_valoracion'] as num?)?.toInt(),
    );
  }
}
