import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';
import 'package:app/services/business/business_delivery_service.dart';
import 'package:app/services/business/sources/delivery_source.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/page_switcher.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/modals/deliveries/delivery_option/_delivery_option.dart';

import 'package:app/screens/home/sections/deliveries/delivery_format.dart';
import './method_card.dart';
import './method_general.dart';
import './method_home.dart';

/// Opens the delivery methods over the deliveries desk.
///
/// A side panel and not a page: these answers change once in a while, and the
/// map they shape stays in sight to the left while they are set. [onArea]
/// runs after the panel closed onto the desk's areas, where they are drawn.
Future<void> showDeliveryMethod(
  BuildContext context, {
  required void Function() onArea
}) async {
  final width = math.min(_width, MediaQuery.of(context).size.width * .5);

  await showSideModal(
    context: context,
    title: S.of(context).deliveries_method_title,
    minWidth: width,
    maxWidth: width,
    builder: (context) => DeliveryMethodModal(onArea: onArea)
  );
}

/// Room for the fixed/flexible answers side by side.
const double _width = 480;

/// Everything the company decides about delivering, apart from following the
/// deliveries themselves, as two steps in one panel: how it delivers (three
/// cards, and what it already has), then that method's form with what holds
/// for every delivery under it.
///
/// One panel and not a stack of them: the person picks a kind of service,
/// fills it in and lands back on the list with it added; a back arrow at the
/// top of the form is the only other way out.
///
/// It owns its [BusinessDeliveryService]: the panel opens above the section's
/// providers, and every `/business/delivery/` endpoint answers for the active
/// company, so a fresh read on each opening is the right one.
class DeliveryMethodModal extends StatefulWidget {
  const DeliveryMethodModal({super.key, required this.onArea, this.source});

  final void Function() onArea;

  /// Where the service reads and writes; the deployment's when `null`.
  final DeliverySource? source;

  @override
  State<DeliveryMethodModal> createState() => _DeliveryMethodModalState();
}

class _DeliveryMethodModalState extends State<DeliveryMethodModal> {
  late final BusinessDeliveryService _delivery = BusinessDeliveryService(source: widget.source);

  /// The kind picked for a new method; `null` on the first page or an edit.
  DeliveryMode? _mode;

  /// The method being edited.
  DeliveryOption? _editing;

  /// What holds for every delivery, drafted while a form is open.
  DeliveryGeneralDraft? _general;

  bool _saving = false;

  bool get _inForm => _general != null;

