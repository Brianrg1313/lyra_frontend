import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channel_provider_model.dart';

import '../widgets/form_block.dart';
import '../widgets/option_card.dart';
import '../widgets/option_grid.dart';
import '../state/channel_form_controller.dart';

/// Que red se conecta: el primer bloque del formulario, y el que decide todo lo
/// que viene despues —los campos de credenciales salen del proveedor elegido.
///
/// El listado sale del catalogo del backend, no de esta app. Las redes que ya
/// se pueden configurar van arriba y el resto se muestra apagado, con su
/// leyenda: los canales se habilitan de a poco (los de Meta primero) y esconder
/// los que faltan haria parecer que nunca van a estar.
///
/// **En una edicion no se puede cambiar.** Los secretos guardados se juntaron
/// para una red, y apuntarlos a otra dejaria valores que ahi no significan
/// nada; el backend lo rechaza y aca directamente no se ofrece. En su lugar se
/// muestra cual es, apagada.
class ProviderPicker extends StatelessWidget {
  const ProviderPicker({super.key, required this.controller});

  final ChannelFormController controller;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<ChannelCatalogService>();

    return FormBlock(
      title: S.of(context).channel_type_title,
      subtitle: controller.isEditing
        ? S.of(context).channel_type_locked
        : S.of(context).channel_type_subtitle,
      child: switch (catalog.status) {
        ChannelCatalogStatus.idle || ChannelCatalogStatus.loading =>
          const Center(child: Loading()),
        ChannelCatalogStatus.error => _Error(
          onRetry: () => catalog.load(force: true)
        ),
        ChannelCatalogStatus.ready => ValueListenableBuilder<String>(
          valueListenable: controller.provider,
          builder: (context, selected, _) => OptionGrid(children: [
            for (final provider in _visible(catalog, selected)) OptionCard(
              icon: provider.icon,
              title: provider.name,
              subtitle: _capabilities(context, provider),
              selected: provider.provider == selected,
              // Editando, la red esta decidida: la tarjeta se muestra para
              // saber cual es, pero no responde.
              enabled: provider.isSupported && !controller.isEditing,
              badge: provider.isSupported
                ? null
                : S.of(context).channel_type_soon,
              action: () => controller.provider.value = provider.provider
            )
          ])
        )
      }
    );
  }

  /// Que redes mostrar. Editando, solo la del canal: el resto no es una opcion
  /// y ocuparia media pantalla de tarjetas que no se pueden tocar.
  List<ChannelProviderModel> _visible(
    ChannelCatalogService catalog,
    String selected
  ) {
    if (!controller.isEditing) return catalog.sorted;

    final current = catalog.byCode(selected);

    return current == null ? const [] : [current];
  }

  /// Que puede hacer esa red, en una linea: mensajes, comentarios, publicaciones.
  ///
  /// Sale de `capabilities` y no de un texto fijo por red porque es lo que
  /// diferencia dos entradas parecidas: la pagina de Facebook y Messenger son
  /// la misma pagina, pero una responde comentarios y la otra mensajes.
  ///
  /// Devuelve `null` si la red no declaro ninguna, para que la tarjeta no
  /// guarde el lugar de un subtitulo que no existe.
  String? _capabilities(BuildContext context, ChannelProviderModel provider) {
    final labels = [
      for (final capability in provider.capabilities)
        switch (capability) {
          "messages" => S.of(context).channel_capability_messages,
          "comments" => S.of(context).channel_capability_comments,
          "posts" => S.of(context).channel_capability_posts,
          "mentions" => S.of(context).channel_capability_mentions,
          "calls" => S.of(context).channel_capability_calls,
          _ => ""
        }
    ]..removeWhere((label) => label.isEmpty);

    return labels.isEmpty ? null : labels.join(" · ");
  }
}

/// El catalogo no cargo. Sin el no hay formulario que dibujar —los campos de
/// credenciales salen de ahi— asi que se ofrece reintentar en el lugar.
class _Error extends StatelessWidget {
  const _Error({required this.onRetry});

  final void Function() onRetry;

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(CI.info, size: AppSize.text * 1.2, color: ThemeColor.of(context).icon),
    SizedBox(width: AppSize.spaceS),
    Expanded(child: TextSmall(
      S.of(context).channel_catalog_error,
      lines: 2,
      ellipsis: true,
      color: ThemeColor.of(context).text.secondary
    )),
    SizedBox(width: AppSize.spaceS),
    FeedbackButton(
      action: onRetry,
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.spaceS,
        vertical: AppSize.gap
      ),
      color: ThemeColor.of(context).surfaceOver,
      child: TextSmall(S.of(context).channels_retry)
    )
  ]);
}
