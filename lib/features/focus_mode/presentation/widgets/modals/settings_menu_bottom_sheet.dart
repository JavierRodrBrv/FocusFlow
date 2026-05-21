import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/presentation/models/focus_state.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/modals/settings/views/pomodoro_settings_view.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/modals/settings/views/feedback_menu_view.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/modals/settings/views/language_menu_view.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/modals/settings/views/main_menu_view.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/modals/settings/views/wallpaper_menu_view.dart';

enum SettingsView {
  main,
  wallpaper,
  language,
  feedback,
  pomodoroSettings,
}

class SettingsMenuBottomSheet extends StatefulWidget {
  final FocusState initialState;

  const SettingsMenuBottomSheet({
    super.key,
    required this.initialState,
  });

  @override
  State<SettingsMenuBottomSheet> createState() => _SettingsMenuBottomSheetState();
}

class _SettingsMenuBottomSheetState extends State<SettingsMenuBottomSheet> {
  SettingsView _currentView = SettingsView.main;

  void _navigateTo(SettingsView view) {
    setState(() {
      _currentView = view;
    });
  }

  void _goBack() {
    setState(() {
      _currentView = SettingsView.main;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: FlutterBackgroundService().on('update'),
      initialData: widget.initialState.toJson(),
      builder: (context, snapshot) {
        FocusState state = widget.initialState;
        if (snapshot.hasData && snapshot.data != null) {
          try {
            state = FocusState.fromJson(snapshot.data!);
          } catch (e) {
            // Use last known
          }
        }

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildCurrentView(state),
          ),
        );
      },
    );
  }

  Widget _buildCurrentView(FocusState state) {
    final service = FlutterBackgroundService();

    switch (_currentView) {
      case SettingsView.main:
        return MainMenuView(
          key: const ValueKey('main_menu'),
          state: state,
          onToggleAlarm: () => service.invoke('sendEvent', {'event': 'toggleAlarmSound'}),
          onToggleAutoTransition: () => service.invoke('sendEvent', {'event': 'toggleAutoTransition'}),
          onGoToPomodoros: () => _navigateTo(SettingsView.pomodoroSettings),
          onGoToWallpaper: () => _navigateTo(SettingsView.wallpaper),
          onGoToLanguage: () => _navigateTo(SettingsView.language),
          onGoToFeedback: () => _navigateTo(SettingsView.feedback),
          onShowTutorial: () => Navigator.pop(context, 'tutorial'),
        );
      case SettingsView.wallpaper:
        return WallpaperMenuView(
          key: const ValueKey('wallpaper_menu'),
          state: state,
          onBack: _goBack,
          onSelectEffect: (effect) => service.invoke('sendEvent', {
            'event': 'setBackgroundEffect',
            'effect': effect.index,
          }),
        );
      case SettingsView.language:
        return LanguageMenuView(
          key: const ValueKey('language_menu'),
          state: state,
          onBack: _goBack,
          onSelectLanguage: (code) => service.invoke('sendEvent', {
            'event': 'setLanguageCode',
            'code': code,
          }),
        );
      case SettingsView.feedback:
        return FeedbackMenuView(
          key: const ValueKey('feedback_menu'),
          onBack: _goBack,
          onSuccess: () => Navigator.pop(context),
        );
      case SettingsView.pomodoroSettings:
        return PomodoroSettingsView(
          key: const ValueKey('pomodoro_settings'),
          state: state,
          onBack: _goBack,
          onSave: ({
            required isPomodoro,
            required studyMinutes,
            required shortMinutes,
            required longMinutes,
          }) {
            service.invoke('sendEvent', {
              'event': 'setPomodoroMode',
              'isPomodoro': isPomodoro,
            });
            service.invoke('sendEvent', {
              'event': 'setPomodoroConfig',
              'studyMinutes': studyMinutes,
              'shortBreakMinutes': shortMinutes,
              'longBreakMinutes': longMinutes,
            });
          },
        );
    }
  }
}
