import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/background_effect.dart';
import 'package:focus_flow/features/focus_mode/presentation/bloc/focus_bloc.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/components/gradient_flow_background.dart';
import 'package:http/http.dart' as http;

class SettingsMenuBottomSheet extends StatefulWidget {
  final FocusState initialState;
  const SettingsMenuBottomSheet({super.key, required this.initialState});

  @override
  State<SettingsMenuBottomSheet> createState() =>
      _SettingsMenuBottomSheetState();
}

class _SettingsMenuBottomSheetState extends State<SettingsMenuBottomSheet> {
  int _currentView = 0; // 0: Main, 1: Fondo, 2: Feedback
  int _previousView = 0;

  // Feedback State
  final TextEditingController _feedbackController = TextEditingController();
  final FocusNode _feedbackFocusNode = FocusNode();
  int _feedbackSelectedIndex = 0; // 0 = Bug, 1 = Idea
  bool _feedbackIsLoading = false;
  bool _feedbackIsSuccess = false;

  void _goToView(int view) {
    setState(() {
      _previousView = _currentView;
      _currentView = view;
    });

    // Auto-focus if entering feedback view
    if (view == 2) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _feedbackFocusNode.requestFocus();
      });
    } else {
      _feedbackFocusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _feedbackFocusNode.dispose();
    super.dispose();
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
            // Error parsing, ignore
          }
        }

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            transitionBuilder: (Widget child, Animation<double> animation) {
              final isEntering = child.key == ValueKey(_currentView);
              double beginOffset = _currentView > _previousView ? 1.0 : -1.0;
              if (!isEntering) beginOffset = -beginOffset;

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(beginOffset, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            child: _buildCurrentView(context, state),
          ),
        );
      },
    );
  }

  Widget _buildCurrentView(BuildContext context, FocusState state) {
    switch (_currentView) {
      case 1:
        return _buildFondoMenu(context, state);
      case 2:
        return _buildFeedbackMenu(context);
      default:
        return _buildMainMenu(context, state);
    }
  }

  Widget _buildMainMenu(BuildContext context, FocusState state) {
    return Container(
      key: const ValueKey(0),
      padding: const EdgeInsets.symmetric(vertical: 20),
      constraints: const BoxConstraints(minHeight: 480),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Ajustes y Ayuda',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SwitchListTile(
              secondary: Icon(
                state.isAlarmSoundEnabled ? Icons.volume_up : Icons.volume_off,
                color: state.isAlarmSoundEnabled ? Colors.amber : Colors.grey,
              ),
              title: const Text(
                'Sonido de Alarma',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Si se desactiva, solo vibrará al finalizar.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              value: state.isAlarmSoundEnabled,
              onChanged: (bool value) {
                FlutterBackgroundService().invoke('sendEvent', {
                  'event': 'toggleAlarmSound',
                });
              },
              activeTrackColor: Colors.amber,
              activeThumbColor: Colors.amberAccent,
            ),

            ListTile(
              leading:
                  const Icon(Icons.palette_outlined, color: Colors.cyanAccent),
              title: const Text(
                'Fondo de Pantalla',
                style: TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white30),
              onTap: () => _goToView(1),
            ),

            const Divider(color: Colors.white10),

            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.white70),
              title: const Text(
                'Ver Tutorial',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context, 'tutorial');
              },
            ),

            ListTile(
              leading: const Icon(Icons.mail_outline, color: Colors.blueAccent),
              title: const Text(
                'Enviar Feedback / Reportar Bug',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                '¡Tu opinión nos ayuda a mejorar!',
                style: TextStyle(color: Colors.white38),
              ),

              trailing: const Icon(Icons.chevron_right, color: Colors.white30),
              onTap: () => _goToView(2),
            ),

            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white54),
              title: const Text(
                'Versión 0.2.0 (Beta)',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () {},
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFondoMenu(BuildContext context, FocusState state) {
    return Container(
      key: const ValueKey(1),
      padding: const EdgeInsets.symmetric(vertical: 20),
      // Mantenemos una altura mínima y máxima consistente para evitar saltos y expansión infinita
      constraints: const BoxConstraints(minHeight: 480),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with Back Button
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white70,
                ),
                onPressed: () => _goToView(0),
              ),
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(right: 48.0),
                    child: Text(
                      'Fondo',
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

          const SizedBox(height: 40),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOption(
                  label: 'Sólido',
                  effect: BackgroundEffect.solid,
                  isSelected: state.backgroundEffect == BackgroundEffect.solid,
                  preview: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                  ),
                  onTap: () => _setBackground(BackgroundEffect.solid),
                ),
                _buildOption(
                  label: 'Gradiente',
                  effect: BackgroundEffect.gradient,
                  isSelected:
                      state.backgroundEffect == BackgroundEffect.gradient,
                  preview: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: const GradientFlowBackground(
                      child: SizedBox.expand(),
                    ),
                  ),
                  onTap: () => _setBackground(BackgroundEffect.gradient),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFeedbackMenu(BuildContext context) {
    final activeColor = _feedbackSelectedIndex == 0
        ? const Color(0xFFEF5350)
        : const Color(0xFF2979FF);

    return Container(
      key: const ValueKey(2),
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: const BoxConstraints(minHeight: 480),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white70,
                  ),
                  onPressed: () => _goToView(0),
                ),
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 48.0),
                      child: Text(
                        'Feedback',
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
            const SizedBox(height: 20),
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child:
                        _buildFeedbackSegment(0, '¿Es un Bug? 🐞', activeColor),
                  ),
                  Expanded(
                    child:
                        _buildFeedbackSegment(1, '¿Una Idea? 💡', activeColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _feedbackController,
              focusNode: _feedbackFocusNode,
              maxLines: 4,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[100],
                hintText: _feedbackSelectedIndex == 0
                    ? 'Describe el error que encontraste...'
                    : 'Cuéntanos qué te gustaría ver...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: (_feedbackIsLoading || _feedbackIsSuccess)
                  ? null
                  : _submitFeedback,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 56,
                decoration: BoxDecoration(
                  color: _feedbackIsSuccess ? Colors.green : activeColor,
                  borderRadius: BorderRadius.circular(
                    _feedbackIsLoading || _feedbackIsSuccess ? 50 : 16,
                  ),
                ),
                alignment: Alignment.center,
                child: _buildFeedbackButtonContent(),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSegment(int index, String label, Color activeColor) {
    final isSelected = _feedbackSelectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (_feedbackSelectedIndex != index) {
          HapticFeedback.lightImpact();
          setState(() => _feedbackSelectedIndex = index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: isSelected ? Border.all(color: activeColor, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackButtonContent() {
    if (_feedbackIsLoading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    }
    if (_feedbackIsSuccess) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check, color: Colors.white),
          SizedBox(width: 8),
          Text(
            '¡Gracias!',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      );
    }
    return const Text(
      'Enviar Feedback',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  Future<void> _submitFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() => _feedbackIsLoading = true);

    final subject = _feedbackSelectedIndex == 0
        ? 'Bug Report [FocusFlow]'
        : 'Feature Idea [FocusFlow]';
    final url = Uri.parse('https://formsubmit.co/ajax/andaluzcode@gmail.com');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Referer': 'https://focusflow.app',
        },
        body: jsonEncode({
          '_subject': subject,
          'name': 'FocusFlow App User',
          'message': text,
          '_template': 'table',
          '_captcha': 'false',
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _feedbackIsLoading = false;
          _feedbackIsSuccess = true;
        });
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _goToView(0);
        _feedbackController.clear();
        setState(() => _feedbackIsSuccess = false);
      } else {
        throw Exception('Server Error');
      }
    } catch (e) {
      setState(() => _feedbackIsLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildOption({
    required String label,
    required BackgroundEffect effect,
    required bool isSelected,
    required Widget preview,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 160,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
                width: 2,
              ),
            ),
            child: preview,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<BackgroundEffect>(
                value: effect,
                groupValue: isSelected ? effect : null,
                onChanged: (val) {
                  if (val != null) onTap();
                },
                activeColor: Colors.blueAccent,
              ),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _setBackground(BackgroundEffect effect) {
    FlutterBackgroundService().invoke('sendEvent', {
      'event': 'setBackgroundEffect',
      'effect': effect.index,
    });
  }
}
