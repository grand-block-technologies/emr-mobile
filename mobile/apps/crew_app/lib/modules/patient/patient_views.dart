import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/crew_routes.dart';
import '../../data/crew_repository.dart';
import '../home/crew_controller.dart';
import 'patient_controller.dart';

/// "Add vitals" in one tap: the only patient is used as is; with none, an unknown patient is
/// registered for the paramedic; with several, the paramedic picks one.
Future<void> startQuickVitals(BuildContext context) async {
  final c = Get.find<PatientController>();
  await c.load();
  int? age;
  if (c.patients.isEmpty) {
    if (c.caseId == null) return;
    age = await _askEstimatedAge();
    if (age == null) return;
  }
  var p = await c.patientForQuickVitals(unknownAge: age);
  if (p == null) {
    if (c.patients.isEmpty || !context.mounted) return;
    p = await showModalBottomSheet<LocalPatient>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Text('vitals_pick_patient'.tr, style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final x in c.patients)
              ListTile(
                key: Key('pick_${x.ref}'),
                leading: const Icon(LucideIcons.user),
                title: Text(x.displayName),
                onTap: () => Navigator.of(context).pop(x),
              ),
          ],
        ),
      ),
    );
    if (p == null) return;
    c.select(p);
  }
  await Get.toNamed<void>(CrewRoutes.vitals);
}

/// An unknown patient needs an estimated age before the server accepts the registration.
Future<int?> _askEstimatedAge() => Get.dialog<int>(const _AgeDialog());

class _AgeDialog extends StatefulWidget {
  const _AgeDialog();

  @override
  State<_AgeDialog> createState() => _AgeDialogState();
}

class _AgeDialogState extends State<_AgeDialog> {
  final _ctl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _ok() {
    final age = int.tryParse(_ctl.text.trim());
    if (age == null || age < 0 || age > 120) {
      setState(() => _error = 'v_number'.tr);
      return;
    }
    Get.back(result: age);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('vitals_unknown_patient'.tr),
    content: LabeledField(
      fieldKey: const Key('quick_age'),
      label: 'estimated_age'.tr,
      controller: _ctl,
      keyboardType: TextInputType.number,
      maxLength: 3,
      ltr: true,
      errorText: _error,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _ok(),
    ),
    actions: [
      TextButton(onPressed: () => Get.back<void>(), child: Text('cancel'.tr)),
      FilledButton(key: const Key('quick_age_ok'), onPressed: _ok, child: Text('continue'.tr)),
    ],
  );
}

String _rejectedKindKey(OutboxKind k) => switch (k) {
  OutboxKind.patient => 'not_sent_patient',
  OutboxKind.observation => 'not_sent_vitals',
  OutboxKind.treatment => 'not_sent_treatment',
  OutboxKind.handover => 'not_sent_handover',
  _ => 'not_sent_other',
};

/// Opened by tapping "Not sent: N" in the sync chip.
class NotSentView extends StatelessWidget {
  const NotSentView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PatientController>();
    return Scaffold(
      appBar: AppBar(title: Text('not_sent_title'.tr), bottom: const SyncBar()),
      body: Obx(
        () => c.rejected.isEmpty
            ? Center(child: Text('send_nothing'.tr))
            : ListView(padding: const EdgeInsets.all(Space.screen), children: const [NotSentList()]),
      ),
    );
  }
}

