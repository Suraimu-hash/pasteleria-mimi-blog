import 'package:flutter/material.dart';

import '../utils/formato.dart';

class PedidoDetalleModel {
  final String nombre;
  final double precioUnitario;
  final int cantidad;
  final double subtotal;

  PedidoDetalleModel({
    required this.nombre,
    required this.precioUnitario,
    required this.cantidad,
    required this.subtotal,
  });

  factory PedidoDetalleModel.fromJson(Map<String, dynamic> json) {
    return PedidoDetalleModel(
      nombre: json['nombre'] as String,
      precioUnitario: (json['precio_unitario'] as num).toDouble(),
      cantidad: (json['cantidad'] as num).toInt(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }
}

class PedidoModel {
  final int id;
  final String fecha;
  final double total;
  final String estatus;
  final String direccionEnvio;
  final String? telefono;
  final String metodoPago;
  final String referenciaPago;
  final String? tarjetaUltimos4;
  final int usuarioId;
  final String cliente;
  final List<PedidoDetalleModel> detalles;

  PedidoModel({
    required this.id,
    required this.fecha,
    required this.total,
    required this.estatus,
    required this.direccionEnvio,
    this.telefono,
    required this.metodoPago,
    required this.referenciaPago,
    this.tarjetaUltimos4,
    required this.usuarioId,
    required this.cliente,
    required this.detalles,
  });

  /// Estatus posibles, en el orden en que avanza un pedido.
  static const List<String> estatusPosibles = [
    'pendiente_pago',
    'pagado',
    'en_preparacion',
    'enviado',
    'entregado',
    'cancelado',
  ];

  static String nombreEstatus(String estatus) {
    switch (estatus) {
      case 'pendiente_pago':
        return 'Pago pendiente';
      case 'pagado':
        return 'Pagado';
      case 'en_preparacion':
        return 'En preparación';
      case 'enviado':
        return 'Enviado';
      case 'entregado':
        return 'Entregado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return estatus;
    }
  }

  static Color colorEstatus(String estatus) {
    switch (estatus) {
      case 'pendiente_pago':
        return Colors.orange;
      case 'pagado':
        return Colors.blue;
      case 'en_preparacion':
        return Colors.purple;
      case 'enviado':
        return Colors.teal;
      case 'entregado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get estatusTexto => nombreEstatus(estatus);
  String get fechaFormateada => formatearFecha(fecha);
  bool get cancelable => estatus == 'pagado' || estatus == 'pendiente_pago';

  String get pagoTexto => metodoPago == 'tarjeta'
      ? 'Tarjeta •••• ${tarjetaUltimos4 ?? ''}'
      : 'Efectivo al recibir';

  int get numArticulos => detalles.fold(0, (s, d) => s + d.cantidad);

  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    return PedidoModel(
      id: json['id_ped'] as int,
      fecha: json['fecha'] as String,
      total: (json['total'] as num).toDouble(),
      estatus: json['estatus'] as String,
      direccionEnvio: json['direccion_envio'] as String,
      telefono: json['telefono'] as String?,
      metodoPago: json['metodo_pago'] as String,
      referenciaPago: json['referencia_pago'] as String,
      tarjetaUltimos4: json['tarjeta_ultimos4'] as String?,
      usuarioId: json['usr_id'] as int,
      cliente: json['cliente'] as String? ?? '',
      detalles: (json['detalles'] as List<dynamic>)
          .map((d) => PedidoDetalleModel.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}
