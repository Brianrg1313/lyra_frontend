import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';
import 'package:app/services/business/business_delivery_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/modals/deliveries/delivery_option/_delivery_option.dart';
import 'package:app/screens/modals/deliveries/edit_delivery_notes/_edit_delivery_notes.dart';

import 'package:app/screens/home/sections/deliveries/delivery_format.dart';
import './delivery_options.dart';
import './delivery_settings.dart';

/// Body of the delivery settings: whether, how and where the company delivers
/// (`/business/delivery/`).
///
/// Its order is a customer's: do you deliver (and where, and what past the
/// areas), how —every way it delivers: its own riders, a delivery app
/// (PedidosYa, Yummy, Rappi) or a parcel carrier (Zoom, MRW, DHL), each with
/// how far it reaches, what it costs and how long it takes—, and can I pick it
/// up instead. It is what the assistant tells a customer who asks.
///
/// The carriers offered are the ones available in the company's country,
/// which is why the form reads their catalog before it opens and why the
/// country is changed from the business's settings sheet (see
/// `BusinessProfileDetails`).
///
/// What it reads is provided by the panel (see `DeliverySettingsModal`), so
/// the body only draws it and asks for the writes. The delivery area is drawn
/// on the desk under the panel: [onArea] closes the panel back to it.
class DeliverySettingsBody extends StatefulWidget {
  const DeliverySettingsBody({super.key, required this.onArea});

  /// Back to the delivery area, on the desk.
  final void Function() onArea;

  @override
  State<DeliverySettingsBody> createState() => _DeliverySettingsBodyState();
}

class _DeliverySettingsBodyState extends State<DeliverySettingsBody> {
  @override
  void initState() {
    super.initState();

    // Deferred to the first frame because the load notifies the service, and
    // notifying while the tree is mounting is a rebuild in the middle of a
    // build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BusinessDeliveryService>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessDeliveryService>();
    final delivery = service.delivery;

    return switch (service.status) {
      BusinessDeliveryStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).business_delivery_error_title,
        subtitle: S.of(context).business_delivery_error_subtitle,
        action: service.retry,
        actionLabel: S.of(context).business_list_retry
      ),
      BusinessDeliveryStatus.ready when delivery != null => ScrollableWidget(
        padding: EdgeInsets.only(bottom: AppSize.padding),
        children: [
          TextSmall(
            S.of(context).deliveries_settings_subtitle,
            lines: 3,
            color: ThemeColor.of(context).text.secondary
          ),
          SizedBox(height: AppSize.spaceM),
          DeliverySettingsBlock(
            delivery: delivery,
            onFlag: _flag,
            onNotes: () => _notes(delivery),
            onArea: widget.onArea,
            onMeeting: _meeting
          ),
          SizedBox(height: AppSize.padding),
          DeliveryOptionsBlock(
            delivery: delivery,
            onAdd: _form,
            onEdit: (option) => _form(option: option),
            onRemove: _remove
          ),
          SizedBox(height: AppSize.padding),
          DeliveryPickupBlock(delivery: delivery, onFlag: _flag)
        ]
      ),
      _ => const Center(child: Loading())
    };
  }

  Future<void> _flag(DeliveryFlag flag, bool? value) =>
    context.read<BusinessDeliveryService>().setFlag(context, flag, value);

  Future<void> _meeting(bool value) =>
    context.read<BusinessDeliveryService>().setMeeting(context, value);

  Future<void> _notes(BusinessDeliveryModel delivery) async {
    final notes = await showDeliveryNotes(context, notes: delivery.notes);

    if (notes == null || notes == delivery.notes || !mounted) return;

    await context.read<BusinessDeliveryService>().setNotes(context, notes);
  }

  /// Opens the option form and writes what it hands back.
  ///
  /// The carrier catalog is read **before** opening it and handed in: the
  /// panel stacks under a navigator this one's service is not in scope of, and
  /// a picker that fills itself in halfway through a form is a picker somebody
  /// already scrolled past. After the first time it answers from what it has.
  Future<void> _form({DeliveryOption? option}) async {
    final service = context.read<BusinessDeliveryService>();
    final delivery = service.delivery;

    if (delivery == null) return;

    await service.loadCatalog();
    if (!mounted) return;

    final request = await showDeliveryOptionForm(
      context,
      catalog: service.catalog,
      currency: delivery.currency,
      option: option
    );

    if (request == null || !mounted) return;

    await (option == null
      ? service.createOption(context, request)
      : service.updateOption(context, request));
  }

  /// Removes an option, after asking — like every destructive action here,
  /// with [showAlertModal]. What it warns about is what happens: customers
  /// stop being offered it, and whether the company delivers does not change.
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

    await context.read<BusinessDeliveryService>().removeOption(context, option.id);
  }
}
