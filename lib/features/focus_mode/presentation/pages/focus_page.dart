import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/hardcore_mode_card.dart';
import 'package:focus_flow/features/premium/presentation/utils/ad_consent_manager.dart';
import 'package:focus_flow/features/premium/presentation/widgets/premium_feature_dialog.dart';
import 'package:focus_flow/flavors.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../premium/presentation/widgets/ad_banner_widget.dart';
import '../bloc/focus_bloc.dart';
import '../widgets/sound_mixer.dart';
import '../widgets/saved_mix_player.dart';
import '../widgets/timer_controls.dart';
import '../widgets/timer_display.dart';
import '../widgets/settings_menu_bottom_sheet.dart';

class FocusPage extends StatelessWidget {
  const FocusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onFinish: () {
        if (F.appFlavor == Flavor.dev) {
          _showDevDialog(context);
        }
      },
      builder: (context) => const FocusView(),
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
  late ConfettiController _confettiController;
  bool _completionDialogShown = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    // HANDSHAKE: Pedir estado activamente al iniciar y reintentar
    _handshakeTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      print('[FocusPage] Handshake retry...');
      FlutterBackgroundService().invoke('sendEvent', {'event': 'requestState'});
    });
    print('[FocusPage] Requesting initial state...');
    FlutterBackgroundService().invoke('sendEvent', {'event': 'requestState'});

    // CONSENT
    _checkConsent();

    // CHECK TUTORIAL (Handles Dev Dialog logic)
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTutorial());
  }

  @override
  void dispose() {
    _handshakeTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _checkCompletion(FocusState state) {
    if (state.pomodoroStatus == PomodoroStatus.finished) {
      if (!_completionDialogShown) {
        _completionDialogShown = true;
        
        // Detener alarma inmediatamente al mostrar el diálogo (usuario activo)
        FlutterBackgroundService().invoke('sendEvent', {'event': 'stopAlarm'});
        
        _confettiController.play();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCompletionDialog(context);
        });
      }
    } else {
      // Reset flag if not finished (e.g., reset timer)
      if (state.pomodoroStatus != PomodoroStatus.finished) {
        _completionDialogShown = false;
      }
    }
  }

  Future<void> _showCompletionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, color: Colors.amber, size: 60),
              const SizedBox(height: 20),
              const Text(
                '¡Sesión Completada!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Has mantenido el foco con éxito. ¡Gran trabajo!',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                FlutterBackgroundService().invoke('sendEvent', {'event': 'resetTimer'});
                Navigator.of(context).pop();
              },
              child: const Text('Continuar', style: TextStyle(color: Colors.blueAccent, fontSize: 16)),
            ),
          ],
        );
      },
    );
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
      } else {
        // Si ya se vio el tutorial, mostramos el diálogo de desarrollo directamente (si aplica)
        if (F.appFlavor == Flavor.dev && mounted) {
          _showDevDialog(context);
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
      _mixerKey,
      _savedMixesKey,
      _hardcoreKey,
      _premiumKey,
      _tutorialKey,
    ]);
  }

  Future<void> _checkConsent() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final canRequest = await AdConsentManager().requestConsent();
    print(
        '[FocusPage] Consent result: $canRequest. Updating Background Service...');

    FlutterBackgroundService().invoke('sendEvent',
        {'event': 'updateConsentStatus', 'canRequest': canRequest});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: FlutterBackgroundService().on('update'),
      builder: (context, snapshot) {
        FocusState state;

        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          // ESTADO DE CARGA INICIAL POR DEFECTO
          // Si no hay datos, asumimos loading pero NO bloqueamos con spinner infinito
          // si ya tenemos datos previos (snapshot.hasData). 
          // Si es el primer build, mostramos spinner.
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          // Si sigue null tras waiting, loading
          state = const FocusState(); // Fallback temporal
        } else {
          try {
            state = FocusState.fromJson(snapshot.data!);
            print("[FocusPage] Received State: ${state.status}");
            // Chequear si terminó para mostrar confetti/dialog
            _checkCompletion(state);
          } catch (e) {
            print("Error decoding state: $e");
            state = const FocusState();
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('FocusFlow'),
            backgroundColor: Colors.transparent,
            centerTitle: true,
            elevation: 0,
            leading: Showcase(
              key: _tutorialKey,
              title: 'Menú',
              description:
                  'Accede al tutorial, ajustes y feedback aquí.',
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white70),
                tooltip: 'Menú',
                onPressed: () async {
                  final result = await showModalBottomSheet(
                    context: context,
                    builder: (context) => const SettingsMenuBottomSheet(),
                  );
                  
                  if (result == 'tutorial') {
                    _startShowcase();
                  }
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
                  tooltip: F.appFlavor == Flavor.dev
                      ? 'Simular Premium (Dev)'
                      : 'Premium',
                  onPressed: () {
                    if (F.appFlavor == Flavor.dev) {
                      FlutterBackgroundService()
                          .invoke('sendEvent', {'event': 'togglePremium'});
                    } else {
                      if (!state.isPremium) {
                        showDialog(
                          context: context,
                          builder: (context) => const PremiumFeatureDialog(
                            featureName: 'Premium',
                            featureDescription:
                                'Desbloquea todas las funciones y elimina los anuncios.',
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Ya eres usuario Premium.')),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              _buildBody(context, state),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2, // Hacia abajo
                  maxBlastForce: 5, // Velocidad
                  minBlastForce: 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  gravity: 0.1,
                  colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple], 
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              FlutterBackgroundService().invoke('sendEvent', {
                'event': 'updatePomodoroDuration',
                'durationSeconds': 10
              });
              // Forzamos reseteo para que coja la nueva duración inmediatamente
              FlutterBackgroundService().invoke('sendEvent', {'event': 'resetTimer'});
            },
            backgroundColor: Colors.redAccent,
            child: const Text('10s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, FocusState state) {
    final service = FlutterBackgroundService();

    if (state.status == AppStatus.initial ||
        state.status == AppStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == AppStatus.error) {
      return const Center(child: Text("Error fatal de inicialización"));
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            children: [
              const SizedBox(height: 20),
              Showcase(
                key: _timerKey,
                title: 'Temporizador',
                description:
                    'Aquí puedes ver el tiempo restante de tu sesión de enfoque.',
                child: TimerDisplay(state: state, service: service),
              ),
              const SizedBox(height: 30),
              Showcase(
                key: _controlsKey,
                title: 'Controles',
                description: 'Inicia, pausa o reinicia tu temporizador aquí.',
                child: TimerControls(state: state, service: service),
              ),
              const SizedBox(height: 40),
              Showcase(
                key: _mixerKey,
                title: 'Mezclador de Sonidos',
                description:
                    'Crea tu ambiente perfecto ajustando los sonidos de fondo.',
                child: SoundMixer(state: state, service: service),
              ),
              const SizedBox(height: 40),
              Showcase(
                key: _savedMixesKey,
                title: 'Mezclas Guardadas',
                description:
                    'Accede rápidamente a tus combinaciones de sonido favoritas.',
                child: SavedMixPlayer(state: state, service: service),
              ),
              Showcase(
                key: _hardcoreKey,
                title: 'Modo Hardcore',
                description:
                    'Activa este modo para evitar distracciones. Si giras el móvil, pierdes.',
                child: HardcoreModeCard(state: state, service: service),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        if (!state.isPremium && state.canRequestAds)
          const SafeArea(
            top: false,
            child: AdBannerWidget(),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

void _showDevDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Row(
        children: [
          Icon(Icons.bug_report, color: Colors.orangeAccent),
          SizedBox(width: 10),
          Text('Versión de Desarrollo', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: const Text(
        'Estás utilizando una versión de prueba (Dev).\n\n'
        '• Las funciones Premium se pueden simular.\n'
        '• Puede contener errores experimentales.\n'
        '• ¡Ayúdanos a mejorar! Envía tus ideas o reporta fallos desde el nuevo menú de Ajustes (icono ☰).',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido',
              style: TextStyle(color: Colors.blueAccent)),
        ),
      ],
    ),
  );
}
