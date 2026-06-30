import 'package:flutter/material.dart';
import 'package:focus_flow/l10n/app_localizations.dart';

extension TimeFormatterExtension on int {
  String toFormattedDuration(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (this == 0) return '0${l10n.secondSuffixShort}';
    int h = this ~/ 3600;
    int m = (this % 3600) ~/ 60;
    int s = this % 60;
    
    List<String> parts = [];
    if (h > 0) parts.add('$h${l10n.hourSuffixShort}');
    if (m > 0) parts.add('$m${l10n.minuteSuffixShort}');
    if (s > 0) parts.add('$s${l10n.secondSuffixShort}');
    
    return parts.join(' ');
  }
}
