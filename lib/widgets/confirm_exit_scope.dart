import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class ConfirmExitScope extends StatelessWidget {
  final Widget child;
  final String title;
  final String message;

  const ConfirmExitScope({
    super.key,
    required this.child,
    this.title = 'Exit Precon Wellness?',
    this.message = 'Are you sure you want to exit the app?',
  });

  static Future<bool> showExitDialog(
    BuildContext context, {
    String? title,
    String? message,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title ?? 'Exit Precon Wellness?'),
        content: Text(
          message ?? 'Are you sure you want to exit the app?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary(isDark),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showExitDialog(
          context,
          title: title,
          message: message,
        );
        if (shouldExit) {
          await SystemNavigator.pop();
        }
      },
      child: child,
    );
  }
}
