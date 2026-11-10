import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/health_tag.dart';
import '../services/health_service.dart';
import '../services/theme_service.dart';
import '../theme/app_colors.dart';
import '../utils/error_messages.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

Color _tagInk(HealthSeverity s, bool isDark) {
  switch (s) {
    case HealthSeverity.critical:
      return AppColors.accentInk(isDark);
    case HealthSeverity.care:
      return AppColors.cautionInk(isDark);
    case HealthSeverity.info:
      return AppColors.textSecondary(isDark);
  }
}

Color _tagFill(HealthSeverity s, bool isDark) {
  switch (s) {
    case HealthSeverity.critical:
      return AppColors.accentMuted(isDark);
    case HealthSeverity.care:
      return AppColors.cautionMuted(isDark);
    case HealthSeverity.info:
      return AppColors.neutralMuted(isDark);
  }
}

/// A pill showing one condition or allergy, coloured by its level.
class HealthTagChip extends StatelessWidget {
  final String label;
  final HealthSeverity severity;
  final bool isDark;
  final bool small;
  final Color? fill;

  const HealthTagChip({
    super.key,
    required this.label,
    required this.severity,
    required this.isDark,
    this.small = false,
    this.fill,
  });

  @override
  Widget build(BuildContext context) {
    final ink = _tagInk(severity, isDark);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 7 : 9, vertical: small ? 3 : 4),
      decoration: BoxDecoration(
        color: fill ?? _tagFill(severity, isDark),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (severity == HealthSeverity.critical) ...[
          Icon(Icons.warning_amber_rounded, size: small ? 11 : 13, color: ink),
          const SizedBox(width: 3),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: small ? 11 : 12, fontWeight: FontWeight.w600, color: ink, height: 1.2),
          ),
        ),
      ]),
    );
  }
}

/// Tags in a wrapping row, most serious first. With [max], extra tags collapse into "+N".
class HealthTagRow extends StatelessWidget {
  final List<HealthTag> tags;
  final bool isDark;
  final int? max;
  final bool small;
  final Color? fill;

  const HealthTagRow({super.key, required this.tags, required this.isDark, this.max, this.small = false, this.fill});

  @override
  Widget build(BuildContext context) {
    final shown = max != null && tags.length > max! ? tags.take(max!).toList() : tags;
    final hidden = tags.length - shown.length;
    return Wrap(
      spacing: small ? 4 : 6,
      runSpacing: small ? 4 : 6,
      children: [
        for (final t in shown) HealthTagChip(label: t.label, severity: t.severity, isDark: isDark, small: small, fill: fill),
        if (hidden > 0)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text('+$hidden',
                style: TextStyle(fontSize: small ? 11 : 12, fontWeight: FontWeight.w600, color: AppColors.textMuted(isDark))),
          ),
      ],
    );
  }
}

/// Card listing a client's conditions and allergies, with add, edit and remove.
/// Staff see it as "Health notes"; clients see it as "My health info".
class HealthInfoCard extends StatefulWidget {
  final Client client;
  final bool isDark;
  final bool isStaff;

  /// Called with the new list after anything is added, edited or removed.
  final ValueChanged<List<HealthTag>>? onChanged;

  const HealthInfoCard({
    super.key,
    required this.client,
    required this.isDark,
    required this.isStaff,
    this.onChanged,
  });

  @override
  State<HealthInfoCard> createState() => _HealthInfoCardState();
}

class _HealthInfoCardState extends State<HealthInfoCard> {
  final HealthService _health = HealthService();
  List<HealthTag> _tags = [];
  bool _loading = true;
  bool _failed = false;

  bool get _dark => widget.isDark;

  @override
  void initState() {
    super.initState();
    _tags = widget.client.healthTags;
    _load();
  }

