import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get_it/get_it.dart';
import 'package:focus_flow/features/stats/domain/repositories/i_session_stats_repository.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/modals/settings_menu_bottom_sheet.dart';
import 'package:focus_flow/features/stats/presentation/screens/dashboard_screen.dart';
import 'package:focus_flow/features/premium/presentation/widgets/premium_feature_dialog.dart';
import 'package:focus_flow/features/session_history/presentation/pages/session_history_page.dart';
import 'package:focus_flow/flavors.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
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
        title: l10n.settingsAndHelp,
        description: l10n.settingsHelpDesc,
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
        const StreakStatsButton(),
        Showcase(
          key: historyKey,
          title: l10n.sessionsHistory,
          description: l10n.sessionsHistoryDesc,
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
          title: l10n.premiumExperience,
          description: l10n.premiumExperienceDesc,
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
                  builder: (context) => PremiumFeatureDialog(
                    featureName: l10n.premiumFeatureTitle,
                    featureDescription: l10n.premiumFeatureDesc,
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

class StreakStatsButton extends StatefulWidget {
  const StreakStatsButton({super.key});

  @override
  State<StreakStatsButton> createState() => _StreakStatsButtonState();
}

class _StreakStatsButtonState extends State<StreakStatsButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  late Animation<double> _bounceAnimation;
  bool _hasStreak = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.1, end: 0.55).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 80),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.25).chain(CurveTween(curve: Curves.easeOutBack)), weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: 1.25, end: 1.0).chain(CurveTween(curve: Curves.easeInBack)), weight: 10),
    ]).animate(_controller);

    _checkStreak();
  }

  Future<void> _checkStreak() async {
    try {
      final repo = GetIt.I<ISessionStatsRepository>();
      final sessions = await repo.getAllValidSessions();
      
      final completedDates = sessions
          .where((r) => r.status == 'completed')
          .map((r) => DateTime(r.startTime.year, r.startTime.month, r.startTime.day))
          .toSet()
          .toList();

      int streak = 0;
      if (completedDates.isNotEmpty) {
        completedDates.sort((a, b) => b.compareTo(a));
        
        final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        final yesterday = today.subtract(const Duration(days: 1));
        
        final latest = completedDates.first;
        if (latest == today || latest == yesterday) {
          streak = 1;
          for (int i = 0; i < completedDates.length - 1; i++) {
            final current = completedDates[i];
            final next = completedDates[i + 1];
            final diff = current.difference(next).inDays;
            
            if (diff == 1) {
              streak++;
            } else if (diff > 1) {
              break;
            }
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _hasStreak = F.appFlavor == Flavor.dev ? true : (streak >= 3);
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_hasStreak)
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withValues(alpha: _glowAnimation.value),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),
        IconButton(
          icon: Icon(
            Icons.bar_chart_rounded,
            color: _hasStreak ? Colors.orangeAccent : Colors.white70,
          ),
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            ).then((_) => _checkStreak());
          },
        ),
        if (_hasStreak)
          Positioned(
            right: 4,
            top: 4,
            child: ScaleTransition(
              scale: _bounceAnimation,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '🔥',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
