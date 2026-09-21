import 'package:flutter/material.dart';
import 'package:focus_flow/shared/theme/app_colors.dart';
import 'package:focus_flow/shared/theme/app_text_styles.dart';
import 'package:focus_flow/features/focus_mode/presentation/models/focus_state.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import '../components/language_tile.dart';

class LanguageMenuView extends StatelessWidget {
  final FocusState state;
  final VoidCallback onBack;
  final Function(String) onSelectLanguage;

  const LanguageMenuView({
    super.key,
    required this.state,
    required this.onBack,
    required this.onSelectLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textSecondary),
              onPressed: onBack,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 48.0),
                  child: Text(
                    l10n.languageMenuTitle,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            l10n.selectLanguage,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary.withValues(alpha: 0.6), fontSize: 14),
          ),
        ),
        const SizedBox(height: 30),
        LanguageTile(
          title: l10n.spanish,
          flag: l10n.spanishFlag,
          isSelected: state.languageCode == 'es' || state.languageCode == null,
          onTap: () => onSelectLanguage('es'),
        ),
        LanguageTile(
          title: l10n.english,
          flag: l10n.englishFlag,
          isSelected: state.languageCode == 'en',
          onTap: () => onSelectLanguage('en'),
        ),
      ],
    );
  }
}
