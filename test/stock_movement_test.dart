import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:core/form.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/stock/movements/stock_movement_model.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';
import 'package:app/services/stock/summary/stock_summary_service.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/summary_layout.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/summary_stepper.dart';
import 'package:app/screens/modals/inventory/stock_movement/_stock_movement.dart';
import 'package:app/screens/modals/inventory/stock_movement/movement_option.dart';
import 'package:app/screens/modals/inventory/stock_movement/movement_shape.dart';
import 'package:app/screens/modals/inventory/stock_movement/quantity_field.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/summary_product_row.dart';

const String _table = "550e8400-e29b-41d4-a716-446655440000";
const String _product = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";

const CurrencyModel _currency = CurrencyModel(
  code: "ARS",
  name: "Peso",
  symbol: "\$"
);

/// Las columnas y una fila del resumen, con los dos contadores del inventario.
Map<String, dynamic> _response({int stock = 12, int reserved = 3}) => {
  "table": _table,
  "total": 1,
  "page": 1,
  "size": 30,
  "columns": [
    {
      "key": "11111111-1111-4111-8111-111111111111",
      "name": "Nombre",
      "type": "text",
      "width": 240,
      "options": [],
      "fixed": false
    },
    {
      "key": "stock",
      "name": "Cantidad",
      "type": "stock",
      "width": 90,
      "options": [],
      "fixed": true
    },
    {
      "key": "reserved",
      "name": null,
      "type": "counter",
      "width": null,
      "options": [],
      "fixed": true
    }
  ],
  "data": {
    "keys": [
      "id",
      "11111111-1111-4111-8111-111111111111",
      "stock",
      "reserved"
    ],
    "values": [
      [_product, "Yerba 1kg", stock, reserved]
    ]
  }
};

Widget _app(Widget Function(BuildContext context) body) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: Builder(builder: (context) {
    AppSize.instance(context);

    return Scaffold(body: body(context));
  })
);

/// El control de un contador, con el ancho que le da su columna.
Widget _stepper({
  required StockCounter counter,
  required int stock,
  required int reserved
}) => _app((context) => Center(child: SizedBox(
  width: SummaryLayout.numberWidth,
  child: ChangeNotifierProvider<StockSummaryService>(
    create: (_) => StockSummaryService(),
    child: SummaryStepper(
      productId: _product,
      counter: counter,
      stock: stock,
      reserved: reserved
    )
  )
)));

