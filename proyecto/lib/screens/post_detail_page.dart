import 'package:flutter/material.dart';

import '../models/comentario_model.dart';
import '../models/post_model.dart';
import '../services/comentario_service.dart';
import '../services/post_service.dart';
import '../services/session.dart';
import '../theme.dart';
import '../utils/interacciones.dart';
import '../widgets/estrellas.dart';
import '../widgets/sticker_view.dart';

class PostDetailPage extends StatefulWidget {
  final PostModel post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final ComentarioService comentarioService = ComentarioService();
  final PostService postService = PostService();
  final TextEditingController comentarioController = TextEditingController();

  List<ComentarioModel> comentarios = [];
  bool cargando = true;
  bool enviando = false;
  bool valorando = false;
  String? error;
  String? stickerElegido; // sticker que acompañará al próximo comentario
  final Set<String> reaccionando = {}; // "idComentario:tipo" en curso

  late PostModel post = widget.post;

  /// El autor de la publicación y los administradores pueden eliminarla.
  bool get puedeEliminarPost => Sesion.esAdmin || post.autorId == Sesion.usuarioId;

  bool puedeEliminarComentario(ComentarioModel c) =>
      Sesion.esAdmin || c.usuarioId == Sesion.usuarioId;

  @override
  void initState() {
    super.initState();
    cargarComentarios();
  }

  @override
  void dispose() {
    comentarioController.dispose();
    super.dispose();
  }

