import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService authService = AuthService();
  final UserService userService = UserService();

  Map<String, dynamic>? usuarioActual; // null si viene del login
  bool argumentoLeido = false;
  bool guardando = false;

  // 1 = Administrador, 2 = General
  int tipoUsuario = 2;

  bool get esAdmin => (usuarioActual?['tip_usu'] as num?)?.toInt() == 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!argumentoLeido) {
      final argumento = ModalRoute.of(context)?.settings.arguments;
      if (argumento is Map) {
        usuarioActual = Map<String, dynamic>.from(argumento);
      }
      argumentoLeido = true;
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void mostrarMensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> registrarUsuario() async {
    if (guardando) return;

    final nombre = nombreController.text.trim();
    final correo = correoController.text.trim();
    final password = passwordController.text;

    final mensaje = authService.validarRegistro(
      nombre: nombre,
      correo: correo,
      password: password,
      confirmarPassword: password,
    );

    if (mensaje != null) {
      mostrarMensaje(mensaje);
      return;
    }

    if (password.length < 8) {
      mostrarMensaje('La contraseña debe tener al menos 8 caracteres');
      return;
    }

    setState(() => guardando = true);

    try {
      await userService.agregarUsuario(
        UserModel(
          id: 0,
          nombre: nombre,
          correo: correo,
          password: password,
          direccion: null,
          // Solo un admin puede elegir el tipo; el registro público es general.
          tipoUsuario: esAdmin ? tipoUsuario : 2,
        ),
      );

      if (!mounted) return;

      mostrarMensaje('Usuario registrado correctamente');

      if (esAdmin) {
        Navigator.pushReplacementNamed(
          context,
          '/users',
          arguments: usuarioActual,
        );
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      mostrarMensaje(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: esAdmin ? AppBar(title: const Text('Registrar usuario')) : null,
      drawer: esAdmin
          ? AppDrawer(usuario: usuarioActual!, rutaActual: '/register')
          : null,
      body: AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            child: AuthCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_add,
                    size: 65,
                    color: Color(0xFFE0568A),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    esAdmin ? 'REGISTRAR USUARIO' : 'CREAR CUENTA',
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6D2E46),
                    ),
                  ),
                  const SizedBox(height: 25),
                  CustomTextField(
                    controller: nombreController,
                    label: 'Nombre completo',
                    prefixIcon: Icons.person,
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: correoController,
                    label: 'Correo electrónico',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: passwordController,
                    label: 'Contraseña',
                    prefixIcon: Icons.lock,
                    obscureText: true,
                  ),
                  if (esAdmin) ...[
                    const SizedBox(height: 15),
                    DropdownButtonFormField<int>(
                      initialValue: tipoUsuario,
                      decoration: InputDecoration(
                        labelText: 'Tipo de usuario',
                        prefixIcon:
                            const Icon(Icons.admin_panel_settings_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Administrador'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('Cliente'),
                        ),
                      ],
                      onChanged: (v) => setState(() => tipoUsuario = v ?? 2),
                    ),
                  ],
                  const SizedBox(height: 25),
                  PrimaryButton(
                    text: guardando ? 'GUARDANDO...' : 'REGISTRAR',
                    onPressed: registrarUsuario,
                  ),
                  if (!esAdmin) ...[
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Ya tengo una cuenta'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}