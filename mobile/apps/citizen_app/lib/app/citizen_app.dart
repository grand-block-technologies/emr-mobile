import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/citizen_repository.dart';
import '../modules/family/family_controllers.dart';
import '../modules/family/family_views.dart';
import '../modules/home/citizen_home_view.dart';
import '../modules/requests/requests_controller.dart';
import '../modules/requests/requests_views.dart';
import '../modules/signup/signup_controller.dart';
import '../modules/signup/signup_view.dart';
import '../modules/sos/sos_controller.dart';
import '../services/sos_locator.dart';
import 'citizen_routes.dart';

const citizenAppVersion = '1.0.0';

/// The username of an app sign-up is the phone; accept it the way people type it.
String normalizeCitizenUsername(String input) {
  final looksLikePhone = RegExp(r'^[\d\s+()-]+$').hasMatch(input);
  return looksLikePhone ? (Phone.toE164(input) ?? input) : input;
}

AuthFlowConfig citizenFlowConfig() => AuthFlowConfig(
      homeRoute: CitizenRoutes.home,
      appTitleKey: 'app_title',
      brandIcon: LucideIcons.siren,
      showEmergencyCall: true,
      roleAllowed: (me) => me.isCitizen,
      usernameLabelKey: 'username_or_phone',
      normalizeUsername: normalizeCitizenUsername,
      devPhones: const {'demo.citizen': '+249912345003'},
      loginFooter: (_) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: Text('no_account'.tr, style: const TextStyle(color: AppColors.inkMuted, fontSize: 14))),
          TextButton(
            key: const Key('signup_link'),
            onPressed: () => Get.toNamed<void>(CitizenRoutes.signUp),
            child: Text('signup_link'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

/// Citizen services on top of the core. [locator] is swapped in tests.
void registerCitizenServices({SosLocator? locator}) {
  Get.put(CitizenRepository(api: Get.find(), cache: Get.find<KeyValueStore>(tag: kCacheTag)), permanent: true);
  Get.put<SosLocator>(locator ?? GeolocatorSosLocator(), permanent: true);
}

List<GetPage<dynamic>> citizenPages() => [
      GetPage<void>(
        name: CitizenRoutes.home,
        page: () => const CitizenHomeView(),
        binding: BindingsBuilder(() {
          Get.lazyPut(CitizenHomeController.new);
          Get.lazyPut(() => SosController(repo: Get.find(), locator: Get.find(), net: Get.find()));
          Get.lazyPut(() => RequestsController(repo: Get.find()));
          Get.lazyPut(() => FamilyController(repo: Get.find()));
          Get.lazyPut(() => ProfileController(repo: Get.find()));
        }),
      ),
      GetPage<void>(
        name: CitizenRoutes.request,
        page: () => const RequestDetailView(),
        binding: BindingsBuilder(
          () => Get.lazyPut(() => RequestDetailController(repo: Get.find(), id: (Get.arguments as RequestArgs).id)),
        ),
      ),
      GetPage<void>(
        name: CitizenRoutes.signUp,
        page: () => const SignUpView(),
        binding: BindingsBuilder(() => Get.lazyPut(() => SignUpController(repo: Get.find()))),
      ),
      GetPage<void>(
        name: CitizenRoutes.history,
        page: () => const HistoryView(),
        binding: BindingsBuilder(() => Get.lazyPut(() => HistoryController(repo: Get.find()))),
      ),
    ];
