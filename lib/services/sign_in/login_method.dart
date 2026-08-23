/// Manera en que una cuenta inicia sesion.
///
/// No la elige la app: la resuelve el backend en `sign_in/email` a partir del
/// correo y la devuelve como numero. Por eso el primer paso del login pide solo
/// el correo — hasta que el backend no contesta, la pantalla no sabe si tiene
/// que pedir una contraseña, un codigo o mandar a un OAuth.
///
/// Los numeros son los de la columna `authentication.login_method` y tienen que
/// coincidir con el enum del backend.
enum LoginMethod {
  /// Codigo de verificacion por correo. `sign_in/email` ya lo envia al
  /// responder, asi que la pantalla del codigo no tiene que pedirlo: solo
  /// completarlo en `sign_in/code`.
  code(1),

  /// Contraseña, que se completa en `sign_in/password`.
  password(2),

  google(3),
  apple(4),
  facebook(5);

  const LoginMethod(this.value);

  /// Numero con el que llega desde el backend.
  final int value;

  /// Si la app puede completar el metodo hoy. Los tres OAuth estan declarados
  /// porque el backend ya los devuelve, pero todavia no hay nada detras: al
  /// recibirlos el login se queda donde esta en vez de llevar a una pantalla
  /// que no existe.
  bool get isAvailable => this == code || this == password;

  /// Lee el metodo tal como viene en el cuerpo de la respuesta. Devuelve `null`
  /// para cualquier numero que esta version no conozca, para que un metodo
  /// nuevo del backend no se confunda con uno viejo.
  static LoginMethod? from(dynamic raw) => switch (
    raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? "")
  ) {
    1 => code,
    2 => password,
    3 => google,
    4 => apple,
    5 => facebook,
    _ => null
  };
}
