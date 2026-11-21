import 'package:flutter/material.dart';

import '../models/carrito_model.dart';
import '../services/tienda_service.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/app_drawer.dart';
import '../widgets/imagen_red.dart';
import 'checkout_page.dart';

/// Carrito de compras del usuario (se guarda en el servidor).
class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  final TiendaService tienda = TiendaService();

  CarritoModel? carrito;
  Object? error;
  bool ocupado = false;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    setState(() => error = null);
    try {
      final c = await tienda.obtenerCarrito();
      if (mounted) setState(() => carrito = c);
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  /// Ejecuta una acción que devuelve el carrito actualizado.
  Future<void> _accion(Future<CarritoModel> Function() accion) async {
    setState(() => ocupado = true);
    try {
      final c = await accion();
      if (mounted) setState(() => carrito = c);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(limpiarError(e))));
      }
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  Future<void> vaciar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text('¿Quitar todos los productos del carrito?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Vaciar')),
        ],
      ),
    );
    if (ok == true) _accion(tienda.vaciarCarrito);
  }

  Future<void> pagar() async {
    final c = carrito;
    if (c == null || c.vacio) return;
    final compro = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CheckoutPage(carrito: c)),
    );
    if (compro == true && mounted) {
      await cargar();
      if (!mounted) return;
      Navigator.pushNamed(context, '/pedidos');
    }
  }

  Widget _item(CarritoItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ImagenRed(url: item.imagen, alto: 70, ancho: 70),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Mimi.cacao),
                  ),
                  Text(
                    '${formatearPrecio(item.precio)} c/u',
                    style: const TextStyle(color: Mimi.gris, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Quitar uno',
                        onPressed: ocupado
                            ? null
                            : item.cantidad > 1
                                ? () => _accion(() => tienda.cambiarCantidad(
                                    item.productoId, item.cantidad - 1))
                                : () => _accion(() => tienda.quitarDelCarrito(item.productoId)),
                        icon: Icon(item.cantidad > 1 ? Icons.remove_circle_outline : Icons.delete_outline),
                      ),
                      Text('${item.cantidad}', style: const TextStyle(fontSize: 16)),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Agregar uno',
                        onPressed: ocupado || item.cantidad >= item.stock
                            ? null
                            : () => _accion(() => tienda.cambiarCantidad(
                                item.productoId, item.cantidad + 1)),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      const Spacer(),
                      Text(
                        formatearPrecio(item.subtotal),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = carrito;
    Widget cuerpo;
    if (error != null && c == null) {
      cuerpo = VistaError(error: error!, alReintentar: cargar);
    } else if (c == null) {
      cuerpo = const Center(child: CircularProgressIndicator());
    } else if (c.vacio) {
      cuerpo = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 64, color: Mimi.rosa),
            const SizedBox(height: 12),
            const Text('Tu carrito está vacío'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.canPop(context)
                  ? Navigator.pop(context)
                  : Navigator.pushReplacementNamed(context, '/tienda'),
              icon: const Icon(Icons.storefront),
              label: const Text('Ir a la tienda'),
            ),
          ],
        ),
      );
    } else {
      cuerpo = Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: cargar,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: c.items.map(_item).toList(),
              ),
            ),
          ),
          Material(
            elevation: 8,
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text('Total (${c.numArticulos} artículos)',
                            style: const TextStyle(fontSize: 16)),
                        const Spacer(),
                        Text(
                          formatearPrecio(c.total),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Mimi.frambuesa,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: ocupado ? null : pagar,
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('Proceder al pago'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi carrito'),
        actions: [
          if (c != null && !c.vacio)
            IconButton(
              tooltip: 'Vaciar carrito',
              onPressed: ocupado ? null : vaciar,
              icon: const Icon(Icons.remove_shopping_cart_outlined),
            ),
        ],
      ),
      drawer: Navigator.canPop(context) ? null : const AppDrawer(rutaActual: '/carrito'),
      body: cuerpo,
    );
  }
}
