import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../theme/app_colors.dart';

class ThemeToggleButton extends StatelessWidget {
  final Color? color;
  const ThemeToggleButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDark(context);
        final currentMode = ThemeService.instance.themeMode;

        return Tooltip(
          message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(isDark),
                size: 20,
                color: color ?? AppColors.textSecondary(isDark),
              ),
            ),
            onPressed: () => ThemeService.instance.toggleTheme(context),
            onLongPress: () => _showThemePicker(context, currentMode, isDark),
          ),
        );
      },
    );
  }

  void _showThemePicker(BuildContext context, ThemeMode currentMode, bool isDark) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.border(isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(isDark),
                    ),
                  ),
                ),
              ),
              _option(
                ctx: ctx,
                icon: Icons.brightness_auto_rounded,
                label: 'System',
                selected: currentMode == ThemeMode.system,
                isDark: isDark,
                onTap: () => ThemeService.instance.setThemeMode(ThemeMode.system),
              ),
              _option(
                ctx: ctx,
                icon: Icons.light_mode_rounded,
                label: 'Light',
                selected: currentMode == ThemeMode.light,
                isDark: isDark,
                onTap: () => ThemeService.instance.setThemeMode(ThemeMode.light),
              ),
              _option(
                ctx: ctx,
                icon: Icons.dark_mode_rounded,
                label: 'Dark',
                selected: currentMode == ThemeMode.dark,
                isDark: isDark,
                onTap: () => ThemeService.instance.setThemeMode(ThemeMode.dark),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option({
    required BuildContext ctx,
    required IconData icon,
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: selected ? AppColors.brand(isDark) : AppColors.textSecondary(isDark),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? AppColors.brand(isDark) : AppColors.textPrimary(isDark),
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded, size: 18, color: AppColors.brand(isDark))
          : null,
      onTap: () {
        onTap();
        Navigator.pop(ctx);
      },
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
