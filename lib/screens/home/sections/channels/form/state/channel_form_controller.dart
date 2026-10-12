import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/channels/channel_agent_role.dart';
import 'package:app/services/channels/channel_data_source.dart';
import 'package:app/services/channels/channel_detail_model.dart';
import 'package:app/services/channels/channel_preset.dart';
import 'package:app/services/channels/channel_provider_model.dart';
import 'package:app/services/channels/channel_request.dart';
import 'package:app/services/channels/channel_tools.dart';

// WIDGETS
import 'package:core/form.dart';

/// Where the form page is.
///
/// Only the create starts in [ready]: a channel that already exists has to be
/// fetched before anything can be drawn, because its configuration is what
/// fills the fields.
enum ChannelFormStatus { loading, ready, error }

/// All the state of a channel's form, outside the widgets.
///
/// It lives apart from the screen for the same reason as the spreadsheet one:
/// there are many independent pieces —the channel type, the agent's role, the
/// data source, the tools and one field per value the network asks for— and
/// none has to repaint the others. That is why each one is its own
/// [ValueNotifier] and not a `setState` of the page: choosing a tool cannot
/// rebuild the fifteen credential fields next to it.
///
/// The configuration fields are created **on demand and reused by key**
/// ([field]). Switching networks does not throw them away: `app_secret` is
/// literally the same value in WhatsApp, Messenger and Instagram —they are the
/// same Meta app— so whoever pasted it once does not have to paste it again
/// if they picked the wrong network at the start.
///
/// [configForm] holds the network's fields, and **it is never validated**. It
/// is not carelessness: a channel is saved half-configured by design (it is
/// registered before Meta issues the tokens), so no field there can stop a
/// save. It also keeps controllers of networks that are not being shown, and
/// `FormController.validate` goes through every one it has registered,
/// including those that were never drawn.
///
/// There is no name or description to validate any more: the backend no
/// longer requires either, so the only real gate before saving is having
/// picked a provider (which fixes the scope) — see [ChannelFormSection._submit].
class ChannelFormController {
  ChannelFormController({required this.channelId}) {
    // A role change can leave the chosen source out of what that role is
    // allowed to read (support does not get a product table): the picker
    // shown does not even offer it any more, so the value has to follow.
    role.addListener(_syncSource);

    // Everything that can be touched reports into [dirty]. The text fields
    // hook themselves up as they are created (see [field]); these three are
    // there from the start.
    role.addListener(_recompute);
    source.addListener(_recompute);
    tools.addListener(_recompute);
    methods.addListener(_recompute);

    // Touching `table` here is what creates it (it is `late`), which is the
    // point: a select whose listener were attached only once it got drawn
    // would miss the value [apply] puts in it.
    table.textController.addListener(_recompute);
  }

  /// Id of the channel being edited, or empty if one is being created.
  final String channelId;

  /// `true` if this is the edit of a channel that already exists.
  bool get isEditing => channelId.isNotEmpty;

  /// A new channel has nothing to fetch: it is drawn on the spot.
  late final status = ValueNotifier<ChannelFormStatus>(
    isEditing ? ChannelFormStatus.loading : ChannelFormStatus.ready
  );

  /// Code of the chosen network, or empty if none has been chosen yet.
  ///
  /// In an edit it cannot be changed: the stored credentials were gathered for
  /// one network and pointing them at another would leave values that mean
  /// nothing there. The backend rejects it (`provider_is_immutable`) and the
  /// selector does not even offer it.
  final provider = ValueNotifier<String>("");

  final role = ValueNotifier<ChannelAgentRole>(ChannelAgentRole.initial);
  final source = ValueNotifier<ChannelDataSource>(ChannelDataSource.initial);

  /// Enabled tools. The whole set is replaced instead of mutating it: a
  /// [ValueNotifier] compares by identity and mutating the `Set` would not
  /// notify anyone.
  final tools = ValueNotifier<Set<ChannelTool>>(const {});

  /// Ids of the company's payment accounts this channel may offer a customer.
  /// Replaced whole rather than mutated, for the same reason as [tools].
  ///
  /// Empty is a legitimate answer and the default one: not every account a
  /// company charges through is public —the owner's personal Zelle, the
  /// account a distributor pays into— so a channel offers the ones it was
  /// given and no others, and a channel given none simply does not talk about
  /// paying.
  final methods = ValueNotifier<Set<String>>(const {});

  /// `true` while the save is in transit. The save button listens to it.
  final saving = ValueNotifier<bool>(false);

