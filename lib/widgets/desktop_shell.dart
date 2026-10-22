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
    return ClipRect(
      child: Navigator(
        onGenerateInitialRoutes: (_, _) => [MaterialPageRoute(builder: (_) => child)],
      ),
    );
  }
}
