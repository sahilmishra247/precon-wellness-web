// Shared date and number formats, so every screen writes them the same way.

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "Mon 26 Oct"
String fmtDay(DateTime d) => '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

/// "26 Oct 2026"
String fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// "11:00"
String fmtTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// "Mon 26 Oct, 11:00"
String fmtDayTime(DateTime d) => '${fmtDay(d)}, ${fmtTime(d)}';

/// "60" rather than "60.0"; keeps real decimals ("1.5").
String fmtAmount(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

/// "73.2 kg"
String fmtKg(double v) => '${v.toStringAsFixed(1)} kg';
