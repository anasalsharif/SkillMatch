import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1100 && desktop != null) {
          return desktop!;
        } else if (constraints.maxWidth >= 650 && tablet != null) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
}

// Extension methods for responsive dimensions
extension ResponsiveExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  // Get responsive width (percentage of screen width)
  double responsiveWidth(double percentage) => screenWidth * percentage;

  // Get responsive height (percentage of screen height)
  double responsiveHeight(double percentage) => screenHeight * percentage;

  // Get responsive font size
  double responsiveFontSize(double baseSize) {
    if (ResponsiveLayout.isMobile(this)) {
      return baseSize;
    } else if (ResponsiveLayout.isTablet(this)) {
      return baseSize * 1.2;
    } else {
      return baseSize * 1.4;
    }
  }

  // Get responsive padding
  EdgeInsets get responsivePadding {
    if (ResponsiveLayout.isMobile(this)) {
      return const EdgeInsets.all(16.0);
    } else if (ResponsiveLayout.isTablet(this)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }
}
