import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/connectivity_service.dart';
import '../../services/outbox/outbox_service.dart';
import '../theme/app_colors.dart';
import 'basics.dart';

/// "Online · all sent" / "Offline · 3 waiting" / "Sending 2 of 3". Every screen shows whether
/// it is online and that nothing is lost (deck: standard data states).
class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({required this.online, required this.state, super.key});

  final bool online;
  final SyncState state;

  @override
  Widget build(BuildContext context) {
    final (label, tone, icon) = describe(online: online, state: state);
    return Semantics(liveRegion: true, child: StatusChip(label: label, tone: tone, icon: icon));
  }

  static (String, Tone, IconData) describe({required bool online, required SyncState state}) {
    final n = '${state.pending}';
    if (state.isSending) {
      return (
        'sync_sending'.trParams({'i': '${state.sendingIndex}', 'n': '${state.sendingTotal}'}),
        Tone.info,
        LucideIcons.refreshCw,
      );
    }
    if (!online) {
      return state.pending == 0
          ? ('sync_offline'.tr, Tone.warning, LucideIcons.wifiOff)
          : ('sync_offline_waiting'.trParams({'n': n}), Tone.warning, LucideIcons.wifiOff);
    }
    if (state.pending > 0) {
      return (
        (state.blocked ? 'sync_waiting_retry' : 'sync_online_pending').trParams({'n': n}),
        Tone.warning,
        LucideIcons.cloudOff,
      );
    }
    return ('sync_online_all_sent'.tr, Tone.info, LucideIcons.cloudCheck);
  }
}

/// [SyncStatusChip] wired to the live services.
class LiveSyncChip extends StatelessWidget {
  const LiveSyncChip({super.key});

  @override
  Widget build(BuildContext context) {
    final net = Get.find<ConnectivityService>();
    final outbox = Get.isRegistered<OutboxService>() ? Get.find<OutboxService>() : null;
    return Obx(
      () => SyncStatusChip(online: net.online.value, state: outbox?.sync.value ?? const SyncState()),
    );
  }
}

/// Full-width strip under the app bar with the live sync state. Use as `AppBar.bottom`:
/// unlike an action it never squeezes the title on a narrow phone.
class SyncBar extends StatelessWidget implements PreferredSizeWidget {
  const SyncBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Space.sm),
        child: Align(alignment: AlignmentDirectional.centerStart, child: LiveSyncChip()),
      );
}
