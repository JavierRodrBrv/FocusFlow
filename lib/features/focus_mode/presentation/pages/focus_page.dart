import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/premium/presentation/widgets/ad_banner_widget.dart';

// Widgets desacoplados
import 'package:focus_flow/features/focus_mode/presentation/widgets/timer_display.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/timer_controls.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/sound_mixer.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/hardcore_mode_card.dart';

import '../bloc/focus_bloc.dart';

class FocusPage extends StatelessWidget {
  const FocusPage({super.key});

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