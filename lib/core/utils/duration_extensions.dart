extension DurationExtensions on Duration {
  String toShortPrettyString() {
    if (inSeconds < 60) return '${inSeconds}s';
    return '${inMinutes}m ${inSeconds % 60}s';
  }

  double calculateMoneyLost({double ratePerSecond = 0.20}) {
    return inSeconds * ratePerSecond;
  }
}
