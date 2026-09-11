import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/channels/channel_detail_model.dart';
import 'package:app/screens/home/sections/channels/form/state/channel_form_controller.dart';

/// That the data-source select is handed **both halves** of its value: the
/// table's id and the table's name.
///
/// This looks like a nicety and is not. Core's `SelectInput` paints the
/// `textController`, and on mount it resolves the label out of its own
/// options whenever it finds that controller empty next to a `selectedValue`
/// — writing into a controller mid-build. That write is harmless the first
/// time a panel opens (nothing else is listening yet) and an assertion
/// (`setState() or markNeedsBuild() called during build`) the moment a second
/// widget shares the controller, which is what happens if the form is ever
/// remounted rather than rebuilt. Filling the label in leaves the select
/// nothing to write.
///
/// The name is the table's current one, re-joined by the backend on every
/// read (`ChannelTableModel`), and it matches `TableLiteModel.title` — both
/// are the `name` column, which is why the label the select would have
/// resolved and the one put here are the same string.
void main() {
  // The controllers hold a `FocusNode`, which needs the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  ChannelDetailModel channel({List<Map<String, dynamic>> tables = const []}) =>
    ChannelDetailModel.fromJson({
      "id": "c1",
      "provider": "whatsapp",
      "name": "",
      "role": "sales",
      "settings": const {"data_source": "table"},
      "tables": tables,
      "ready": true
    });

  test('reading a channel fills the select with the id and the label', () {
    final controller = ChannelFormController(channelId: "c1");
    addTearDown(controller.dispose);

    controller.apply(channel(tables: [
      {"id": "t1", "name": "Winter catalogue"}
    ]));

    expect(controller.table.selectedValue, "t1");
    expect(
      controller.table.textController.text,
      "Winter catalogue",
      reason: "an empty box next to a chosen value is what makes core's "
        "select write the label itself, mid-build"
    );
  });

  test('a channel with no source leaves both halves empty', () {
    final controller = ChannelFormController(channelId: "c1");
    addTearDown(controller.dispose);

    controller.apply(channel());

    expect(controller.table.selectedValue, isNull);
    expect(controller.table.textController.text, isEmpty);
  });

  test('cancelling a table change puts the label back with the id', () {
    final controller = ChannelFormController(channelId: "c1");
    addTearDown(controller.dispose);

    controller.apply(channel(tables: [
      {"id": "t1", "name": "Winter catalogue"}
    ]));

    // What choosing another option in the select does to the controller.
    controller.table.selectedValue = "t2";
    controller.table.textController.text = "Summer catalogue";

    expect(controller.dirty.value, isTrue);

    controller.revert();

    expect(controller.table.selectedValue, "t1");
    expect(controller.table.textController.text, "Winter catalogue");
    expect(controller.dirty.value, isFalse);
  });
}
