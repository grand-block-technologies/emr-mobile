import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/crew_routes.dart';
import 'patient_controller.dart';

class PatientsView extends StatelessWidget {
  const PatientsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PatientController>();
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('patient_care'.tr), bottom: const SyncBar()),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('patient_add'),
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.onBrand,
        onPressed: () => Get.toNamed<void>(CrewRoutes.patientNew),
        icon: const Icon(LucideIcons.userPlus, size: 20),
        label: Text('patient_add'.tr),
      ),
      body: Obx(() {
        if (c.caseId == null) return const NoAccessView();
        if (c.patients.isEmpty) {
          return EmptyView(
            icon: LucideIcons.user,
            title: 'no_patients_title'.tr,
            body: 'no_patients_body'.tr,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.screen,
            Space.screen,
            96,
          ),
          itemCount: c.patients.length,
          separatorBuilder: (_, _) => const SizedBox(height: Space.lg),
          itemBuilder: (_, i) {
            final p = c.patients[i];
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(p.displayName, style: t.titleMedium),
                      ),
                      if (p.body.temporary ?? false)
                        StatusChip(
                          label: 'patient_unknown'.tr,
                          tone: Tone.warning,
                        ),
                    ],
                  ),
                  for (final e in p.entries.reversed.take(3)) ...[
                    const SizedBox(height: Space.xs),
                    Row(
                      children: [
                        Text(e.label.tr, style: t.bodySmall),
                        const Spacer(),
                        LtrText(SudanTime.clock(e.at), style: t.bodySmall),
                      ],
                    ),
                  ],
                  const SizedBox(height: Space.inCard),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          key: Key('vitals_${p.ref}'),
                          label: 'vitals'.tr,
                          icon: LucideIcons.heartPulse,
                          onPressed: () {
                            c.select(p);
                            Get.toNamed<void>(CrewRoutes.vitals);
                          },
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: AppButton(
                          key: Key('treatment_${p.ref}'),
                          label: 'treatment'.tr,
                          variant: ButtonVariant.secondary,
                          icon: LucideIcons.pill,
                          onPressed: () {
                            c.select(p);
                            Get.toNamed<void>(CrewRoutes.treatment);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}

/// Simple labelled choice chips for small fixed lists.
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
    this.errorText,
    this.prefix = '',
  });
  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final String prefix;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: [
          for (final o in options)
            ChoiceChip(
              key: Key('choice_$prefix$o'),
              label: Text('$prefix$o'.tr),
              selected: value == o,
              selectedColor: AppColors.brandSoft,
              onSelected: (_) => onChanged(o),
            ),
        ],
      ),
      if (errorText != null) ...[
        const SizedBox(height: Space.xs),
        Text(
          errorText!,
          style: const TextStyle(
            color: AppColors.danger,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ],
  );
}

class PatientFormView extends StatefulWidget {
  const PatientFormView({super.key});

  @override
  State<PatientFormView> createState() => _PatientFormViewState();
}

class _PatientFormViewState extends State<PatientFormView> {
  final _nameAr = TextEditingController();
  final _nameEn = TextEditingController();
  final _nid = TextEditingController();
  final _phone = TextEditingController();
  final _label = TextEditingController();
  final _age = TextEditingController();
  bool _unknown = false;
  String? _sex;
  PatientController get c => Get.find<PatientController>();