  @override
  void initState() {
    super.initState();

    // Deferred to the first frame because the load notifies the service, and
    // notifying while the tree is mounting is a rebuild in the middle of a
    // build. The catalog is read right after: the cards name its carriers,
    // and the form picks from it.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await _delivery.load();
      if (mounted) await _delivery.loadCatalog();
    });
  }

  @override
  void dispose() {
    _general?.dispose();
    _delivery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    ChangeNotifierProvider<BusinessDeliveryService>.value(
      value: _delivery,
      child: Consumer<BusinessDeliveryService>(builder: (context, service, _) {
        final delivery = service.delivery;

        return switch (service.status) {
          BusinessDeliveryStatus.error => SectionMessage(
            icon: CI.info,
            title: S.of(context).business_delivery_error_title,
            subtitle: S.of(context).business_delivery_error_subtitle,
            action: service.retry,
            actionLabel: S.of(context).business_list_retry
          ),
          BusinessDeliveryStatus.ready when delivery != null => PageSwitcher(
            id: _inForm ? (_editing?.id ?? _mode!) : "home",
            child: _inForm
              ? _form(context, service, delivery)
              : DeliveryMethodHome(
                  delivery: delivery,
                  catalog: service.catalog,
                  onPick: (mode) => _open(delivery, mode: mode),
                  onEdit: (option) => _open(delivery, option: option),
                  onRemove: _remove,
                  onFlag: _flag
                )
          ),
          _ => const Center(child: Loading())
        };
      })
    );

  Widget _form(BuildContext context, BusinessDeliveryService service, BusinessDeliveryModel delivery) {
    final scheme = ThemeColor.of(context);
    final editing = _editing;
    final mode = editing?.mode ?? _mode!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          FocusableWidget(
            action: _back,
            message: S.of(context).deliveries_method_back,
            child: Padding(
              padding: EdgeInsets.all(AppSize.gap),
              child: Icon(CI.arrow_left, size: AppSize.text, color: scheme.icon)
            )
          ),
          SizedBox(width: AppSize.gap),
          Icon(mode.icon, size: AppSize.text, color: scheme.primary),
          SizedBox(width: AppSize.gap),
          Expanded(child: TextMedium(
            editing == null
              ? deliveryMethodName(context, mode)
              : deliveryOptionName(context, editing),
            bold: true,
            ellipsis: true
          ))
        ]),
        SizedBox(height: AppSize.gap * 0.5),
        TextSmall(
          editing == null
            ? deliveryMethodNote(context, mode)
            : S.of(context).deliveries_method_edit_note,
          lines: 2,
          color: scheme.text.secondary
        ),
        SizedBox(height: AppSize.spaceS),
        Expanded(child: DeliveryOptionForm(
          catalog: service.catalog,
          currency: delivery.currency,
          option: editing,
          mode: editing == null ? mode : null,
          saving: _saving,
          onSubmit: (request) => _save(delivery, request),
          extra: (context, reach) => DeliveryGeneralBlock(
            draft: _general!,
            reach: reach,
            onMeeting: (value) => setState(() => _general!.meeting = value),
            onArea: _area
          )
        ))
      ]
    );
  }

  /// Opens the form of a new method of [mode], or of [option].
  ///
  /// The catalog is awaited first: a carrier picker that fills itself in
  /// halfway through a form is a picker somebody already scrolled past.
  Future<void> _open(BusinessDeliveryModel delivery, {DeliveryMode? mode, DeliveryOption? option}) async {
    await _delivery.loadCatalog();
    if (!mounted) return;

    setState(() {
      _mode = mode;
      _editing = option;
      _general = DeliveryGeneralDraft(delivery);
    });
  }

  /// Back to the first page. The draft's input is still mounted while this
  /// runs, so it is let go of after the frame that removes it.
  void _back() {
    final general = _general;

    setState(() {
      _mode = null;
      _editing = null;
      _general = null;
    });

    if (general != null) WidgetsBinding.instance.addPostFrameCallback((_) => general.dispose());
  }

  /// Closes onto the desk's areas, where they are drawn.
  void _area() {
    Navigator.pop(context);
    widget.onArea();
  }

  /// Writes the method, then what holds for every delivery if it changed.
  ///
  /// Once the method is written the panel goes back to the list whatever
  /// follows: staying on the form would let the same method be saved twice.
  /// A new method also turns delivery back on when the company had said no —
  /// adding a way to deliver is saying yes, and leaving it off would keep the
  /// new one from ever being offered.
  Future<void> _save(BusinessDeliveryModel delivery, Map<String, dynamic> request) async {
    final general = _general;

    if (general == null) return;

    setState(() => _saving = true);

    final written = _editing == null
      ? await _delivery.createOption(context, request)
      : await _delivery.updateOption(context, request);

    if (written && mounted) {
      final notes = general.notes.value.trim();

      if (general.meeting != delivery.meeting) await _delivery.setMeeting(context, general.meeting);
      if (mounted && notes != delivery.notes) await _delivery.setNotes(context, notes);
      if (mounted && _editing == null && delivery.delivers == false) {
        await _delivery.setFlag(context, DeliveryFlag.delivers, true);
      }
    }

    if (!mounted) return;

    setState(() => _saving = false);

    if (!written) return;

    FloatFlag.of(context).message(S.of(context).deliveries_method_saved);
    _back();
  }

  Future<void> _flag(DeliveryFlag flag, bool? value) =>
    _delivery.setFlag(context, flag, value);

  /// Removes a method, after asking. What it warns about is what happens:
  /// customers stop being offered it, and whether the company delivers does
  /// not change.
  Future<void> _remove(DeliveryOption option) async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).business_delivery_remove_title,
      message: S.of(context).business_delivery_remove_message(
        deliveryOptionName(context, option)
      ),
      confirmText: S.of(context).business_delivery_remove,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !mounted) return;

    await _delivery.removeOption(context, option.id);
  }
}
