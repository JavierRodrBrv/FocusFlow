import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
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

  bool get _shouldShowEffect {
    return state.pomodoroStatus != PomodoroStatus.initial;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(seconds: 2),
                  child: _shouldShowEffect
                      ? BackdropFilter(
                          key: const ValueKey('bottom_bar_blur'),
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.1),
                          ),
                        )
                      : Container(
                          key: const ValueKey('bottom_bar_solid'),
                          color: const Color(0xFF1E293B),
                        ),
                ),
              ),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Row(
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
            iconColor: state.isHardcoreMode ? Colors.redAccent : Colors.blueAccent,
            onTap: onFocusModeTap,
          ),
        ),
      ],
    );
  }
}
