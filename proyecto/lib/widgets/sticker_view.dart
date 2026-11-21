import 'package:flutter/material.dart';

import '../utils/interacciones.dart';

/// Dibuja un sticker (emoji grande + frase) con una pequeña animación de entrada.
class StickerView extends StatelessWidget {
  final Sticker sticker;
  final double tamano;

  const StickerView({super.key, required this.sticker, this.tamano = 1});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.elasticOut,
      builder: (context, escala, child) =>
          Transform.scale(scale: escala, child: child),
      child: Transform.rotate(
        angle: -0.05,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * tamano,
            vertical: 8 * tamano,
          ),
          decoration: BoxDecoration(
            color: Color(sticker.color),
            borderRadius: BorderRadius.circular(18 * tamano),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(sticker.emoji, style: TextStyle(fontSize: 40 * tamano)),
              Text(
                sticker.texto,
                style: TextStyle(
                  fontSize: 13 * tamano,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6D2E46),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
