import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/hardcore_mode_card.dart';
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
      // Notificamos al servicio que la UI se ha ido para que corte el grifo
      FlutterBackgroundService().invoke('sendEvent', {'event': 'ui_paused'});
    } else if (state == AppLifecycleState.resumed) {
      print('[FocusPage] App Resumed: Stabilizing UI...');

      bool shouldReset = false;
      if (_pauseTime != null) {
        final inactiveDuration = DateTime.now().difference(_pauseTime!);
        if (inactiveDuration > _inactivityThreshold) {
          shouldReset = true;
        }
      }

      if (shouldReset) {
        print('[FocusPage] Hard Reset triggered by inactivity.');
        setState(() {
          _viewKey = UniqueKey();
          _pauseTime = null;
        });
      } else {
        // Si no hay reset, simplemente avisamos que hemos vuelto
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
      globalFloatingActionWidget: (context) => FloatingActionWidget(
        top: 80,
        right: 20,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade900,
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.blue.shade900,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => ShowCaseWidget.of(context).dismiss(),
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: Icon(
                  Icons.skip_next,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
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
  final GlobalKey _mixerKey = GlobalKey();
  final GlobalKey _savedMixesKey = GlobalKey();
  final GlobalKey _hardcoreKey = GlobalKey();
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

    // Si acabamos de ser creados, marcamos un breve periodo de estabilización
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
      bool devNoticeSeen = box.get('dev_notice_seen', defaultValue: false);

      if (!seen) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _startShowcase();
          box.put('tutorial_seen', true);
        }
      } else if (F.appFlavor == Flavor.dev && !devNoticeSeen && mounted) {
        showDialog(
          context: context,
          builder: (context) => const DevVersionDialog(),
        );
        box.put('dev_notice_seen', true);
      }
    } catch (e) {
      print("Error checking tutorial: $e");
    }
  }

  void _startShowcase() {
    ShowCaseWidget.of(context).startShowCase([
      _timerKey,
      _controlsKey,
      _hardcoreKey,
      _mixerKey,
      _savedMixesKey,
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
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('FocusFlow'),
                if (state.status == AppStatus.loading ||
                    state.status == AppStatus.error) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: state.status == AppStatus.error
                          ? Colors.red
                          : Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: Colors.transparent,
            centerTitle: true,
            elevation: 0,
            leading: Showcase(
              key: _tutorialKey,
              title: 'Menú',
              description: 'Accede al tutorial, ajustes y feedback aquí.',
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white70),
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
                description:
                    'Desbloquea funciones exclusivas y elimina anuncios.',
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
                mixerKey: _mixerKey,
                savedMixesKey: _savedMixesKey,
                hardcoreKey: _hardcoreKey,
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
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              FlutterBackgroundService().invoke('sendEvent', {
                'event': 'updatePomodoroDuration',
                'durationSeconds': 10,
              });
              FlutterBackgroundService().invoke('sendEvent', {
                'event': 'resetTimer',
              });
            },
            backgroundColor: Colors.redAccent,
            child: const Text(
              '10s',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
