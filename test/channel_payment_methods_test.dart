import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/channels/channel_detail_model.dart';
import 'package:app/services/channels/channel_provider_model.dart';
import 'package:app/screens/home/sections/channels/form/state/channel_form_controller.dart';

/// Which of the company's accounts a channel may tell a customer to pay into.
///
/// The rule that matters is that the selection is a **picker and not a
/// patch**: the write replaces whatever the channel had with exactly what the
/// list carries, so `PAYMENT_METHODS` always travels — an empty one is the
/// request to offer none, not a key to leave out. That is what lets the form
/// be saved without this side knowing what was linked before it opened.
///
/// The other half is the same comparison `channel_form_dirty` pins for the
/// rest of the form: the accounts arrive from the read, so a panel that was
/// only opened has nothing to confirm, and ticking an account back off leaves
/// nothing either.
void main() {
  // The controllers hold a `FocusNode`, which needs the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  ChannelDetailModel channel({List<Map<String, dynamic>> methods = const []}) =>
    ChannelDetailModel.fromJson({
      "id": "c1",
      "provider": "whatsapp",
      "name": "",
      "role": "sales",
      "enabled": true,
      "settings": const {"data_source": "table"},
      "credentials": const <String>[],
      "tables": const [],
      "payment_methods": methods,
      "missing": const [],
      "ready": true
    });

  test('the accounts come from the read and confirm nothing on their own', () {
    final controller = ChannelFormController(channelId: "c1");
    addTearDown(controller.dispose);

    controller.apply(channel(methods: [
      {"id": "m1", "code": "zelle", "label": "Zelle shop", "method": "transfer"},
      {"id": "m2", "code": "cash", "label": "Counter", "method": "cash"}
    ]));

    expect(controller.methods.value, {"m1", "m2"});
    expect(controller.dirty.value, isFalse);
  });

  test('offering another account is a change, taking it back is not', () {
    final controller = ChannelFormController(channelId: "c1");
    addTearDown(controller.dispose);

    controller.apply(channel(methods: [
      {"id": "m1", "code": "zelle", "label": "Zelle shop", "method": "transfer"}
    ]));

    controller.toggleMethod("m2");
    expect(controller.dirty.value, isTrue);

    controller.toggleMethod("m2");
    expect(
      controller.dirty.value,
      isFalse,
      reason: "back to what the channel offers is nothing to confirm"
    );
  });

  test('the order accounts were ticked in is not a change', () {
    final controller = ChannelFormController(channelId: "c1");
    addTearDown(controller.dispose);

    controller.apply(channel(methods: [
      {"id": "m1", "code": "zelle", "label": "Zelle shop", "method": "transfer"},
      {"id": "m2", "code": "cash", "label": "Counter", "method": "cash"}
    ]));

    controller.toggleMethod("m1");
    controller.toggleMethod("m1");

    expect(controller.methods.value, {"m1", "m2"});
    expect(controller.dirty.value, isFalse);
  });

  test('the create body carries the chosen accounts', () {
    final controller = ChannelFormController(channelId: "");
    addTearDown(controller.dispose);

    controller.toggleMethod("m2");
    controller.toggleMethod("m1");

    final body = controller.payload(_schema);

    expect(body["PROVIDER"], "whatsapp");
    expect(
      body["PAYMENT_METHODS"],
      ["m1", "m2"],
      reason: "a stable order, so two identical selections read the same"
    );
  });

  test('the edit body replaces the selection, empty included', () {
    final controller = ChannelFormController(channelId: "c1");
    addTearDown(controller.dispose);

    controller.apply(channel(methods: [
      {"id": "m1", "code": "zelle", "label": "Zelle shop", "method": "transfer"}
    ]));

    controller.toggleMethod("m1");

    final body = controller.payload(_schema);

    expect(body["ID"], "c1");
    expect(
      body["PAYMENT_METHODS"],
      isEmpty,
      reason: "an empty list is 'offer none', which the key has to travel to say"
    );
  });
}

/// A provider with a single scope and no fields, which is all the payload
/// needs: what is being read here is the accounts, not the credentials.
final ChannelProviderModel _schema = const ChannelProviderModel(
  provider: "whatsapp",
  name: "WhatsApp",
  category: "messaging",
  scopes: [ChannelProviderScope(scope: "messages", name: "Messages")]
);