  Future<void> _load() async {
    try {
      final tags = await _health.getTags(widget.client.email);
      if (!mounted) return;
      widget.client.healthTags = tags;
      setState(() {
        _tags = tags;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _afterChange(bool? changed) async {
    if (changed != true) return;
    await _load();
    widget.onChanged?.call(_tags);
  }

  Future<void> _add() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => AddHealthInfoDialog(client: widget.client, isStaff: widget.isStaff, existing: _tags),
    );
    await _afterChange(changed);
  }

  Future<void> _open(HealthTag tag) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => HealthTagDialog(tag: tag, isStaff: widget.isStaff, clientName: widget.client.fullName),
    );
    await _afterChange(changed);
  }

  String _byLine(HealthTag t) {
    final who = t.addedByClient
        ? (widget.isStaff ? widget.client.fullName.split(' ').first : 'you')
        : (t.addedByName.isNotEmpty ? t.addedByName : 'staff');
    final d = t.createdAt.toLocal();
    return 'Added by $who · ${d.day} ${_months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isStaff ? 'Health notes' : 'My health info';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
      decoration: BoxDecoration(
        color: AppColors.surface(_dark),
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        border: Border.all(color: AppColors.border(_dark)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Text(title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(_dark))),
          ),
          TextButton.icon(
            onPressed: _loading ? null : _add,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ]),
        Padding(padding: const EdgeInsets.only(right: 8), child: _body()),
      ]),
    );
  }

  Widget _body() {
    if (_loading && _tags.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (_failed && _tags.isEmpty) {
      return Text("Couldn't load health info.", style: TextStyle(fontSize: 13, color: AppColors.textSecondary(_dark)));
    }
    if (_tags.isEmpty) {
      return Text(
        widget.isStaff
            ? 'No conditions or allergies recorded.'
            : 'Optional. Add any medical conditions or allergies so your coach and dietician can plan safely.',
        style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary(_dark)),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < _tags.length; i++) ...[
        if (i > 0) Divider(height: 17, color: AppColors.border(_dark).withValues(alpha: 0.6)),
        InkWell(
          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
          onTap: () => _open(_tags[i]),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              HealthTagChip(label: _tags[i].label, severity: _tags[i].severity, isDark: _dark),
              if (_tags[i].note.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(_tags[i].note, style: TextStyle(fontSize: 13, height: 1.35, color: AppColors.textPrimary(_dark))),
              ],
              const SizedBox(height: 3),
              Text(_byLine(_tags[i]), style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(_dark))),
            ]),
          ),
        ),
      ],
    ]);
  }
}

/// Strip shown above a plan editor so staff keep a client's conditions in mind.
class HealthReminderStrip extends StatefulWidget {
  final Client client;
  final String title;
  final EdgeInsets margin;

  const HealthReminderStrip({
    super.key,
    required this.client,
    required this.title,
    this.margin = const EdgeInsets.fromLTRB(16, 12, 16, 0),
  });

  @override
  State<HealthReminderStrip> createState() => _HealthReminderStripState();
}

class _HealthReminderStripState extends State<HealthReminderStrip> {
  List<HealthTag> _tags = [];

