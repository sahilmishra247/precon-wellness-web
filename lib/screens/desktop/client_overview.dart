import 'package:flutter/material.dart';
import '../../widgets/ui.dart';
import '../../widgets/motion.dart';
import '../../models/appointment.dart';
import '../../models/client.dart';
import '../../models/exercise.dart';
import '../../models/food_item.dart';
import '../../models/meal_slot.dart';
import '../../models/note.dart';
import '../../models/progress_entry.dart';
import '../../services/appointment_service.dart';
import '../../services/wellness_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/url_helper.dart';
import '../../widgets/weight_chart.dart';

/// Two-column summary of one client.
/// Staff Overview tab: next session, today's meals and workout on the left;
/// weight numbers, chart and latest note on the right.
/// Client home ([clientHome]): today's plan first, with no weight numbers or
/// chart, so a slow week on the scale is not the first thing a client sees.
class ClientOverview extends StatefulWidget {
  final Client client;
  final bool isDark;

  /// The client's own home: greeting and today's plan, no weight figures.
  final bool clientHome;

  /// Opens the Progress section, e.g. to log a weight.
  final VoidCallback? onOpenProgress;
  final String progressActionLabel;

  const ClientOverview({
    super.key,
    required this.client,
    required this.isDark,
    this.clientHome = false,
    this.onOpenProgress,
    this.progressActionLabel = 'Open progress',
  });

  @override
  State<ClientOverview> createState() => _ClientOverviewState();
}

class _ClientOverviewState extends State<ClientOverview> {
  final WellnessService _wellness = WellnessService();
  final AppointmentService _appointments = AppointmentService();

  bool _isLoading = true;
  List<ProgressEntry> _entries = [];
  List<Appointment> _upcoming = [];
  List<Note> _notes = [];
  List<FoodItem> _food = [];
  List<Exercise> _exercises = [];
  List<MealSlot> _slots = [];

  static const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<List<T>> _safe<T>(Future<List<T>> f) => f.catchError((_) => <T>[]);

