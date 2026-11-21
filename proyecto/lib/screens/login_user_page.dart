import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/session.dart';
import '../theme.dart';
import 'register_user_page.dart';
import 'recover_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usuarioController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final AuthService authService = AuthService();

  bool ocultarPassword = true;

  bool cargando = false;

  @override
  void initState() {
    super.initState();
    // Llegar al login (inicio o cerrar sesión) siempre borra la sesión anterior.
    Sesion.cerrar();
  }

  @override
  void dispose() {
    usuarioController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> iniciarSesion() async {
    final mensaje = authService.validarLogin(
      usuario: usuarioController.text,
      password: passwordController.text,
    );

    if (mensaje != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final usuario = await authService.autenticar(
        correo: usuarioController.text,
        password: passwordController.text,
      );

      if (!mounted) return;

      // Administradores y clientes entran al blog; el administrador además
      // ve en el menú la gestión de usuarios.
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/blog',
        (route) => false,
        arguments: Map<String, dynamic>.from(usuario),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF1F5),
              Color(0xFFFFD9E6),
              Color(0xFFFFE8D6),
              Color(0xFFFFF4E8),
            ],
          ),
        ),
        child: Center(
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cake, size: 65, color: Mimi.rosa),
                    const SizedBox(height: 8),
                    const Text(
                      'Pastelería Mimi',
                      style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: Mimi.gris,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'INICIAR SESIÓN',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6D2E46),
                      ),
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: usuarioController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: passwordController,
                      obscureText: ocultarPassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            ocultarPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              ocultarPassword = !ocultarPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RecoverPasswordPage(),
                            ),
                          );
                        },
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),
                    const SizedBox(height: 5),
                    ElevatedButton(
                      onPressed: cargando ? null : iniciarSesion,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: const Color(0xFFE0568A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        cargando ? 'VALIDANDO...' : 'INGRESAR',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('¿No tienes cuenta?'),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          child: const Text('Registrarse'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}