/// Clinical writes the server refused. They stay here until fixed and resent, or deleted on purpose.
class NotSentList extends StatelessWidget {
  const NotSentList({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PatientController>();
    final lang = currentLang();
    return Obx(() {
      if (c.rejected.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader('not_sent_title'.tr, subtitle: 'not_sent_body'.tr),
          for (final r in c.rejected) ...[
            AppCard(
              key: Key('not_sent_${r.item.seq}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.circleAlert, size: 20, color: AppColors.danger),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Text(
                          _rejectedKindKey(r.item.kind).tr,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      LtrText(SudanTime.clock(r.item.createdAt)),
                    ],
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    r.error.message(lang),
                    style: const TextStyle(color: AppColors.danger),
                  ),
                  const SizedBox(height: Space.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          key: Key('resend_${r.item.seq}'),
                          label: _canEdit(r) ? 'not_sent_fix'.tr : 'not_sent_resend'.tr,
                          icon: LucideIcons.send,
                          onPressed: () => unawaited(_resend(c, r)),
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: AppButton(
                          key: Key('discard_${r.item.seq}'),
                          label: 'delete'.tr,
                          variant: ButtonVariant.secondary,
                          icon: LucideIcons.trash2,
                          onPressed: () => unawaited(_discard(c, r)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.md),
          ],
          const SizedBox(height: Space.md),
        ],
      );
    });
  }

  static bool _canEdit(RejectedItem r) =>
      r.item.kind == OutboxKind.handover ||
      (r.item.kind == OutboxKind.treatment && (r.item.body as Map?)?['kind'] == 'medicine');

  static Future<void> _resend(PatientController c, RejectedItem r) async {
    final body = r.item.body;
    if (r.item.kind == OutboxKind.treatment && body is Map && body['kind'] == 'medicine') {
      final med = await pickMedicine();
      if (med == null) return;
      await c.resend(r, body: {...body, 'name': med.code});
      return;
    }
    if (r.item.kind == OutboxKind.handover && body is Map) {
      final text = await _editText('handover_summary'.tr, '${body['summary'] ?? ''}');
      if (text == null) return;
      await c.resend(r, body: {...body, 'summary': text});
      return;
    }
    await c.resend(r);
  }

  static Future<void> _discard(PatientController c, RejectedItem r) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('not_sent_delete_title'.tr),
        content: Text('not_sent_delete_body'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
          FilledButton(
            key: const Key('discard_confirm'),
            onPressed: () => Get.back(result: true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    if (ok ?? false) await c.discard(r);
  }

  static Future<String?> _editText(String label, String initial) {
    final ctl = TextEditingController(text: initial);
    return Get.dialog<String>(
      AlertDialog(
        title: Text(label),
        content: TextField(controller: ctl, maxLines: 8, maxLength: HandoverBody.maxSummary),
        actions: [
          TextButton(onPressed: () => Get.back<String>(), child: Text('cancel'.tr)),
          FilledButton(
            onPressed: () => Get.back(result: ctl.text.trim().isEmpty ? null : ctl.text.trim()),
            child: Text('send'.tr),
          ),
        ],
      ),
    ).whenComplete(ctl.dispose);
  }
}

/// Searchable list of medicines (Arabic and English names). Returns the chosen one.
Future<Medicine?> pickMedicine() => Get.bottomSheet<Medicine>(
  const _MedicineSheet(),
  isScrollControlled: true,
  backgroundColor: AppColors.surface,
);

class _MedicineSheet extends StatefulWidget {
  const _MedicineSheet();

  @override
  State<_MedicineSheet> createState() => _MedicineSheetState();
}

class _MedicineSheetState extends State<_MedicineSheet> {
  String _q = '';

  /// Lower case, and the Arabic alef forms folded together so أ إ آ ا all match.
  static String _fold(String v) => v.toLowerCase().replaceAll(RegExp('[أإآ]'), 'ا');

  @override
  Widget build(BuildContext context) {
    final crew = Get.find<CrewController>();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Padding(
          padding: EdgeInsets.fromLTRB(Space.screen, Space.lg, Space.screen, MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            children: [
              LabeledField(
                fieldKey: const Key('medicine_search'),
                label: 'medicine_search'.tr,
                onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              ),
              const SizedBox(height: Space.md),
              Expanded(
                child: Obx(() {
                  final all = crew.medicines;
                  bool match(String? v) => _fold(v ?? '').contains(_fold(_q));
                  final list = all.where((m) => _q.isEmpty || match(m.nameAr) || match(m.nameEn) || match(m.code)).toList();
                  if (all.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('medicines_empty'.tr, textAlign: TextAlign.center),
                          const SizedBox(height: Space.md),
                          AppButton(
                            label: 'retry'.tr,
                            expand: false,
                            variant: ButtonVariant.secondary,
                            onPressed: () => unawaited(crew.loadMedicines()),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final m = list[i];
                      final other = currentLang() == 'en' ? m.nameAr : m.nameEn;
                      return ListTile(
                        key: Key('medicine_${m.code}'),
                        title: Text(m.name(currentLang())),
                        subtitle: other == null ? null : Text(other),
                        onTap: () => Get.back(result: m),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.screen,
            Space.screen,
            96,
          ),
          children: [
            const NotSentList(),
            if (c.patients.isEmpty)
              EmptyView(
                icon: LucideIcons.user,
                title: 'no_patients_title'.tr,
                body: 'no_patients_body'.tr,
              ),
            for (final p in c.patients) ...[
            AppCard(
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
                        Text(
                          e.failed ? '${e.label.tr} · ${'entry_not_saved'.tr}' : e.label.tr,
                          style: e.failed ? t.bodySmall!.copyWith(color: AppColors.danger) : t.bodySmall,
                        ),
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
            ),
            const SizedBox(height: Space.lg),
            ],
          ],
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

/// Ignores a second tap on "Save" while the first one is still being processed, so a double tap
/// cannot queue the same entry twice.
class _SaveGuard {
  bool _running = false;

  Future<void> run(Future<void> Function() save) async {
    if (_running) return;
    _running = true;
    try {
      await save();
    } finally {
      _running = false;
    }
  }
}

class PatientFormView extends StatefulWidget {
  const PatientFormView({super.key});

  @override
  State<PatientFormView> createState() => _PatientFormViewState();
}

class _PatientFormViewState extends State<PatientFormView> {
  final _guard = _SaveGuard();
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
              onPressed: () => unawaited(_guard.run(_save)),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Shown when vitals were already recorded: a new save is a new reading, it never edits an old one.
class _VitalsAddedNote extends StatelessWidget {
  const _VitalsAddedNote();

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    child: Container(
      key: const Key('vitals_added_note'),
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(Space.controlRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, size: 20, color: AppColors.brandActive),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              'vitals_added_note'.tr,
              style: const TextStyle(color: AppColors.brandActive, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
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
  final _guard = _SaveGuard();
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
            if (c.hasVitals) ...[
              const _VitalsAddedNote(),
              const SizedBox(height: Space.lg),
            ],
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
              onPressed: () => unawaited(_guard.run(_save)),
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
  final _guard = _SaveGuard();
  final _name = TextEditingController();
  final _dose = TextEditingController();
  final _note = TextEditingController();
  String? _kind;
  String? _route;
  Medicine? _medicine;
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
      // A medicine is sent as its code; the server refuses anything not on its list.
      name: _kind == 'medicine' ? (_medicine?.code ?? '') : _name.text,
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
              onChanged: (v) => setState(() {
                _kind = v;
                _medicine = null;
              }),
              errorText: c.fieldErrors['kind'],
            ),
            const SizedBox(height: Space.lg),
            if (_kind == 'medicine')
              _MedicineField(
                medicine: _medicine,
                errorText: c.fieldErrors['name'],
                onPicked: (m) => setState(() => _medicine = m),
              )
            else
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
              onPressed: () => unawaited(_guard.run(_save)),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Read-only field that opens the medicine picker.
class _MedicineField extends StatelessWidget {
  const _MedicineField({required this.medicine, required this.onPicked, this.errorText});
  final Medicine? medicine;
  final ValueChanged<Medicine> onPicked;
  final String? errorText;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('medicine_name'.tr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      OutlinedButton.icon(
        key: const Key('t_medicine'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(Space.minTarget),
          alignment: AlignmentDirectional.centerStart,
        ),
        icon: const Icon(LucideIcons.pill, size: 18),
        label: Text(medicine?.name(currentLang()) ?? 'medicine_pick'.tr),
        onPressed: () async {
          final m = await pickMedicine();
          if (m != null) onPicked(m);
        },
      ),
      if (errorText != null) ...[
        const SizedBox(height: Space.xs),
        Text(errorText!, style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    ],
  );
}