  Future<void> _load() async {
    final email = widget.client.email;
    final results = await Future.wait([
      _safe(_wellness.getProgressEntries(email)),
      _safe(_appointments.getAppointments(clientEmail: email)),
      _safe(_wellness.getNotes(email)),
      _safe(_wellness.getDietItems(email)),
      _safe(_wellness.getExercises(email)),
      _safe(_wellness.getMealSlots(email)),
    ]);
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _entries = (results[0] as List<ProgressEntry>)..sort((a, b) => a.date.compareTo(b.date));
      _upcoming = (results[1] as List<Appointment>).where((a) => a.appointmentDate.isAfter(now)).toList()
        ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
      _notes = (results[2] as List<Note>)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _food = results[3] as List<FoodItem>;
      _exercises = results[4] as List<Exercise>;
      _slots = (results[5] as List<MealSlot>)..sort(MealSlot.byTime);
      _isLoading = false;
    });
  }

  bool get _dark => widget.isDark;

  String _fmtDay(DateTime d) => '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
  String _fmtTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  String _fmtKg(double v) => '${v.toStringAsFixed(1)} kg';
  String _fmtAmount(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        final home = widget.clientHome;
        final main = home
            ? [_greeting(), _todaysMeals(), _workout()]
            : [_numbers(), _chart(), _latestNote()];
        final side = home
            ? [_nextSession(), _latestNote(), _progressPrompt()]
            : [_nextSession(), _todaysMeals(), _workout()];

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: home
                      ? [
                          Expanded(child: _stack(main)),
                          const SizedBox(width: 20),
                          // Line the side cards up with the first card under the greeting.
                          SizedBox(width: 340, child: Padding(padding: const EdgeInsets.only(top: 128), child: _stack(side))),
                        ]
                      : [
                          SizedBox(width: 340, child: _stack(side)),
                          const SizedBox(width: 20),
                          Expanded(child: _stack(main)),
                        ],
                )
              : _stack(home ? [main.first, ...side.take(1), ...main.skip(1), ...side.skip(1)] : [...side, ...main]),
        );
      }),
    );
  }

  Widget _stack(List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            FadeSlideIn(index: i, child: HoverLift(child: children[i])),
          ],
        ],
      );

  // ── Left column ──────────────────────────────────────────────────────────

  Widget _greeting() {
    final now = DateTime.now();
    final firstName = widget.client.fullName.split(' ').first;
    return HeroBanner(
      title: _fmtDay(now),
      subtitle: widget.client.goal.isNotEmpty
          ? "$firstName's plan for today · Goal: ${widget.client.goal}"
          : "$firstName's plan for today",
    );
  }

  Widget _nextSession() {
    final next = _upcoming.isNotEmpty ? _upcoming.first : null;
    if (next == null) {
      return _card(
        title: 'Next session',
        icon: Icons.calendar_month_outlined,
        child: _empty('No upcoming sessions booked'),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, Color(0xFFF08A5D)],
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.event_available_rounded, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text('Next session', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.9))),
        ]),
        const SizedBox(height: 10),
        Text('${_fmtDay(next.appointmentDate)}, ${_fmtTime(next.appointmentDate)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        if (next.notes.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(next.notes, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9))),
        ],
        if (next.meetingLink.isNotEmpty) ...[
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.accentInk()),
            onPressed: () => UrlHelper.openUrl(context, next.meetingLink),
            icon: const Icon(Icons.video_call_rounded, size: 18),
            label: const Text('Join call'),
          ),
        ],
        if (_upcoming.length > 1) ...[
          const SizedBox(height: 10),
          Text('${_upcoming.length - 1} more booked after this',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
        ],
      ]),
    );
  }

  Widget _todaysMeals() {
    final today = _dayKeys[DateTime.now().weekday - 1];
    final items = _food.where((f) {
      final day = f.dayOfWeek.toLowerCase();
      return day == 'all' || day == today;
    }).toList();

    final rows = <Widget>[];
    for (final slot in _slots) {
      final mealItems = items.where((f) => (f.mealType ?? '').toLowerCase() == slot.key).toList();
      if (mealItems.isEmpty) continue;
      rows.add(_listRow(
        slot.label,
        mealItems.map((f) => '${f.name} (${_fmtAmount(f.amount)} ${f.unit})').join(', '),
      ));
    }

    return _card(
      title: "Today's meals",
      icon: Icons.restaurant_outlined,
      child: rows.isEmpty
          ? _empty('No diet plan for today yet.')
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
    );
  }

  Widget _workout() {
    return _card(
      title: 'Workout plan',
      icon: Icons.fitness_center_outlined,
      trailing: _exercises.isEmpty ? null : _muted('${_exercises.length} ${_exercises.length == 1 ? 'exercise' : 'exercises'}'),
      child: _exercises.isEmpty
          ? _empty('No workout plan yet.')
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final e in _exercises.take(6)) _listRow(e.name, '${e.sets} × ${e.reps}', valueRight: true),
            ]),
    );
  }

  // ── Right column ─────────────────────────────────────────────────────────

  Widget _numbers() {
    final start = widget.client.weight;
    final current = _entries.isNotEmpty ? _entries.last.weight : start;
    final change = current - start;
    final h = widget.client.height / 100;
    final bmi = h > 0 ? current / (h * h) : 0.0;
    final changeColor = change == 0
        ? AppColors.textSecondary(_dark)
        : (change < 0 ? AppColors.success : AppColors.warning);

    return Row(children: [
      Expanded(child: _metric('Current weight', _fmtKg(current),
          _entries.isNotEmpty ? 'Logged ${_fmtDay(_entries.last.date)}' : 'From profile', area: AppColors.progress)),
      const SizedBox(width: 12),
      Expanded(child: _metric('Since start', '${change > 0 ? '+' : change < 0 ? '−' : ''}${_fmtKg(change.abs())}',
          'Started at ${_fmtKg(start)}', valueColor: changeColor, area: change > 0 ? AppColors.diet : AppColors.progress)),
      const SizedBox(width: 12),
      Expanded(child: _metric('BMI', bmi > 0 ? bmi.toStringAsFixed(1) : '—', '${widget.client.height.toInt()} cm', area: AppColors.workout)),
      const SizedBox(width: 12),
      Expanded(child: _metric('Age', '${widget.client.age} yrs',
          widget.client.gender.isNotEmpty ? widget.client.gender : '—', area: AppColors.notes)),
    ]);
  }

  Widget _chart() {
    return _card(
      title: 'Weight history',
      icon: Icons.show_chart_rounded,
      trailing: widget.onOpenProgress == null
          ? null
          : TextButton.icon(
              onPressed: widget.onOpenProgress,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(widget.progressActionLabel),
            ),
      child: _entries.isEmpty
          ? _empty('No weights logged yet.')
          : WeightChart(entries: _entries, isDark: _dark, baseline: widget.client.weight > 0 ? widget.client.weight : null),
    );
  }

  Widget _latestNote() {
    final note = _notes.isNotEmpty ? _notes.first : null;
    return _card(
      title: widget.clientHome ? 'From your care team' : 'Latest consultation note',
      icon: Icons.note_alt_outlined,
      trailing: note == null ? null : _muted(_fmtDay(note.createdAt)),
      child: note == null
          ? _empty('No notes yet.')
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(note.text, maxLines: 6, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.textPrimary(_dark))),
              if ((note.authorName ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                _muted('By ${note.authorName}'),
              ],
            ]),
    );
  }

  /// Client home only: an invitation to weigh in, with no figures.
  Widget _progressPrompt() {
    return _card(
      title: 'Progress',
      icon: Icons.monitor_weight_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Weigh in once a week, at the same time of day.',
            style: TextStyle(fontSize: 13, color: AppColors.textPrimary(_dark))),
        if (widget.onOpenProgress != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: widget.onOpenProgress,
            icon: const Icon(Icons.monitor_weight_outlined, size: 16),
            label: Text(widget.progressActionLabel),
          ),
        ],
      ]),
    );
  }

  // ── Building blocks ──────────────────────────────────────────────────────

  Widget _card({required String title, required Widget child, Widget? trailing, IconData? icon}) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 36,
          child: Row(children: [
            if (icon != null) ...[IconChip(icon, size: 34), const SizedBox(width: 12)],
            Expanded(child: Text(title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary(_dark)))),
            ?trailing,
          ]),
        ),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }

  Widget _metric(String label, String value, String sub, {Color? valueColor, AreaColor area = AppColors.neutral}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: area.tint,
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        border: Border.all(color: area.color.withValues(alpha: 0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: area.ink)),
        const SizedBox(height: 8),
        CountUpText(value, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 0,
                color: valueColor ?? AppColors.textPrimary(_dark))),
        const SizedBox(height: 2),
        Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary(_dark))),
      ]),
    );
  }

  Widget _listRow(String label, String value, {bool valueRight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border(_dark).withValues(alpha: 0.6)))),
      child: valueRight
          ? Row(children: [
              Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(_dark)))),
              _muted(value),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label(label),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(_dark))),
            ]),
    );
  }

  Widget _label(String s, {Color? color}) => Text(s,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color ?? AppColors.textSecondary(_dark)));

  Widget _muted(String s) => Text(s, style: TextStyle(fontSize: 12, color: AppColors.textSecondary(_dark)));

  Widget _empty(String s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(s, style: TextStyle(fontSize: 13, color: AppColors.textSecondary(_dark))),
      );
}