  void mostrarMensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  String _limpiar(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> cargarComentarios() async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      final lista = await comentarioService.obtenerComentarios(post.id);
      if (mounted) setState(() => comentarios = lista);
    } catch (e) {
      if (mounted) setState(() => error = _limpiar(e));
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> enviarComentario() async {
    final texto = comentarioController.text.trim();
    if (texto.isEmpty && stickerElegido == null) {
      mostrarMensaje('Escribe un comentario o elige un sticker');
      return;
    }

    setState(() => enviando = true);
    try {
      final nuevo = await comentarioService.agregarComentario(
        post.id,
        texto,
        sticker: stickerElegido,
      );
      comentarioController.clear();
      if (mounted) {
        setState(() {
          comentarios = [...comentarios, nuevo];
          stickerElegido = null;
        });
      }
    } catch (e) {
      mostrarMensaje('No se pudo comentar: ${_limpiar(e)}');
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  // ---------------- Valoración ----------------
  Future<void> calificar(int estrellas) async {
    setState(() => valorando = true);
    try {
      final actualizado = post.miValoracion == estrellas
          ? await postService.quitarValoracion(post.id) // tocar la misma = quitar
          : await postService.valorar(post.id, estrellas);
      if (mounted) setState(() => post = actualizado);
    } catch (e) {
      mostrarMensaje('No se pudo calificar: ${_limpiar(e)}');
    } finally {
      if (mounted) setState(() => valorando = false);
    }
  }

  Widget _seccionValoracion() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Mimi.rosaClaro),
      ),
      child: Column(
        children: [
          EstrellasPromedio(
            promedio: post.promedioEstrellas,
            total: post.numValoraciones,
            tamano: 20,
          ),
          const SizedBox(height: 8),
          Text(
            post.miValoracion == null
                ? '¿Qué te pareció? Califícalo'
                : 'Tu calificación: ${post.miValoracion} '
                    '(toca la misma estrella para quitarla)',
            style: const TextStyle(color: Mimi.gris, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          SelectorEstrellas(
            valor: post.miValoracion,
            habilitado: !valorando,
            alCalificar: calificar,
          ),
        ],
      ),
    );
  }

  // ---------------- Reacciones ----------------
  Future<void> reaccionar(ComentarioModel c, String tipo) async {
    final clave = '${c.id}:$tipo';
    if (reaccionando.contains(clave)) return;
    setState(() => reaccionando.add(clave));
    try {
      final actualizado = await comentarioService.reaccionar(c.id, tipo);
      if (mounted) {
        setState(() => comentarios = [
              for (final x in comentarios) x.id == c.id ? actualizado : x,
            ]);
      }
    } catch (e) {
      mostrarMensaje('No se pudo reaccionar: ${_limpiar(e)}');
    } finally {
      if (mounted) setState(() => reaccionando.remove(clave));
    }
  }

  void elegirReaccion(ComentarioModel c) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in reacciones)
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    reaccionar(c, r.codigo);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(r.emoji, style: const TextStyle(fontSize: 34)),
                        Text(r.nombre, style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barraReacciones(ComentarioModel c) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final r in c.reacciones)
          if (reaccionPorCodigo(r.tipo) != null)
            GestureDetector(
              onTap: () => reaccionar(c, r.tipo),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: r.mia ? Mimi.rosaClaro : const Color(0xFFF5F0EE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: r.mia ? Mimi.rosa : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      key: ValueKey('${c.id}-${r.tipo}-${r.total}'),
                      tween: Tween(begin: 1.6, end: 1),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      builder: (context, escala, child) =>
                          Transform.scale(scale: escala, child: child),
                      child: Text(
                        reaccionPorCodigo(r.tipo)!.emoji,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${r.total}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: r.mia ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => elegirReaccion(c),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: Icon(Icons.add_reaction_outlined, size: 20, color: Mimi.gris),
          ),
        ),
      ],
    );
  }

  // ---------------- Stickers y emojis ----------------
  void abrirPanelExpresiones() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => DefaultTabController(
        length: 2,
        child: SizedBox(
          height: 360,
          child: Column(
            children: [
              const TabBar(
                labelColor: Mimi.rosa,
                indicatorColor: Mimi.rosa,
                tabs: [
                  Tab(icon: Icon(Icons.emoji_emotions_outlined), text: 'Emojis'),
                  Tab(icon: Icon(Icons.sticky_note_2_outlined), text: 'Stickers'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    GridView.count(
                      crossAxisCount: 6,
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (final e in emojisRapidos)
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => insertarEmoji(e),
                            child: Center(
                              child: Text(e, style: const TextStyle(fontSize: 28)),
                            ),
                          ),
                      ],
                    ),
                    GridView.count(
                      crossAxisCount: 3,
                      padding: const EdgeInsets.all(12),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        for (final st in stickers)
                          InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              setState(() => stickerElegido = st.codigo);
                            },
                            child: Center(
                              child: FittedBox(
                                child: StickerView(sticker: st, tamano: 0.8),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void insertarEmoji(String emoji) {
    final texto = comentarioController.text;
    final sel = comentarioController.selection;
    final inicio = sel.isValid ? sel.start : texto.length;
    final fin = sel.isValid ? sel.end : texto.length;
    final nuevo = texto.replaceRange(inicio, fin, emoji);
    comentarioController.value = TextEditingValue(
      text: nuevo,
      selection: TextSelection.collapsed(offset: inicio + emoji.length),
    );
  }

  Future<bool> _confirmar(String titulo, String mensaje) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return resultado == true;
  }

  Future<void> eliminarPost() async {
    final ok = await _confirmar(
      'Eliminar publicación',
      '¿Seguro que quieres eliminar "${post.titulo}"? '
          'También se borrarán sus comentarios.',
    );
    if (!ok) return;

    try {
      await postService.eliminarPost(post.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      mostrarMensaje('No se pudo eliminar: ${_limpiar(e)}');
    }
  }

  Future<void> eliminarComentario(ComentarioModel comentario) async {
    final ok = await _confirmar(
      'Eliminar comentario',
      '¿Quieres eliminar este comentario?',
    );
    if (!ok) return;

    try {
      await comentarioService.eliminarComentario(comentario.id);
      if (mounted) {
        setState(() => comentarios =
            comentarios.where((c) => c.id != comentario.id).toList());
      }
    } catch (e) {
      mostrarMensaje('No se pudo eliminar: ${_limpiar(e)}');
    }
  }

  Widget _imagen() {
    final placeholder = Container(
      height: 230,
      width: double.infinity,
      color: Mimi.rosaClaro,
      child: const Icon(Icons.cake_outlined, size: 64, color: Mimi.rosa),
    );

    if (post.imagen.isEmpty) return placeholder;

    return Image.network(
      post.imagen,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      height: 230,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }

  Widget _listaComentarios() {
    if (cargando) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Column(
        children: [
          Text(error!, textAlign: TextAlign.center),
          TextButton(
            onPressed: cargarComentarios,
            child: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (comentarios.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Sé la primera persona en comentar'),
      );
    }

    return Column(
      children: comentarios.map(_tarjetaComentario).toList(),
    );
  }

  Widget _tarjetaComentario(ComentarioModel c) {
    final sticker = stickerPorCodigo(c.sticker);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: Mimi.rosaClaro,
              child: Icon(Icons.person, color: Mimi.rosa),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.nombreUsuario,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Mimi.cacao,
                    ),
                  ),
                  Text(
                    c.fechaFormateada,
                    style: const TextStyle(fontSize: 11, color: Mimi.gris),
                  ),
                  if (c.comentario.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(c.comentario, style: const TextStyle(fontSize: 15)),
                  ],
                  if (sticker != null) ...[
                    const SizedBox(height: 8),
                    StickerView(sticker: sticker),
                  ],
                  const SizedBox(height: 8),
                  _barraReacciones(c),
                ],
              ),
            ),
            if (puedeEliminarComentario(c))
              IconButton(
                tooltip: 'Eliminar comentario',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => eliminarComentario(c),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del pastel'),
        actions: [
          if (puedeEliminarPost)
            IconButton(
              tooltip: 'Eliminar publicación',
              icon: const Icon(Icons.delete_outline),
              onPressed: eliminarPost,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _imagen(),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (post.tags.isNotEmpty)
                          Text(
                            post.tags,
                            style: const TextStyle(
                              color: Mimi.rosa,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 10),
                        Text(
                          post.titulo,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Mimi.frambuesa,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.person_outline,
                                size: 18, color: Mimi.rosa),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                post.autor,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('• ${post.fechaFormateada}'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          post.descripcion,
                          style: const TextStyle(fontSize: 17, height: 1.6),
                        ),
                        const SizedBox(height: 20),
                        _seccionValoracion(),
                        const Divider(height: 40),
                        Text(
                          'Comentarios (${comentarios.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Mimi.cacao,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _listaComentarios(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // CAJA PARA ESCRIBIR UN COMENTARIO
          Material(
            elevation: 8,
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (stickerElegido != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            StickerView(
                              sticker: stickerPorCodigo(stickerElegido)!,
                              tamano: 0.6,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Sticker listo para enviar',
                                style: TextStyle(color: Mimi.gris),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Quitar sticker',
                              icon: const Icon(Icons.close),
                              onPressed: () =>
                                  setState(() => stickerElegido = null),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Emojis y stickers',
                          onPressed: abrirPanelExpresiones,
                          icon: const Icon(
                            Icons.emoji_emotions_outlined,
                            color: Mimi.rosa,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: comentarioController,
                            maxLength: 1000,
                            minLines: 1,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            buildCounter: (context,
                                    {required currentLength,
                                    required isFocused,
                                    maxLength}) =>
                                null,
                            decoration: const InputDecoration(
                              hintText: 'Escribe un comentario...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: 'Enviar comentario',
                          onPressed: enviando ? null : enviarComentario,
                          icon: enviando
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
