import 'package:flutter/material.dart';

import '../services/session.dart';
import '../theme.dart';

/// Menú lateral. Todos los usuarios ven el blog, publicar y su perfil;
/// las opciones de gestión de usuarios solo aparecen para administradores.
class AppDrawer extends StatelessWidget {
  final Map<String, dynamic>? usuario;
  final String rutaActual;

  const AppDrawer({
    super.key,
    this.usuario,
    required this.rutaActual,
  });

  Map<String, dynamic> get _datos => usuario ?? Sesion.usuario ?? {};
  String get nombre => _datos['nom_usr']?.toString() ?? 'Usuario';
  String get correo => _datos['mail']?.toString() ?? '';
  bool get esAdmin => (_datos['tip_usu'] as num?)?.toInt() == 1;

  void _navegar(BuildContext context, String ruta) {
    Navigator.pop(context);
    if (ruta == rutaActual) return;
    Navigator.pushReplacementNamed(context, ruta, arguments: _datos);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    decoration: const BoxDecoration(color: Mimi.frambuesa),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        esAdmin ? Icons.storefront : Icons.person,
                        color: Mimi.frambuesa,
                        size: 34,
                      ),
                    ),
                    accountName: Text(nombre),
                    accountEmail: Text(
                      esAdmin ? '$correo · Administrador' : correo,
                    ),
                  ),
                  _opcion(context, Icons.cake_outlined, 'Blog de pasteles', '/blog'),
                  _opcion(context, Icons.add_photo_alternate_outlined,
                      'Publicar pastel', '/add-blog'),
                  _opcion(context, Icons.chat_outlined, 'Mensajes', '/mensajes'),
                  const Divider(),
                  _seccion('Tienda'),
                  _opcion(context, Icons.storefront_outlined, 'Tienda', '/tienda'),
                  _opcion(context, Icons.shopping_cart_outlined, 'Mi carrito',
                      '/carrito'),
                  _opcion(context, Icons.receipt_long_outlined,
                      esAdmin ? 'Pedidos' : 'Mis pedidos', '/pedidos'),
                  const Divider(),
                  _opcion(context, Icons.account_circle_outlined, 'Mi perfil',
                      '/profile'),
                  if (esAdmin) ...[
                    const Divider(),
                    _seccion('Administración'),
                    _opcion(context, Icons.inventory_2_outlined,
                        'Gestionar productos', '/admin-productos'),
                    _opcion(context, Icons.people_alt_outlined,
                        'Gestión de usuarios', '/users'),
                    _opcion(context, Icons.person_add_alt_1, 'Registrar usuario',
                        '/register'),
                  ],
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                // La pantalla de login borra la sesión al abrirse.
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Text(
        titulo.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Mimi.gris,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _opcion(
    BuildContext context,
    IconData icono,
    String titulo,
    String ruta,
  ) {
    final seleccionado = ruta == rutaActual;
    return ListTile(
      leading: Icon(icono, color: seleccionado ? Mimi.rosa : null),
      title: Text(titulo),
      selected: seleccionado,
      selectedColor: Mimi.rosa,
      onTap: () => _navegar(context, ruta),
    );
  }
}
