import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../services/api_client.dart';
import '../services/mensaje_service.dart';
import '../services/post_service.dart';
import '../services/session.dart';
import '../theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/category_chip.dart';
import '../widgets/post_card.dart';
import 'post_detail_page.dart';

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final PostService postService = PostService();

  late Future<List<PostModel>> futuroPosts;

  bool soloMias = false; // "Mis pasteles": publicaciones del usuario en sesión
  String? etiqueta; // filtro por etiqueta (null = todas)
  List<String> etiquetas = [];
  int mensajesSinLeer = 0;

  @override
  void initState() {
    super.initState();
    futuroPosts = _iniciarCarga();
    _contarMensajes();
  }

  Future<void> _contarMensajes() async {
    try {
      final n = await MensajeService().contarNoLeidos();
      if (mounted) setState(() => mensajesSinLeer = n);
    } catch (_) {
      // no es crítico
    }
  }

  Future<void> _abrir(String ruta) async {
    await Navigator.pushNamed(context, ruta);
    if (mounted) {
      _contarMensajes();
      recargarPosts();
    }
  }

  Future<List<PostModel>> _iniciarCarga() {
    final futuro = postService.obtenerPosts(mias: soloMias);

    // Con la lista completa se arman los chips de etiquetas.
    futuro.then((posts) {
      if (!mounted || soloMias) return;
      final conjunto = <String>{};
      for (final post in posts) {
        conjunto.addAll(post.listaTags);
      }
      setState(() => etiquetas = conjunto.toList()..sort());
    }).catchError((_) {});

    return futuro;
  }

  void recargarPosts() {
    setState(() {
      futuroPosts = _iniciarCarga();
    });
  }

  void seleccionarTodos() {
    soloMias = false;
    etiqueta = null;
    recargarPosts();
  }

  void seleccionarMias() {
    soloMias = true;
    etiqueta = null;
    recargarPosts();
  }

  void seleccionarEtiqueta(String valor) {
    final veniaDeMias = soloMias;
    soloMias = false;
    etiqueta = valor;
    if (veniaDeMias) {
      recargarPosts();
    } else {
      setState(() {});
    }
  }

  Future<void> abrirDetalle(PostModel post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PostDetailPage(post: post)),
    );
    if (mounted) recargarPosts(); // pudo cambiar el nº de comentarios o borrarse
  }

  Future<void> nuevaPublicacion() async {
    await Navigator.pushNamed(context, '/add-blog');
    if (mounted) recargarPosts();
  }

  List<PostModel> aplicarFiltro(List<PostModel> posts) {
    final filtro = etiqueta?.toLowerCase();
    if (filtro == null) return posts;
    return posts
        .where((p) => p.listaTags.any((t) => t.toLowerCase() == filtro))
        .toList();
  }

  Widget _chip(String texto, bool seleccionado, VoidCallback alTocar) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: CategoryChip(
        text: texto,
        selected: seleccionado,
        onTap: alTocar,
      ),
    );
  }

  Widget _vistaError(Object error) {
    final expirada = error is SesionExpirada;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(expirada ? Icons.lock_clock : Icons.cloud_off, size: 48),
          const SizedBox(height: 12),
          Text(
            expirada
                ? 'Tu sesión expiró.'
                : 'No se pudieron cargar las publicaciones.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString().replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (expirada)
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              ),
              child: const Text('Iniciar sesión'),
            )
          else
            ElevatedButton(
              onPressed: recargarPosts,
              child: const Text('Reintentar'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pastelería Mimi'),
            Text(
              'Hola, ${Sesion.nombre}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Tienda',
            onPressed: () => _abrir('/tienda'),
            icon: const Icon(Icons.storefront_outlined),
          ),
          IconButton(
            tooltip: 'Mensajes',
            onPressed: () => _abrir('/mensajes'),
            icon: Badge(
              isLabelVisible: mensajesSinLeer > 0,
              label: Text('$mensajesSinLeer'),
              child: const Icon(Icons.chat_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () {
              // La pantalla de login borra la sesión al abrirse.
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: const AppDrawer(rutaActual: '/blog'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: nuevaPublicacion,
        icon: const Icon(Icons.add),
        label: const Text('Publicar pastel'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          recargarPosts();
          try {
            await futuroPosts;
          } catch (_) {}
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            const Text(
              'Blog de pasteles',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Mimi.frambuesa,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Descubre, comparte y comenta los mejores pasteles',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _chip('Todos', !soloMias && etiqueta == null, seleccionarTodos),
                  _chip('Mis pasteles', soloMias, seleccionarMias),
                  for (final e in etiquetas)
                    _chip(
                      e,
                      !soloMias && etiqueta == e,
                      () => seleccionarEtiqueta(e),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<PostModel>>(
              future: futuroPosts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return _vistaError(snapshot.error!);
                }

                final posts = aplicarFiltro(snapshot.data ?? []);

                if (posts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        soloMias
                            ? 'Aún no has publicado ningún pastel'
                            : 'No hay publicaciones',
                      ),
                    ),
                  );
                }

                return Column(
                  children: posts
                      .map(
                        (post) => PostCard(
                          post: post,
                          onTap: () => abrirDetalle(post),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
