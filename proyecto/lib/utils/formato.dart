/// Convierte una fecha ISO (2026-11-20T09:05:00) a "20/11/2026 09:05".
String formatearFecha(String iso) {
  final fecha = DateTime.tryParse(iso);
  if (fecha == null) return iso;
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} '
      '${dos(fecha.hour)}:${dos(fecha.minute)}';
}


/// 1234.5 -> "$1,234.50"
String formatearPrecio(num valor) {
  final partes = valor.toStringAsFixed(2).split('.');
  final entero = partes[0];
  final buffer = StringBuffer();
  for (var i = 0; i < entero.length; i++) {
    if (i > 0 && (entero.length - i) % 3 == 0) buffer.write(',');
    buffer.write(entero[i]);
  }
  return '\$${buffer.toString()}.${partes[1]}';
}

/// Hora corta para el chat: "09:05" si es de hoy, si no "20/11 09:05".
String formatearHoraChat(String iso) {
  final fecha = DateTime.tryParse(iso);
  if (fecha == null) return iso;
  String dos(int n) => n.toString().padLeft(2, '0');
  final hoy = DateTime.now();
  final hora = '${dos(fecha.hour)}:${dos(fecha.minute)}';
  if (fecha.year == hoy.year && fecha.month == hoy.month && fecha.day == hoy.day) {
    return hora;
  }
  return '${dos(fecha.day)}/${dos(fecha.month)} $hora';
}
