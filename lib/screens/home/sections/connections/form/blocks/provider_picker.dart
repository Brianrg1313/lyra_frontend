import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/connections/connection_catalog_service.dart';
import 'package:app/services/connections/connection_provider_model.dart';

import '../widgets/form_block.dart';
import '../widgets/option_card.dart';
import '../widgets/option_grid.dart';
import '../state/connection_form_controller.dart';

/// A que servicio pertenece la cuenta: el primer bloque del formulario, y el que
/// decide todo lo que viene despues —los campos de credenciales salen del
/// proveedor elegido.
///
/// El listado sale del catalogo del backend, no de esta app. Los servicios que ya
/// se pueden configurar van arriba y el resto se muestra apagado, con su leyenda:
/// las integraciones se habilitan de a poco (las de Meta primero) y esconder las
/// que faltan haria parecer que nunca van a estar.
///
/// **En una edicion no se puede cambiar.** Los secretos guardados se juntaron para
/// un servicio, y apuntarlos a otro dejaria valores que ahi no significan nada; el
/// backend lo rechaza y aca directamente no se ofrece. En su lugar se muestra cual
/// es, apagado.
class ProviderPicker extends StatelessWidget {
  const ProviderPicker({super.key, required this.controller});

  final ConnectionFormController controller;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<ConnectionCatalogService>();

    return FormBlock(
      title: S.of(context).connection_provider_title,
      subtitle: controller.isEditing
        ? S.of(context).connection_provider_locked
        : S.of(context).connection_provider_subtitle,
      child: switch (catalog.status) {
        ConnectionCatalogStatus.idle || ConnectionCatalogStatus.loading =>
          const Center(child: Loading()),
        ConnectionCatalogStatus.error => _Error(
          onRetry: () => catalog.load(force: true)
        ),
        ConnectionCatalogStatus.ready => ValueListenableBuilder<String>(
          valueListenable: controller.provider,
          builder: (context, selected, _) => OptionGrid(children: [
            for (final provider in _visible(catalog, selected)) OptionCard(
              icon: provider.icon,
              title: provider.name,
              subtitle: _scopes(context, provider),
              selected: provider.provider == selected,
              // Editando, el servicio esta decidido: la tarjeta se muestra para
              // saber cual es, pero no responde.
              enabled: provider.isSupported && !controller.isEditing,
              badge: provider.isSupported
                ? null
                : S.of(context).connection_provider_soon,
              action: () => controller.provider.value = provider.provider
            )
          ])
        )
      }
    );
  }

  /// Que servicios mostrar. Editando, solo el de la cuenta: el resto no es una
  /// opcion y ocuparia media pantalla de tarjetas que no se pueden tocar.
  List<ConnectionProviderModel> _visible(
    ConnectionCatalogService catalog,
    String selected
  ) {
    if (!controller.isEditing) return catalog.sorted;

    final current = catalog.byCode(selected);

    return current == null ? const [] : [current];
  }

  /// A que se va a poder poner la cuenta, en una linea: mensajes directos,
  /// comentarios, comentarios de anuncios.
  ///
  /// Es lo que diferencia dos entradas parecidas: la pagina de Facebook y
  /// Messenger son la misma pagina, pero una contesta comentarios y la otra
  /// mensajes —y cada una pide sus propias credenciales—. Ademas es cuantos bots
  /// va a poder alimentar la cuenta, que es lo que se viene a hacer despues.
  ///
  /// Los codigos conocidos se traducen aca y los que no, se muestran con el nombre
  /// que mando el backend: un trabajo nuevo del catalogo tiene que poder leerse
  /// desde una app vieja, aunque sea en el idioma del servidor.
  ///
  /// Devuelve `null` si el servicio no declaro ninguno, para que la tarjeta no
  /// guarde el lugar de un subtitulo que no existe.
  String? _scopes(BuildContext context, ConnectionProviderModel provider) {
    final labels = [
      for (final scope in provider.scopes)
        switch (scope.scope) {
          "messages" => S.of(context).connection_scope_messages,
          "comments" => S.of(context).connection_scope_comments,
          "ad_comments" => S.of(context).connection_scope_ad_comments,
          "mentions" => S.of(context).connection_scope_mentions,
          "posts" => S.of(context).connection_scope_posts,
          "calls" => S.of(context).connection_scope_calls,
          _ => scope.name
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
      S.of(context).connection_catalog_error,
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
      child: TextSmall(S.of(context).connections_retry)
    )
  ]);
}
