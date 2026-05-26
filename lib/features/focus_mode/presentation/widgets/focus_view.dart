import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get_it/get_it.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/domain/services/focus_coordinator_service.dart';
import 'package:focus_flow/app/background_service.dart';

import '../models/focus_state.dart';
import 'dialogs/session_completion_dialog.dart';
import 'dialogs/pomodoro_cycle_complete_dialog.dart';
import 'components/layout/focus_body.dart';
import 'components/overlays/confetti_overlay.dart';
import 'layout/focus_app_bar.dart';
import 'layout/focus_bottom_bar.dart';
import 'modals/focus_modals.dart';
import 'components/background/timer_shader_background.dart';

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
  final GlobalKey _mixerKey = GlobalKey();
  final GlobalKey _focusModeKey = GlobalKey();
  final GlobalKey _historyKey = GlobalKey();

  late final FocusCoordinatorService _coordinator;
  Timer? _handshakeTimer;
  Timer? _heartbeatTimer;
  late ConfettiController _confettiController;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _completionDialogShown = false;
  FocusState? _lastKnownState;
  late Stream<Map<String, dynamic>?> _updateStream;
  bool _isResuming = false;
  int _loadingTicks = 0;
  bool _serviceIsAlive = false;

  // Zoom Mode Local State
  bool _overlayVisible = true;
  Timer? _overlayTimer;
  bool? _lastKnownIsZoomMode;

  @override
  void initState() {
    super.initState();
    _coordinator = GetIt.instance<FocusCoordinatorService>();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _updateStream = FlutterBackgroundService().on('update');

    // Escuchar señales de vida del servicio
    FlutterBackgroundService().on('serviceReady').listen((_) {
      debugPrint('[FocusView] Background Isolate is alive');
      if (mounted) setState(() => _serviceIsAlive = true);
    });

    FlutterBackgroundService().on('serviceInitialized').listen((_) {
      debugPrint('[FocusView] Background Service fully initialized');
      _requestState();
    });

    _initDeepLinks();

    _requestState();
    _startHeartbeat();

    // Watchdog Agresivo: Chequeo cada segundo
    _handshakeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lastKnownState == null ||
          _lastKnownState!.status == AppStatus.loading) {
        _loadingTicks++;
        
        // Cada segundo pedimos el estado
        _requestState();

        // 1. Si tras 3s no sabemos NADA (ni siquiera si el Isolate ha arrancado) -> Re-kick
        if (!_serviceIsAlive && _loadingTicks >= 3) {
          debugPrint('[FocusView] Watchdog: Isolate dead detected. Re-kicking...');
          initializeService();
          _loadingTicks = 0;
        } 
        // 2. Si el Isolate arrancó pero llevamos > 5s sin recibir el estado real -> Re-kick
        // (Esto cubre bloqueos lógicos como el error de Hive que vimos en logs)
        else if (_loadingTicks >= 5) {
          debugPrint('[FocusView] Watchdog: Service logic hang. Re-kicking...');
          initializeService();
          _loadingTicks = 0;
        }
      } else {
        _loadingTicks = 0;
      }
    });

    _coordinator.checkConsent();
    _isResuming = true;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isResuming = false);
    });
  }

  void _handleScreenTap(bool isZoomMode) {
    if (!isZoomMode) return;

    if (mounted) {
      setState(() {
        _overlayVisible = true;
      });
    }

    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _overlayVisible = false;
        });
      }
    });
  }

  void _handleZoomModeTransition(bool isZoomMode) {
    if (_lastKnownIsZoomMode == isZoomMode) return;

    // Usamos postFrameCallback para evitar el error de setState durante el build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          if (isZoomMode) {
            // Al entrar en modo zoom, ocultamos todo inmediatamente
            _overlayVisible = false;
          } else {
            // Al salir, mostramos todo y cancelamos timers
            _overlayVisible = true;
            _overlayTimer?.cancel();
          }
          _lastKnownIsZoomMode = isZoomMode;
        });
      }
    });
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _coordinator.handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('[FocusView] Error getting initial link: $e');
    }
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _coordinator.handleDeepLink,
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel(); // Added
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

    if (state.pomodoroStatus == PomodoroStatus.finished && !state.isPomodoroMode) {
      // SOLO MOSTRAR SI EL ESTADO ANTERIOR NO ERA 'FINISHED'
      if (!_completionDialogShown &&
          (_lastKnownState?.pomodoroStatus != PomodoroStatus.finished)) {
        _completionDialogShown = true;
        FlutterBackgroundService().invoke('sendEvent', {'event': 'stopAlarm'});
        _confettiController.play();
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => SessionCompletionDialog(
                penaltyCount: state.penaltyCount,
                totalPenaltyTime: state.totalPenaltyTime,
                isHardcoreMode: state.isHardcoreMode,
                isPremium: state.isPremium,
                canRequestAds: state.canRequestAds,
              ),
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

  bool _pomodoroCycleCompleteDialogShown = false;

  void _checkPomodoroCycleCompletion(FocusState state) {
    if (_isResuming) return;

    if (state.hasCompletedPomodoroCycle) {
      if (!_pomodoroCycleCompleteDialogShown) {
        _pomodoroCycleCompleteDialogShown = true;
        FlutterBackgroundService().invoke('sendEvent', {'event': 'stopAlarm'});
        _confettiController.play();
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => PomodoroCycleCompleteDialog(
                studyMinutes: state.pomodoroDuration.inMinutes,
                shortMinutes: state.shortBreakDuration.inMinutes,
                longMinutes: state.longBreakDuration.inMinutes,
                onStartNewCycle: (groupId) {
                  FlutterBackgroundService().invoke('sendEvent', {'event': 'resetTimer'});
                  Future.delayed(const Duration(milliseconds: 100), () {
                    FlutterBackgroundService().invoke('sendEvent', {
                      'event': 'startTimer',
                      'groupId': groupId,
                    });
                  });
                },
                onFinish: () {
                  FlutterBackgroundService().invoke('sendEvent', {'event': 'resetTimer'});
                },
              ),
            );
          });
        }
      }
    } else {
      _pomodoroCycleCompleteDialogShown = false;
    }
  }

  void _startShowcase() {
    // Wait for the modal to be fully dismissed
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      ShowCaseWidget.of(context).startShowCase([
        _timerKey,
        _controlsKey,
        _mixerKey,
        _focusModeKey,
        _tutorialKey,
        _historyKey,
        _premiumKey,
      ]);
    });
  }

  void _showMixerModal(FocusState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          SoundMixerModal(state: state, service: FlutterBackgroundService()),
    );
  }

  void _showFocusModal(FocusState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          FocusModeModal(state: state, service: FlutterBackgroundService()),
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
            _checkCompletion(state);
            _checkPomodoroCycleCompletion(state);

            // Manejar la transición de modo zoom de forma segura
            _handleZoomModeTransition(state.isZoomMode);

            _lastKnownState = state;
          } catch (e) {
            state = _lastKnownState ?? const FocusState();
          }
        } else {
          state =
              _lastKnownState ?? const FocusState(status: AppStatus.loading);
        }

        return GestureDetector(
          onTap: () => _handleScreenTap(state.isZoomMode),
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              TimerShaderBackground(state: state),
              Scaffold(
                backgroundColor: Colors.transparent,
                extendBody: true,
                extendBodyBehindAppBar: true,
                appBar: state.isZoomMode
                    ? null
                    : PreferredSize(
                        preferredSize: const Size.fromHeight(kToolbarHeight),
                        child: FocusAppBar(
                          state: state,
                          tutorialKey: _tutorialKey,
                          premiumKey: _premiumKey,
                          historyKey: _historyKey,
                          onTutorialResult: (result) {
                            if (result == 'tutorial') _startShowcase();
                          },
                        ),
                      ),
                body: Stack(
                  children: [
                    FocusBody(
                      state: state,
                      service: FlutterBackgroundService(),
                      timerKey: _timerKey,
                      controlsKey: _controlsKey,
                      overlayVisible: _overlayVisible,
                    ),
                    ConfettiOverlay(controller: _confettiController),
                  ],
                ),
                bottomNavigationBar: state.isZoomMode
                    ? null
                    : FocusBottomBar(
                        state: state,
                        mixerKey: _mixerKey,
                        focusModeKey: _focusModeKey,
                        onMixerTap: () => _showMixerModal(state),
                        onFocusModeTap: () => _showFocusModal(state),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
