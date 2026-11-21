/// Catálogos de reacciones y stickers. La API guarda solo el código;
/// aquí se define cómo se ve cada uno.
class Reaccion {
  final String codigo;
  final String emoji;
  final String nombre;
  const Reaccion(this.codigo, this.emoji, this.nombre);
}

class Sticker {
  final String codigo;
  final String emoji;
  final String texto;
  final int color; // ARGB
  const Sticker(this.codigo, this.emoji, this.texto, this.color);
}

const List<Reaccion> reacciones = [
  Reaccion('me_encanta', '❤️', 'Me encanta'),
  Reaccion('me_gusta', '👍', 'Me gusta'),
  Reaccion('antojo', '🤤', 'Antojo'),
  Reaccion('risa', '😂', 'Me divierte'),
  Reaccion('wow', '😮', 'Wow'),
  Reaccion('triste', '😢', 'Me entristece'),
];

const List<Sticker> stickers = [
  Sticker('delicioso', '😋', '¡Delicioso!', 0xFFFFE0B2),
  Sticker('quiero_uno', '🤤', '¡Quiero uno!', 0xFFFFD9E6),
  Sticker('feliz_cumple', '🎂', '¡Feliz cumple!', 0xFFE1F5FE),
  Sticker('hermoso', '😍', '¡Qué hermoso!', 0xFFFCE4EC),
  Sticker('receta', '📝', '¿Receta, porfa?', 0xFFFFF9C4),
  Sticker('aplausos', '👏', '¡Bravo!', 0xFFE8F5E9),
  Sticker('chef', '👩‍🍳', '¡Nivel chef!', 0xFFEDE7F6),
  Sticker('corazones', '💕', '¡Lo amé!', 0xFFFFEBEE),
];

/// Emojis rápidos para insertar en el texto del comentario o del chat.
const List<String> emojisRapidos = [
  '😀', '😍', '🤤', '😋', '😂', '🥳', '👏', '🙌', '❤️', '💕',
  '🎂', '🍰', '🧁', '🍩', '🍪', '🍫', '🍓', '🍒', '✨', '🔥',
];

Reaccion? reaccionPorCodigo(String codigo) {
  for (final r in reacciones) {
    if (r.codigo == codigo) return r;
  }
  return null;
}

Sticker? stickerPorCodigo(String? codigo) {
  if (codigo == null) return null;
  for (final s in stickers) {
    if (s.codigo == codigo) return s;
  }
  return null;
}
