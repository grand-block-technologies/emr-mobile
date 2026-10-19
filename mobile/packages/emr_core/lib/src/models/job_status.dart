/// Dispatch statuses in the order the server enforces:
///
/// ```
/// sent → confirmed → en_route → on_scene → leaving_scene → at_hospital → completed
///                                   └──────────→ completed  (treated at scene)
/// ```
enum JobStatus {
  sent('sent'),
  confirmed('confirmed'),
  enRoute('en_route'),
  onScene('on_scene'),
  leavingScene('leaving_scene'),
  atHospital('at_hospital'),
  completed('completed');

  const JobStatus(this.wire);
  final String wire;

  static JobStatus? fromWire(String? s) {
    for (final v in values) {
      if (v.wire == s) return v;
    }
    return null;
  }

  /// Steps the crew may press next. `sent → confirmed` goes through /confirm, not /status.
  List<JobStatus> get next => switch (this) {
        sent => const [confirmed],
        confirmed => const [enRoute],
        enRoute => const [onScene],
        onScene => const [leavingScene, completed],
        leavingScene => const [atHospital],
        atHospital => const [completed],
        completed => const [],
      };

  bool canMoveTo(JobStatus to) => next.contains(to);

  /// The one big button for this step (the "primary" next step).
  JobStatus? get primaryNext => next.isEmpty ? null : next.first;

  bool get isTravelling => this == enRoute || this == leavingScene;
  bool get isAtScene => this == onScene;
  bool get isClosed => this == completed;
}
