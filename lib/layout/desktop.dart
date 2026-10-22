import 'package:flutter/widgets.dart';

/// Windows at least this wide get the desktop split-view layout.
/// Phones and narrow browser windows keep the mobile layout.
const double kDesktopBreakpoint = 1000;

bool isDesktopLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;