  @override
  void dispose() {
    for (final t in [_nameAr, _nameEn, _nid, _phone, _label, _age]) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await c.register(
      unknown: _unknown,
      fullNameAr: _nameAr.text,
      fullNameEn: _nameEn.text,
      sex: _sex ?? '',
      nationalId: _nid.text,
      phone: _phone.text,
      temporaryLabel: _label.text,
      estimatedAge: int.tryParse(_age.text.trim()),
    );
    if (ok) {
      Get.back<void>();
      showToast('patient_queued'.tr);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('patient_add'.tr)),
    body: SafeArea(
      top: false,
      child: Obx(
        () => ListView(
          padding: const EdgeInsets.all(Space.screen),
          children: [
            FormErrorBanner(c),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text('patient_known'.tr)),
                ButtonSegment(value: true, label: Text('patient_unknown'.tr)),
              ],
              selected: {_unknown},
              onSelectionChanged: (v) => setState(() => _unknown = v.first),
            ),
            const SizedBox(height: Space.xxl),
            if (_unknown) ...[
              LabeledField(
                fieldKey: const Key('p_label'),
                label: 'temporary_label'.tr,
                controller: _label,
                errorText: c.fieldErrors['temporaryLabel'],
                helper: 'temporary_label_help'.tr,
              ),
              const SizedBox(height: Space.lg),
              LabeledField(
                fieldKey: const Key('p_age'),
                label: 'estimated_age'.tr,
                controller: _age,
                keyboardType: TextInputType.number,
                ltr: true,
                errorText: c.fieldErrors['estimatedAge'],
              ),
            ] else ...[
              LabeledField(
                fieldKey: const Key('p_nid'),
                label: 'national_id'.tr,
                controller: _nid,
                keyboardType: TextInputType.number,
                ltr: true,
                maxLength: 15,
                errorText: c.fieldErrors['nationalId'],
              ),
              const SizedBox(height: Space.lg),
              LabeledField(
                fieldKey: const Key('p_name_ar'),
                label: 'full_name_ar'.tr,
                controller: _nameAr,
                errorText: c.fieldErrors['fullNameAr'],
              ),
              const SizedBox(height: Space.lg),
              LabeledField(
                label: '${'full_name_en'.tr} (${'optional'.tr})',
                controller: _nameEn,
                ltr: true,
              ),
              const SizedBox(height: Space.lg),
              LabeledField(
                label: '${'phone'.tr} (${'optional'.tr})',
                controller: _phone,
                keyboardType: TextInputType.phone,
                ltr: true,
                errorText: c.fieldErrors['phone'],
              ),
            ],
            const SizedBox(height: Space.lg),
            ChoiceRow(
              label: 'sex'.tr,
              options: TreatmentOptions.sexes,
              value: _sex,
              prefix: 'sex_',
              onChanged: (v) => setState(() => _sex = v),
              errorText: c.fieldErrors['sex'],
            ),
            const SizedBox(height: Space.xxl),
            AppButton(
              key: const Key('p_save'),
              label: 'save'.tr,
              onPressed: () => unawaited(_save()),
            ),
          ],
        ),
      ),
    ),
  );
}

class VitalsView extends StatefulWidget {
  const VitalsView({super.key});

  @override
  State<VitalsView> createState() => _VitalsViewState();
}

class _VitalsViewState extends State<VitalsView> {
  static const fields = [
    'heartRate',
    'respRate',
    'spo2',
    'systolic',
    'diastolic',
    'temperatureC',
    'bloodGlucoseMmol',
    'painScore',
  ];
  final _ctl = {for (final f in fields) f: TextEditingController()};
  final _note = TextEditingController();
  bool? _oxygen;
  String? _avpu;
  PatientController get c => Get.find<PatientController>();

  @override
  void dispose() {
    for (final t in [..._ctl.values, _note]) {
      t.dispose();
    }
    super.dispose();
  }

  Map<String, num?> get _values => {
    for (final f in fields)
      f: num.tryParse(_ctl[f]!.text.trim().replaceAll(',', '.')),
  };

