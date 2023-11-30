import 'dart:developer';

import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1100;
  static const double tabletLandscapeBreakpoint = 1024;

  const Responsive({
    Key? key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  }) : super(key: key);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isMobileLandscape(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint &&
          MediaQuery.of(context).size.width < tabletLandscapeBreakpoint &&
          MediaQuery.of(context).orientation == Orientation.landscape;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint &&
          MediaQuery.of(context).size.width < desktopBreakpoint &&
          MediaQuery.of(context).orientation == Orientation.portrait;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint &&
          MediaQuery.of(context).orientation != Orientation.portrait;

  @override
  Widget build(BuildContext context) {
    if (isDesktop(context)) {
      return desktop;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return mobile;
    }
  }
}
