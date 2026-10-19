import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../family/family_views.dart';
import '../profile/profile_view.dart';
import '../requests/requests_controller.dart';
import '../requests/requests_views.dart';
import '../sos/sos_view.dart';

class CitizenHomeController extends GetxController {
  final tab = 0.obs;

  void select(int i) {
    tab.value = i;
    // The requests list is the place people check after an SOS: always show it fresh.
    if (i == 1 && Get.isRegistered<RequestsController>()) Get.find<RequestsController>().reload();
  }
}

class CitizenHomeView extends StatelessWidget {
  const CitizenHomeView({super.key});

  static const _titles = ['tab_sos', 'tab_requests', 'tab_family', 'tab_profile'];

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CitizenHomeController>();
    return Obx(
      () => Scaffold(
        appBar: AppBar(title: Text(_titles[c.tab.value].tr), bottom: const SyncBar()),
        body: SafeArea(
          child: IndexedStack(
            index: c.tab.value,
            children: [
              // Hidden tabs keep their state but stop animating (no pulse running off-screen).
              for (final (i, tab) in const [SosView(), RequestsTab(), FamilyTab(), ProfileTab()].indexed)
                TickerMode(enabled: i == c.tab.value, child: tab),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: c.tab.value,
          onDestinationSelected: c.select,
          destinations: [
            NavigationDestination(key: const Key('tab_sos'), icon: const Icon(LucideIcons.siren), label: 'tab_sos'.tr),
            NavigationDestination(key: const Key('tab_requests'), icon: const Icon(LucideIcons.clipboardList), label: 'tab_requests'.tr),
            NavigationDestination(key: const Key('tab_family'), icon: const Icon(LucideIcons.users), label: 'tab_family'.tr),
            NavigationDestination(key: const Key('tab_profile'), icon: const Icon(LucideIcons.user), label: 'tab_profile'.tr),
          ],
        ),
      ),
    );
  }
}