  @override
  void initState() {
    super.initState();
    _tags = widget.client.healthTags;
    HealthService().getTags(widget.client.email).then((tags) {
      widget.client.healthTags = tags;
      if (mounted) setState(() => _tags = tags);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    if (_tags.isEmpty) return const SizedBox.shrink();
    final isDark = ThemeService.instance.isDark(context);
    return Container(
      margin: widget.margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cautionMuted(isDark),
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(widget.title,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark))),
          HealthTagRow(tags: _tags, isDark: isDark, fill: AppColors.surface(isDark)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Dialogs
// -----------------------------------------------------------------------------

/// Picker for adding conditions and allergies: tap presets, or type something else.
class AddHealthInfoDialog extends StatefulWidget {
  final Client client;
  final bool isStaff;
  final List<HealthTag> existing;

  const AddHealthInfoDialog({super.key, required this.client, required this.isStaff, required this.existing});

  @override
  State<AddHealthInfoDialog> createState() => _AddHealthInfoDialogState();
}

class _AddHealthInfoDialogState extends State<AddHealthInfoDialog> {
  final HealthService _health = HealthService();
  final _customController = TextEditingController();
  List<HealthPreset> _presets = [];
  final Set<String> _picked = {};
  HealthKind _customKind = HealthKind.condition;
  HealthSeverity _customSeverity = HealthSeverity.care;
  bool _saveAsPreset = false;
  bool _consent = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _needsConsent => !widget.isStaff && widget.client.healthConsentAt == null;

  @override
  void initState() {
    super.initState();
    _health.getPresets().then((p) {
      if (mounted) setState(() { _presets = p; _loading = false; });
    }).catchError((Object e) {
      if (mounted) setState(() { _loading = false; _error = describeError(e); });
    });
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  bool _alreadyAdded(String label) => widget.existing.any((t) => t.label.toLowerCase() == label.toLowerCase());

  Future<void> _save() async {
    final custom = _customController.text.trim();
    if (_picked.isEmpty && custom.isEmpty) {
      setState(() => _error = 'Pick at least one, or type your own.');
      return;
    }
    if (_needsConsent && !_consent) {
      setState(() => _error = 'Please tick the box to share this with your team.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      for (final p in _presets.where((p) => _picked.contains(p.key))) {
        await _health.addTag(
          clientEmail: widget.client.email,
          kind: p.kind,
          label: p.label,
          preset: p.key,
          consent: _consent,
        );
      }
      if (custom.isNotEmpty && !_alreadyAdded(custom)) {
        var presetKey = '';
        if (widget.isStaff && _saveAsPreset) {
          final preset = await _health.createPreset(kind: _customKind, label: custom, severity: _customSeverity);
          presetKey = preset.key;
        }
        await _health.addTag(
          clientEmail: widget.client.email,
          kind: _customKind,
          label: custom,
          preset: presetKey,
          severity: widget.isStaff ? _customSeverity : null,
          consent: _consent,
        );
      }
      if (_needsConsent) widget.client.healthConsentAt = DateTime.now();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = describeError(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDark(context);
    final subtitle = widget.isStaff
        ? 'For ${widget.client.fullName}. Tap a tag afterwards to change its level.'
        : 'Optional. Only you and your PreCon team can see this.';

    return Dialog(
      backgroundColor: AppColors.surface(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusXL)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Add health info',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary(isDark))),
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary(isDark))),
            const SizedBox(height: 14),
            Flexible(
              child: _loading
                  ? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                  : SingleChildScrollView(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        for (final kind in HealthKind.values) ...[
                          _groupLabel(kind.pluralLabel, isDark),
                          Wrap(spacing: 6, runSpacing: 6, children: [
                            for (final p in _presets.where((p) => p.kind == kind && !_alreadyAdded(p.label)))
                              FilterChip(
                                label: Text(p.label),
                                selected: _picked.contains(p.key),
                                showCheckmark: true,
                                visualDensity: VisualDensity.compact,
                                onSelected: (on) => setState(() => on ? _picked.add(p.key) : _picked.remove(p.key)),
                              ),
                          ]),
                          const SizedBox(height: 14),
                        ],
                        _groupLabel('Something else', isDark),
                        Row(children: [
                          Expanded(
                            child: TextField(
                              controller: _customController,
                              decoration: const InputDecoration(hintText: 'e.g. Gout, or sesame allergy', isDense: true),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<HealthKind>(
                            value: _customKind,
                            underline: const SizedBox.shrink(),
                            items: const [
                              DropdownMenuItem(value: HealthKind.condition, child: Text('Condition')),
                              DropdownMenuItem(value: HealthKind.allergy, child: Text('Allergy')),
                            ],
                            onChanged: (k) => setState(() => _customKind = k ?? HealthKind.condition),
                          ),
                        ]),
                        if (widget.isStaff && _customController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          SeverityPicker(value: _customSeverity, onChanged: (s) => setState(() => _customSeverity = s)),
                          CheckboxListTile(
                            value: _saveAsPreset,
                            onChanged: (v) => setState(() => _saveAsPreset = v ?? false),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text('Also add it to the preset list for everyone',
                                style: TextStyle(fontSize: 13, color: AppColors.textPrimary(isDark))),
                          ),
                        ],
                        if (_needsConsent) ...[
                          const SizedBox(height: 6),
                          CheckboxListTile(
                            value: _consent,
                            onChanged: (v) => setState(() => _consent = v ?? false),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              'I agree to share this with my coach and dietician so they can plan safely. '
                              'This is a note for the team, not a medical record.',
                              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary(isDark)),
                            ),
                          ),
                        ],
                      ]),
                    ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.error)),
            ],
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _saving || _loading ? null : _save,
                child: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _groupLabel(String text, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(text.toUpperCase(),
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: AppColors.textMuted(isDark))),
      );
}

/// Three-way level choice. Staff only.
class SeverityPicker extends StatelessWidget {
  final HealthSeverity value;
  final ValueChanged<HealthSeverity> onChanged;

  const SeverityPicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<HealthSeverity>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        for (final s in [HealthSeverity.info, HealthSeverity.care, HealthSeverity.critical])
          ButtonSegment(value: s, label: Text(s.label)),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// Detail of one tag: note, level (staff only) and remove.
class HealthTagDialog extends StatefulWidget {
  final HealthTag tag;
  final bool isStaff;
  final String clientName;

  const HealthTagDialog({super.key, required this.tag, required this.isStaff, required this.clientName});

  @override
  State<HealthTagDialog> createState() => _HealthTagDialogState();
}

class _HealthTagDialogState extends State<HealthTagDialog> {
  final HealthService _health = HealthService();
  late final TextEditingController _note = TextEditingController(text: widget.tag.note);
  late HealthSeverity _severity = widget.tag.severity;
  bool _saving = false;
  bool _confirmRemove = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() { _saving = true; _error = null; });
    try {
      await action();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = describeError(e); });
    }
  }

