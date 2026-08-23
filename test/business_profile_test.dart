import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/files/file_model.dart';
import 'package:app/services/business/business_profile_model.dart';

/// El perfil tal como lo devuelve `GET /business/` con todo cargado.
Map<String, dynamic> _full() => {
  "id": "b-1",
  "nickname": "acme",
  "name": "Acme",
  "legal_name": "Acme, C.A.",
  "caption": "Todo para el hogar",
  "logo": {
    "id": "f-1",
    "scope": "media",
    "mime": "image/webp",
    "width": 512,
    "height": 512,
    "variants": [512, 128]
  },
  "activity_type": "RETAIL",
  "verification": "verified",
  "verified": true,
  "verified_date": "2026-02-10T00:00:00.000Z",
  "tax_id": "J-123456789",
  "country": "ve",
  "address": "Av. Principal 1",
  "language": "es",
  "currency": "VES",
  "currencies": ["usd", "EUR"],
  "phone": "+58 412 0000000",
  "email": "hola@acme.test",
  "website": "https://acme.test",
  "incorporation_date": "2019-05-03T00:00:00.000Z",
  "owner": true,
  "date": "2026-01-01T00:00:00.000Z"
};

/// Lo que devuelve una empresa recien creada: el backend contesta todos los
/// campos, pero los opcionales todavia estan en null.
Map<String, dynamic> _empty() => {
  "id": "b-2",
  "nickname": null,
  "name": "Nueva",
  "legal_name": null,
  "caption": null,
  "logo": null,
  "activity_type": "OTHER",
  "verification": "untrusted",
  "verified": false,
  "verified_date": null,
  "tax_id": null,
  "country": null,
  "address": null,
  "language": "es",
  "currency": "USD",
  "currencies": [],
  "phone": null,
  "email": null,
  "website": null,
  "incorporation_date": null,
  "owner": false,
  "date": "2026-08-01T00:00:00.000Z"
};

void main() {
  group('lectura del perfil', () {
    test('lee la empresa entera', () {
      final profile = BusinessProfileModel.fromJson(_full());

      expect(profile.id, "b-1");
      expect(profile.name, "Acme");
      expect(profile.legalName, "Acme, C.A.");
      expect(profile.nickname, "acme");
      expect(profile.caption, "Todo para el hogar");
      expect(profile.activity, BusinessActivity.retail);
      expect(profile.verification, BusinessVerification.verified);
      expect(profile.taxId, "J-123456789");
      expect(profile.address, "Av. Principal 1");
      expect(profile.language, "es");
      expect(profile.currency, "VES");
      expect(profile.phone, "+58 412 0000000");
      expect(profile.email, "hola@acme.test");
      expect(profile.website, "https://acme.test");
      expect(profile.owner, isTrue);
    });

    test('lo opcional que no vino queda vacio, no nulo', () {
      final profile = BusinessProfileModel.fromJson(_empty());

      // El perfil pregunta una sola cosa por cada dato —si hay algo que
      // mostrar— y con una sola forma de decir "no hay" no se puede olvidar la
      // otra al pintarlo.
      expect(profile.legalName, isEmpty);
      expect(profile.nickname, isEmpty);
      expect(profile.caption, isEmpty);
      expect(profile.taxId, isEmpty);
      expect(profile.country, isEmpty);
      expect(profile.address, isEmpty);
      expect(profile.phone, isEmpty);
      expect(profile.email, isEmpty);
      expect(profile.website, isEmpty);
      expect(profile.currencies, isEmpty);
      expect(profile.logo, isNull);
      expect(profile.verifiedDate, isNull);
      expect(profile.incorporationDate, isNull);
    });

    test('las fechas llegan como texto ISO y se leen como fechas', () {
      final profile = BusinessProfileModel.fromJson(_full());

      expect(profile.verifiedDate?.year, 2026);
      expect(profile.incorporationDate?.year, 2019);
      expect(profile.date?.year, 2026);
    });

    test('una fecha ilegible vale lo mismo que una que no vino', () {
      final profile = BusinessProfileModel.fromJson({
        ..._full(),
        "incorporation_date": "ayer"
      });

      expect(profile.incorporationDate, isNull);
    });

    test('el pais y las monedas se leen siempre en mayusculas', () {
      final profile = BusinessProfileModel.fromJson(_full());

      expect(profile.country, "VE");
      expect(profile.currencies, ["USD", "EUR"]);
    });

    test('las monedas se guardan como llegaron, no traducidas', () {
      // Ni la principal ni las secundarias caen en otra moneda cuando el
      // catalogo de plataforma no las tiene: eso seria decir que la empresa
      // cobra en una moneda en la que no cobra. Con que escribir un importe lo
      // contesta [CurrencyCatalogService], no este modelo.
      final profile = BusinessProfileModel.fromJson({
        ..._full(),
        "currency": "XYZ",
        "currencies": ["XYZ"]
      });

      expect(profile.currency, "XYZ");
      expect(profile.currencies, ["XYZ"]);
    });

    test('una respuesta a medias no se lleva puesto el perfil', () {
      final profile = BusinessProfileModel.fromJson({"id": "b-3"});

      expect(profile.id, "b-3");
      expect(profile.name, isEmpty);
      expect(profile.activity, BusinessActivity.unknown);
      expect(profile.verification, BusinessVerification.untrusted);
      expect(profile.currency, isEmpty);
      expect(profile.owner, isFalse);
    });
  });

  group('situacion legal', () {
    test('lee las situaciones que otorga la verificacion', () {
      expect(BusinessVerification.from("verified"), BusinessVerification.verified);
      expect(BusinessVerification.from("PENDING"), BusinessVerification.pending);
      expect(BusinessVerification.from("rejected"), BusinessVerification.rejected);
      expect(BusinessVerification.from("trusted"), BusinessVerification.trusted);
    });

    test('lo que no se reconoce no otorga confianza', () {
      // Ante la duda, la situacion mas conservadora: es donde arranca toda
      // empresa y es la que la hace operar con limites.
      expect(BusinessVerification.from(null), BusinessVerification.untrusted);
      expect(BusinessVerification.from(""), BusinessVerification.untrusted);
      expect(BusinessVerification.from("lo_que_sea"), BusinessVerification.untrusted);
    });
  });

  group('sector', () {
    test('el codigo que viaja al backend es el que llego', () {
      for (final activity in BusinessActivity.catalog) {
        expect(BusinessActivity.from(activity.value), activity);
      }
    });

    test('el catalogo no ofrece elegir lo desconocido', () {
      expect(BusinessActivity.catalog, isNot(contains(BusinessActivity.unknown)));
      expect(BusinessActivity.catalog.length, BusinessActivity.values.length - 1);
    });
  });

  group('logo', () {
    test('el logo es un archivo, no una direccion', () {
      final logo = FileModel.from(_full()["logo"]);

      expect(logo?.id, "f-1");
      expect(logo?.scope, FileScope.media);
      expect(logo?.mime, "image/webp");

      // Los anchos se ordenan al leerlos: se los recorre para elegir.
      expect(logo?.variants, [128, 512]);
    });

    test('sin id no hay logo: no habria de donde bajarlo', () {
      expect(FileModel.from({"id": ""}), isNull);
      expect(FileModel.from(null), isNull);
      expect(FileModel.from("f-1"), isNull);
    });
  });
}
