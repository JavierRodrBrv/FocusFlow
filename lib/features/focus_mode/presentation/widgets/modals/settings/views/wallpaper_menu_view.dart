import 'package:flutter/material.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/background_effect.dart';
import 'package:focus_flow/features/focus_mode/presentation/models/focus_state.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/components/background/gradient_flow_background.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import '../components/wallpaper_option_card.dart';

class WallpaperMenuView extends StatelessWidget {
  final FocusState state;
  final VoidCallback onBack;
  final Function(BackgroundEffect) onSelectEffect;

  const WallpaperMenuView({
    super.key,
    required this.state,
    required this.onBack,
    required this.onSelectEffect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with Back Button
        Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white70,
              ),
              onPressed: onBack,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 48.0),
                  child: Text(
                    l10n.wallpaper,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 40),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              WallpaperOptionCard(
                label: l10n.solid,
                effect: BackgroundEffect.solid,
                isSelected: state.backgroundEffect == BackgroundEffect.solid,
                preview: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                ),
                onTap: () => onSelectEffect(BackgroundEffect.solid),
              ),
              WallpaperOptionCard(
                label: l10n.gradient,
                effect: BackgroundEffect.gradient,
                isSelected: state.backgroundEffect == BackgroundEffect.gradient,
                preview: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: const GradientFlowBackground(
                    child: SizedBox.expand(),
                  ),
                ),
                onTap: () => onSelectEffect(BackgroundEffect.gradient),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}
