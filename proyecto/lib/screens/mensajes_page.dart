import 'dart:async';

import 'package:flutter/material.dart';

import '../models/mensaje_model.dart';
import '../services/mensaje_service.dart';
import '../theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/imagen_red.dart';
import 'chat_page.dart';

/// Bandeja de mensajes: conversaciones del usuario y botón para escribir a alguien.
class MensajesPage extends StatefulWidget {
  const MensajesPage({super.key});

  @override
  State<MensajesPage> createState() => _MensajesPageState();
}

class _MensajesPageState extends State<MensajesPage> {
  final MensajeService servicio = MensajeService();

  List<ConversacionModel> conversaciones = [];
  bool cargando = true;
  Object? error;
  Timer? temporizador;

  @override
  void initState() {
    super.initState();
    cargar();
    // Revisa mensajes nuevos cada 8 segundos mientras la pantalla está abierta.
    temporizador = Timer.periodic(const Duration(seconds: 8), (_) => cargar(silencioso: true));
  }

  @override
  void dispose() {
    temporizador?.cancel();
    super.dispose();
  }

  Future<void> cargar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        cargando = true;
        error = null;
      });
    }
    try {
      final lista = await servicio.obtenerConversaciones();
      if (mounted) setState(() => conversaciones = lista);
    } catch (e) {
      if (mounted && !silencioso) setState(() => error = e);
    } finally {
      if (mounted && !silencioso) setState(() => cargando = false);
    }
  }

  Future<void> abrirChat(int usuarioId, String nombre) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatPage(usuarioId: usuarioId, nombre: nombre)),
    );
    if (mounted) cargar(silencioso: true);
  }

  Future<void> nuevoMensaje() async {
    List<ContactoModel> contactos;
    try {
      contactos = await servicio.obtenerContactos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(limpiarError(e))));
      }
      return;
    }
    if (!mounted) return;

    final elegido = await showModalBottomSheet<ContactoModel>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _SelectorContacto(contactos: contactos),
    );
    if (elegido != null) abrirChat(elegido.id, elegido.nombre);
  }

  @override
  Widget build(BuildContext context) {
    Widget cuerpo;
    if (cargando && conversaciones.isEmpty) {
      cuerpo = const Center(child: CircularProgressIndicator());
    } else if (error != null && conversaciones.isEmpty) {
      cuerpo = ListView(children: [VistaError(error: error!, alReintentar: cargar)]);
    } else if (conversaciones.isEmpty) {
      cuerpo = ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.forum_outlined, size: 64, color: Mimi.rosa),
          SizedBox(height: 12),
          Center(child: Text('Aún no tienes conversaciones')),
          SizedBox(height: 4),
          Center(
            child: Text(
              'Toca "Nuevo mensaje" para escribirle a la pastelería\no a otro usuario.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Mimi.gris),
            ),
          ),
        ],
      );
    } else {
      cuerpo = ListView.separated(
        itemCount: conversaciones.length,
        separatorBuilder: (context, i) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, i) {
          final c = conversaciones[i];
          final sinLeer = c.noLeidos > 0;
          return ListTile(
            onTap: () => abrirChat(c.usuarioId, c.nombre),
            leading: CircleAvatar(
              backgroundColor: c.esAdmin ? Mimi.frambuesa : Mimi.rosaClaro,
              child: Icon(
                c.esAdmin ? Icons.storefront : Icons.person,
                color: c.esAdmin ? Colors.white : Mimi.rosa,
              ),
            ),
            title: Text(
              c.nombre,
              style: TextStyle(fontWeight: sinLeer ? FontWeight.bold : FontWeight.w500),
            ),
            subtitle: Text(
              c.ultimoMensaje,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: sinLeer ? FontWeight.w600 : FontWeight.normal,
                color: sinLeer ? Mimi.cacao : Mimi.gris,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(c.hora, style: const TextStyle(fontSize: 11, color: Mimi.gris)),
                const SizedBox(height: 4),
                if (sinLeer)
                  Badge(
                    label: Text('${c.noLeidos}'),
                    backgroundColor: Mimi.rosa,
                  ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mensajes')),
      drawer: Navigator.canPop(context) ? null : const AppDrawer(rutaActual: '/mensajes'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: nuevoMensaje,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Nuevo mensaje'),
      ),
      body: RefreshIndicator(onRefresh: cargar, child: cuerpo),
    );
  }
}

class _SelectorContacto extends StatefulWidget {
  final List<ContactoModel> contactos;

  const _SelectorContacto({required this.contactos});

  @override
  State<_SelectorContacto> createState() => _SelectorContactoState();
}

class _SelectorContactoState extends State<_SelectorContacto> {
  String filtro = '';

  @override
  Widget build(BuildContext context) {
    final visibles = widget.contactos
        .where((c) => c.nombre.toLowerCase().contains(filtro.toLowerCase()))
        .toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: false,
              onChanged: (v) => setState(() => filtro = v),
              decoration: const InputDecoration(
                hintText: 'Buscar usuario',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: visibles.isEmpty
                ? const Center(child: Text('Sin resultados'))
                : ListView.builder(
                    itemCount: visibles.length,
                    itemBuilder: (context, i) {
                      final c = visibles[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: c.esAdmin ? Mimi.frambuesa : Mimi.rosaClaro,
                          child: Icon(
                            c.esAdmin ? Icons.storefront : Icons.person,
                            color: c.esAdmin ? Colors.white : Mimi.rosa,
                          ),
                        ),
                        title: Text(c.nombre),
                        subtitle: c.esAdmin ? const Text('Pastelería (administrador)') : null,
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
