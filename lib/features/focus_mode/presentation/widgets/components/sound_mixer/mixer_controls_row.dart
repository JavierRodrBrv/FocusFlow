import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/premium/presentation/widgets/premium_feature_dialog.dart';
import '../../../models/focus_state.dart';
import '../../modals/saved_mixes_bottom_sheet.dart';
import 'circular_action_button.dart';

class MixerControlsRow extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;
  final AnimationController iconController;
  final bool isPlaying;

  const MixerControlsRow({
    super.key,
    required this.state,
    required this.service,
    required this.iconController,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // LOAD MIX BUTTON
        CircularActionButton(
          icon: Icons.queue_music,
          isPremium: state.isPremium,
          color: Colors.white70,
          onPressed: () {
            if (state.isPremium) {
              SavedMixesBottomSheet.show(context, state, service);
            } else {
              showDialog(
                context: context,
                builder: (context) => const PremiumFeatureDialog(
                  featureName: 'Cargar mezclas guardadas',
                  featureDescription:
                      'Accede y carga al instante tus mezclas de sonido personalizadas que has guardado previamente.',
                ),
              );
            }
          },
        ),

        const SizedBox(width: 24),

        // PLAY/PAUSE BUTTON
        InkWell(
          onTap: () {
            service.invoke('sendEvent', {
              'event': isPlaying ? 'pauseMix' : 'resumeMix',
            });
          },
          borderRadius: BorderRadius.circular(30),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPlaying
                  ? Colors.blueAccent
                  : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: isPlaying
                  ? [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: iconController,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),

        const SizedBox(width: 24),

        // SAVE MIX BUTTON
        CircularActionButton(
          icon: Icons.save_alt,
          isPremium: state.isPremium,
          color: Colors.blueAccent,
          onPressed: () {
            if (state.isPremium) {
              service.invoke('sendEvent', {'event': 'saveMix'});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mix guardado.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              showDialog(
                context: context,
                builder: (context) => const PremiumFeatureDialog(
                  featureName: 'Guardar mezclas de sonido',
                  featureDescription:
                      'Guarda tus configuraciones de sonido ambientale para usarlas más tarde.',
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
