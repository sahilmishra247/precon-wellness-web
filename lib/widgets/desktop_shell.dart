import 'package:flutter/material.dart';
import '../services/session_manager.dart';
import '../screens/login_screen.dart';
import '../theme/app_colors.dart';
import 'theme_toggle_button.dart';

/// One entry in the desktop icon rail.
class RailDestination {
  final IconData icon;
  final String label;
  const RailDestination(this.icon, this.label);
}

/// Slim dark navigation bar on the left of the desktop layout.
/// Icons only; each shows its name on hover.
class IconRail extends StatelessWidget {
  final List<RailDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool isDark;

  const IconRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      color: AppColors.rail(isDark),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppColors.radiusMedium),
            ),
            padding: const EdgeInsets.all(5),
            child: Image.asset(
              'assets/images/logo.png',
              errorBuilder: (_, _, _) => const Icon(Icons.spa_outlined, color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < destinations.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _railButton(destinations[i], i == selectedIndex, () => onSelected(i)),
            ),
          const Spacer(),
          const ThemeToggleButton(color: AppColors.railInk),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded, color: AppColors.railInk, size: 20),
            onPressed: () => confirmAndLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _railButton(RailDestination d, bool selected, VoidCallback onTap) {
    return Tooltip(
      message: d.label,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 300),
      child: Semantics(
        button: true,
        selected: selected,
        label: d.label,
        child: Material(
          color: selected ? AppColors.railActive : Colors.transparent,
          borderRadius: BorderRadius.circular(AppColors.radiusMedium),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppColors.radiusMedium),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(d.icon, size: 21, color: selected ? Colors.white : AppColors.railInk),
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks to confirm, clears the session and returns to the login screen.
Future<void> confirmAndLogout(BuildContext context) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('Are you sure you want to log out of your account?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );
  if (confirm == true && context.mounted) {
    await SessionManager.clear();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

/// Hosts an existing full-page screen inside a pane of the desktop layout.
/// Pages the screen opens stay inside the pane, so the rail and client list
/// remain visible. Give it a key that changes when [child] should be replaced.
class PaneNavigator extends StatelessWidget {
  final Widget child;
  const PaneNavigator({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DesktopPaneScope(
      child: ClipRect(
        child: Navigator(
          onGenerateInitialRoutes: (_, _) => [MaterialPageRoute(builder: (_) => child)],
        ),
      ),
    );
  }
}

/// True when a client (not staff) is signed in, for wording screens to them.
bool get viewerIsClient => SessionManager.role == 'client';

/// Present above every screen hosted in a [PaneNavigator]. Screens check
/// [DesktopPaneScope.of] to drop their phone app bar and floating button and
/// use the wide layout instead.
class DesktopPaneScope extends InheritedWidget {
  const DesktopPaneScope({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DesktopPaneScope>() != null;

  @override
  bool updateShouldNotify(DesktopPaneScope oldWidget) => false;
}

/// Title row at the top of a screen inside a desktop pane, with the screen's
/// actions on the right (where the phone layout has a floating button).
class PaneToolbar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const PaneToolbar({super.key, required this.title, this.subtitle, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark))),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark))),
                ],
              ],
            ),
          ),
          for (final a in actions) ...[const SizedBox(width: 8), a],
        ],
      ),
    );
  }
}

/// One row of a [PaneTable]. [actions] (edit, delete...) show on hover.
class PaneTableRow {
  final List<Widget> cells;
  final VoidCallback? onTap;
  final List<Widget> actions;
  const PaneTableRow({required this.cells, this.onTap, this.actions = const []});
}

/// A bordered table for lists inside a desktop pane: a header row, then one
/// row per item. [flex] gives each column's share of the width.
class PaneTable extends StatelessWidget {
  final List<String> columns;
  final List<int> flex;
  final List<PaneTableRow> rows;
  final String emptyText;

  const PaneTable({
    super.key,
    required this.columns,
    required this.flex,
    required this.rows,
    this.emptyText = 'Nothing here yet',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasActions = rows.any((r) => r.actions.isNotEmpty);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.bg(isDark),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              for (var i = 0; i < columns.length; i++)
                Expanded(
                  flex: flex[i],
                  child: Text(
                    columns[i],
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary(isDark)),
                  ),
                ),
              if (hasActions) const SizedBox(width: 88),
            ]),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(emptyText, style: TextStyle(fontSize: 14, color: AppColors.textSecondary(isDark))),
            ),
          for (final row in rows)
            _PaneTableRowView(row: row, flex: flex, isDark: isDark, reserveActions: hasActions),
        ],
      ),
    );
  }
}

class _PaneTableRowView extends StatefulWidget {
  final PaneTableRow row;
  final List<int> flex;
  final bool isDark;
  final bool reserveActions;
  const _PaneTableRowView({required this.row, required this.flex, required this.isDark, required this.reserveActions});

  @override
  State<_PaneTableRowView> createState() => _PaneTableRowViewState();
}

class _PaneTableRowViewState extends State<_PaneTableRowView> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: _hover ? AppColors.bg(widget.isDark) : Colors.transparent,
        child: InkWell(
          onTap: row.onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border(widget.isDark)))),
            child: Row(children: [
              for (var i = 0; i < row.cells.length; i++)
                Expanded(flex: widget.flex[i], child: row.cells[i]),
              if (widget.reserveActions)
                SizedBox(
                  width: 88,
                  child: Opacity(
                    // Kept in the tree (not just hidden) so keyboard users can reach them.
                    opacity: _hover ? 1 : 0.35,
                    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: row.actions),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Small icon button used for row actions in a [PaneTable].
class RowAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;
  const RowAction({super.key, required this.icon, required this.tooltip, required this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, color: color ?? AppColors.textSecondary(isDark)),
    );
  }
}

/// Body text style for a [PaneTable] cell.
TextStyle paneCellStyle(bool isDark, {bool strong = false, bool muted = false}) => TextStyle(
      fontSize: 14,
      fontWeight: strong ? FontWeight.w500 : FontWeight.w400,
      color: muted ? AppColors.textSecondary(isDark) : AppColors.textPrimary(isDark),
    );
