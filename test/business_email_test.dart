import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/business/business_email_model.dart';
import 'package:app/services/business/business_profile_model.dart';

void main() {
  test('un proposito que esta version no conoce cae en other', () {
    expect(BusinessEmailPurpose.from("support"), BusinessEmailPurpose.support);
    expect(BusinessEmailPurpose.from(" HR "), BusinessEmailPurpose.hr);
    expect(BusinessEmailPurpose.from("warranty"), BusinessEmailPurpose.other);
    expect(BusinessEmailPurpose.from(null), BusinessEmailPurpose.other);
  });

  test('el codigo del proposito viaja tal como se llama', () {
    expect(BusinessEmailPurpose.hr.value, "hr");
    expect(BusinessEmailPurpose.general.value, "general");
  });

  test('una fila sin direccion no se arma', () {
    final emails = BusinessEmailModel.fromList([
      {"id": "1", "email": "hola@acme.test", "purpose": "general", "main": true},
      {"id": "2", "email": "   ", "purpose": "sales"},
      "ventas@acme.test"
    ]);

    expect(emails.length, 1);
    expect(emails.first.email, "hola@acme.test");
    expect(emails.first.main, isTrue);
  });

  test('main llega como bandera o como numero', () {
    expect(
      BusinessEmailModel.fromJson({"id": "1", "email": "a@b.c", "main": 1}).main,
      isTrue
    );
    expect(
      BusinessEmailModel.fromJson({"id": "1", "email": "a@b.c", "main": 0}).main,
      isFalse
    );
  });

  test('sin nombre propio la direccion se nombra por su proposito', () {
    final named = BusinessEmailModel.fromJson({
      "id": "1",
      "email": "pagos@acme.test",
      "purpose": "billing",
      "label": "Facturacion Colombia"
    });

    expect(named.label, "Facturacion Colombia");
    expect(named.purpose, BusinessEmailPurpose.billing);

    final bare = BusinessEmailModel.fromJson({
      "id": "2",
      "email": "rrhh@acme.test",
      "purpose": "hr",
      "label": null
    });

    expect(bare.label, "");
  });

  test('el perfil trae la lista y ademas la principal suelta', () {
    final profile = BusinessProfileModel.fromJson({
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Acme",
      "email": "soporte@acme.test",
      "emails": [
        {
          "id": "1",
          "email": "soporte@acme.test",
          "purpose": "support",
          "main": true
        },
        {"id": "2", "email": "ventas@acme.test", "purpose": "sales"}
      ]
    });

    expect(profile.email, "soporte@acme.test");
    expect(profile.emails.length, 2);
    expect(profile.emails.first.purpose, BusinessEmailPurpose.support);
  });

  test('verified llega como bandera o como numero', () {
    expect(
      BusinessEmailModel.fromJson({
        "id": "1",
        "email": "a@b.c",
        "verified": 1,
        "verified_date": "2026-03-04T10:00:00.000Z"
      }).verified,
      isTrue
    );
    expect(
      BusinessEmailModel.fromJson({"id": "1", "email": "a@b.c"}).verified,
      isFalse
    );
  });

  test('una direccion sin verificar no trae fecha de verificacion', () {
    final pending = BusinessEmailModel.fromJson({
      "id": "1",
      "email": "a@b.c",
      "verified": false,
      "verified_date": null
    });

    expect(pending.verified, isFalse);
    expect(pending.verifiedDate, isNull);

    final done = BusinessEmailModel.fromJson({
      "id": "2",
      "email": "a@b.c",
      "verified": true,
      "verified_date": "2026-03-04T10:00:00.000Z"
    });

    expect(done.verifiedDate, DateTime.utc(2026, 3, 4, 10));
  });

  test('un perfil viejo sin correos no rompe', () {
    final profile = BusinessProfileModel.fromJson({"id": "1", "name": "Acme"});

    expect(profile.emails, isEmpty);
  });
}
