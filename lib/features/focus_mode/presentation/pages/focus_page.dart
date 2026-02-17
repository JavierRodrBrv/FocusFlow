import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/premium/presentation/utils/ad_consent_manager.dart';
import 'package:focus_flow/features/premium/presentation/widgets/premium_feature_dialog.dart';
import 'package:focus_flow/flavors.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:showcaseview/showcaseview.dart';

import '../bloc/focus_bloc.dart';
import '../widgets/settings_menu_bottom_sheet.dart';
import '../widgets/dialogs/dev_version_dialog.dart';
import '../widgets/dialogs/session_completion_dialog.dart';
import '../widgets/focus_body.dart';
import '../widgets/modals/focus_modals.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> with WidgetsBindingObserver {
  Key _viewKey = UniqueKey();
  DateTime? _pauseTime;
  static const _inactivityThreshold = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pauseTime = DateTime.now();
      FlutterBackgroundService().invoke('sendEvent', {'event': 'ui_paused'});
    } else if (state == AppLifecycleState.resumed) {
      bool shouldReset = false;
      if (_pauseTime != null) {
        final inactiveDuration = DateTime.now().difference(_pauseTime!);
        if (inactiveDuration > _inactivityThreshold) {
          shouldReset = true;
        }
      }

      if (shouldReset) {
        setState(() {
          _viewKey = UniqueKey();
          _pauseTime = null;
        });
      } else {
        FlutterBackgroundService().invoke('sendEvent', {'event': 'ui_resumed'});
      }
    }
  }

  void _handleTutorialCompletion() async {
    if (F.appFlavor == Flavor.dev) {
      var box = await Hive.openBox('settings');
      bool devNoticeSeen = box.get('dev_notice_seen', defaultValue: false);
      if (!devNoticeSeen) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => const DevVersionDialog(),
          );
        }
        box.put('dev_notice_seen', true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onFinish: _handleTutorialCompletion,
      onDismiss: (_) => _handleTutorialCompletion(),
      builder: (context) => FocusView(key: _viewKey),
    );
  }
}

class FocusView extends StatefulWidget {
  const FocusView({super.key});

  @override
  State<FocusView> createState() => _FocusViewState();
}

class _FocusViewState extends State<FocusView> {
  final GlobalKey _timerKey = GlobalKey();
  final GlobalKey _controlsKey = GlobalKey();
  final GlobalKey _premiumKey = GlobalKey();
  final GlobalKey _tutorialKey = GlobalKey();

  Timer? _handshakeTimer;
  Timer? _heartbeatTimer;
  late ConfettiController _confettiController;
  bool _completionDialogShown = false;
  FocusState? _lastKnownState;
  late Stream<Map<String, dynamic>?> _updateStream;
  bool _isResuming = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _updateStream = FlutterBackgroundService().on('update');

    _requestState();
    _startHeartbeat();

    _handshakeTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_lastKnownState == null ||
          _lastKnownState!.status == AppStatus.loading) {
        _requestState();
      }
    });

    _checkConsent();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTutorial());

    _isResuming = true;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isResuming = false);
    });
  }

  @override
  void dispose() {
    _handshakeTimer?.cancel();
    _heartbeatTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _requestState() {
    FlutterBackgroundService().invoke('sendEvent', {'event': 'requestState'});
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        FlutterBackgroundService().invoke('sendEvent', {
          'event': 'ui_heartbeat',
        });
      }
    });
  }

  void _checkCompletion(FocusState state) {
    if (_isResuming) return;

    if (state.pomodoroStatus == PomodoroStatus.finished) {
      if (!_completionDialogShown) {
        _completionDialogShown = true;
        FlutterBackgroundService().invoke('sendEvent', {'event': 'stopAlarm'});
        _confettiController.play();
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const SessionCompletionDialog(),
            );
          });
        }
      }
    } else {
      if (state.pomodoroStatus != PomodoroStatus.finished) {
        _completionDialogShown = false;
      }
    }
  }

  Future<void> _checkTutorial() async {
    try {
      var box = await Hive.openBox('settings');
      bool seen = box.get('tutorial_seen', defaultValue: false);
      if (!seen) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _startShowcase();
          box.put('tutorial_seen', true);
        }
      }
    } catch (e) {
      print("Error checking tutorial: $e");
    }
  }

  void _startShowcase() {
    ShowCaseWidget.of(context).startShowCase([
      _timerKey,
      _controlsKey,
      _premiumKey,
      _tutorialKey,
    ]);
  }

  Future<void> _checkConsent() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final canRequest = await AdConsentManager().requestConsent();
    FlutterBackgroundService().invoke('sendEvent', {
      'event': 'updateConsentStatus',
      'canRequest': canRequest,
    });
  }

  void _showMixerModal(FocusState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SoundMixerModal(
        state: state,
        service: FlutterBackgroundService(),
      ),
    );
  }

  void _showFocusModal(FocusState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FocusModeModal(
        state: state,
        service: FlutterBackgroundService(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _updateStream,
      builder: (context, snapshot) {
        FocusState state;
        if (snapshot.hasData && snapshot.data != null) {
          try {
            state = FocusState.fromJson(snapshot.data!);
            _lastKnownState = state;
            _checkCompletion(state);
          } catch (e) {
            state = _lastKnownState ?? const FocusState();
          }
        } else {
          state =
              _lastKnownState ?? const FocusState(status: AppStatus.loading);
        }

        return Scaffold(
          appBar: AppBar(
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
              key: _tutorialKey,
              title: 'Menú',
              description: 'Accede al tutorial y ajustes.',
              child: IconButton(
                icon: const Icon(Icons.notes_rounded, color: Colors.white70),
                onPressed: () async {
                  final result = await showModalBottomSheet(
                    context: context,
                    builder: (context) =>
                        SettingsMenuBottomSheet(initialState: state),
                  );
                  if (result == 'tutorial') _startShowcase();
                },
              ),
            ),
            actions: [
              Showcase(
                key: _premiumKey,
                title: 'Premium',
                description: 'Desbloquea funciones exclusivas.',
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
          ),
          body: Stack(
            children: [
              FocusBody(
                state: state,
                service: FlutterBackgroundService(),
                timerKey: _timerKey,
                controlsKey: _controlsKey,
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2,
                  maxBlastForce: 5,
                  minBlastForce: 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 10,
                  gravity: 0.1,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple,
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              height: 80,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BottomAction(
                    icon: Icons.tune_rounded,
                    label: 'Ambiente',
                    onTap: () => _showMixerModal(state),
                  ),
                  VerticalDivider(
                    color: Colors.white.withOpacity(0.05),
                    indent: 20,
                    endIndent: 20,
                  ),
                  _BottomAction(
                    icon: Icons.psychology_rounded,
                    label: 'Modo Foco',
                    onTap: () => _showFocusModal(state),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.blueAccent, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
