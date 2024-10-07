import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// This class is used to handle screen responsiveness.
///
/// [isMobile], [isTablet] and [isDesktop] are used to determine the screen size.
class Responsive extends StatelessWidget {
  const Responsive({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
  });
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;

  // static final Size _size = MediaQueryData.fromWindow(WidgetsBinding.instance.window).size;

  // This size work fine on my design, maybe you need some customization depends on your design

  // This isMobile, isTablet, isDesktop helep us later
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 750;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width < 1100 && MediaQuery.of(context).size.width >= 750;

  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1100;

  static bool isStaticMobile = Get.width < 750;
  static bool isStaticTablet = Get.width < 1100 && Get.width >= 750;

  static bool isStaticDesktop = Get.width >= 1100;

  static Size designSize = isStaticMobile
      ? const Size(428, 926)
      : isStaticTablet
          ? const Size(597, 833)
          : const Size(1024, 833);

  static int intR(
    BuildContext context, {
    required int mobile,
    required int tablet,
    required int desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  static double doubleR(
    BuildContext context, {
    required double mobile,
    double? tablet,
    required double desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return desktop;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // If our width is more than 1100 then we consider it a desktop
    if (size.width >= 1100) {
      return desktop!;
    }
    // If width it less then 1100 and more then 750 we consider it as tablet
    else if (size.width >= 750 && tablet != null) {
      return tablet!;
    }
    // Or less then that we called it mobile
    else {
      return mobile!;
    }
  }
}



// responsive screen size

double screenheight (BuildContext context){ 
  return MediaQuery.of(context).size.height;}

double screenwidth (BuildContext context){ 
  return MediaQuery.of(context).size.width;}
