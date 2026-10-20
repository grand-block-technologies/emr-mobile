import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/citizen_routes.dart';
import 'family_controllers.dart';

class FamilyTab extends StatelessWidget {
  const FamilyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FamilyController>();
    return Obx(
      () => RefreshIndicator(
        onRefresh: c.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Space.screen),
          children: [
            RowGroup(
              children: [
                ListRow(
                  icon: LucideIcons.fileHeart,
                  title: 'my_history'.tr,
                  subtitle: 'my_history_body'.tr,
                  onTap: () => Get.toNamed<void>(CitizenRoutes.history),
                ),
              ],
            ),
            const SizedBox(height: Space.betweenCards),
            SectionHeader('family_title'.tr, subtitle: 'family_body'.tr),
            if (c.links.isNotEmpty) ...[
              RowGroup(
                children: [
                  for (final d in c.links)
                    ListRow(
                      icon: d.relation == 'child'
                          ? LucideIcons.baby
                          : LucideIcons.userRound,
                      title: 'relation_${d.relation}'.tr,
                      subtitle: d.childNationalId,
                      detail: StatusChip(
                        label: 'link_${d.status}'.tr,
                        tone: d.status == 'pending' ? Tone.warning : Tone.info,
                        icon: d.status == 'pending'
                            ? LucideIcons.hourglass
                            : LucideIcons.check,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Space.lg),
            ],
            AppButton(
              key: const Key('family_add'),
              label: 'family_add'.tr,
              variant: ButtonVariant.secondary,
              icon: LucideIcons.userPlus,
              onPressed: () =>
                  unawaited(showAppSheet<void>(const _AddDependantSheet())),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddDependantSheet extends StatefulWidget {
  const _AddDependantSheet();

  @override
  State<_AddDependantSheet> createState() => _AddDependantSheetState();
}

class _AddDependantSheetState extends State<_AddDependantSheet> {
  final _id = TextEditingController();
  DependantRelation? _relation;
  FamilyController get c => Get.find<FamilyController>();

  @override
  void dispose() {
    _id.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.xxl),
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'family_add'.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: Space.lg),
              FormErrorBanner(c),
              LabeledField(
                fieldKey: const Key('child_id'),
                label: 'child_national_id'.tr,
                controller: _id,
                keyboardType: TextInputType.number,
                maxLength: 15,
                ltr: true,
                errorText: c.fieldErrors['childNationalId'],
              ),
              const SizedBox(height: Space.lg),
              Text(
                'relation'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: Space.sm,
                children: [
                  for (final r in DependantRelation.values)
                    ChoiceChip(
                      key: Key('relation_${r.wire}'),
                      label: Text('relation_${r.wire}'.tr),
                      selected: _relation == r,
                      selectedColor: AppColors.brandSoft,
                      onSelected: (_) => setState(() => _relation = r),
                    ),
                ],
              ),
              if (c.fieldErrors['relation'] != null)
                Text(
                  c.fieldErrors['relation']!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              const SizedBox(height: Space.xxl),
              AppButton(
                key: const Key('family_save'),
                label: 'send'.tr,
                busy: c.busy.value,
                onPressed: () async {
                  if (await c.add(_id.text, _relation)) {
                    Get.back<void>();
                    showToast('family_sent'.tr);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HistoryController>();
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('my_history'.tr)),
      body: Obx(() {
        if (c.loading.value) return const LoadingView();
        if (c.notVerified.value) {
          return ListView(
            padding: const EdgeInsets.all(Space.screen),
            children: [
              EmptyView(
                icon: LucideIcons.shieldCheck,
                title: 'history_verify_title'.tr,
                body: 'history_verify_body'.tr,
              ),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, step) in [
                      'history_step_1',
                      'history_step_2',
                      'history_step_3',
                    ].indexed) ...[
                      if (i > 0) const SizedBox(height: Space.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LtrText('${i + 1}.', style: t.titleMedium),
                          const SizedBox(width: Space.sm),
                          Expanded(child: Text(step.tr, style: t.bodyLarge)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }
        if (c.error.value != null) {
          return ErrorView(error: c.error.value!, onRetry: c.reload);
        }
        final h = c.history.value;
        if (h.isEmpty) {
          return EmptyView(
            icon: LucideIcons.fileText,
            title: 'history_empty'.tr,
          );
        }
        final lang = currentLang();
        // Visits newest first; the other lists keep the server order.
        final epoch = DateTime.fromMillisecondsSinceEpoch(0);
        final visits = List<HistoryRow>.of(h.visits.content)
          ..sort(
            (HistoryRow x, HistoryRow y) =>
                (y.at ?? epoch).compareTo(x.at ?? epoch),
          );
        Widget card(String title, String? subtitle, DateTime? at) => AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.titleMedium),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: Space.xs),
                Text(subtitle, style: t.bodyLarge),
              ],
              if (at != null) ...[
                const SizedBox(height: Space.xs),
                Text(SudanTime.dateTime(at, lang), style: t.bodySmall),
              ],
            ],
          ),
        );
        Widget section(
          String key,
          String titleKey,
          List<HistoryRow> rows,
          Widget Function(HistoryRow) item,
        ) => rows.isEmpty
            ? const SizedBox.shrink()
            : Column(
                key: Key(key),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(titleKey.tr),
                  for (final r in rows) ...[
                    item(r),
                    const SizedBox(height: Space.md),
                  ],
                  const SizedBox(height: Space.md),
                ],
              );
        String? str(HistoryRow r, String k) =>
            r.raw[k] is String ? r.raw[k] as String : null;
        DateTime? date(HistoryRow r, String k) =>
            DateTime.tryParse(str(r, k) ?? '');
        return RefreshIndicator(
          onRefresh: c.reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Space.screen),
            children: [
              section(
                'history_visits',
                'history_visits',
                visits,
                (r) => card(
                  'history_entry'.tr,
                  str(r, 'dischargeNote'),
                  date(r, 'startedAt'),
                ),
              ),
              section(
                'history_diagnoses',
                'history_diagnoses',
                h.diagnoses.content,
                (r) {
                  return card(
                    str(r, 'description') ??
                        str(r, 'icd10Code') ??
                        'history_entry'.tr,
                    str(r, 'description') == null ? null : str(r, 'icd10Code'),
                    date(r, 'recordedAt'),
                  );
                },
              ),
              section(
                'history_checks',
                'history_checks',
                h.checkResults.content,
                (r) {
                  return card(
                    str(r, 'checkCode') ?? '',
                    [?str(r, 'resultValue'), ?str(r, 'resultUnit')].join(' '),
                    date(r, 'doneAt'),
                  );
                },
              ),
              section(
                'history_conditions',
                'history_conditions',
                h.conditions.content,
                (r) {
                  final kind = str(r, 'kind');
                  return card(
                    str(r, 'name') ?? '',
                    kind == null ? null : 'condition_$kind'.tr,
                    date(r, 'recordedAt'),
                  );
                },
              ),
              if (c.hasNext)
                AppButton(
                  label: 'load_more'.tr,
                  variant: ButtonVariant.secondary,
                  onPressed: c.more,
                ),
            ],
          ),
        );
      }),
    );
  }
}
