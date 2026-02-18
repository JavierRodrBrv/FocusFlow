import 'package:flutter/material.dart';
import 'package:focus_flow/features/focus_mode/presentation/bloc/focus_bloc.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/components/bottom_action_item.dart';
import 'package:showcaseview/showcaseview.dart';

class FocusBottomBar extends StatelessWidget {
  final FocusState state;
  final GlobalKey mixerKey;
  final GlobalKey focusModeKey;
  final VoidCallback onMixerTap;
  final VoidCallback onFocusModeTap;

  const FocusBottomBar({
    super.key,
    required this.state,
    required this.mixerKey,
    required this.focusModeKey,
    required this.onMixerTap,
    required this.onFocusModeTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Showcase(
              key: mixerKey,
              title: 'Ambiente Personalizado',
              description:
                  'Crea tu atmósfera ideal combinando sonidos de lluvia, fuego o ruido marrón. Ajusta los niveles a tu gusto para aislarte de distracciones.',
              child: BottomActionItem(
                icon: Icons.tune_rounded,
                label: 'Ambiente',
                onTap: onMixerTap,
              ),
            ),
            VerticalDivider(
              color: Colors.white.withValues(alpha: 0.05),
              indent: 20,
              endIndent: 20,
            ),
            Showcase(
              key: focusModeKey,
              title: 'Modo Foco Profundo',
              description:
                  'Activa este modo para obligarte a dejar el móvil boca abajo. Si lo levantas, la sesión se pausará, ayudándote a evitar tentaciones.',
              child: BottomActionItem(
                icon: Icons.psychology_rounded,
                label: 'Modo Foco',
                onTap: onFocusModeTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
