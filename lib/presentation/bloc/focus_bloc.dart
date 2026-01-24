
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:injectable/injectable.dart';
import 'package:focus_flow/domain/repositories/premium_repository.dart';
import 'package:focus_flow/data/services/sound_mixer_service.dart';

part 'focus_event.dart';
part 'focus_state.dart';

@injectable
class FocusBloc extends Bloc<FocusEvent, FocusState> {
  final PremiumRepository _premiumRepository;
  final SoundMixerService _soundMixerService;

  FocusBloc(this._premiumRepository, this._soundMixerService) : super(const FocusState()) {
    print('[FocusBloc] Created');
    on<InitializeApp>(_onInitializeApp);
    on<TogglePremiumStatus>(_onTogglePremiumStatus);
    on<UpdateRainVolume>(_onUpdateRainVolume);
    on<UpdateFireVolume>(_onUpdateFireVolume);
    on<UpdateBrownNoiseVolume>(_onUpdateBrownNoiseVolume);
  }

  @override
  void onEvent(FocusEvent event) {
    super.onEvent(event);
    print('[FocusBloc] Event: ${event.runtimeType}');
  }

  @override
  void onChange(Change<FocusState> change) {
    super.onChange(change);
    print('[FocusBloc] State Change: ${change.nextState.status}, isPremium: ${change.nextState.isPremium}, canRequestAds: ${change.nextState.canRequestAds}');
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    print('[FocusBloc] ERROR: $error');
  }

  Future<void> _onInitializeApp(InitializeApp event, Emitter<FocusState> emit) async {
    print('[FocusBloc] Handling InitializeApp');
    emit(state.copyWith(status: AppStatus.loading));
    try {
      // 1. Flujo de consentimiento UMP con la API actualizada
      print('[FocusBloc] Starting UMP Consent Flow...');
      final params = ConsentRequestParameters();
      
      // El Completer nos permite esperar a que los callbacks asíncronos terminen.
      final consentCompleter = Completer<void>();

      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          print('[FocusBloc] Consent info updated. Is form available: ${await ConsentInformation.instance.isConsentFormAvailable()}');
          // Si el formulario está disponible, cargarlo y mostrarlo.
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            ConsentForm.loadConsentForm(
              (ConsentForm consentForm) {
                consentForm.show(
                  (FormError? formError) {
                    print('[FocusBloc] Consent form dismissed.');
                    // Cuando el formulario se cierra, completamos el future.
                    consentCompleter.complete();
                  },
                );
              },
              (FormError? formError) {
                print('[FocusBloc] ERROR loading consent form: ${formError?.message}');
                consentCompleter.complete(); // Completar igualmente para no bloquear la app
              },
            );
          } else {
            // Si no hay formulario que mostrar, completamos inmediatamente.
            consentCompleter.complete();
          }
        },
        (FormError error) {
          print('[FocusBloc] ERROR requesting consent info: ${error.message}');
          consentCompleter.complete(); // Completar igualmente para no bloquear la app
        },
      );

      // Esperar a que el flujo de consentimiento (incluido el formulario) termine.
      await consentCompleter.future;

      // 2. Comprobar si se pueden solicitar anuncios
      final canRequest = await ConsentInformation.instance.canRequestAds();
      print('[FocusBloc] Can request ads: $canRequest');
      emit(state.copyWith(canRequestAds: canRequest));

      // 3. Inicializar Mobile Ads (solo si hay consentimiento)
      if (canRequest) {
        print('[FocusBloc] Initializing Mobile Ads SDK...');
        await MobileAds.instance.initialize();
        print('[FocusBloc] Mobile Ads SDK Initialized.');
      }
      
      // 4. Continuar con el resto de la inicialización
      final isPremium = await _premiumRepository.isPremium();
      await _soundMixerService.init();
      
      emit(state.copyWith(status: AppStatus.loaded, isPremium: isPremium));
      print('[FocusBloc] App Initialized successfully');
    } catch (e) {
      print('[FocusBloc] ERROR during initialization: $e');
      emit(state.copyWith(status: AppStatus.error));
    }
  }

  Future<void> _onTogglePremiumStatus(TogglePremiumStatus event, Emitter<FocusState> emit) async {
    print('[FocusBloc] Handling TogglePremiumStatus');
    final newStatus = !state.isPremium;
    await _premiumRepository.setPremiumStatus(newStatus);
    emit(state.copyWith(isPremium: newStatus));
  }

  void _onUpdateRainVolume(UpdateRainVolume event, Emitter<FocusState> emit) {
    print('[FocusBloc] Handling UpdateRainVolume');
    _soundMixerService.setRainVolume(event.volume);
    emit(state.copyWith(rainVolume: event.volume));
  }

  void _onUpdateFireVolume(UpdateFireVolume event, Emitter<FocusState> emit) {
    print('[FocusBloc] Handling UpdateFireVolume');
    _soundMixerService.setFireVolume(event.volume);
    emit(state.copyWith(fireVolume: event.volume));
  }

  void _onUpdateBrownNoiseVolume(UpdateBrownNoiseVolume event, Emitter<FocusState> emit) {
    print('[FocusBloc] Handling UpdateBrownNoiseVolume');
    _soundMixerService.setBrownNoiseVolume(event.volume);
    emit(state.copyWith(brownNoiseVolume: event.volume));
  }

  @override
  Future<void> close() {
    print('[FocusBloc] Closed');
    _soundMixerService.dispose();
    return super.close();
  }
}
