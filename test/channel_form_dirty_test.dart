import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/channels/channel_agent_role.dart';
import 'package:app/services/channels/channel_detail_model.dart';
import 'package:app/services/channels/channel_provider_model.dart';
import 'package:app/services/channels/channel_tools.dart';
import 'package:app/screens/home/sections/channels/form/state/channel_form_controller.dart';

/// When the channel panel offers to confirm or cancel.
///
/// The rule is that `dirty` is a **comparison against the channel as it was
/// read**, not a "somebody touched something" flag. Two things follow from
/// that and both are pinned here: pouring the channel into the form leaves
/// nothing to confirm (otherwise the bar would greet everyone who opened a
/// panel), and typing a value back to what it already was takes the bar away
/// again (core's `InputController.isEdited` never goes back down, which is
/// why it is not what this reads).
///
/// A secret is the one asymmetry: the backend never returns a stored token,
/// so the field is empty on a channel that has one. Typing into it is a
/// change; clearing it is not "delete the token", it is "leave the one that
/// is there" — so an empty secret box has to read as clean.
void main() {
  // The controllers hold a `FocusNode`, which needs the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  ChannelDetailModel channel({
    String role = "sales",
    List<Map<String, dynamic>> tables = const []
  }) => ChannelDetailModel.fromJson({
    "id": "c1",
    "provider": "whatsapp",
    "name": "",
    "role": role,
    "enabled": true,
    "settings": {
      "data_source": "table",
      ChannelTool.voice.settingKey: true
    },
    "credentials": ["access_token"],
    "tables": tables,
    "missing": const [],
    "ready": true
  });

  test('a channel just read has nothing to confirm', () {
    final controller = ChannelFormController(channelId: "c1");
    addTearDown(controller.dispose);

    controller.apply(channel(tables: [
      {"id": "t1", "name": "Winter catalogue"}
    ]));

    expect(controller.dirty.value, isFalse);
    expect(controller.role.value, ChannelAgentRole.seller);
    expect(controller.tableIds, ["t1"]);
  });

  test('changing the role raises the bar, putting it back takes it away', () {
    final controller = ChannelFormController(channelId: "c1");
    addTearDown(controller.dispose);

    controller.apply(channel());

    controller.role.value = ChannelAgentRole.support;
    expect(controller.dirty.value, isTrue);

    controller.role.value = ChannelAgentRole.seller;
    expect(
      controller.dirty.value,
      isFalse,
      reason: "back to what the channel holds is nothing to confirm"
    );
  });

  test('toggling a tool counts as a change', () {
    final controller = ChannelFormController(channelId: "c1");
    addTearDown(controller.dispose);

    controller.apply(channel());
    expect(controller.tools.value, contains(ChannelTool.voice));

    controller.toggleTool(ChannelTool.voice);
    expect(controller.dirty.value, isTrue);

    controller.toggleTool(ChannelTool.voice);
    expect(controller.dirty.value, isFalse);
  });

  test('an untouched secret box is clean, and typing into it is not', () {
    final controller = ChannelFormController(channelId: "c1");
    addTearDown(controller.dispose);

    final detail = channel();
    controller.apply(detail);

    final schema = detail.schema;
    expect(
      schema,
      isNull,
      reason: "this payload carries no schema, so the fields are made here"
    );

    // The credentials block creates its inputs the first time it is drawn.
    // Doing that must not, on its own, look like a change.
    final token = controller.field(_secret("access_token"));
    expect(controller.dirty.value, isFalse);

    token.textController.text = "EAAG...";
    expect(controller.dirty.value, isTrue);

    // Clearing it means "leave the token that is stored", not "delete it" —
    // which is the same as never having touched the box.
    token.textController.text = "";
    expect(controller.dirty.value, isFalse);
  });

  test('revert puts the form back to the channel that was read', () {
    final controller = ChannelFormController(channelId: "c1");
    addTearDown(controller.dispose);

    controller.apply(channel(tables: [
      {"id": "t1", "name": "Winter catalogue"}
    ]));

    controller.role.value = ChannelAgentRole.support;
    controller.field(_secret("access_token")).textController.text = "EAAG...";

    expect(controller.dirty.value, isTrue);

    controller.revert();

    expect(controller.dirty.value, isFalse);
    expect(controller.role.value, ChannelAgentRole.seller);
    expect(controller.tableIds, ["t1"]);
    expect(
      controller.valueOf("access_token"),
      isEmpty,
      reason: "a secret goes back to the empty box that means 'already stored'"
    );
  });
}

/// A secret field of a provider's schema, as the catalog would describe it.
ChannelProviderField _secret(String key) => ChannelProviderField.fromJson({
  "key": key,
  "label": key,
  "type": "secret",
  "secret": true,
  "required": true
});
