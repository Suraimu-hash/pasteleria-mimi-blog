import 'package:flutter/material.dart';

/// Muestra un promedio de estrellas (admite medias estrellas).
class EstrellasPromedio extends StatelessWidget {
  final double promedio;
  final int total;
  final double tamano;

  const EstrellasPromedio({
    super.key,
    required this.promedio,
    required this.total,
    this.tamano = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            promedio >= i
                ? Icons.star_rounded
                : (promedio >= i - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded),
            size: tamano,
            color: Colors.amber.shade700,
          ),
        const SizedBox(width: 4),
        Text(
          total == 0 ? 'Sin calificar' : '${promedio.toStringAsFixed(1)} ($total)',
          style: TextStyle(fontSize: tamano * 0.8, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

/// Selector de 1 a 5 estrellas. Al tocar una estrella se llama [alCalificar].
class SelectorEstrellas extends StatelessWidget {
  final int? valor;
  final ValueChanged<int> alCalificar;
  final bool habilitado;

  const SelectorEstrellas({
    super.key,
    required this.valor,
    required this.alCalificar,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    final actual = valor ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            tooltip: '$i ${i == 1 ? 'estrella' : 'estrellas'}',
            visualDensity: VisualDensity.compact,
            onPressed: habilitado ? () => alCalificar(i) : null,
            icon: AnimatedScale(
              scale: i <= actual ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.elasticOut,
              child: Icon(
                i <= actual ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 34,
                color: Colors.amber.shade700,
              ),
            ),
          ),
      ],
    );
  }
}
