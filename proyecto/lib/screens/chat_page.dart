import 'dart:async';

import 'package:flutter/material.dart';

import '../models/mensaje_model.dart';
import '../services/mensaje_service.dart';
import '../services/session.dart';
import '../theme.dart';
import '../utils/interacciones.dart';
import '../widgets/imagen_red.dart';

/// Conversación privada con otro usuario. Revisa mensajes nuevos cada 3 s.
class ChatPage extends StatefulWidget {
  final int usuarioId;
  final String nombre;

  const ChatPage({super.key, required this.usuarioId, required this.nombre});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final MensajeService servicio = MensajeService();
  final TextEditingController textoCtrl = TextEditingController();
  final ScrollController scroll = ScrollController();

  List<MensajeModel> mensajes = [];
  bool cargando = true;
  bool enviando = false;
  bool mostrarEmojis = false;
  Object? error;
  Timer? temporizador;
  bool consultando = false;

  int get ultimoId => mensajes.isEmpty ? 0 : mensajes.last.id;

  @override
  void initState() {
    super.initState();
    cargarTodo();
    temporizador = Timer.periodic(const Duration(seconds: 3), (_) => buscarNuevos());
  }

  @override
  void dispose() {
    temporizador?.cancel();
    textoCtrl.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> cargarTodo() async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      final lista = await servicio.obtenerMensajes(widget.usuarioId);
      if (!mounted) return;
      setState(() => mensajes = lista);
      _bajar();
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> buscarNuevos() async {
    if (consultando || cargando) return;
    consultando = true;
    try {
      final nuevos = await servicio.obtenerMensajes(widget.usuarioId, despuesDe: ultimoId);
      if (!mounted || nuevos.isEmpty) return;
      final ids = mensajes.map((m) => m.id).toSet();
      setState(() => mensajes = [...mensajes, ...nuevos.where((m) => !ids.contains(m.id))]);
      _bajar();
    } catch (_) {
      // Sin conexión momentánea: se reintenta en el siguiente ciclo.
    } finally {
      consultando = false;
    }
  }

  Future<void> enviar() async {
    final texto = textoCtrl.text.trim();
    if (texto.isEmpty) return;
    setState(() => enviando = true);
    try {
      final m = await servicio.enviarMensaje(widget.usuarioId, texto);
      textoCtrl.clear();
      if (!mounted) return;
      if (!mensajes.any((x) => x.id == m.id)) {
        setState(() => mensajes = [...mensajes, m]);
      }
      _bajar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No se envió: ${limpiarError(e)}')));
      }
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void insertarEmoji(String emoji) {
    final texto = textoCtrl.text;
    final sel = textoCtrl.selection;
    final inicio = sel.isValid ? sel.start : texto.length;
    final fin = sel.isValid ? sel.end : texto.length;
    textoCtrl.value = TextEditingValue(
      text: texto.replaceRange(inicio, fin, emoji),
      selection: TextSelection.collapsed(offset: inicio + emoji.length),
    );
  }

  Widget _burbuja(MensajeModel m) {
    final mio = m.remitenteId == Sesion.usuarioId;
    return Align(
      alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: mio ? Mimi.rosa : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mio ? 16 : 4),
              bottomRight: Radius.circular(mio ? 4 : 16),
            ),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 3)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                m.texto,
                style: TextStyle(fontSize: 15, color: mio ? Colors.white : Mimi.cacao),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    m.hora,
                    style: TextStyle(
                      fontSize: 10,
                      color: mio ? const Color(0xDDFFFFFF) : Mimi.gris,
                    ),
                  ),
                  if (mio) ...[
                    const SizedBox(width: 4),
                    Icon(
                      m.leido ? Icons.done_all : Icons.done,
                      size: 14,
                      color: const Color(0xDDFFFFFF),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget lista;
    if (cargando) {
      lista = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      lista = VistaError(error: error!, alReintentar: cargarTodo);
    } else if (mensajes.isEmpty) {
      lista = Center(
        child: Text(
          'Escríbele a ${widget.nombre} 👋',
          style: const TextStyle(color: Mimi.gris),
        ),
      );
    } else {
      lista = ListView.builder(
        controller: scroll,
        padding: const EdgeInsets.all(12),
        itemCount: mensajes.length,
        itemBuilder: (context, i) => _burbuja(mensajes[i]),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Mimi.frambuesa, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.nombre, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: lista),
          if (mostrarEmojis)
            Container(
              color: Colors.white,
              height: 110,
              child: GridView.count(
                crossAxisCount: 10,
                padding: const EdgeInsets.all(6),
                children: [
                  for (final e in emojisRapidos)
                    InkWell(
                      onTap: () => insertarEmoji(e),
                      child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
                    ),
                ],
              ),
            ),
          Material(
            elevation: 8,
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 12, 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Emojis',
                      onPressed: () => setState(() => mostrarEmojis = !mostrarEmojis),
                      icon: Icon(
                        mostrarEmojis ? Icons.keyboard : Icons.emoji_emotions_outlined,
                        color: Mimi.rosa,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: textoCtrl,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 2000,
                        textCapitalization: TextCapitalization.sentences,
                        buildCounter: (context,
                                {required currentLength, required isFocused, maxLength}) =>
                            null,
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Enviar',
                      onPressed: enviando ? null : enviar,
                      icon: const Icon(Icons.send),
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
