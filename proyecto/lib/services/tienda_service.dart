import '../models/carrito_model.dart';
import '../models/pedido_model.dart';
import '../models/producto_model.dart';
import 'api_client.dart';

/// Catálogo, carrito, pago y pedidos.
class TiendaService {
  // ---------- Catálogo ----------
  Future<List<ProductoModel>> obtenerProductos({bool todos = false}) async {
    final datos = await pedirApi(
      'GET',
      '/productos',
      query: todos ? {'todos': 'true'} : null,
    ) as List<dynamic>;
    return datos
        .map((j) => ProductoModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<ProductoModel> guardarProducto(ProductoModel p, {int? id}) async {
    final datos = await pedirApi(
      id == null ? 'POST' : 'PUT',
      id == null ? '/productos' : '/productos/$id',
      cuerpo: p.toJson(),
    );
    return ProductoModel.fromJson(datos as Map<String, dynamic>);
  }

  Future<void> eliminarProducto(int id) => pedirApi('DELETE', '/productos/$id');

  // ---------- Carrito ----------
  Future<CarritoModel> obtenerCarrito() async =>
      CarritoModel.fromJson(await pedirApi('GET', '/carrito') as Map<String, dynamic>);

  Future<CarritoModel> agregarAlCarrito(int productoId, {int cantidad = 1}) async =>
      CarritoModel.fromJson(await pedirApi(
        'POST',
        '/carrito',
        cuerpo: {'prod_id': productoId, 'cantidad': cantidad},
      ) as Map<String, dynamic>);

  Future<CarritoModel> cambiarCantidad(int productoId, int cantidad) async =>
      CarritoModel.fromJson(await pedirApi(
        'PUT',
        '/carrito/$productoId',
        cuerpo: {'cantidad': cantidad},
      ) as Map<String, dynamic>);

  Future<CarritoModel> quitarDelCarrito(int productoId) async =>
      CarritoModel.fromJson(
          await pedirApi('DELETE', '/carrito/$productoId') as Map<String, dynamic>);

  Future<CarritoModel> vaciarCarrito() async =>
      CarritoModel.fromJson(await pedirApi('DELETE', '/carrito') as Map<String, dynamic>);

  // ---------- Pago y pedidos ----------
  Future<PedidoModel> pagar({
    required String direccion,
    String? telefono,
    required String metodoPago, // 'tarjeta' | 'efectivo'
    Map<String, String>? tarjeta,
  }) async {
    final datos = await pedirApi('POST', '/pedidos/checkout', cuerpo: {
      'direccion_envio': direccion.trim(),
      'telefono': (telefono ?? '').trim().isEmpty ? null : telefono!.trim(),
      'metodo_pago': metodoPago,
      'tarjeta': tarjeta,
    });
    return PedidoModel.fromJson(datos as Map<String, dynamic>);
  }

  Future<List<PedidoModel>> obtenerPedidos({bool todos = false}) async {
    final datos = await pedirApi(
      'GET',
      '/pedidos',
      query: todos ? {'todos': 'true'} : null,
    ) as List<dynamic>;
    return datos
        .map((j) => PedidoModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<PedidoModel> cambiarEstatus(int pedidoId, String estatus) async =>
      PedidoModel.fromJson(await pedirApi(
        'PUT',
        '/pedidos/$pedidoId/estatus',
        cuerpo: {'estatus': estatus},
      ) as Map<String, dynamic>);

  Future<PedidoModel> cancelarPedido(int pedidoId) async => PedidoModel.fromJson(
      await pedirApi('POST', '/pedidos/$pedidoId/cancelar') as Map<String, dynamic>);
}
