import 'package:flutter/material.dart';

import '../theme.dart';

/// Imagen desde URL con un ícono de respaldo si no hay o no carga.
class ImagenRed extends StatelessWidget {
  final String url;
  final double? alto;
  final double? ancho;
  final IconData icono;

  const ImagenRed({
    super.key,
    required this.url,
    this.alto,
    this.ancho,
    this.icono = Icons.cake_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final respaldo = Container(
      height: alto,
      width: ancho ?? double.infinity,
      color: Mimi.rosaClaro,
      child: Icon(icono, size: 40, color: Mimi.rosa),
    );
    if (url.isEmpty) return respaldo;
    return Image.network(
      url,
      height: alto,
      width: ancho ?? double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => respaldo,
    );
  }
}

/// Vista de error con botón de reintentar (o de volver a iniciar sesión).
class VistaError extends StatelessWidget {
  final Object error;
  final VoidCallback alReintentar;

  const VistaError({super.key, required this.error, required this.alReintentar});

  @override
  Widget build(BuildContext context) {
    final expirada = error.toString().contains('sesión expiró');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(expirada ? Icons.lock_clock : Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(
              error.toString().replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: expirada
                  ? () => Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (route) => false)
                  : alReintentar,
              child: Text(expirada ? 'Iniciar sesión' : 'Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

String limpiarError(Object e) => e.toString().replaceFirst('Exception: ', '');
