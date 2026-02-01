enum Flavor {
  dev,
  pro,
}

class F {
  static late final Flavor appFlavor;

  static String get name => appFlavor.name;

  static String get title {
    switch (appFlavor) {
      case Flavor.dev:
        return 'FocusFlow Dev';
      case Flavor.pro:
        return 'FocusFlow';
    }
  }

}
