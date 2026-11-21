class CarritoItemModel {
  final int productoId;
  final String nombre;
  final String imagen;
  final double precio;
  final int cantidad;
  final double subtotal;
  final int stock;

  CarritoItemModel({
    required this.productoId,
    required this.nombre,
    required this.imagen,
    required this.precio,
    required this.cantidad,
    required this.subtotal,
    required this.stock,
  });

  factory CarritoItemModel.fromJson(Map<String, dynamic> json) {
    return CarritoItemModel(
      productoId: json['prod_id'] as int,
      nombre: json['nombre'] as String,
      imagen: json['img'] as String? ?? '',
      precio: (json['precio'] as num).toDouble(),
      cantidad: (json['cantidad'] as num).toInt(),
      subtotal: (json['subtotal'] as num).toDouble(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }
}

class CarritoModel {
  final List<CarritoItemModel> items;
  final double total;
  final int numArticulos;

  CarritoModel({
    required this.items,
    required this.total,
    required this.numArticulos,
  });

  bool get vacio => items.isEmpty;

  factory CarritoModel.fromJson(Map<String, dynamic> json) {
    return CarritoModel(
      items: (json['items'] as List<dynamic>)
          .map((i) => CarritoItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toDouble(),
      numArticulos: (json['num_articulos'] as num).toInt(),
    );
  }
}
