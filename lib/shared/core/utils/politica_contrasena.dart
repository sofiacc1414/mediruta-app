/// Espejo de `politica-contrasena.ts` de la API — solo para dar feedback
/// inmediato en el formulario. La autoridad final sigue siendo la API.
class PoliticaContrasena {
  PoliticaContrasena._();

  static const minLength = 8;
  static const maxLength = 72;

  static final _patron = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).+$');

  static const mensaje =
      'La contraseña debe incluir al menos una mayúscula, una minúscula, un número y un carácter especial.';

  /// Devuelve el mensaje de error correspondiente, o `null` si es válida.
  static String? validar(String password) {
    if (password.length < minLength || password.length > maxLength) {
      return 'Debe tener entre $minLength y $maxLength caracteres.';
    }
    if (!_patron.hasMatch(password)) {
      return mensaje;
    }
    return null;
  }
}