  /// `true` when what is on screen differs from what the channel actually
  /// holds. It is what puts the confirm/cancel pair in front of whoever
  /// touched something, and takes it away again when they undo it by hand.
  ///
  /// It is a **comparison and not a flag**: typing into a field and typing it
  /// back leaves nothing to confirm, and an input that reports itself edited
  /// (core's `isEdited`, which never goes back down) would keep the bar up
  /// over a form identical to the channel.
  final dirty = ValueNotifier<bool>(false);

  /// [_snapshot] as of the last time the form and the channel agreed: the
  /// read that filled it ([apply]) or a save that went through. Nothing else
  /// writes it — dirty means "different from what is stored", not "somebody
  /// typed".
  String _baseline = "";

  /// Detail read in an edit. From it comes which secrets are already stored (by
  /// name) and what the channel is missing.
  ChannelDetailModel? detail;

  /// Name the channel already had, if any. Only ever shown, never edited: the
  /// form does not ask for one any more, but a channel from before that change
  /// (or one the backend named on its own) can still have one, and the edit
  /// page's title falls back to it instead of "Connect channel".
  String initialName = "";

  final configForm = FormController();

  /// The network's fields, by key. See the class note about why they are reused
  /// when switching networks.
  final _fields = <String, InputController>{};

  /// Product table chosen as the data source. It is a select and not a text
  /// field: the table's id is stored, not its name, so renaming it does not
  /// disconnect the channel.
  late final table = InputController.select(
    key: ChannelDataSource.tableSettingKey,
    form: configForm
  );

  /// Controller of the [field] field, creating it the first time.
  ///
  /// The type is translated to what the input knows how to do: a secret is
  /// drawn masked, a number with a numeric keyboard. The maximum length is
  /// what the backend accepts per configuration value, which is more than
  /// enough for a permanent token or a PEM key.
  InputController field(ChannelProviderField field) => _fields.putIfAbsent(
    field.key,
    () {
      final input = InputController(
        key: field.key,
        form: configForm,
        type: switch (field.type) {
          ChannelFieldType.secret => InputType.password,
          ChannelFieldType.number => InputType.numeric,
          ChannelFieldType.email => InputType.email,
          _ => InputType.text
        },
        max: 4096
      );

      // Here and not on mount: [apply] fills these before any of them is
      // drawn, and a field created empty by the widget would already be
      // reporting a change that nobody made.
      input.textController.addListener(_recompute);

      return input;
    }
  );

  /// What was typed in a network field, or empty if it was not created (a
  /// network that never got drawn).
  String valueOf(String key) => _fields[key]?.value.trim() ?? "";

  /// The scope a preset fixed, for its provider only: `(provider, scope)`.
  (String, String)? _presetScope;

  /// Fills a create from [preset]: its network, role and tools. Everything
  /// stays editable; only its scope has no picker, so it is kept apart and
  /// travels only while that same network stays chosen ([scopeOf]).
  void applyPreset(ChannelPreset preset) {
    provider.value = preset.provider;
    role.value = preset.role;
    tools.value = Set.of(preset.tools);

    _presetScope = preset.scope.isEmpty ? null : (preset.provider, preset.scope);
  }

  /// `true` if a preset fixed the scope of [code], so the provider picker can
  /// offer a network with several jobs for this one create.
  bool fixesScope(String code) => _presetScope?.$1 == code;

  /// `SCOPE` for a create on [schema]: the preset's, or the network's only one.
  String scopeOf(ChannelProviderModel schema) => fixesScope(schema.provider)
    ? _presetScope!.$2
    : schema.defaultScope;

