import 'dart:developer';

import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const Responsive({
    Key? key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  }) : super(key: key);

  // This isMobile, isTablet, isDesktop help us later
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650 &&
      MediaQuery.of(context).orientation == Orientation.portrait;

  static bool isMobileLandscape(BuildContext context) =>
      MediaQuery.of(context).size.width < 850 &&
      MediaQuery.of(context).orientation == Orientation.landscape;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width < 1100 &&
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).orientation == Orientation.portrait;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    // If our width is more than 1100 then we consider it a desktop
    log('size = $_size');

    if (_size.width >= 1100) {
      log("Size Desktop");
      return desktop;
    }
    // If width it less then 1100 and more then 850 we consider it as tablet
    else if (_size.width >= 650 && tablet != null) {
      log("Size Tablet");
      return tablet!;
    }
    // Or less then that we called it mobile
    else {
      log("Size Mobile");
      return mobile;
    }
  }
}