  void _save() => _run(() => _health.updateTag(
        id: widget.tag.id,
        note: _note.text,
        severity: widget.isStaff && _severity != widget.tag.severity ? _severity : null,
      ));

  void _remove() => _run(() => _health.removeTag(widget.tag.id));

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDark(context);
    final t = widget.tag;
    final kind = t.kind == HealthKind.allergy ? 'Allergy' : 'Condition';
    return Dialog(
      backgroundColor: AppColors.surface(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusXL)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Align(alignment: Alignment.centerLeft, child: HealthTagChip(label: t.label, severity: _severity, isDark: isDark)),
            const SizedBox(height: 6),
            Text(widget.isStaff ? '$kind · ${widget.clientName}' : kind,
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary(isDark))),
            const SizedBox(height: 16),
            if (widget.isStaff) ...[
              Text('How careful should staff be?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary(isDark))),
              const SizedBox(height: 6),
              SeverityPicker(value: _severity, onChanged: (s) => setState(() => _severity = s)),
              const SizedBox(height: 16),
            ] else ...[
              Text('Level: ${t.severity.label}. Your coach or dietician sets this.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary(isDark))),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Details (optional)',
                hintText: widget.isStaff ? 'e.g. Carries an EpiPen. Avoid groundnut oil.' : 'e.g. Since 2021, on Metformin',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.error)),
            ],
            const SizedBox(height: 16),
            Row(children: [
              if (_confirmRemove)
                TextButton(
                  onPressed: _saving ? null : _remove,
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: Text('Yes, remove ${t.label}'),
                )
              else
                TextButton(
                  onPressed: _saving ? null : () => setState(() => _confirmRemove = true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.accentInk(isDark)),
                  child: const Text('Remove'),
                ),
              const Spacer(),
              TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
              const SizedBox(width: 8),
              FilledButton(onPressed: _saving ? null : _save, child: const Text('Save')),
            ]),
          ]),
        ),
      ),
    );
  }
}