  /// Pours into the form the channel that was just read.
  ///
  /// The secrets are **not filled in and it is not an oversight**: the backend
  /// does not return them, it only says under which keys there is one stored.
  /// The field stays empty and the form notifies it is already configured;
  /// typing something replaces it, leaving it blank keeps it.
  void apply(ChannelDetailModel channel) {
    detail = channel;

    provider.value = channel.provider;

    initialName = channel.name;

    // `role` is a real column now, not a value tucked inside `SETTINGS`.
    role.value = ChannelAgentRole.from(channel.role);

    // The data-source category is still this app's own bookkeeping — the
    // backend only knows *which tables*, not *why* — so it keeps living in
    // `SETTINGS` and round-trips through it same as before.
    source.value = ChannelDataSource.from(
      channel.setting(ChannelDataSource.settingKey)
    );

    // Which table: from `tables`, the real link, not from a settings key. The
    // picker is still single-select, so only the first one (if the channel
    // somehow carries more than one) is shown.
    //
    // **The name goes in with the id**, and that is not decoration: core's
    // select paints the `textController` and, finding it empty next to a
    // `selectedValue`, resolves the label out of its options and writes it
    // itself — while mounting, which is mid-build. That write is harmless on
    // a first mount and an assertion the moment a second widget is listening
    // to the same controller. Handing it both leaves it nothing to write.
    if (channel.tables.isEmpty) {
      table.selectedValue = null;
      table.textController.text = "";
    } else {
      table.selectedValue = channel.tables.first.id;
      table.textController.text = channel.tables.first.name;
    }

    tools.value = {
      for (final tool in ChannelTool.values)
        if (channel.flag(tool.settingKey)) tool
    };

    // The accounts are read from the link and not from a settings key, same as
    // the tables. An account turned off in `/money` since it was linked does
    // not come back in the read, so what lands here is always what the channel
    // can actually offer today.
    methods.value = {
      for (final method in channel.paymentMethods)
        if (method.id.isNotEmpty) method.id
    };

    // The flat fields are created already loaded, before anyone draws them:
    // created by the widget they would arrive empty and would need to be
    // filled afterwards, with the text appearing a frame late.
    final schema = channel.schema;

    if (schema != null) {
      for (final item in schema.settingsFields) {
        field(item).textController.text = channel.setting(item.key);
      }
    }

    // Last, once every value is in place: this is the form agreeing with the
    // channel, which is exactly what "nothing to confirm" means.
    settle();
  }

  /// Puts every field back to the channel that was read, undoing whatever was
  /// touched since. Does nothing when there is no channel to go back to (a
  /// create, which has no "as it was").
  ///
  /// The typed secrets go and **are not put back**: the backend never returns
  /// a stored token, so "as it was" for a secret is the empty box that says
  /// one is already configured. Same reasoning as leaving it blank on a save.
  ///
  /// Every input follows on its own once this ran, but only if whoever called
  /// it also rebuilds: the text fields read their controller, and core's
  /// select resyncs the option it has highlighted from `selectedValue` on
  /// every rebuild (its options list is rebuilt too, which is what it watches
  /// for). Without that rebuild the select would go on offering the table
  /// that was just discarded as the chosen one.
  ///
  /// What must **not** be done is remounting them: these controllers are
  /// shared with the widgets being replaced, and a fresh select writing its
  /// label into one of them while the old one is still listening is a
  /// `setState() during build` on a widget nobody is building.
  void revert() {
    final channel = detail;
    if (channel == null) return;

    for (final input in _fields.values) {
      input.textController.text = "";
      input.selectedValue = null;
    }

    apply(channel);
  }

  /// Declares what is on screen to be what the channel holds: after the read
  /// that filled it, and after a save that went through.
  void settle() {
    _baseline = _snapshot();
    dirty.value = false;
  }

  /// Everything that can be edited, in one comparable line.
  ///
  /// Only the fields that carry something are in it, and that is deliberate:
  /// the secret inputs are created the first time they are drawn, empty, and
  /// counting them would turn opening the credentials block into a change.
  String _snapshot() {
    final keys = _fields.keys.toList()..sort();

    return [
      role.value.value,
      source.value.value,
      tableId,
      for (final tool in ChannelTool.values)
        if (tools.value.contains(tool)) tool.settingKey,
      // Sorted: a `Set` does not promise an order, and two identical
      // selections reached by ticking the same accounts in a different order
      // must not read as a change.
      ...methodIds,
      for (final key in keys)
        if (valueOf(key).isNotEmpty) "$key=${valueOf(key)}"
    ].join("|");
  }

  void _recompute() => dirty.value = _snapshot() != _baseline;

  /// Settings that travel in `SETTINGS`: the network's flat fields plus this
  /// app's own data-source category and tools.
  ///
  /// The role and the chosen table are **not** in here any more: `ROLE` and
  /// `TABLES` are real backend fields now and travel top-level (see
  /// [payload]). The data-source category, though, has no backend column of
  /// its own — the runtime only knows *which* tables, not *why* — so it keeps
  /// living here.
  ///
  /// **Everything** is sent, including the empty ones. In the create the empty
  /// ones are discarded when building the body; in the edit they are the ones
  /// that clear a setting that was loaded, which is exactly what is needed to
  /// be able to correct a badly pasted account id.
  Map<String, dynamic> settings(ChannelProviderModel schema) {
    final settings = <String, dynamic>{};

    for (final item in schema.settingsFields) {
      settings[item.key] = valueOf(item.key);
    }

    settings[ChannelDataSource.settingKey] = source.value.value;

    for (final tool in ChannelTool.values) {
      settings[tool.settingKey] = tools.value.contains(tool);
    }

    return settings;
  }

