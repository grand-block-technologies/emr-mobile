import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../family/family_controllers.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProfileController>();
    final t = Theme.of(context).textTheme;
    return Obx(() {
      final p = c.profile.value;
      if (p == null && c.error.value != null) return ErrorView(error: c.error.value!, onRetry: c.load);
      if (p == null) return const LoadingView(cards: 1);
      final lang = currentLang();
      final (tone, icon, key) = switch (p.identity) {
        IdentityStatus.idCardVerified => (Tone.info, LucideIcons.shieldCheck, 'identity_id_card_verified'),
        IdentityStatus.suspended => (Tone.danger, LucideIcons.ban, 'identity_suspended'),
        IdentityStatus.phoneVerified => (Tone.warning, LucideIcons.smartphone, 'identity_phone_verified'),
        IdentityStatus.unknown => (Tone.neutral, LucideIcons.circleHelp, 'identity_unknown'),
      };
      return RefreshIndicator(
        onRefresh: c.load,
        child: ListView(
          padding: const EdgeInsets.all(Space.screen),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AvatarInitials(p.displayName(lang), size: 64),
                      const SizedBox(width: Space.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.displayName(lang), style: t.titleMedium!.copyWith(fontSize: 20)),
                            if (p.phone != null) ...[
                              const SizedBox(height: 2),
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: LtrText(Phone.dialled(p.phone!), style: t.bodyLarge!.copyWith(color: AppColors.inkMuted)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  StatusChip(label: key.tr, tone: tone, icon: icon),
                  if (p.identity == IdentityStatus.phoneVerified) ...[
                    const SizedBox(height: Space.sm),
                    Text('identity_verify_hint'.tr, style: t.bodySmall),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Space.betweenCards),
            RowGroup(
              children: [
                ListRow(icon: LucideIcons.languages, title: 'language'.tr, trailing: const LanguageToggle(), showChevron: false),
              ],
            ),
            const SizedBox(height: Space.betweenCards),
            const SignOutButton(variant: ButtonVariant.secondary, icon: LucideIcons.logOut),
          ],
        ),
      );
    });
  }
}
