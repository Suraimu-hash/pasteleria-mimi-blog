import 'package:flutter/foundation.dart';

/// URL base de la API (FastAPI).
///
/// - Emulador Android: http://10.0.2.2:8000 (se elige solo)
/// - Web, Windows, macOS, Linux, simulador iOS: http://127.0.0.1:8000
/// - Celular físico: indica la IP de tu PC al ejecutar:
///     flutter run --dart-define=API_URL=http://192.168.1.50:8000
String get apiBaseUrl {
  const desdeEntorno = String.fromEnvironment('API_URL');
  if (desdeEntorno.isNotEmpty) return desdeEntorno;

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://127.0.0.1:8000';
}
