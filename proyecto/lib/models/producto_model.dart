class ProductoModel {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String imagen;
  final String categoria;
  final int stock;
  final bool activo;

  ProductoModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.imagen,
    required this.categoria,
    required this.stock,
    required this.activo,
  });

  bool get agotado => stock <= 0;

  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    return ProductoModel(
      id: json['id_prod'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      precio: (json['precio'] as num).toDouble(),
      imagen: json['img'] as String? ?? '',
      categoria: json['categoria'] as String? ?? 'Otros',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'descripcion': descripcion.isEmpty ? null : descripcion,
        'precio': precio,
        'img': imagen.isEmpty ? null : imagen,
        'categoria': categoria.isEmpty ? null : categoria,
        'stock': stock,
        'activo': activo,
      };
}
