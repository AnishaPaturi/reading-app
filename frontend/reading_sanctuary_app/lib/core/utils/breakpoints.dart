enum ScreenSize { mobile, tablet, desktop }

abstract final class Breakpoints {
  static const double mobile = 600;
  static const double desktop = 1024;

  static ScreenSize of(double width) {
    if (width < mobile) return ScreenSize.mobile;
    if (width < desktop) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }
}
