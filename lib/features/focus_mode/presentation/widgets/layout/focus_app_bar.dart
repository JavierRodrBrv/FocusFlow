import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/modals/settings_menu_bottom_sheet.dart';
import 'package:focus_flow/features/stats/presentation/screens/dashboard_screen.dart';
import 'package:focus_flow/features/premium/presentation/widgets/premium_feature_dialog.dart';
import 'package:focus_flow/features/session_history/presentation/pages/session_history_page.dart';
import 'package:focus_flow/flavors.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../models/focus_state.dart';

class FocusAppBar extends StatelessWidget implements PreferredSizeWidget {
  final FocusState state;
  final GlobalKey tutorialKey;
  final GlobalKey premiumKey;
  final GlobalKey historyKey;
  final Function(dynamic result)? onTutorialResult;

  const FocusAppBar({
    super.key,
    required this.state,
    required this.tutorialKey,
    required this.premiumKey,
    required this.historyKey,
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
        description: 'Gestiona las preferencias de la app a tu gusto.',
        child: IconButton(
          icon: const Icon(Icons.notes_rounded, color: Colors.white70),
          onPressed: () async {
            final result = await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) =>
                  SettingsMenuBottomSheet(initialState: state),
            );
            if (onTutorialResult != null) onTutorialResult!(result);
          },
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.bar_chart_rounded, color: Colors.white70),
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const DashboardScreen(),
                transitionsBuilder: (_, animation, __, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          },
        ),
        Showcase(
          key: historyKey,
          title: 'Historial de Sesiones',
          description:
              'Revisa tu rendimiento, tiempo enfocado y ciclos completados.',
          child: IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white70),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SessionHistoryPage(),
                ),
              );
            },
          ),
        ),
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
