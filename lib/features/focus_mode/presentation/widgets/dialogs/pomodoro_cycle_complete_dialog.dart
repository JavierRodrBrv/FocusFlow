import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show File;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/usecases/usecase.dart';
import 'package:focus_flow/features/focus_mode/domain/services/photo_service.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';
import 'package:focus_flow/features/session_history/domain/usecases/save_session_usecase.dart';
import 'package:focus_flow/features/session_history/domain/usecases/get_session_history_usecase.dart';
import 'package:focus_flow/core/presentation/widgets/premium_loader.dart';
import '../components/shared/shader_button.dart';
import 'alternating_button_text.dart';

class PomodoroCycleCompleteDialog extends StatefulWidget {
  final int studyMinutes;
  final int shortMinutes;
  final int longMinutes;
  final Function(String? groupId) onStartNewCycle;
  final VoidCallback onFinish;

  const PomodoroCycleCompleteDialog({
    super.key,
    required this.studyMinutes,
    required this.shortMinutes,
    required this.longMinutes,
    required this.onStartNewCycle,
    required this.onFinish,
  });

  @override
  State<PomodoroCycleCompleteDialog> createState() =>
      _PomodoroCycleCompleteDialogState();
}

class _PomodoroCycleCompleteDialogState
    extends State<PomodoroCycleCompleteDialog> {
  String? _capturedPhotoPath;
  bool _isSavingPhoto = false;

  late int _studyMinutes;
  late int _shortMinutes;
  late int _longMinutes;

  late FixedExtentScrollController _studyController;
  late FixedExtentScrollController _shortController;
  late FixedExtentScrollController _longController;

  final TextEditingController _nameController = TextEditingController();
  bool _isTimeSettingsExpanded = false;
  bool _hasNameError = false;

  bool _validateName() {
    final enteredName = _nameController.text.trim();
    if (enteredName.isEmpty) {
      setState(() {
        _hasNameError = true;
      });
      return false;
    }
    setState(() {
      _hasNameError = false;
    });
    return true;
  }

  @override
  void initState() {
    super.initState();
    _studyMinutes = widget.studyMinutes;
    _shortMinutes = widget.shortMinutes;
    _longMinutes = widget.longMinutes;

    _studyController = FixedExtentScrollController(
      initialItem: _studyMinutes - 1,
    );
    _shortController = FixedExtentScrollController(
      initialItem: _shortMinutes - 1,
    );
    _longController = FixedExtentScrollController(
      initialItem: _longMinutes - 1,
    );
  }

  @override
  void dispose() {
    _studyController.dispose();
    _shortController.dispose();
    _longController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    setState(() {
      _isSavingPhoto = true;
    });
    try {
      final photoPath = await GetIt.instance<PhotoService>().captureStudyFace();
      if (photoPath != null) {
        final getHistory = GetIt.instance<GetSessionHistoryUseCase>();
        final result = await getHistory(NoParams());

        if (result is Success<List<FocusSession>, dynamic>) {
          final sessions =
              (result as Success<List<FocusSession>, dynamic>).value;
          if (sessions.isNotEmpty) {
            // Buscamos la sesión de estudio más reciente del grupo actual que no tenga nombre
            final currentGroupId = sessions.first.groupId;
            final lastStudySession = sessions.firstWhere(
              (s) =>
                  !s.isResting &&
                  s.groupId == currentGroupId &&
                  (s.sessionName == null || s.sessionName!.trim().isEmpty),
              orElse: () => sessions.firstWhere(
                (s) => !s.isResting,
                orElse: () => sessions.first,
              ),
            );
            final updatedSession = lastStudySession.copyWith(
              photoPath: photoPath,
            );

            final saveSession = GetIt.instance<SaveSessionUseCase>();
            await saveSession(updatedSession);

            if (mounted) {
              setState(() {
                _capturedPhotoPath = photoPath;
              });
            }
          }
        } else {
          debugPrint('Failed to get session history to save photo');
        }
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPhoto = false;
        });
      }
    }
  }

  Widget _buildPhotoSection() {
    if (_capturedPhotoPath == null) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: _isSavingPhoto
              ? const SizedBox(
                  key: ValueKey('saving_photo_loader'),
                  height: 80,
                  child: PremiumLoader(
                    size: 80.0,
                    animationPath: 'assets/json/camara_animacion.json',
                  ),
                )
              : Column(
                  key: const ValueKey('take_photo_column'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderButton(
                      key: const ValueKey('take_photo_button'),
                      onPressed: _takePhoto,
                      width: 220,
                      height: 48,
                      child: const AlternatingButtonText(),
                    ),
                  ],
                ),
        ),
      );
    }

    // Polaroid View
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: -0.04, // slight rotation
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Image.file(
                          File(_capturedPhotoPath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: _takePhoto,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '¡Ciclo pomodoro! 🔥',
                    style: GoogleFonts.caveat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveSessionName(String name) async {
    if (name.trim().isEmpty) return;
    try {
      final getHistory = GetIt.instance<GetSessionHistoryUseCase>();
      final result = await getHistory(NoParams());
      if (result is Success<List<FocusSession>, dynamic>) {
        final sessions = (result as Success<List<FocusSession>, dynamic>).value;
        if (sessions.isNotEmpty) {
          final currentGroupId = sessions.first.groupId;
          final saveSession = GetIt.instance<SaveSessionUseCase>();

          // Encontrar todas las sesiones de este grupo que no tienen nombre
          final sessionsToUpdate = sessions
              .where(
                (s) =>
                    s.groupId == currentGroupId &&
                    (s.sessionName == null || s.sessionName!.trim().isEmpty),
              )
              .toList();

          for (var session in sessionsToUpdate) {
            await saveSession(session.copyWith(sessionName: name.trim()));
          }
        }
      }
    } catch (e) {
      debugPrint('Error saving session name: $e');
    }
  }

  void _handleFinish() async {
    if (!_validateName()) return;

    final enteredName = _nameController.text.trim();
    if (enteredName.isNotEmpty) {
      await _saveSessionName(enteredName);
    }
    if (mounted) {
      Navigator.of(context).pop();
      widget.onFinish();
    }
  }

  void _handleStartNewCycle() async {
    if (!_validateName()) return;

    final enteredName = _nameController.text.trim();

    // 1. Guardar el nombre de la sesión si se ingresó
    if (enteredName.isNotEmpty) {
      await _saveSessionName(enteredName);
    }

    // 2. Determinar si los tiempos cambiaron
    final timesChanged =
        _studyMinutes != widget.studyMinutes ||
        _shortMinutes != widget.shortMinutes ||
        _longMinutes != widget.longMinutes;

    String? groupIdToPass;

    if (timesChanged) {
      // Si cambiaron, actualizamos la configuración
      FlutterBackgroundService().invoke('sendEvent', {
        'event': 'setPomodoroConfig',
        'studyMinutes': _studyMinutes,
        'shortBreakMinutes': _shortMinutes,
        'longBreakMinutes': _longMinutes,
      });
      // Al cambiar tiempos, groupIdToPass = null (se generará uno nuevo)
    } else {
      // Si se mantuvieron, obtenemos el groupId de la última sesión
      try {
        final getHistory = GetIt.instance<GetSessionHistoryUseCase>();
        final result = await getHistory(NoParams());
        if (result is Success<List<FocusSession>, dynamic>) {
          final sessions =
              (result as Success<List<FocusSession>, dynamic>).value;
          if (sessions.isNotEmpty) {
            groupIdToPass = sessions.first.groupId;
          }
        }
      } catch (e) {
        debugPrint('Error fetching last groupId: $e');
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
      widget.onStartNewCycle(groupIdToPass);
    }
  }

  Widget _buildPickerColumn({
    required String title,
    required FixedExtentScrollController controller,
    required int maxCount,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 100,
          child: CupertinoPicker(
            scrollController: controller,
            itemExtent: 32,
            onSelectedItemChanged: (int index) {
              onChanged(index + 1);
            },
            children: List.generate(
              maxCount,
              (index) => Center(
                child: Text(
                  '${index + 1} min',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
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
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono Premium de Copa / Trofeo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.amber,
                size: 52,
              ),
            ),
            const SizedBox(height: 20),

            // Título
            const Text(
              '¡Ciclo Completado!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Cuerpo de texto explicativo
            const Text(
              '¡Gran trabajo! Has completado tus 4 bloques de estudio y el descanso largo total. Has mantenido un excelente enfoque.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // 1. TextField para nombre opcional (Diseño Premium)
            TextField(
              controller: _nameController,
              onChanged: (_) {
                if (_hasNameError) {
                  setState(() {
                    _hasNameError = false;
                  });
                }
              },
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: '¿Qué nombre tiene esta sesión?',
                hintStyle: TextStyle(
                  color: _hasNameError
                      ? Colors.redAccent.withValues(alpha: 0.5)
                      : Colors.white30,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _hasNameError
                        ? Colors.redAccent
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _hasNameError
                        ? Colors.redAccent
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _hasNameError
                        ? Colors.redAccent
                        : Colors.orangeAccent,
                    width: 1.5,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.edit_note_rounded,
                  color: _hasNameError ? Colors.redAccent : Colors.orangeAccent,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Sección Momento Foto
            _buildPhotoSection(),

            const SizedBox(height: 24),

            // 3. Pregunta final
            const Text(
              '¿Quieres comenzar un nuevo ciclo Pomodoro?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // 4. Panel Colapsable Premium para Modificar Tiempos
            GestureDetector(
              onTap: () {
                setState(() {
                  _isTimeSettingsExpanded = !_isTimeSettingsExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: Colors.orangeAccent.withValues(alpha: 0.9),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '¿Ajustar tiempos del próximo ciclo?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: _isTimeSettingsExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _isTimeSettingsExpanded
                          ? Column(
                              children: [
                                const SizedBox(height: 12),
                                const Divider(color: Colors.white10),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildPickerColumn(
                                        title: 'Estudio',
                                        controller: _studyController,
                                        maxCount: 120,
                                        onChanged: (val) {
                                          setState(() {
                                            _studyMinutes = val;
                                          });
                                        },
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 80,
                                      color: Colors.white12,
                                    ),
                                    Expanded(
                                      child: _buildPickerColumn(
                                        title: 'D. Corto',
                                        controller: _shortController,
                                        maxCount: 30,
                                        onChanged: (val) {
                                          setState(() {
                                            _shortMinutes = val;
                                          });
                                        },
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 80,
                                      color: Colors.white12,
                                    ),
                                    Expanded(
                                      child: _buildPickerColumn(
                                        title: 'D. Largo',
                                        controller: _longController,
                                        maxCount: 60,
                                        onChanged: (val) {
                                          setState(() {
                                            _longMinutes = val;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        // Botón Listo por hoy
        TextButton(
          onPressed: _handleFinish,
          child: const Text(
            'Listo por hoy',
            style: TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),

        // Botón Comenzar Nuevo Ciclo
        ElevatedButton(
          onPressed: _handleStartNewCycle,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Nuevo Ciclo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
