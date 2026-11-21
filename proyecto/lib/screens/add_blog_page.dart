import 'package:flutter/material.dart';

import '../services/post_service.dart';
import '../services/session.dart';
import '../widgets/app_drawer.dart';

class AddBlogPage extends StatefulWidget {
  const AddBlogPage({super.key});

  @override
  State<AddBlogPage> createState() => _AddBlogPageState();
}

class _AddBlogPageState extends State<AddBlogPage> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descripcion = TextEditingController();
  final _imagen = TextEditingController();
  final _tags = TextEditingController();
  final _servicio = PostService();
  bool _guardando = false;

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    _imagen.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await _servicio.agregarPost(
        titulo: _titulo.text,
        descripcion: _descripcion.text,
        imagen: _imagen.text,
        tags: _tags.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pastel publicado correctamente')),
      );

      // Se abrió con push (botón "Publicar pastel"): regresa al blog.
      // Se abrió desde el menú (pantalla reemplazada): vuelve a la ruta del blog.
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacementNamed(context, '/blog');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar pastel')),
      drawer: const AppDrawer(rutaActual: '/add-blog'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Nuevo pastel',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text('Publicas como: ${Sesion.nombre}'),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _titulo,
                        maxLength: 150,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del pastel',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().length < 2
                            ? 'Ingresa el nombre del pastel (mínimo 2 caracteres)'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _descripcion,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Descripción (sabor, relleno, glaseado, receta...)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Ingresa la descripción'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _imagen,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'URL de la foto (opcional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _tags,
                        decoration: const InputDecoration(
                          labelText: 'Etiquetas (opcional)',
                          hintText: 'chocolate, cumpleaños, frutas',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _guardando ? null : _guardar,
                        icon: _guardando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.cake),
                        label: Text(
                          _guardando ? 'Guardando...' : 'Publicar pastel',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
