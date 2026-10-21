import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/channels/channel_agent_role.dart';
import 'package:app/services/channels/channel_detail_model.dart';
import 'package:app/screens/home/sections/channels/form/state/channel_form_controller.dart';

/// That a channel's form holds **every** table the channel reads, not one.
///
/// A table's own settings link it to channels (`TableChannelsBlock`), so a
/// channel can come back reading a catalog and the combos made of it. A form
/// that kept only the first would send `TABLES` with one id on the next save
/// and silently disconnect the other — which is what the single select did.
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

  const both = [
    {"id": "t2", "name": "Combos"},
    {"id": "t1", "name": "Hardware"}
  ];

  test('reading a channel keeps every table it reads', () {
    final controller = ChannelFormController(channelId: "c1");
    addTearDown(controller.dispose);

    controller.apply(channel(tables: both));

    expect(controller.tableIds, ["t1", "t2"]);
    expect(controller.dirty.value, isFalse);
  });

  test('a channel with no source has no table', () {
    final controller = ChannelFormController(channelId: "c1");
    addTearDown(controller.dispose);

    controller.apply(channel());

    expect(controller.tableIds, isEmpty);
  });

  test('ticking a table and unticking it again is no change', () {
    final controller = ChannelFormController(channelId: "c1");
    addTearDown(controller.dispose);

    controller.apply(channel(tables: [both.last]));

    controller.toggleTable("t2");
    expect(controller.tableIds, ["t1", "t2"]);
    expect(controller.dirty.value, isTrue);

    controller.toggleTable("t2");
    expect(controller.dirty.value, isFalse);
  });

  test('cancelling puts back the tables that were read', () {
    final controller = ChannelFormController(channelId: "c1");
    addTearDown(controller.dispose);

    controller.apply(channel(tables: both));

    controller.toggleTable("t1");
    expect(controller.dirty.value, isTrue);

    controller.revert();

    expect(controller.tableIds, ["t1", "t2"]);
    expect(controller.dirty.value, isFalse);
  });

  test('a role that reads no tables drops them', () {
    final controller = ChannelFormController(channelId: "c1");
    addTearDown(controller.dispose);

    controller.apply(channel(tables: both));

    controller.role.value = ChannelAgentRole.support;

    expect(controller.tableIds, isEmpty);
  });
}