/// Los dos botones del control, en orden: sacar y sumar.
List<FeedbackButton> _steps(WidgetTester tester) =>
  tester.widgetList<FeedbackButton>(find.byType(FeedbackButton)).toList();

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  group('el movimiento', () {
    test('el cuerpo lleva la tabla, el producto y el motivo', () {
      final body = const StockMovement(
        operation: StockOperation.remove,
        quantity: 4,
        reason: StockReason.damage,
        note: "  se mojaron dos cajas  "
      ).request(tableId: _table, productId: _product);

      expect(body["TABLE_ID"], _table);
      expect(body["PRODUCT_ID"], _product);
      expect(body["QUANTITY"], 4);
      expect(body["REASON"], "damage");

      // La nota viaja limpia: los espacios de los costados no explican nada.
      expect(body["NOTE"], "se mojaron dos cajas");
    });

    test('lo que no se lleno no viaja', () {
      // Sin motivo el backend pone el suyo, y sin nota no hay nada que guardar:
      // mandarlas vacias seria escribir un `REASON: ""` que el backend rechaza
      // y una nota en blanco en el libro.
      final body = const StockMovement(
        operation: StockOperation.reserve,
        quantity: 2,
        note: "   "
      ).request(tableId: _table, productId: _product);

      expect(body.containsKey("REASON"), isFalse);
      expect(body.containsKey("NOTE"), isFalse);
    });

    test('dos motivos con el mismo codigo no son el mismo motivo', () {
      // `correction` existe para entrar y para salir, y `expiration` para sacar
      // del stock y para soltar una reserva: si se buscaran por codigo, una
      // correccion de mas y una de menos serian la misma opcion.
      expect(StockReason.addCorrection.key, StockReason.removeCorrection.key);
      expect(StockReason.expired.key, StockReason.holdExpired.key);

      expect(
        StockReason.from("addCorrection", const [StockReason.addCorrection]),
        StockReason.addCorrection
      );

      // Y un motivo que no se ofrecio no se acepta: el backend lo rechazaria
      // como `invalid_reason`.
      expect(
        StockReason.from("sale", const [StockReason.restock]),
        isNull
      );
    });

    test('el saldo se lee del cuerpo de la respuesta', () {
      final balance = StockBalance.fromResponse({
        "productId": _product,
        "onHand": 10,
        "reserved": 4,
        "available": 6,
        "returns": 1
      });

      expect(balance.onHand, 10);
      expect(balance.reserved, 4);
      expect(balance.available, 6);
      expect(balance.returns, 1);
    });

    test('la fila se corrige con el saldo sin perder lo demas', () {
      final row = StockSummaryPage.fromResponse(_response()).rows.first;
      final moved = row.withBalance(stock: 8, reserved: 7);

      expect(moved.id, row.id);
      expect(moved.stock, 8);
      expect(moved.reserved, 7);

      // Lo que el movimiento no toca sigue ahi: el backend contesta el saldo,
      // no la fila.
      expect(moved["11111111-1111-4111-8111-111111111111"], "Yerba 1kg");
    });
  });

  group('la forma del formulario', () {
    test('sacar del stock es lo unico con algo que elegir', () {
      final take = StockMovementShape.of(
        counter: StockCounter.stock,
        direction: StockDirection.take
      );

      expect(take.picks, isTrue);
      expect(take.destinations.length, 3);
      expect(
        take.destinations.map((destination) => destination.operation),
        [
          StockOperation.remove,
          StockOperation.reserve,
          StockOperation.receiveReturn
        ]
      );

      // Los otros tres tienen una sola: una reserva se suelta a la estanteria y
      // a ningun otro lado.
      for (final direction in StockDirection.values) {
        for (final counter in StockCounter.values) {
          if (counter == StockCounter.stock &&
            direction == StockDirection.take) {
            continue;
          }

          expect(
            StockMovementShape.of(counter: counter, direction: direction).picks,
            isFalse
          );
        }
      }
    });

    test('el tope es el contador que el backend vigila', () {
      final take = StockMovementShape.of(
        counter: StockCounter.stock,
        direction: StockDirection.take
      );

      // Sacar de la estanteria y apartar se limitan por lo disponible; una
      // devolucion no, que entra a su propio contador y no sale de la venta.
      expect(take.destinations[0].guard, StockCounter.stock);
      expect(take.destinations[1].guard, StockCounter.stock);
      expect(take.destinations[2].guard, isNull);

      // Soltar reservas se limita por lo reservado, y apartar —aunque se abra
      // desde la columna de reservas— por el stock.
      expect(
        StockMovementShape.of(
          counter: StockCounter.reserved,
          direction: StockDirection.take
        ).destinations.single.guard,
        StockCounter.reserved
      );

      expect(
        StockMovementShape.of(
          counter: StockCounter.reserved,
          direction: StockDirection.put
        ).destinations.single.guard,
        StockCounter.stock
      );

      // Y agregar mercaderia no se limita por nada: cuanta entro hoy no lo sabe
      // el resumen.
      expect(
        StockMovementShape.of(
          counter: StockCounter.stock,
          direction: StockDirection.put
        ).destinations.single.guard,
        isNull
      );
    });
  });

  group('el contador de una fila', () {
    testWidgets('es la cifra con lo que se hace con ella a los lados',
      (tester) async {
        await tester.pumpWidget(_stepper(
          counter: StockCounter.stock,
          stock: 12,
          reserved: 3
        ));

        await tester.pump();

        expect(find.text("12"), findsOneWidget);
        expect(find.text("−"), findsOneWidget);
        expect(find.text("+"), findsOneWidget);

        // Los dos responden: del stock siempre se puede sacar y agregar.
        final steps = _steps(tester);

        expect(steps.length, 2);
        expect(steps.first.action, isNotNull);
        expect(steps.last.action, isNotNull);
      }
    );

    testWidgets('no se suelta una reserva que no existe', (tester) async {
      await tester.pumpWidget(_stepper(
        counter: StockCounter.reserved,
        stock: 5,
        reserved: 0
      ));

      await tester.pump();

      final steps = _steps(tester);

      expect(steps.first.action, isNull);
      expect(steps.last.action, isNotNull);
    });

    testWidgets('no se aparta lo que no hay', (tester) async {
      await tester.pumpWidget(_stepper(
        counter: StockCounter.reserved,
        stock: 0,
        reserved: 2
      ));

      await tester.pump();

      final steps = _steps(tester);

      expect(steps.first.action, isNotNull);
      expect(steps.last.action, isNull);
    });

    testWidgets('el stock en cero sigue recibiendo movimientos',
      (tester) async {
        // Cero no apaga el boton de sacar: por ahi se registra una devolucion
        // que acaba de entrar, que va a su propio contador y no a la venta.
        await tester.pumpWidget(_stepper(
          counter: StockCounter.stock,
          stock: 0,
          reserved: 0
        ));

        await tester.pump();

        final steps = _steps(tester);

        expect(steps.first.action, isNotNull);
        expect(steps.last.action, isNotNull);
      }
    );
  });

  group('la fila del resumen', () {
    testWidgets('no lleva a ninguna parte: lo que responde son sus numeros',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1400, 900);
        addTearDown(tester.view.reset);

        final page = StockSummaryPage.fromResponse(_response());

        await tester.pumpWidget(_app((context) =>
          ChangeNotifierProvider<StockSummaryService>(
            create: (_) => StockSummaryService(),
            child: SummaryProductRow(
              row: page.rows.first,
              layout: SummaryLayout.of(context, page.columns),
              currency: _currency
            )
          )
        ));

        await tester.pump();

        expect(tester.takeException(), isNull);

        // La fila es una banda pintada y nada mas: lo unico que responde al tap
        // son los cuatro botones de sus dos contadores.
        expect(
          find.descendant(
            of: find.byType(SummaryProductRow),
            matching: find.byType(FeedbackButton)
          ),
          findsNWidgets(4)
        );

        expect(find.byType(SummaryStepper), findsNWidgets(2));
        expect(find.text("12"), findsOneWidget);
        expect(find.text("3"), findsOneWidget);
      }
    );
  });

  group('el formulario del movimiento', () {
    /// El formulario abierto desde un boton, con una ventana lo bastante alta
    /// como para que entre entero: lo que se prueba es lo que pregunta, no como
    /// se comporta apretado.
    Future<StockSummaryService> open(
      WidgetTester tester, {
      required StockCounter counter,
      required StockDirection direction,
      int stock = 12,
      int reserved = 3
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1400);
      addTearDown(tester.view.reset);

      // Un servicio sin tabla leida: `move` corta antes de salir a la red, asi
      // que el formulario se puede enviar sin backend.
      final service = StockSummaryService();
      addTearDown(service.dispose);

      await tester.pumpWidget(_app((context) => StockMovementModal(
        service: service,
        productId: _product,
        shape: StockMovementShape.of(counter: counter, direction: direction),
        stock: stock,
        reserved: reserved
      )));

      await tester.pump();

      return service;
    }

    testWidgets('sacar del stock pregunta que les pasa a las unidades',
      (tester) async {
        await open(
          tester,
          counter: StockCounter.stock,
          direction: StockDirection.take
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(MovementOption), findsNWidgets(3));

        // De cuanto se dispone, que es lo que decide el numero que se escribe.
        expect(find.text("12 units available"), findsOneWidget);

        // La primera opcion es la comun y viene elegida: lo que sale del stock
        // casi siempre se vendio. Trae motivos, asi que se pregunta cual.
        expect(find.text("Reason"), findsOneWidget);
      }
    );

    testWidgets('apartar no tiene motivo que preguntar', (tester) async {
      await open(
        tester,
        counter: StockCounter.stock,
        direction: StockDirection.take
      );

      await tester.tap(find.text("To reservations"));
      await tester.pump();

      // Apartar es apartar: no hay nada que elegir y el desplegable se va.
      expect(find.text("Reason"), findsNothing);
    });

    testWidgets('no se saca mas de lo que hay', (tester) async {
      await open(
        tester,
        counter: StockCounter.stock,
        direction: StockDirection.take
      );

      await tester.enterText(find.byType(TextField).first, "99");
      await tester.pump();

      await tester.tap(find.text("Take out"));

      // Y el boton termina su animacion de apretado, que deja su propio
      // temporizador andando.
      await tester.pumpAndSettle();

      // El tope de este lado no reemplaza al del backend, pero evita el viaje:
      // el error dice hasta cuanto se puede.
      expect(
        find.text("Enter a whole number between 1 and 12"),
        findsOneWidget
      );
    });

    testWidgets('agregar mercaderia no tiene tope', (tester) async {
      await open(
        tester,
        counter: StockCounter.stock,
        direction: StockDirection.put
      );

      // Entrar mercaderia no depende de lo que haya: cuanta llego hoy no lo
      // sabe el resumen.
      await tester.enterText(find.byType(TextField).first, "500");
      await tester.pump();

      await tester.tap(find.text("Add"));
      await tester.pumpAndSettle();

      expect(find.textContaining("Enter a whole number"), findsNothing);
    });
  });

  group('el campo de la cantidad', () {
    /// El campo suelto, con el paso y el tope que se quiera probar.
    Future<InputController> field(
      WidgetTester tester, {
      int step = 1,
      int? max
    }) async {
      final form = FormController();
      addTearDown(form.dispose);

      final controller = InputController(
        key: "QUANTITY",
        form: form,
        pattern: "[0-9]",
        type: InputType.numeric,
        max: 9
      );

      await tester.pumpWidget(_app((context) => QuantityField(
        controller: controller,
        title: "Quantity",
        placeholder: "How many units",
        step: step,
        max: max
      )));

      await tester.pump();

      return controller;
    }

    testWidgets('la cifra va centrada entre sus dos botones', (tester) async {
      await field(tester);

      // Una cantidad no es un texto que se lee de izquierda a derecha sino una
      // cifra entre dos botones: apoyada contra el borde izquierdo se lee como
      // si no fuera parte del control.
      expect(
        tester.widget<TextField>(find.byType(TextField)).textAlign,
        TextAlign.center
      );

      // Y no lleva la marca de valido ni la de error a la derecha, que sobre un
      // numero centrado lo dejaria viendose corrido: lo que esta mal se dice
      // con el borde y con el renglon de abajo.
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration?.suffixIcon,
        isNull
      );
    });

    testWidgets('los botones mueven la cantidad de a un paso', (tester) async {
      final controller = await field(tester, step: 1);

      // Con el campo vacio no hay de que restar: ese boton esta apagado.
      expect(_steps(tester).first.action, isNull);

      await tester.tap(find.text("+"));
      await tester.pump();
      expect(controller.text, "1");

      await tester.tap(find.text("+"));
      await tester.pump();
      expect(controller.text, "2");

      await tester.tap(find.text("−"));
      await tester.pump();
      expect(controller.text, "1");

      // Y no baja del piso: un movimiento de cero unidades no es un movimiento.
      expect(_steps(tester).first.action, isNull);
    });

    testWidgets('el paso no es un uno escrito adentro', (tester) async {
      // El dia que el paso salga de una preferencia, esto es lo que tiene que
      // seguir andando: quien cuenta de a diez espera diez del primer toque.
      final controller = await field(tester, step: 10);

      await tester.tap(find.text("+"));
      await tester.pump();
      expect(controller.text, "10");

      await tester.tap(find.text("+"));
      await tester.pump();
      expect(controller.text, "20");

      await tester.tap(find.text("−"));
      await tester.pump();
      expect(controller.text, "10");
    });

    testWidgets('el mas no escribe lo que despues se va a rechazar',
      (tester) async {
        final controller = await field(tester, step: 10, max: 25);

        await tester.tap(find.text("+"));
        await tester.pump();
        await tester.tap(find.text("+"));
        await tester.pump();

        // El tercer paso daria 30, que el backend rechazaria: se planta en el
        // tope y el boton se apaga.
        await tester.tap(find.text("+"));
        await tester.pump();

        expect(controller.text, "25");
        expect(_steps(tester).last.action, isNull);
      }
    );

    testWidgets('un contador en cero no ofrece sumar nada', (tester) async {
      await field(tester, max: 0);

      final steps = _steps(tester);

      expect(steps.first.action, isNull);
      expect(steps.last.action, isNull);
    });

    testWidgets('mover con los botones limpia el error', (tester) async {
      final controller = await field(tester, max: 12);

      controller.status.setStatus(InputStatus.error, InputError.invalid);
      await tester.pump();

      await tester.tap(find.text("+"));
      await tester.pump();

      // Lo que escribe un boton siempre entra: dejarlo en rojo seria marcar
      // como mal un numero que el propio campo acaba de elegir.
      expect(controller.status.message, isNull);
      expect(controller.status.visual, InputStatus.unreviewed);
    });
  });

  group('el panel del formulario', () {
    /// Lo mismo que arma `showModal` en escritorio: la caja del dialogo, con el
    /// margen con el que centra y el ancho maximo que le deja, y adentro el
    /// panel, que apila su cabecera y el formulario **sin acotarlos**. Es la
    /// unica forma de ver aca lo que se ve en pantalla: el panel se mide por su
    /// contenido, asi que los dos problemas que puede tener —salir de un ancho
    /// que no es el suyo, o no entrar de alto— solo aparecen armado asi.
    Future<void> panel(
      WidgetTester tester,
      Size window, {
      double density = 1
    }) async {
      tester.view.devicePixelRatio = density;
      tester.view.physicalSize = Size(
        window.width * density,
        window.height * density
      );
      addTearDown(tester.view.reset);

      final service = StockSummaryService();
      addTearDown(service.dispose);

      await tester.pumpWidget(_app((context) {
        final size = MediaQuery.of(context).size;

        // El mismo envoltorio que `showModal`, pieza por pieza: si aca se
        // arma a mano un `Center` con un alto ya acotado, lo que se prueba es
        // una caja parecida y no la que sale en pantalla —y lo que desborda
        // vive justamente en la diferencia—.
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          constraints: BoxConstraints(maxWidth: size.width * .55),
          child: Surface.line(
            borderColor: Colors.white12,
            color: ThemeColor.of(context).surfaceOver,
            child: ModalDesktop(
            // El titulo va corto **a proposito**: la fuente de las pruebas
            // dibuja cada letra como un cuadrado de un eme, asi que un titulo
            // de verdad mide aca el triple que en pantalla y seria el que
            // decide el ancho del panel. Lo que se esta midiendo es el
            // formulario, no la cabecera.
            title: "Stock",
            builder: (_) => StockMovementModal(
              service: service,
              productId: _product,
              shape: StockMovementShape.of(
                counter: StockCounter.stock,
                direction: StockDirection.take
              ),
              stock: 12,
              reserved: 3
            )
          )
          )
        );
      }));

      await tester.pump();
    }

    testWidgets('mide lo que mide el formulario, no un multiplo suyo',
      (tester) async {
        await panel(tester, const Size(1280, 900));

        expect(tester.takeException(), isNull);

        // El panel se mide por su contenido, asi que el ancho lo declara el
        // formulario: fijo y no un tope, o la caja sale del ancho del renglon
        // mas largo que tenga adentro.
        expect(
          tester.getSize(find.byType(StockMovementModal)).width,
          StockMovementModal.width
        );

        // Y la caja mide eso mas su aire, ni un pixel mas. Es lo que se rompe
        // si se le pasa un `minWidth` a `showModal`: no es un ancho minimo sino
        // el paso al que redondea lo que mide, asi que con el ancho del
        // formulario la caja sale del doble de ancha.
        expect(
          tester.getSize(find.byType(ModalDesktop)).width,
          StockMovementModal.width + AppSize.padding * 2
        );
      }
    );

    testWidgets('entra tambien en una pantalla densa', (tester) async {
      // Una ventana de escritorio con muchos puntos por pixel. `Responsive`
      // divide el ancho **logico** por esa densidad —y el ancho logico ya venia
      // dividido— asi que una pantalla asi le da "telefono" a una ventana de
      // 1400 de ancho. Este formulario no le pregunta: lo que decide si es una
      // hoja o una caja es de que sistema operativo se trata, no cuantos
      // puntos tiene la pantalla, y el alto se acota igual en los dos casos.
      await panel(tester, const Size(1400, 800), density: 3);

      expect(tester.takeException(), isNull);
    });

    testWidgets('entra en una ventana absurdamente baja', (tester) async {
      // El hueco lo dice la columna del panel, no una cuenta, asi que no hay un
      // alto minimo por debajo del cual la cuenta deje de servir: el formulario
      // se queda con lo que sobre, sea lo que sea.
      await panel(tester, const Size(1280, 420));

      expect(tester.takeException(), isNull);
    });

    testWidgets('en la hoja de un telefono se desplaza igual', (tester) async {
      // The modal's other shape: the sheet bounds the height against the
      // screen itself, with no column above the form to share it out.
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 780);
      addTearDown(tester.view.reset);

      final service = StockSummaryService();
      addTearDown(service.dispose);

      await tester.pumpWidget(_app((context) => ModalPhone(
        (_) => StockMovementModal(
          service: service,
          productId: _product,
          shape: StockMovementShape.of(
            counter: StockCounter.stock,
            direction: StockDirection.take
          ),
          stock: 12,
          reserved: 3
        ),
        title: "Stock"
      )));

      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(StockMovementModal), findsOneWidget);
    });

    testWidgets('entra en una ventana baja', (tester) async {
      // Este es el formulario mas largo de la app y el panel no lo aprieta: le
      // pasa el alto sin acotar y desborda. Es el formulario el que se acota, y
      // lo que sobra se alcanza desplazando.
      await panel(tester, const Size(1280, 600));

      expect(tester.takeException(), isNull);

      expect(
        tester.getSize(find.byType(ModalDesktop)).height,
        lessThanOrEqualTo(600 - 48 - 2)
      );

      // Y sigue siendo el mismo formulario: lo que no entra se alcanza bajando.
      expect(find.byType(Scrollable), findsWidgets);
    });
  });
}