  /// Secrets that travel in `CREDENTIALS`: only the ones that were typed.
  ///
  /// An empty secret field means "leave the one that was already there" and
  /// not "delete it": the form cannot show the stored token, so leaving it
  /// blank is exactly what someone who came to change the channel's name does.
  /// Sending it empty would delete the token of a channel that was working.
  Map<String, dynamic> credentials(ChannelProviderModel schema) {
    final credentials = <String, dynamic>{};

    for (final item in schema.secretFields) {
      final value = valueOf(item.key);
      if (value.isNotEmpty) credentials[item.key] = value;
    }

    return credentials;
  }

  /// Id of the chosen product table, or empty if none was chosen.
  String get tableId => table.selectedValue?.trim() ?? "";

  /// `TABLES` for the write: the one chosen table, or none. The picker is
  /// single-select even though the backend accepts several — sending a list
  /// of at most one is what that shape looks like from here.
  List<String> get tableIds => tableId.isEmpty ? const [] : [tableId];

  /// `PAYMENT_METHODS` for the write: the chosen accounts, in a stable order.
  /// The backend replaces the whole selection with whatever this carries, so
  /// an empty list is the request to offer none and not a key to omit.
  List<String> get methodIds => methods.value.toList()..sort();

  /// Body of the corresponding write: the create or the edit.
  ///
  /// `SCOPE` only goes in the create: it is fixed together with `PROVIDER` at
  /// that point and cannot change afterwards, so the edit does not send either.
  Map<String, dynamic> payload(ChannelProviderModel schema) => isEditing
    ? editChannelRequest(
        id: channelId,
        role: role.value.value,
        tables: tableIds,
        methods: methodIds,
        settings: settings(schema),
        credentials: credentials(schema)
      )
    : createChannelRequest(
        provider: schema.provider,
        scope: scopeOf(schema),
        role: role.value.value,
        tables: tableIds,
        methods: methodIds,
        settings: settings(schema),
        credentials: credentials(schema)
      );

  /// Turns a tool on or off.
  void toggleTool(ChannelTool tool) {
    final next = Set<ChannelTool>.from(tools.value);

    if (!next.remove(tool)) next.add(tool);

    tools.value = next;
  }

  /// Offers a payment account through this channel, or stops offering it.
  void toggleMethod(String id) {
    final next = Set<String>.from(methods.value);

    if (!next.remove(id)) next.add(id);

    methods.value = next;
  }

  /// Corrects the data source when it falls outside what the current role
  /// allows, see [ChannelDataSource.allowedFor]. Chosen table stays only if
  /// the source that goes with it is still the one showing.
  void _syncSource() {
    final allowed = ChannelDataSource.allowedFor(role.value);
    if (allowed.contains(source.value)) return;

    source.value = allowed.first;
    if (!source.value.needsTable) table.selectedValue = null;
  }

  /// Marks the form as busy. The inputs lock themselves by listening to the
  /// `loading` of the form they registered with.
  void busy(bool value) {
    saving.value = value;
    configForm.loading.value = value;
  }

  void dispose() {
    role.removeListener(_syncSource);
    role.removeListener(_recompute);
    source.removeListener(_recompute);
    tools.removeListener(_recompute);
    methods.removeListener(_recompute);

    status.dispose();
    provider.dispose();
    role.dispose();
    source.dispose();
    tools.dispose();
    methods.dispose();
    saving.dispose();
    dirty.dispose();

    // The configuration ones are released by hand, and not with
    // `configForm.dispose()`, because a form only knows the controllers that
    // **actually got drawn** (they register on input mount). Here there are
    // others: the ones [apply] created before the first frame and those of a
    // network that was chosen and then changed. Iterating the map reaches them
    // all, and skipping the form's dispose avoids releasing twice the ones
    // that are in both.
    for (final input in _fields.values) {
      input.dispose();
    }

    table.dispose();

    _fields.clear();
    configForm.inputs.clear();
    configForm.data.clear();
    configForm.loading.dispose();
  }
}
