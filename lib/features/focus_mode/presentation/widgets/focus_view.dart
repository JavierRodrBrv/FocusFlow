import 'dart:async';

import 'package:app_links/app_links.dart'; // Added
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/premium/presentation/utils/ad_consent_manager.dart';

import '../models/focus_state.dart';
import 'dialogs/session_completion_dialog.dart';
import 'components/focus_body.dart';
import 'components/confetti_overlay.dart';
import 'layout/focus_app_bar.dart';
import 'layout/focus_bottom_bar.dart';
import 'modals/focus_modals.dart';
import 'components/timer_shader_background.dart';

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

  Timer? _handshakeTimer;
  Timer? _heartbeatTimer;
  late ConfettiController _confettiController;
  late AppLinks _appLinks; // Added
  StreamSubscription<Uri>? _linkSubscription; // Added
  bool _completionDialogShown = false;
  FocusState? _lastKnownState;
  late Stream<Map<String, dynamic>?> _updateStream;
  bool _isResuming = false;

  // Zoom Mode Local State
  bool _overlayVisible = true;
  Timer? _overlayTimer;
  bool? _lastKnownIsZoomMode;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _updateStream = FlutterBackgroundService().on('update');

    _initDeepLinks(); // Added

    _requestState();
    _startHeartbeat();

    _handshakeTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_lastKnownState == null ||
          _lastKnownState!.status == AppStatus.loading) {
        _requestState();
      }
    });

    _checkConsent();
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

  // Added method
  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Listen to link stream
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  // Added method
  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'focusflow') {
      final host = uri.host;
      if (host == 'pause') {
        FlutterBackgroundService().invoke('sendEvent', {'event': 'pauseTimer'});
      } else if (host == 'resume') {
        FlutterBackgroundService().invoke('sendEvent', {'event': 'startTimer'});
      } else if (host == 'stop') {
        FlutterBackgroundService().invoke('sendEvent', {'event': 'resetTimer'});
      }
    }
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

    if (state.pomodoroStatus == PomodoroStatus.finished) {
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

  void _startShowcase() {
    ShowCaseWidget.of(context).startShowCase([
      _timerKey,
      _controlsKey,
      _mixerKey,
      _focusModeKey,
      _tutorialKey,
      _historyKey,
      _premiumKey,
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
