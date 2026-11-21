import 'package:flutter/material.dart';

import '../models/producto_model.dart';
import '../services/tienda_service.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/app_drawer.dart';
import '../widgets/imagen_red.dart';

/// Administración del catálogo (solo administradores).
class AdminProductosPage extends StatefulWidget {
  const AdminProductosPage({super.key});

  @override
  State<AdminProductosPage> createState() => _AdminProductosPageState();
}

class _AdminProductosPageState extends State<AdminProductosPage> {
  final TiendaService tienda = TiendaService();
  late Future<List<ProductoModel>> futuro;

  @override
  void initState() {
    super.initState();
    futuro = tienda.obtenerProductos(todos: true);
  }

  Future<void> recargar() async {
    setState(() => futuro = tienda.obtenerProductos(todos: true));
    try {
      await futuro;
    } catch (_) {}
  }

  void mostrarMensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> abrirFormulario([ProductoModel? producto]) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductoFormPage(producto: producto)),
    );
    if (guardado == true) recargar();
  }

  Future<void> eliminar(ProductoModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${p.nombre}"? Los pedidos anteriores se conservan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await tienda.eliminarProducto(p.id);
      mostrarMensaje('Producto eliminado');
      recargar();
    } catch (e) {
      mostrarMensaje(limpiarError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar productos')),
      drawer: Navigator.canPop(context)
          ? null
          : const AppDrawer(rutaActual: '/admin-productos'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
      ),
      body: RefreshIndicator(
        onRefresh: recargar,
        child: FutureBuilder<List<ProductoModel>>(
          future: futuro,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(children: [VistaError(error: snap.error!, alReintentar: recargar)]);
            }
            final productos = snap.data ?? [];
            if (productos.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Center(child: Text('No hay productos. Agrega el primero.')),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: productos.length,
              itemBuilder: (context, i) {
                final p = productos[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => abrirFormulario(p),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ImagenRed(url: p.imagen, alto: 52, ancho: 52),
                    ),
                    title: Text(
                      p.nombre,
                      style: TextStyle(
                        decoration: p.activo ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    subtitle: Text(
                      '${formatearPrecio(p.precio)} · Stock: ${p.stock}'
                      '${p.activo ? '' : ' · OCULTO'}',
                      style: TextStyle(color: p.stock == 0 ? Colors.red : Mimi.gris),
                    ),
                    trailing: IconButton(
                      tooltip: 'Eliminar',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => eliminar(p),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Formulario para crear o editar un producto.
class ProductoFormPage extends StatefulWidget {
  final ProductoModel? producto;

  const ProductoFormPage({super.key, this.producto});

  @override
  State<ProductoFormPage> createState() => _ProductoFormPageState();
}

class _ProductoFormPageState extends State<ProductoFormPage> {
  final TiendaService tienda = TiendaService();
  final formKey = GlobalKey<FormState>();

  late final nombreCtrl = TextEditingController(text: widget.producto?.nombre ?? '');
  late final descCtrl = TextEditingController(text: widget.producto?.descripcion ?? '');
  late final precioCtrl = TextEditingController(
    text: widget.producto == null ? '' : widget.producto!.precio.toStringAsFixed(2),
  );
  late final stockCtrl = TextEditingController(text: '${widget.producto?.stock ?? 10}');
  late final imgCtrl = TextEditingController(text: widget.producto?.imagen ?? '');
  late final catCtrl = TextEditingController(text: widget.producto?.categoria ?? 'Pasteles');
  late bool activo = widget.producto?.activo ?? true;
  bool guardando = false;

  @override
  void dispose() {
    for (final c in [nombreCtrl, descCtrl, precioCtrl, stockCtrl, imgCtrl, catCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> guardar() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => guardando = true);
    try {
      final datos = ProductoModel(
        id: widget.producto?.id ?? 0,
        nombre: nombreCtrl.text.trim(),
        descripcion: descCtrl.text.trim(),
        precio: double.parse(precioCtrl.text.trim()),
        imagen: imgCtrl.text.trim(),
        categoria: catCtrl.text.trim(),
        stock: int.parse(stockCtrl.text.trim()),
        activo: activo,
      );
      await tienda.guardarProducto(datos, id: widget.producto?.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No se pudo guardar: ${limpiarError(e)}')));
      }
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  InputDecoration _deco(String etiqueta, IconData icono) => InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono),
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.producto == null ? 'Nuevo producto' : 'Editar producto'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: nombreCtrl,
              decoration: _deco('Nombre', Icons.cake_outlined),
              validator: (v) => (v ?? '').trim().length < 2 ? 'Escribe el nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descCtrl,
              maxLines: 3,
              decoration: _deco('Descripción', Icons.notes),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: precioCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _deco('Precio', Icons.attach_money),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').trim());
                      return n == null || n <= 0 ? 'Precio no válido' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _deco('Stock', Icons.inventory_2_outlined),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      return n == null || n < 0 ? 'Stock no válido' : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: catCtrl,
              decoration: _deco('Categoría', Icons.category_outlined),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: imgCtrl,
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
              decoration: _deco('URL de la imagen', Icons.image_outlined),
            ),
            if (imgCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ImagenRed(url: imgCtrl.text.trim(), alto: 160),
              ),
            ],
            SwitchListTile(
              value: activo,
              onChanged: (v) => setState(() => activo = v),
              title: const Text('Visible en la tienda'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: guardando ? null : guardar,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
