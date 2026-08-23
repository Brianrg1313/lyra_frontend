import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/sign_in/login_method.dart';

void main() {
  group('lectura del metodo', () {
    test('lee el numero que devuelve el backend', () {
      expect(LoginMethod.from(1), LoginMethod.code);
      expect(LoginMethod.from(2), LoginMethod.password);
      expect(LoginMethod.from(3), LoginMethod.google);
      expect(LoginMethod.from(4), LoginMethod.apple);
      expect(LoginMethod.from(5), LoginMethod.facebook);
    });

    test('lo lee igual si viene como texto o como decimal', () {
      // El cuerpo de la respuesta es el numero pelado y el decodificador de
      // JSON no siempre lo entrega como int.
      expect(LoginMethod.from("2"), LoginMethod.password);
      expect(LoginMethod.from(2.0), LoginMethod.password);
    });

    test('un metodo desconocido no se confunde con uno conocido', () {
      expect(LoginMethod.from(null), isNull);
      expect(LoginMethod.from(0), isNull);
      expect(LoginMethod.from(9), isNull);
      expect(LoginMethod.from("password"), isNull);
    });

    test('el numero que se lee es el mismo que declara cada metodo', () {
      for (final method in LoginMethod.values) {
        expect(LoginMethod.from(method.value), method);
      }
    });
  });

  test('solo el codigo y la contraseña se pueden completar hoy', () {
    // Los OAuth estan declarados porque el backend ya los devuelve, pero no hay
    // nada detras: el login no debe llevar a ninguna pantalla con ellos.
    expect(LoginMethod.code.isAvailable, isTrue);
    expect(LoginMethod.password.isAvailable, isTrue);
    expect(LoginMethod.google.isAvailable, isFalse);
    expect(LoginMethod.apple.isAvailable, isFalse);
    expect(LoginMethod.facebook.isAvailable, isFalse);
  });
}
