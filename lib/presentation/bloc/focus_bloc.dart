
import 'package:bloc/bloc.dart';
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
    print('[FocusBloc] State Change: ${change.nextState.status}, isPremium: ${change.nextState.isPremium}');
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
