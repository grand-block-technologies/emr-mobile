import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/crew_repository.dart';

/// Jobs the crew member was on, newest first, from any phone (`GET /crew/jobs`).
/// Offline it shows the last first page it loaded.
class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  CrewRepository get _repo => Get.find<CrewRepository>();
  final _jobs = <CrewPastJob>[];
  int _page = 0;
  bool _hasNext = false;
  bool _loading = true;
  bool _offline = false;
  ApiError? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load({bool more = false}) async {
    setState(() => _loading = !more);
    try {
      final p = await _repo.pastJobs(page: more ? _page + 1 : 0);
      setState(() {
        if (!more) _jobs.clear();
        _jobs.addAll(p.content);
        _page = p.page;
        _hasNext = p.hasNext;
        _offline = false;
        _error = null;
      });
    } on Object catch (e) {
      final err = ApiError.of(e);
      if (more) {
        showToast(err.message(currentLang()));
      } else {
        final cached = await _repo.cachedPastJobs();
        setState(() {
          _jobs
            ..clear()
            ..addAll(cached);
          _hasNext = false;
          _offline = cached.isNotEmpty;
          _error = cached.isEmpty ? err : null;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('history_title'.tr)),
    body: SafeArea(
      top: false,
      child: Builder(
        builder: (context) {
          if (_loading) return const LoadingView();
          if (_error != null) return ErrorView(error: _error!, onRetry: _load);
          if (_jobs.isEmpty) {
            return EmptyView(
              icon: LucideIcons.history,
              title: 'history_empty_title'.tr,
              body: 'history_empty_body'.tr,
            );
          }
          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(Space.screen),
              children: [
                if (_offline) ...[
                  Row(
                    children: [
                      const Icon(LucideIcons.wifiOff, size: 16, color: AppColors.warning),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Text(
                          'history_offline'.tr,
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.md),
                ],
                for (final j in _jobs) ...[
                  _HistoryCard(j),
                  const SizedBox(height: Space.md),
                ],
                if (_hasNext)
                  AppButton(
                    key: const Key('history_more'),
                    label: 'load_more'.tr,
                    variant: ButtonVariant.secondary,
                    onPressed: () => unawaited(_load(more: true)),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

/// The closing reason in words; an unknown code is shown as it is.
String closingReasonLabel(String code) {
  final key = 'reason_$code';
  final text = key.tr;
  return text == key ? code.replaceAll('_', ' ') : text;
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard(this.j);
  final CrewPastJob j;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = Priority.fromCode(j.priority);
    final lang = currentLang();
    final when = j.completedAt ?? j.sentAt;
    final (label, tone, icon) = j.cancelled
        ? ('history_cancelled'.tr, Tone.warning, LucideIcons.circleX)
        : j.closingReason == null
        ? ('history_completed'.tr, Tone.done, LucideIcons.circleCheck)
        : (
            closingReasonLabel(j.closingReason!),
            j.closingReason == 'taken_to_hospital' ? Tone.done : Tone.info,
            j.closingReason == 'taken_to_hospital' ? LucideIcons.hospital : LucideIcons.circleCheck,
          );
    return AppCard(
      key: Key('history_${j.dispatchId}'),
      stripe: p?.fill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (j.caseNumber != null)
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: LtrText(j.caseNumber!, style: t.labelMedium!.copyWith(color: AppColors.inkMuted)),
                  ),
                )
              else
                const Spacer(),
              if (when != null) Text(SudanTime.dateTime(when, lang), style: t.bodySmall),
            ],
          ),
          if (j.complaint != null) ...[
            const SizedBox(height: Space.xs),
            Text(j.complaint!, style: t.titleMedium),
          ],
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.xs,
            children: [
              if (p != null) PriorityPill(p),
              StatusChip(label: label, tone: tone, icon: icon),
            ],
          ),
          if (j.hospital(lang) != null || j.plateNumber != null) ...[
            const SizedBox(height: Space.sm),
            if (j.hospital(lang) != null)
              InfoRow(icon: LucideIcons.hospital, label: 'destination'.tr, text: j.hospital(lang)!),
            if (j.plateNumber != null) ...[
              const SizedBox(height: Space.xs),
              InfoRow(icon: LucideIcons.ambulance, label: 'ambulance'.tr, text: j.plateNumber!),
            ],
          ],
        ],
      ),
    );
  }
}
