import 'package:flutter/material.dart';

import '../models/producto_model.dart';
import '../services/tienda_service.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/app_drawer.dart';
import '../widgets/category_chip.dart';
import '../widgets/imagen_red.dart';

/// Catálogo de productos de Pastelería Mimi.
class TiendaPage extends StatefulWidget {
  const TiendaPage({super.key});

  @override
  State<TiendaPage> createState() => _TiendaPageState();
}

class _TiendaPageState extends State<TiendaPage> {
  final TiendaService tienda = TiendaService();

  List<ProductoModel> productos = [];
  bool cargando = true;
  Object? error;
  String? categoria;
  int articulosEnCarrito = 0;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      final lista = await tienda.obtenerProductos();
      final carrito = await tienda.obtenerCarrito();
      if (!mounted) return;
      setState(() {
        productos = lista;
        articulosEnCarrito = carrito.numArticulos;
      });
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  void mostrarMensaje(String texto, {bool conBotonCarrito = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto),
        action: conBotonCarrito
            ? SnackBarAction(label: 'Ver carrito', onPressed: abrirCarrito)
            : null,
      ));
  }

  Future<void> agregar(ProductoModel p, {int cantidad = 1}) async {
    try {
      final carrito = await tienda.agregarAlCarrito(p.id, cantidad: cantidad);
      if (!mounted) return;
      setState(() => articulosEnCarrito = carrito.numArticulos);
      mostrarMensaje('${p.nombre} agregado al carrito', conBotonCarrito: true);
    } catch (e) {
      mostrarMensaje(limpiarError(e));
    }
  }

  Future<void> abrirCarrito() async {
    await Navigator.pushNamed(context, '/carrito');
    if (mounted) cargar(); // pudo comprar o cambiar el carrito
  }

  void verDetalle(ProductoModel p) {
    var cantidad = 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ImagenRed(url: p.imagen, alto: 200),
                ),
                const SizedBox(height: 14),
                Text(
                  p.categoria.toUpperCase(),
                  style: const TextStyle(
                    color: Mimi.rosa,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.nombre,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Mimi.frambuesa,
                  ),
                ),
                const SizedBox(height: 8),
                Text(p.descripcion, style: const TextStyle(fontSize: 15, height: 1.5)),
                const SizedBox(height: 12),
                Text(
                  p.agotado ? 'Agotado' : '${p.stock} disponibles',
                  style: TextStyle(color: p.agotado ? Colors.red : Mimi.gris),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      formatearPrecio(p.precio * cantidad),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Mimi.cacao,
                      ),
                    ),
                    const Spacer(),
                    IconButton.outlined(
                      onPressed: cantidad > 1 ? () => setSheet(() => cantidad--) : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('$cantidad', style: const TextStyle(fontSize: 18)),
                    ),
                    IconButton.outlined(
                      onPressed: cantidad < p.stock ? () => setSheet(() => cantidad++) : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: p.agotado
                        ? null
                        : () {
                            Navigator.pop(sheetContext);
                            agregar(p, cantidad: cantidad);
                          },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Agregar al carrito'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tarjeta(ProductoModel p) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () => verDetalle(p),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImagenRed(url: p.imagen),
                  if (p.agotado)
                    Container(
                      color: const Color(0x88000000),
                      alignment: Alignment.center,
                      child: const Text(
                        'AGOTADO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Mimi.cacao,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatearPrecio(p.precio),
                          style: const TextStyle(
                            color: Mimi.rosa,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Agregar al carrito',
                        visualDensity: VisualDensity.compact,
                        onPressed: p.agotado ? null : () => agregar(p),
                        icon: const Icon(Icons.add_shopping_cart, color: Mimi.rosa),
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
    final categorias = productos.map((p) => p.categoria).toSet().toList()..sort();
    final visibles = categoria == null
        ? productos
        : productos.where((p) => p.categoria == categoria).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda Mimi'),
        actions: [
          IconButton(
            tooltip: 'Mis pedidos',
            onPressed: () => Navigator.pushNamed(context, '/pedidos'),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          IconButton(
            tooltip: 'Carrito',
            onPressed: abrirCarrito,
            icon: Badge(
              isLabelVisible: articulosEnCarrito > 0,
              label: Text('$articulosEnCarrito'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
        ],
      ),
      drawer: Navigator.canPop(context) ? null : const AppDrawer(rutaActual: '/tienda'),
      body: RefreshIndicator(
        onRefresh: cargar,
        child: Builder(builder: (context) {
          if (cargando && productos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (error != null && productos.isEmpty) {
            return ListView(children: [VistaError(error: error!, alReintentar: cargar)]);
          }
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pide tu pastel en línea',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Mimi.frambuesa,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 42,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: CategoryChip(
                                text: 'Todo',
                                selected: categoria == null,
                                onTap: () => setState(() => categoria = null),
                              ),
                            ),
                            for (final c in categorias)
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: CategoryChip(
                                  text: c,
                                  selected: categoria == c,
                                  onTap: () => setState(() => categoria = c),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (visibles.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('No hay productos disponibles')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 260,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _tarjeta(visibles[i]),
                      childCount: visibles.length,
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}
