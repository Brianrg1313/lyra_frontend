import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:core/form.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/business/business_email_model.dart';
import 'package:app/services/business/business_profile_model.dart';
import 'package:app/services/catalog/country_catalog_service.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/screens/home/sections/business/settings/profile_details.dart';
import 'package:app/screens/home/sections/business/settings/profile_field.dart';
import 'package:app/screens/home/sections/business/settings/profile_emails.dart';
import 'package:app/screens/home/sections/business/settings/profile_header.dart';
import 'package:app/screens/home/sections/business/settings/profile_identity.dart';
import 'package:app/screens/home/sections/business/settings/profile_tag.dart';
import 'package:app/screens/home/sections/business/settings/profile_id.dart';
import 'package:app/screens/home/sections/business/settings/profile_incorporation.dart';
import 'package:app/screens/home/sections/business/settings/profile_logo.dart';
import 'package:app/screens/home/sections/business/settings/profile_phone.dart';
import 'package:app/screens/home/sections/business/settings/profile_website.dart';

/// Una empresa con todo cargado: es la unica forma de ver todas las filas de la
/// ficha a la vez, porque un dato que no esta no se dibuja.
const _id = "550e8400-e29b-41d4-a716-446655440000";

BusinessProfileModel _profile() => BusinessProfileModel(
  id: _id,
  name: "Acme",
  legalName: "Acme, C.A.",
  nickname: "acme",
  caption: "Todo para el hogar",
  activity: BusinessActivity.retail,
  verification: BusinessVerification.verified,
  taxId: "J-123456789",
  country: "VE",
  address: "Av. Principal 1",
  language: "es",
  currency: "VES",
  currencies: const ["USD"],
  phone: "+584120000000",
  email: "soporte@acme.test",
  emails: const [
    BusinessEmailModel(
      id: "11111111-1111-4111-8111-111111111111",
      email: "soporte@acme.test",
      purpose: BusinessEmailPurpose.support,
      main: true,
      verified: true
    ),
    BusinessEmailModel(
      id: "22222222-2222-4222-8222-222222222222",
      email: "ventas@acme.test",
      purpose: BusinessEmailPurpose.sales,
      label: "Ventas mayoristas"
    )
  ],
  website: "https://acme.test",
  incorporationDate: DateTime.utc(2019, 5, 3),
  owner: true,
  date: DateTime.utc(2026)
);

/// Los catalogos de plataforma que la ficha consume para ofrecer el pais y la
/// moneda. En la app los siembra `ClientService.resolve` desde `/init`; aca se
/// los siembra a mano porque son singletons y la ficha los lee del arbol.
void _seedCatalogs() {
  CountryCatalogService().seed({
    "keys": ["code", "name", "phone", "currency", "flag"],
    "values": [
      ["AR", "Argentina", "54", "ARS", "flag-ar"],
      ["VE", "Venezuela", "58", "VES", "flag-ve"]
    ]
  });

  CurrencyCatalogService().seed({
    "keys": ["code", "name", "symbol", "position", "space", "decimals", "type"],
    "values": [
      ["USD", "US Dollar", "\$", "left", false, 2, "fiat"],
      ["VES", "Bolivar", "Bs.", "right", true, 2, "fiat"]
    ]
  });
}

Widget _app(double width, {BusinessProfileModel? profile}) => MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: CountryCatalogService()),
    ChangeNotifierProvider.value(value: CurrencyCatalogService())
  ],
  child: MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Builder(builder: (context) {
      AppSize.instance(context);

      return Scaffold(body: Center(child: SizedBox(
        width: width,
        child: SingleChildScrollView(
          child: BusinessProfileDetails(profile: profile ?? _profile())
        )
      )));
    })
  )
);

/// Un valor escrito en la ficha, se pueda seleccionar o no: los que se copian
/// se dibujan con `SelectableText` y a esos `find.text` no los encuentra.
Finder _written(String value) => find.byWidgetPredicate(
  (widget) => widget is TextMedium && widget.text == value
);

/// Una etiqueta de estado con ese texto: la situacion legal de la empresa o si
/// una direccion de correo se comprobo.
Finder _tag(String label) => find.byWidgetPredicate(
  (widget) => widget is ProfileTag && widget.label == label
);

/// Lo que hay escrito en el campo de texto que vive dentro de [row].
String _typed(WidgetTester tester, Finder row) => tester.widget<TextField>(
  find.descendant(of: row, matching: find.byType(TextField)).last
).controller!.text;