  Future<void> _save() async {
    final values = _values;
    final unusual = c.unusual(values);
    if (unusual.isNotEmpty) {
      final ok = await Get.dialog<bool>(
        AlertDialog(
          title: Text('unusual_title'.tr),
          content: Text(
            '${'unusual_body'.tr}\n\n${unusual.map((f) => '• ${'vital_$f'.tr}: ${values[f]}').join('\n')}',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('back'.tr),
            ),
            FilledButton(
              key: const Key('unusual_confirm'),
              onPressed: () => Get.back(result: true),
              child: Text('confirm'.tr),
            ),
          ],
        ),
      );
      if (!(ok ?? false)) return;
    }
    if (await c.addVitals(
      values,
      onOxygen: _oxygen,
      consciousness: _avpu,
      note: _note.text,
    )) {
      Get.back<void>();
      showToast('vitals_queued'.tr);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${'vitals'.tr} · ${c.selected.value?.displayName ?? ''}'),
    ),
    body: SafeArea(
      top: false,
      child: Obx(
        () => ListView(
          padding: const EdgeInsets.all(Space.screen),
          children: [
            FormErrorBanner(c),
            Wrap(
              spacing: Space.md,
              runSpacing: Space.lg,
              children: [
                for (final f in fields)
                  SizedBox(
                    width:
                        (MediaQuery.sizeOf(context).width -
                            Space.screen * 2 -
                            Space.md) /
                        2,
                    child: LabeledField(
                      fieldKey: Key('v_$f'),
                      label: 'vital_$f'.tr,
                      controller: _ctl[f],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      ltr: true,
                      errorText: c.fieldErrors[f],
                      hint: _hint(f),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Space.lg),
            ChoiceRow(
              label: 'vital_consciousness'.tr,
              options: Vitals.consciousness,
              value: _avpu,
              prefix: 'avpu_',
              onChanged: (v) => setState(() => _avpu = v),
            ),
            const SizedBox(height: Space.lg),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('vital_onOxygen'.tr),
              value: _oxygen ?? false,
              onChanged: (v) => setState(() => _oxygen = v),
            ),
            const SizedBox(height: Space.lg),
            LabeledField(
              label: '${'note'.tr} (${'optional'.tr})',
              controller: _note,
              maxLines: 3,
            ),
            const SizedBox(height: Space.xxl),
            AppButton(
              key: const Key('v_save'),
              label: 'save'.tr,
              onPressed: () => unawaited(_save()),
            ),
          ],
        ),
      ),
    ),
  );

  static String _hint(String f) {
    final r = Vitals.byField[f]!;
    return '${r.min}–${r.max}';
  }
}

class TreatmentView extends StatefulWidget {
  const TreatmentView({super.key});

  @override
  State<TreatmentView> createState() => _TreatmentViewState();
}

class _TreatmentViewState extends State<TreatmentView> {
  final _name = TextEditingController();
  final _dose = TextEditingController();
  final _note = TextEditingController();
  String? _kind;
  String? _route;
  PatientController get c => Get.find<PatientController>();

  @override
  void dispose() {
    for (final t in [_name, _dose, _note]) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (await c.addTreatment(
      kind: _kind ?? '',
      name: _name.text,
      dose: _dose.text,
      route: _route,
      note: _note.text,
    )) {
      Get.back<void>();
      showToast('treatment_queued'.tr);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${'treatment'.tr} · ${c.selected.value?.displayName ?? ''}'),
    ),
    body: SafeArea(
      top: false,
      child: Obx(
        () => ListView(
          padding: const EdgeInsets.all(Space.screen),
          children: [
            FormErrorBanner(c),
            ChoiceRow(
              label: 'treatment_kind'.tr,
              options: TreatmentOptions.kinds,
              value: _kind,
              prefix: 'kind_',
              onChanged: (v) => setState(() => _kind = v),
              errorText: c.fieldErrors['kind'],
            ),
            const SizedBox(height: Space.lg),
            LabeledField(
              fieldKey: const Key('t_name'),
              label: 'treatment_name'.tr,
              controller: _name,
              errorText: c.fieldErrors['name'],
            ),
            const SizedBox(height: Space.lg),
            LabeledField(
              label: '${'dose'.tr} (${'optional'.tr})',
              controller: _dose,
              ltr: true,
            ),
            const SizedBox(height: Space.lg),
            ChoiceRow(
              label: 'route'.tr,
              options: TreatmentOptions.routes,
              value: _route,
              prefix: 'route_',
              onChanged: (v) => setState(() => _route = v),
            ),
            const SizedBox(height: Space.lg),
            LabeledField(
              label: '${'note'.tr} (${'optional'.tr})',
              controller: _note,
              maxLines: 3,
            ),
            const SizedBox(height: Space.xxl),
            AppButton(
              key: const Key('t_save'),
              label: 'save'.tr,
              onPressed: () => unawaited(_save()),
            ),
          ],
        ),
      ),
    ),
  );
}
