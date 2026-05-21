import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/features/focus_mode/presentation/models/focus_state.dart';
import 'package:focus_flow/l10n/app_localizations.dart';

class PomodoroSettingsView extends StatefulWidget {
  final FocusState state;
  final VoidCallback onBack;
  final Function({
    required bool isPomodoro,
    required int studyMinutes,
    required int shortMinutes,
    required int longMinutes,
  }) onSave;

  const PomodoroSettingsView({
    super.key,
    required this.state,
    required this.onBack,
    required this.onSave,
  });

  @override
  State<PomodoroSettingsView> createState() => _PomodoroSettingsViewState();
}

class _PomodoroSettingsViewState extends State<PomodoroSettingsView> {
  late bool _isPomodoroMode;
  late int _studyMinutes;
  late int _shortMinutes;
  late int _longMinutes;

  late FixedExtentScrollController _studyController;
  late FixedExtentScrollController _shortController;
  late FixedExtentScrollController _longController;

  @override
  void initState() {
    super.initState();
    _isPomodoroMode = widget.state.isPomodoroMode;
    _studyMinutes = widget.state.pomodoroDuration.inMinutes;
    _shortMinutes = widget.state.shortBreakDuration.inMinutes;
    _longMinutes = widget.state.longBreakDuration.inMinutes;

    // Los pickers son de base 1, por lo que el índice es minutes - 1
    _studyController = FixedExtentScrollController(initialItem: _studyMinutes - 1);
    _shortController = FixedExtentScrollController(initialItem: _shortMinutes - 1);
    _longController = FixedExtentScrollController(initialItem: _longMinutes - 1);
  }

  @override
  void dispose() {
    _studyController.dispose();
    _shortController.dispose();
    _longController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    widget.onSave(
      isPomodoro: _isPomodoroMode,
      studyMinutes: _studyMinutes,
      shortMinutes: _shortMinutes,
      longMinutes: _longMinutes,
    );
  }

  Widget _buildPickerColumn({
    required String title,
    required FixedExtentScrollController controller,
    required int maxCount,
    required ValueChanged<int> onChanged,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: CupertinoPicker(
            scrollController: controller,
            itemExtent: 38,
            onSelectedItemChanged: (int index) {
              onChanged(index + 1);
            },
            children: List.generate(
              maxCount,
              (index) => Center(
                child: Text(
                  l10n.minOnly(index + 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fila de encabezado
        Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white70,
              ),
              onPressed: widget.onBack,
            ),
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 48.0),
                  child: Text(
                    'Pomodoros',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Interruptor del modo Pomodoro
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: const Text(
                'Modo Pomodoro',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Ejecuta un ciclo de estudio y descansos automáticos.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              value: _isPomodoroMode,
              onChanged: (val) {
                setState(() {
                  _isPomodoroMode = val;
                });
                _saveSettings();
              },
              activeColor: Colors.orangeAccent,
              activeTrackColor: Colors.orangeAccent.withOpacity(0.3),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Selectores de tiempo (Animados al activarse/desactivarse)
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isPomodoroMode ? 1.0 : 0.4,
          child: AbsorbPointer(
            absorbing: !_isPomodoroMode,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPickerColumn(
                        title: 'Estudio',
                        controller: _studyController,
                        maxCount: 120,
                        onChanged: (val) {
                          _studyMinutes = val;
                          _saveSettings();
                        },
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 100,
                      color: Colors.white12,
                    ),
                    Expanded(
                      child: _buildPickerColumn(
                        title: 'Descanso Corto',
                        controller: _shortController,
                        maxCount: 30,
                        onChanged: (val) {
                          _shortMinutes = val;
                          _saveSettings();
                        },
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 100,
                      color: Colors.white12,
                    ),
                    Expanded(
                      child: _buildPickerColumn(
                        title: 'Descanso Largo',
                        controller: _longController,
                        maxCount: 60,
                        onChanged: (val) {
                          _longMinutes = val;
                          _saveSettings();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}
