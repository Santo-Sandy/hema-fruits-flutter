import 'package:flutter/widgets.dart';

class AppBreakpoints {
  AppBreakpoints._();

  static const double mobileMax = 767;
  static const double tabletMax = 1023;
  static const double desktopMin = 1024;

  static bool isMobile(double width) => width <= mobileMax;
  static bool isTablet(double width) => width > mobileMax && width < desktopMin;
  static bool isDesktop(double width) => width >= desktopMin;

  static bool isMobileContext(BuildContext context) {
    return isMobile(MediaQuery.sizeOf(context).width);
  }

  static bool isTabletContext(BuildContext context) {
    return isTablet(MediaQuery.sizeOf(context).width);
  }

  static bool isDesktopContext(BuildContext context) {
    return isDesktop(MediaQuery.sizeOf(context).width);
  }
}
