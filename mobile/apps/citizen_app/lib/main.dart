import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/citizen_app.dart';
import 'app/citizen_translations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await bootstrapCore(
    config: const AppConfig(clientApp: ClientApp.citizen, version: citizenAppVersion),
    flow: citizenFlowConfig(),
  );
  registerCitizenServices();
  runApp(EmrApp(title: 'EMR Ambulance', pages: citizenPages(), translations: citizenTranslations));
}
