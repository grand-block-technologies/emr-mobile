import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/crew_repository.dart';
import '../modules/handover/handover_view.dart';
import '../modules/history/history_view.dart';
import '../modules/home/crew_controller.dart';
import '../modules/job/no_transport_view.dart';
import '../modules/home/crew_home_view.dart';
import '../modules/home/settings_view.dart';
import '../modules/patient/patient_controller.dart';
import '../modules/patient/patient_views.dart';
import '../modules/pin/pin_controller.dart';
import '../modules/pin/pin_view.dart';
import '../modules/shift/scan_view.dart';
import '../services/gps_service.dart';
import '../services/live_service.dart';
import '../services/lock_service.dart';
import '../services/pin_service.dart';
import 'crew_routes.dart';

const crewAppVersion = '1.0.0';

/// Demo phones for reading SMS codes in development (docs/demo-accounts.md).
const _devPhones = {
  'demo.driver1': '+249999990108',
  'demo.driver2': '+249999990110',
  'demo.driver3': '+249999990111',
  'demo.medic1': '+249999990109',
};

AuthFlowConfig crewFlowConfig() => AuthFlowConfig(
  homeRoute: CrewRoutes.home,
  appTitleKey: 'app_title',
  brandIcon: LucideIcons.ambulance,
  roleAllowed: (me) => me.isCrew,
  devPhones: _devPhones,
  afterSignIn: (me, {required freshLogin}) async {
    final lock = Get.find<LockService>();
    final hasPin = await Get.find<PinService>().hasVerifier();
    await Get.find<CrewController>().restore();
    if (!hasPin) return CrewRoutes.pinSetup;
    if (freshLogin) {
      lock.unlock();
      return null;
    }
    return CrewRoutes.pinUnlock;
  },
);

/// Crew services on top of the core. [location] and [stomp] are swapped in tests.
void registerCrewServices({LocationSource? location, StompConnector? stomp}) {
  final session = Get.find<SessionService>();
  final outbox = Get.find<OutboxService>();
  final repo = Get.put(
    CrewRepository(
      api: Get.find(),
      outbox: outbox,
      cache: Get.find<KeyValueStore>(tag: kCacheTag),
    ),
    permanent: true,
  );
  Get.put(PinService(Get.find()), permanent: true);
  final lock = Get.put(LockService(session: session), permanent: true);
  final live = Get.put(
    LiveService(
      connector: stomp ?? StompDartConnector(),
      session: session,
      url: Get.find<AppConfig>().wsUrl,
    ),
    permanent: true,
  );
  final gps = Get.put(
    GpsService(source: location ?? GeolocatorSource(), outbox: outbox),
    permanent: true,
  );
  final crew = Get.put(
    CrewController(repo: repo, outbox: outbox, live: live, gps: gps),
    permanent: true,
  );

  // Quick vitals starts from the job screen, before the patient route is ever opened.
  Get.lazyPut(
    () => PatientController(repo: repo, crew: crew),
    fenix: true,
  );

  // "Not sent: N" in the sync chip opens the list of refused items.
  LiveSyncChip.onNotSentTap = () => unawaited(Get.to<void>(() => const NotSentView()));

  // Start network work, live updates and GPS only once the PIN screen is passed.
  ever<bool>(lock.locked, (locked) {
    if (!locked && session.isSignedIn) unawaited(crew.activate());
  });

  // A push is only a hint to re-read the job (never trusted for display).
  Get.find<PushService>().hints.listen((_) => crew.refresh());

  session.onWipe(() async {
    await crew.wipe();
    lock.lock();
  });
}

final _guard = [LockGuard()];

List<GetPage<dynamic>> crewPages() => [
  GetPage<void>(
    name: CrewRoutes.home,
    page: () => const CrewHomeView(),
    middlewares: _guard,
  ),
  GetPage<void>(
    name: CrewRoutes.settings,
    page: () => const CrewSettingsView(),
    middlewares: _guard,
  ),
  GetPage<dynamic>(
    name: CrewRoutes.scan,
    page: () => const ScanView(),
    middlewares: _guard,
  ),
  GetPage<void>(
    name: CrewRoutes.pinSetup,
    page: () => const PinView(),
    binding: BindingsBuilder(() => Get.lazyPut(() => _pin(PinMode.setup))),
  ),
  GetPage<void>(
    name: CrewRoutes.pinUnlock,
    page: () => const PinView(),
    binding: BindingsBuilder(() => Get.lazyPut(() => _pin(PinMode.unlock))),
  ),
  GetPage<void>(
    name: CrewRoutes.patients,
    page: () => const PatientsView(),
    middlewares: _guard,
    binding: BindingsBuilder(
      () => Get.lazyPut(
        () => PatientController(repo: Get.find(), crew: Get.find()),
        fenix: true,
      ),
    ),
  ),
  GetPage<void>(
    name: CrewRoutes.handover,
    page: () => const HandoverView(),
    middlewares: _guard,
  ),
  GetPage<void>(
    name: CrewRoutes.noTransport,
    page: () => const NoTransportView(),
    middlewares: _guard,
  ),
  GetPage<void>(
    name: CrewRoutes.history,
    page: () => const HistoryView(),
    middlewares: _guard,
  ),
  GetPage<void>(
    name: CrewRoutes.patientNew,
    page: () => const PatientFormView(),
    middlewares: _guard,
  ),
  GetPage<void>(
    name: CrewRoutes.vitals,
    page: () => const VitalsView(),
    middlewares: _guard,
  ),
  GetPage<void>(
    name: CrewRoutes.treatment,
    page: () => const TreatmentView(),
    middlewares: _guard,
  ),
];

PinController _pin(PinMode mode) => PinController(
  mode: mode,
  repo: Get.find(),
  pins: Get.find(),
  lock: Get.find(),
  session: Get.find(),
);
