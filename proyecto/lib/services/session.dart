/// Sesión del usuario en memoria: token JWT + datos del usuario.
///
/// El token se envía en la cabecera `Authorization: Bearer ...` en cada
/// petición. Se borra al cerrar sesión (la pantalla de login lo limpia).
class Sesion {
  static String? token;
  static Map<String, dynamic>? usuario;

  static bool get activa => token != null && usuario != null;

  static int get usuarioId => (usuario?['id_usr'] as num?)?.toInt() ?? 0;

  static String get nombre => usuario?['nom_usr']?.toString() ?? 'Usuario';

  static bool get esAdmin => (usuario?['tip_usu'] as num?)?.toInt() == 1;

  static void iniciar(String nuevoToken, Map<String, dynamic> datosUsuario) {
    token = nuevoToken;
    usuario = Map<String, dynamic>.from(datosUsuario);
  }

  static void cerrar() {
    token = null;
    usuario = null;
  }

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
}