/// El nombre en grande, que es con lo que abre la columna de datos.
Finder get _title => find.byWidgetPredicate(
  (widget) => widget is TextLarge && widget.text == "Acme"
);

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  setUp(() {
    // La plataforma dice en que paises y monedas se puede operar, y la ficha
    // ofrece eso. Son singletons: se siembran antes de cada prueba y se vacian
    // despues para que ninguna dependa de lo que dejo la anterior.
    _seedCatalogs();

    addTearDown(CountryCatalogService().clear);
    addTearDown(CurrencyCatalogService().clear);

    // La ficha se mide contra el ancho que le dan, asi que la ventana tiene que
    // ser mas grande que la mas ancha de las dos disposiciones.
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;

    view.physicalSize = const Size(1400, 1600);
    view.devicePixelRatio = 1;

    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
  });

  testWidgets('el nombre y el estado abren los datos', (tester) async {
    await tester.pumpWidget(_app(1000));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // De quien es la ficha se lee una sola vez y arriba de todo: el nombre en
    // grande, con la situacion legal y el rol de quien mira.
    expect(_title, findsOneWidget);
    expect(find.byType(BusinessProfileHeader), findsOneWidget);
    expect(find.text("Owner"), findsOneWidget);

    // Acotado a la cabecera: "Verified" tambien es como se lee una direccion
    // de correo comprobada, y son dos cosas distintas —una es la situacion
    // legal de la empresa, la otra es que una casilla funciona—.
    expect(
      find.descendant(
        of: find.byType(BusinessProfileHeader),
        matching: find.text("Verified")
      ),
      findsOneWidget
    );

    // Antes del primer dato: es el titulo de lo que sigue, no una fila mas.
    expect(
      tester.getTopLeft(_title).dy,
      lessThan(tester.getTopLeft(find.text("Legal name")).dy)
    );
  });

  testWidgets('the photo belongs to the header, not to the data', (tester) async {
    await tester.pumpWidget(_app(1000));
    await tester.pumpAndSettle();

    // It is drawn once and inside the header, which is what says whose
    // everything below is. It is not one more row of the sheet: the data
    // blocks must not carry it.
    expect(find.byType(BusinessProfileLogo), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BusinessProfileHeader),
        matching: find.byType(BusinessProfileLogo)
      ),
      findsOneWidget
    );
    expect(
      find.descendant(
        of: find.byType(BusinessProfileIdentity),
        matching: find.byType(BusinessProfileLogo)
      ),
      findsNothing
    );
  });

  testWidgets('las personas con acceso no son un dato del perfil', (tester) async {
    await tester.pumpWidget(_app(1000));
    await tester.pumpAndSettle();

    expect(find.text("People with access"), findsNothing);
  });

  testWidgets('cada dato que se puede cambiar trae con que hacerlo', (tester) async {
    await tester.pumpWidget(_app(1000));
    await tester.pumpAndSettle();

    // Los datos que se escriben de la ficha llena: nombre, lema, razon social,
    // handle, identificador fiscal y sitio, mas uno por cada correo.
    //
    // El sector y el idioma no estan: se eligen de una lista y se
    // cambian en su propia fila, sin modal y sin lapiz (ver
    // `ProfileSelectField`). El telefono y la fecha de constitucion tampoco: se
    // cargan en la fila, repartidos en los campos que los componen. La
    // direccion y el pais tampoco: se editan enteros en Ubicacion. La moneda
    // ya no es de esta ficha: vive en Finanzas.
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ProfileAction && widget.icon == CI.edit
      ),
      findsNWidgets(8)
    );
  });

  testWidgets('un dato que se elige se lee con su etiqueta', (tester) async {
    await tester.pumpWidget(_app(1000));
    await tester.pumpAndSettle();

    // Lo guardado es el codigo que viaja al backend (`RETAIL`); lo que se lee
    // es su etiqueta, la misma con la que se elige el sector al crear la
    // empresa.
    expect(find.text("Retail"), findsOneWidget);
    expect(find.text("RETAIL"), findsNothing);
  });

  testWidgets('the country is on this sheet, the address is not', (tester) async {
    await tester.pumpWidget(_app(1000));
    await tester.pumpAndSettle();

    // The country is the company's and every branch shares it, so it is read
    // and changed here. The address belongs to each branch and is edited in
    // the branches tab.
    expect(find.text("Country"), findsOneWidget);
    expect(find.text("Address"), findsNothing);
    expect(_written("Av. Principal 1"), findsNothing);
  });

  testWidgets('the currencies are not part of this sheet', (tester) async {
    // The main currency and the exchange currencies are read and set up in the
    // finance section (payment methods tab). Not even without a catalog does
    // the main one come back as a text field: changing it relabels every
    // stored price instead of converting it, and the backend refuses it here.
    CountryCatalogService().clear();
    CurrencyCatalogService().clear();

    await tester.pumpWidget(_app(1000));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_written("VES"), findsNothing);
    expect(_written("USD"), findsNothing);

    expect(
      find.byWidgetPredicate(
        (widget) => widget is ProfileAction && widget.icon == CI.edit
      ),
      findsNWidgets(8)
    );
  });

  testWidgets('el telefono se carga entre dos campos', (tester) async {
    await tester.pumpWidget(_app(1000));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // El codigo se elige de la lista de paises habilitados —por eso lleva la
    // bandera— y el numero se escribe: son dos datos con dos formas distintas
    // de cargarse, no un campo de texto donde caben las dos.
    final row = find.byType(BusinessProfilePhone);

    expect(row, findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.byType(SelectInput)),
      findsOneWidget
    );
    expect(
      find.descendant(of: row, matching: find.byType(Input)),
      findsOneWidget
    );

    // Lo guardado llega partido: el codigo en el desplegable, el numero en el
    // campo.
    expect(
      find.descendant(of: row, matching: find.text("+58")),
      findsOneWidget
    );
    expect(_typed(tester, row), "4120000000");
  });

  testWidgets('el telefono solo ofrece guardarse si cambio', (tester) async {
    await tester.pumpWidget(_app(1000));
    await tester.pumpAndSettle();

    Finder save() => find.byWidgetPredicate(
      (widget) => widget is ProfileTextAction && widget.label == "Save"
    );

    // Recien abierta la ficha no hay nada que guardar: un boton puesto ahi
    // desde el principio se leeria como que el dato esta a medio cargar.
    expect(save(), findsNothing);

    final number = find.descendant(
      of: find.byType(BusinessProfilePhone),
      matching: find.byType(Input)
    );

    await tester.ensureVisible(number);
    await tester.enterText(number, "4121111111");
    await tester.pumpAndSettle();

    expect(save(), findsOneWidget);
  });

  testWidgets('la fecha de constitucion se carga por partes', (tester) async {
    await tester.pumpWidget(_app(1000));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final row = find.byType(BusinessProfileIncorporation);

    // Dos campos que se escriben —el año y el dia— y uno que se elige: el mes
    // es el unico de los tres que no es un numero, y elegido por su nombre no
    // hay que saber si va antes o despues del dia.
    expect(
      find.descendant(of: row, matching: find.byType(Input)),
      findsNWidgets(2)
    );
    expect(
      find.descendant(of: row, matching: find.byType(SelectInput)),
      findsOneWidget
    );

    // Lo guardado (2019-05-03) llega repartido en los tres.
    expect(
      find.descendant(of: row, matching: find.text("May")),
      findsOneWidget
    );

    final typed = find.descendant(of: row, matching: find.byType(TextField));

    expect(tester.widget<TextField>(typed.first).controller!.text, "2019");
    expect(tester.widget<TextField>(typed.last).controller!.text, "03");
  });

  testWidgets('el sitio se abre desde la ficha', (tester) async {
    await tester.pumpWidget(_app(1000));
    await tester.pumpAndSettle();

    // La direccion vive dentro de algo que se toca y no suelta en el renglon:
    // es la unica fila del perfil que lleva a otro lado, y un texto suelto en
    // una ficha se lee, no se toca.
    final link = find.descendant(
      of: find.byType(BusinessProfileWebsite),
      matching: find.byWidgetPredicate(
        (widget) => widget is FeedbackButton && widget.message == "Open website"
      )
    );

    expect(link, findsOneWidget);
    expect(
      find.descendant(of: link, matching: _written("https://acme.test")),
      findsOneWidget
    );
  });

  testWidgets('los correos se listan y se ve cual es la principal', (tester) async {
    await tester.pumpWidget(_app(1000));
    await tester.pumpAndSettle();

    expect(find.text("soporte@acme.test"), findsOneWidget);
    expect(find.text("ventas@acme.test"), findsOneWidget);

    // Cada uno se nombra como lo nombra la empresa: con el nombre que le puso
    // y, si no le puso ninguno, con para que es.
    expect(find.text("Support"), findsOneWidget);
    expect(find.text("Ventas mayoristas"), findsOneWidget);

    expect(find.text("Primary"), findsOneWidget);
  });

  testWidgets('solo las que no son la principal se pueden ascender', (tester) async {
    await tester.pumpWidget(_app(1000));
    await tester.pumpAndSettle();

    // Escrito y no un tilde: cual direccion publica la empresa es una decision,
    // y un icono no dice cual se estaria tomando.
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ProfileTextAction && widget.label == "Make primary"
      ),
      findsOneWidget
    );
  });

  testWidgets('sin correos el bloque igual deja cargar el primero', (tester) async {
    await tester.pumpWidget(_app(1000, profile: BusinessProfileModel(
      id: _id,
      name: "Acme"
    )));
    await tester.pumpAndSettle();

    expect(
      find.text("This business has no email addresses yet."),
      findsOneWidget
    );
    // Agregar no es un dato de la empresa sino lo que se hace con la lista
    // entera, asi que vive en el titulo del bloque y va escrito.
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ProfileTextAction && widget.label == "Add address"
      ),
      findsOneWidget
    );
  });

  testWidgets('el identificador se ve tapado y se destapa a pedido', (tester) async {
    await tester.pumpWidget(_app(1000));
    await tester.pumpAndSettle();

    expect(_written(_id), findsNothing);
    expect(find.textContaining("550e8400-•"), findsOneWidget);

    // Se copia sin destaparlo, asi que las dos acciones conviven.
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ProfileAction && widget.icon == CI.copy
      ),
      findsOneWidget
    );

    final eye = find.byWidgetPredicate(
      (widget) => widget is ProfileAction && widget.icon == CI.eye
    );

    // La ficha entera no entra en la ventana y el identificador esta al final,
    // asi que hay que llevarlo a la vista: un boton fuera de pantalla no se
    // puede tocar, y el toque se perderia sin que la prueba se entere.
    await tester.ensureVisible(eye);
    await tester.pumpAndSettle();

    await tester.tap(eye);
    await tester.pumpAndSettle();

    // Destapado se puede seleccionar para copiarlo a mano, asi que ya no es un
    // `Text` sino un `SelectableText`: lo que se busca es el dato, no con que
    // widget quedo escrito.
    expect(_written(_id), findsOneWidget);
  });

  testWidgets('destapar el identificador no mueve su caja', (tester) async {
    await tester.pumpWidget(_app(1000));
    await tester.pumpAndSettle();

    final box = find.descendant(
      of: find.byType(BusinessProfileId),
      matching: find.byWidgetPredicate((widget) => widget is Surface)
    );

    final closed = tester.getSize(box);

    final eye = find.byWidgetPredicate(
      (widget) => widget is ProfileAction && widget.icon == CI.eye
    );

    await tester.ensureVisible(eye);
    await tester.pumpAndSettle();

    await tester.tap(eye);
    await tester.pumpAndSettle();

    // Tapado y destapado son el mismo renglon: si la caja cambia de alto al
    // destaparlo, sus dos botones dejan de estar centrados y el dato parece
    // otro. Destapado el texto se puede seleccionar, y un texto seleccionable
    // se reserva todos los renglones que le dejen salvo que se le diga que mida
    // lo que ocupa (ver `TextMedium`).
    expect(tester.getSize(box).height, closed.height);
  });

  testWidgets('el identificador y sus botones viven en la misma caja', (tester) async {
    await tester.pumpWidget(_app(1000));
    await tester.pumpAndSettle();

    // `byType` no sirve: `Surface` es abstracta y lo que se dibuja es una de
    // sus variantes.
    final box = find.ancestor(
      of: find.textContaining("550e8400-•"),
      matching: find.byWidgetPredicate((widget) => widget is Surface)
    );

    expect(box, findsOneWidget);

    // Destapar y copiar no son dos acciones mas de la ficha: son lo que se hace
    // con esos caracteres, asi que estan adentro de la misma caja y no cruzados
    // al otro extremo del renglon.
    for (final icon in [CI.eye, CI.copy]) {
      expect(
        find.descendant(
          of: box,
          matching: find.byWidgetPredicate(
            (widget) => widget is ProfileAction && widget.icon == icon
          )
        ),
        findsOneWidget
      );
    }
  });

  testWidgets('cada direccion dice si se comprobo que llega', (tester) async {
    await tester.pumpWidget(_app(1000));
    await tester.pumpAndSettle();

    // Los dos estados se escriben: una fila sin etiqueta no se leeria como
    // comprobada, se leeria como incompleta. Acotado a las filas de correo
    // porque la situacion legal de la empresa se lee con la misma palabra.
    final rows = find.byType(ProfileEmailField);

    expect(
      find.descendant(of: rows, matching: _tag("Verified")),
      findsOneWidget
    );
    expect(
      find.descendant(of: rows, matching: _tag("Unverified")),
      findsOneWidget
    );

    // Y solo la que falta comprobar ofrece hacerlo.
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ProfileTextAction && widget.label == "Verify"
      ),
      findsOneWidget
    );
  });

  testWidgets('el sitio se puede cargar aunque la empresa no tenga ninguno', (tester) async {
    await tester.pumpWidget(_app(1000, profile: BusinessProfileModel(
      id: _id,
      name: "Acme"
    )));
    await tester.pumpAndSettle();

    // Es la situacion de toda empresa el dia que el dato existe: escondida
    // mientras esta vacia, la fila no seria un dato que no se muestra, seria un
    // dato que no se puede cargar.
    expect(find.text("Website"), findsOneWidget);
    expect(find.text("Phone"), findsOneWidget);

    expect(
      find.byWidgetPredicate(
        (widget) => widget is ProfileAction &&
          widget.icon == CI.plus &&
          widget.message == "Add Website"
      ),
      findsOneWidget
    );
  });
}
