import 'package:flutter/material.dart';
import '../layout/desktop.dart';
import '../theme/app_colors.dart';

/// Sign-in style screens on wide windows: a brand panel on the left and the
/// screen itself on the right. Narrow windows and phones get [child] as is.
class AuthSplitLayout extends StatelessWidget {
  final Widget child;
  const AuthSplitLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!isDesktopLayout(context)) return child;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _BrandPanel(isDark: isDark)),
        Expanded(child: child),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  final bool isDark;
  const _BrandPanel({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.rail(isDark),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(64, 56, 64, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppColors.radiusLarge),
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    errorBuilder: (_, _, _) => const Icon(Icons.spa_outlined, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Precon Wellness',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -0.3),
                ),
              ],
            ),
            const Spacer(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your care team, your plan, one place.',
                    style: TextStyle(
                      fontSize: 40,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.8,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Meals, workouts, sessions and notes from your coach and dietician, kept together.',
                    style: TextStyle(fontSize: 17, height: 1.55, color: AppColors.railInk),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              'Need help signing in? Contact your coach.',
              style: TextStyle(fontSize: 13, color: AppColors.railInk.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
