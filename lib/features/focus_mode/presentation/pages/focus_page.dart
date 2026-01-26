import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/hardcore_mode_card.dart';
import 'package:focus_flow/features/premium/presentation/utils/ad_consent_manager.dart';

import '../../../premium/presentation/widgets/ad_banner_widget.dart';
import '../bloc/focus_bloc.dart';
import '../widgets/sound_mixer.dart';
import '../widgets/saved_mix_player.dart';
import '../widgets/timer_controls.dart';
import '../widgets/timer_display.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  @override
  void initState() {
    super.initState();
    // HANDSHAKE: Pedir estado activamente al iniciar
    print('[FocusPage] Requesting initial state...');
    FlutterBackgroundService().invoke('sendEvent', {'event': 'requestState'});
    
    // CONSENT: Iniciar flujo de consentimiento en UI
    _checkConsent();
  }

  Future<void> _checkConsent() async {
    // Pequeño delay para no bloquear la UI en el frame 0
    await Future.delayed(const Duration(milliseconds: 500));
    final canRequest = await AdConsentManager().requestConsent();
    print('[FocusPage] Consent result: $canRequest. Updating Background Service...');
    
    FlutterBackgroundService().invoke('sendEvent', {
      'event': 'updateConsentStatus', 
      'canRequest': canRequest
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: FlutterBackgroundService().on('update'),
      builder: (context, snapshot) {
        FocusState state;
        
        // --- State Decoding Logic ---
        if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
          state = const FocusState();
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          state = const FocusState();
        } else {
          try {
            state = FocusState.fromJson(snapshot.data!);
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
            actions: [
              IconButton(
                icon: Icon(
                  state.isPremium ? Icons.workspace_premium : Icons.workspace_premium_outlined,
                  color: state.isPremium ? Colors.amber : Colors.white70,
                ),
                tooltip: 'Simular Premium',
                onPressed: () {
                  FlutterBackgroundService().invoke('sendEvent', {'event': 'togglePremium'});
                },
              ),
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, FocusState state) {
    final service = FlutterBackgroundService();
    
    if (state.status == AppStatus.initial || state.status == AppStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state.status == AppStatus.error) {
      return const Center(child: Text("Error fatal de inicialización"));
    }
    
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            children: [
              const SizedBox(height: 20),
              
              TimerDisplay(state: state, service: service),
              const SizedBox(height: 30),
              
              TimerControls(state: state, service: service),
              const SizedBox(height: 40),
              
              SoundMixer(state: state, service: service),
              const SizedBox(height: 40),

              SavedMixPlayer(state: state, service: service),
              
              HardcoreModeCard(state: state, service: service),
              
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