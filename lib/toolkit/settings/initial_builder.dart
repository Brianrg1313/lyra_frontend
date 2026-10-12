import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';
import 'package:app/services/client/client_service.dart';
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/connection/cloud_presence.dart';
import 'package:app/services/catalog/country_catalog_service.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/files/cdn_service.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/services/badges/badges_service.dart';
import 'package:app/services/business/own_job_title_service.dart';
import 'package:app/services/badges/notifications_service.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/lan/hybrid_service.dart';
import 'package:app/services/lan/sync_service.dart';
import 'package:app/services/baileys/baileys_service.dart';
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channels_service.dart';
import 'package:app/services/connections/connection_catalog_service.dart';
import 'package:app/services/connections/connections_service.dart';
import 'package:app/services/stock/tables/tables_service.dart';
import 'package:app/services/inventory/picture_import_service.dart';

/// Single instance of the client.
///
/// It lives here and not inside the provider because `initialValidator` runs
/// outside the widget tree, without a BuildContext, and needs to load the
/// session onto the same instance that the screens consume afterward.
final clientService = ClientService();

/// Single instance of the businesses.
///
/// It lives next to the client and for the same reason: `ClientService.resolve`
/// populates it from `/init` before the tree is built, onto the same instance
/// that the side bar's selector and the business section consume.
final businessService = BusinessService();

/// Single instance of the LAN session (plan §7.4): the boot flow and every LAN page share one
/// connection to the master.
final lanService = LanService();

/// Single instance of the one session over the cloud and a master (plan §9.6): the sign in
/// opens it, the server section switches it, the boot flow resumes it.
final hybridService = HybridService(lan: lanService, presence: CloudPresence());

/// Single instance of the master's sync with the cloud: it enrols the master by itself once the
/// owner is online and the company linked, so it follows the session wherever it is.
final syncService = SyncService(lan: lanService, hybrid: hybridService);

// Wraps the whole app before it is handed to MaterialApp.
//
// Only services whose state must outlive navigation belong here. Flow scoped
// services (sign in / sign up) are provided by their own screens so the app
// does not register them while those flows are not in use.
Widget initialBuilder(Widget app) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => HomeService()),
    // `.value` because the instance's lifecycle belongs to this file, not to
    // the provider: it must not be destroyed if the tree gets remounted.
    ChangeNotifierProvider.value(value: clientService),
    ChangeNotifierProvider.value(value: businessService),
    // A singleton: `BusinessService` binds it to every company it activates.
    ChangeNotifierProvider.value(value: BranchService()),
    // Also `.value`, and for a stronger reason: it's a singleton and its
    // lifecycle is that of the connection, not that of the tree. It's
    // registered only so its state can be observed with `context.watch`.
    ChangeNotifierProvider.value(value: ConnectionService()),
    // The platform catalogs: which countries are operated in and which
    // currencies can be charged in, along with how each amount is written.
    // Also `.value` and for the same reason as the connection: they're
    // singletons that `ClientService.resolve` populates from `/init` before
    // the tree exists, and they're registered only so forms can observe them
    // with `context.watch` —which is what makes a region enabled today show
    // up without publishing a new version—.
    ChangeNotifierProvider.value(value: CountryCatalogService()),
    ChangeNotifierProvider.value(value: CurrencyCatalogService()),
    // And where images are downloaded from, which arrives in the same
    // response and for the same reason: no response carries image addresses,
    // it carries ids, and the address is backend configuration. Moving them
    // to a CDN isn't a new app version.
    ChangeNotifierProvider.value(value: CdnService()),
    // What the person may open in each company, from the same response:
    // the side bar and the buttons watch it to hide what would be a 403.
    ChangeNotifierProvider.value(value: PermissionsService()),
    // What is pending in the active company, from the same response and then
    // the socket: the side bar, the tabs and the header draw its dots.
    ChangeNotifierProvider.value(value: BadgesService()),
    ChangeNotifierProvider.value(value: OwnJobTitleService()),
    // The feed behind the bell: what just happened, live, and its last page.
    ChangeNotifierProvider.value(value: NotificationsService()),
    // Which areas the deployment mode has: the side bar leaves out the ones
    // it doesn't, and in hybrid it changes with the internet.
    ChangeNotifierProvider.value(value: CapabilityService()),
    ChangeNotifierProvider.value(value: lanService),
    ChangeNotifierProvider.value(value: hybridService),
    ChangeNotifierProvider.value(value: syncService),
    // The state (the list's cache) must survive navigation between the table
    // list and the creation screen, so it lives at the app's scope and not
    // the section's.
    ChangeNotifierProvider(create: (_) => TablesService()),
    // Listens to `image/progress` whatever section is open: it is this device's half of
    // the imported pictures, and it works with nobody looking.
    ChangeNotifierProvider.value(value: PictureImportService()),
    // Same reason as the tables: the list's cache has to survive navigation
    // between the channel list and a channel's form.
    ChangeNotifierProvider(create: (_) => ChannelsService()),
    // The provider catalog doesn't belong to a business or to a screen: it's
    // public configuration that's read once per session and is consumed both
    // by the list (for each network's name and icon) and by the form (which
    // is drawn entirely from it).
    ChangeNotifierProvider(create: (_) => ChannelCatalogService()),
    // The sidecar link for WhatsApp Personal channels: which sessions
    // `baileys_server` holds and their live status. App-wide because a
    // session, once started, keeps running independently of which screen is
    // open — same reasoning as `ConnectionService`.
    ChangeNotifierProvider(create: (_) => BaileysService()),
    // The connections (accounts for outside services) follow the same pair
    // as the channels, and for the same reasons: the list's cache has to
    // survive navigation between the list and an account's form...
    ChangeNotifierProvider(create: (_) => ConnectionsService()),
    // ...and the provider catalog is public configuration read once per
    // session, not a business's data. It's a different catalog from the
    // channels' because it describes something else: what values each
    // service asks for to connect an account, and what jobs it can be put on
    // afterward.
    ChangeNotifierProvider(create: (_) => ConnectionCatalogService())
  ],
  child: app
);
