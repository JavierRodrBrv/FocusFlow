import 'package:flutter/material.dart';
import 'dart:io' show File;
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/usecases/usecase.dart';
import 'package:focus_flow/features/focus_mode/domain/services/photo_service.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';
import 'package:focus_flow/features/session_history/domain/usecases/save_session_usecase.dart';
import 'package:focus_flow/features/session_history/domain/usecases/get_session_history_usecase.dart';
import 'package:focus_flow/core/presentation/widgets/premium_loader.dart';

class PomodoroCycleCompleteDialog extends StatefulWidget {
  final int studyMinutes;
  final int shortMinutes;
  final int longMinutes;
  final VoidCallback onStartNewCycle;
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
  State<PomodoroCycleCompleteDialog> createState() => _PomodoroCycleCompleteDialogState();
}

class _PomodoroCycleCompleteDialogState extends State<PomodoroCycleCompleteDialog> {
  String? _capturedPhotoPath;
  bool _isSavingPhoto = false;

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
          final sessions = (result as Success<List<FocusSession>, dynamic>).value;
          if (sessions.isNotEmpty) {
            // Buscamos la sesión de estudio más reciente (no la sesión de descanso) para asociarle la foto
            final lastStudySession = sessions.firstWhere(
              (s) => !s.isResting,
              orElse: () => sessions.first,
            );
            final updatedSession = lastStudySession.copyWith(photoPath: photoPath);
            
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
        child: _isSavingPhoto
            ? const SizedBox(
                height: 80,
                child: PremiumLoader(size: 64.0),
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Colors.pinkAccent, Colors.purpleAccent, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pinkAccent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _takePhoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    '¿Sonríes? 📸',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
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
            const SizedBox(height: 16),
      
            // Detalle del ciclo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuración utilizada:',
                    style: TextStyle(
                      color: Colors.orangeAccent.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• Estudio: ${widget.studyMinutes} min',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    '• Descanso Corto: ${widget.shortMinutes} min',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    '• Descanso Largo: ${widget.longMinutes} min',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            
            // Sección Momento Foto
            _buildPhotoSection(),
            
            const SizedBox(height: 24),
      
            // Pregunta final
            const Text(
              '¿Quieres comenzar un nuevo ciclo Pomodoro?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        // Botón Listo por hoy
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onFinish();
          },
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
          onPressed: () {
            Navigator.of(context).pop();
            widget.onStartNewCycle();
          },
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
