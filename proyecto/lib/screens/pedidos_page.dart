import 'package:flutter/material.dart';

import '../models/pedido_model.dart';
import '../services/session.dart';
import '../services/tienda_service.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/app_drawer.dart';
import '../widgets/imagen_red.dart';

/// Historial de pedidos. El administrador ve los de todos los clientes y
/// puede cambiar su estatus; el cliente puede cancelar antes de que se prepare.
class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  final TiendaService tienda = TiendaService();
  late Future<List<PedidoModel>> futuro;

  bool get esAdmin => Sesion.esAdmin;

  @override
  void initState() {
    super.initState();
    futuro = tienda.obtenerPedidos(todos: esAdmin);
  }

  Future<void> recargar() async {
    setState(() => futuro = tienda.obtenerPedidos(todos: esAdmin));
    try {
      await futuro;
    } catch (_) {}
  }

  void mostrarMensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> cambiarEstatus(PedidoModel p, String estatus) async {
    try {
      await tienda.cambiarEstatus(p.id, estatus);
      mostrarMensaje('Pedido #${p.id}: ${PedidoModel.nombreEstatus(estatus)}');
      recargar();
    } catch (e) {
      mostrarMensaje(limpiarError(e));
    }
  }

  Future<void> cancelar(PedidoModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: Text('¿Seguro que quieres cancelar el pedido #${p.id}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await tienda.cancelarPedido(p.id);
      mostrarMensaje('Pedido cancelado');
      recargar();
    } catch (e) {
      mostrarMensaje(limpiarError(e));
    }
  }

  Widget _chipEstatus(String estatus) {
    final color = PedidoModel.colorEstatus(estatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        PedidoModel.nombreEstatus(estatus),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _tarjeta(PedidoModel p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        shape: const Border(),
        leading: CircleAvatar(
          backgroundColor: Mimi.rosaClaro,
          child: Text('${p.numArticulos}', style: const TextStyle(color: Mimi.frambuesa)),
        ),
        title: Row(
          children: [
            Text('Pedido #${p.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(formatearPrecio(p.total), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chipEstatus(p.estatus),
              Text(
                esAdmin ? '${p.cliente} · ${p.fechaFormateada}' : p.fechaFormateada,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          for (final d in p.detalles)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(child: Text('${d.cantidad} × ${d.nombre}')),
                  Text(formatearPrecio(d.subtotal)),
                ],
              ),
            ),
          const Divider(),
          Text('Entrega: ${p.direccionEnvio}'),
          if (p.telefono != null) Text('Teléfono: ${p.telefono}'),
          Text('Pago: ${p.pagoTexto}'),
          Text('Referencia: ${p.referenciaPago}',
              style: const TextStyle(color: Mimi.gris, fontSize: 12)),
          const SizedBox(height: 10),
          if (esAdmin)
            Row(
              children: [
                const Text('Cambiar estatus: '),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: p.estatus,
                    items: [
                      for (final e in PedidoModel.estatusPosibles)
                        DropdownMenuItem(value: e, child: Text(PedidoModel.nombreEstatus(e))),
                    ],
                    onChanged: p.estatus == 'cancelado'
                        ? null
                        : (e) {
                            if (e != null && e != p.estatus) cambiarEstatus(p, e);
                          },
                  ),
                ),
              ],
            )
          else if (p.cancelable)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => cancelar(p),
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                label: const Text('Cancelar pedido', style: TextStyle(color: Colors.red)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(esAdmin ? 'Pedidos de clientes' : 'Mis pedidos'),
        actions: [
          IconButton(onPressed: recargar, icon: const Icon(Icons.refresh), tooltip: 'Actualizar'),
        ],
      ),
      drawer: Navigator.canPop(context) ? null : const AppDrawer(rutaActual: '/pedidos'),
      body: RefreshIndicator(
        onRefresh: recargar,
        child: FutureBuilder<List<PedidoModel>>(
          future: futuro,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(children: [VistaError(error: snap.error!, alReintentar: recargar)]);
            }
            final pedidos = snap.data ?? [];
            if (pedidos.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  const Icon(Icons.receipt_long_outlined, size: 64, color: Mimi.rosa),
                  const SizedBox(height: 12),
                  const Center(child: Text('Aún no hay pedidos')),
                  if (!esAdmin)
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/tienda'),
                        child: const Text('Ir a la tienda'),
                      ),
                    ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(12),
              children: pedidos.map(_tarjeta).toList(),
            );
          },
        ),
      ),
    );
  }
}
