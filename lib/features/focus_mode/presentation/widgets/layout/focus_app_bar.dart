import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/presentation/bloc/focus_bloc.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/modals/settings_menu_bottom_sheet.dart';
import 'package:focus_flow/features/premium/presentation/widgets/premium_feature_dialog.dart';
import 'package:focus_flow/flavors.dart';
import 'package:showcaseview/showcaseview.dart';

class FocusAppBar extends StatelessWidget implements PreferredSizeWidget {
  final FocusState state;
  final GlobalKey tutorialKey;
  final GlobalKey premiumKey;
  final Function(dynamic result)? onTutorialResult;

  const FocusAppBar({
    super.key,
    required this.state,
    required this.tutorialKey,
    required this.premiumKey,
    this.onTutorialResult,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'FocusFlow',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          fontSize: 20,
        ),
      ),
      backgroundColor: Colors.transparent,
      centerTitle: true,
      elevation: 0,
      leading: Showcase(
        key: tutorialKey,
        title: 'Ajustes y Ayuda',
        description:
            'Gestiona tus preferencias de sonido, vuelve a ver este tutorial cuando lo necesites o envíanos tus comentarios para seguir mejorando.',
        child: IconButton(
          icon: const Icon(Icons.notes_rounded, color: Colors.white70),
          onPressed: () async {
            final result = await showModalBottomSheet(
              context: context,
              builder: (context) =>
                  SettingsMenuBottomSheet(initialState: state),
            );
            if (onTutorialResult != null) onTutorialResult!(result);
          },
        ),
      ),
      actions: [
        Showcase(
          key: premiumKey,
          title: 'Experiencia Premium',
          description:
              'Desbloquea todas las mezclas de sonido ambiental, elimina los anuncios y accede a funciones exclusivas para un enfoque total.',
          child: IconButton(
            icon: Icon(
              state.isPremium
                  ? Icons.workspace_premium
                  : Icons.workspace_premium_outlined,
              color: state.isPremium ? Colors.amber : Colors.white70,
            ),
            onPressed: () {
              if (F.appFlavor == Flavor.dev) {
                FlutterBackgroundService().invoke('sendEvent', {
                  'event': 'togglePremium',
                });
              } else if (!state.isPremium) {
                showDialog(
                  context: context,
                  builder: (context) => const PremiumFeatureDialog(
                    featureName: 'Premium',
                    featureDescription:
                        'Desbloquea todas las funciones y elimina los anuncios.',
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
