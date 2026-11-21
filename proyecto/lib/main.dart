import 'package:flutter/material.dart';

import 'screens/add_blog_page.dart';
import 'screens/admin_productos_page.dart';
import 'screens/blog_page.dart';
import 'screens/carrito_page.dart';
import 'screens/login_user_page.dart';
import 'screens/mensajes_page.dart';
import 'screens/pedidos_page.dart';
import 'screens/profile_page.dart';
import 'screens/register_user_page.dart';
import 'screens/tienda_page.dart';
import 'screens/user_page.dart';
import 'theme.dart';

void main() {
  runApp(const MimiApp());
}

class MimiApp extends StatelessWidget {
  const MimiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pastelería Mimi',
      theme: Mimi.tema(),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/blog': (context) => const BlogPage(),
        '/add-blog': (context) => const AddBlogPage(),
        '/profile': (context) => const ProfilePage(),
        '/users': (context) => const UsersPage(),
        // Módulos opcionales
        '/tienda': (context) => const TiendaPage(),
        '/carrito': (context) => const CarritoPage(),
        '/pedidos': (context) => const PedidosPage(),
        '/admin-productos': (context) => const AdminProductosPage(),
        '/mensajes': (context) => const MensajesPage(),
      },
    );
  }
}
