import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import 'app/crew_app.dart';
import 'app/crew_translations.dart';
import 'services/offline_map/offline_map_service.dart';
import 'services/offline_map/tile_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await bootstrapCore(
    config: const AppConfig(clientApp: ClientApp.crew, version: crewAppVersion),
    flow: crewFlowConfig(),
    withOutbox: true,
  );
  final config = Get.find<AppConfig>();
  Get.put(
    OfflineMapService(
      store: TileStore(dir: OfflineMapService.dirIn(await getApplicationSupportDirectory()), fetch: dioTileFetcher()),
      urlTemplate: config.tileUrlTemplate,
    ),
    permanent: true,
  );
  registerCrewServices();
  runApp(EmrApp(title: 'EMR Crew', pages: crewPages(), translations: crewTranslations));
}
