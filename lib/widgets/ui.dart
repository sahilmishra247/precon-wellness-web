import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Rounded square with a tinted fill and a coloured icon, the main way an area
/// (diet, workout, progress…) shows its colour.
class IconChip extends StatelessWidget {
  final IconData icon;
  final AreaColor? area;
  final double size;

  const IconChip(this.icon, {super.key, this.area, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final a = area ?? AppColors.areaForIcon(icon);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: a.tint, borderRadius: BorderRadius.circular(size * 0.32)),
      child: Icon(icon, size: size * 0.5, color: a.ink),
    );
  }
}

/// White card with a soft navy shadow and a hairline border.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.color, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface(),
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        border: Border.all(color: borderColor ?? AppColors.lightBorderSubtle),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );
  }
}

/// Circle with a person's initials, coloured from their name.
class PersonAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const PersonAvatar(this.name, {super.key, this.radius = 18});

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final a = AppColors.avatarFor(name);
    return CircleAvatar(
      radius: radius,
      backgroundColor: a.tint,
      child: Text(
        initials(name),
        style: TextStyle(fontSize: radius * 0.72, fontWeight: FontWeight.w700, color: a.ink),
      ),
    );
  }
}

/// Navy banner with soft leaf-green rings, used at the top of home screens.
class HeroBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const HeroBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 24),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppColors.radiusXL),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.navy, AppColors.navyDeep],
          ),
        ),
        child: Stack(children: [
          const Positioned(right: -40, top: -50, child: DecorRing(size: 200)),
          const Positioned(right: 70, bottom: -70, child: DecorRing(size: 140)),
          Padding(
            padding: padding,
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(subtitle!, style: const TextStyle(fontSize: 14, color: AppColors.railInk, height: 1.4)),
                  ],
                ]),
              ),
              if (trailing != null) ...[const SizedBox(width: 16), trailing!],
            ]),
          ),
        ]),
      ),
    );
  }
}

class DecorRing extends StatelessWidget {
  final double size;
  const DecorRing({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.leaf.withValues(alpha: 0.28), width: math.max(10, size / 9)),
      ),
    );
  }
}
