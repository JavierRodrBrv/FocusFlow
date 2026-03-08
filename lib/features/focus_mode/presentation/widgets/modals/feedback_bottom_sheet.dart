import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class FeedbackBottomSheet extends StatefulWidget {
  const FeedbackBottomSheet({super.key});

  @override
  State<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<FeedbackBottomSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // 0 = Bug, 1 = Idea
  int _selectedIndex = 0;

  // Button State
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus after the sheet animation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSegmentChanged(int index) {
    if (_selectedIndex != index) {
      HapticFeedback.lightImpact();
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _submitFeedback() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();

    // Start Loading
    setState(() {
      _isLoading = true;
    });

    final subject = _selectedIndex == 0
        ? 'Bug Report [FocusFlow]'
        : 'Feature Idea [FocusFlow]';

    // Usando FormSubmit
    // Documentación: https://formsubmit.co/help
    final url = Uri.parse('https://formsubmit.co/ajax/andaluzcode@gmail.com');

    try {
      debugPrint('Enviando feedback a: $url');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // TRUCO: FormSubmit requiere un Referer válido para no pensar que es spam o archivo local
          'Referer': 'https://focusflow.app',
        },
        body: jsonEncode({
          '_subject':
              subject, // Usar _subject para que sea el asunto del correo
          'name': 'FocusFlow App User', // Identificador
          'message': text,
          '_template': 'table',
          '_captcha': 'false',
          // Opcional: Responder a una dirección dummy si no pedimos email al usuario
          // 'email': 'no-reply@focusflow.app',
        }),
      );

      debugPrint('FormSubmit Response Code: ${response.statusCode}');
      debugPrint('FormSubmit Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Success
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });

        HapticFeedback.heavyImpact();

        // Wait 2 seconds then close
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        throw Exception(
          'Server returned ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error sending feedback: $e');
      setState(() {
        _isLoading = false;
      });
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

  Color get _activeColor => _selectedIndex == 0
      ? const Color(0xFFEF5350) // Soft Red for Bug
      : const Color(0xFF2979FF); // Electric Blue for Idea

  @override
  Widget build(BuildContext context) {
    // Determine keyboard height to push content up if needed
    // standard bottom sheet handles this usually, but let's be safe
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header (Optional, if we want a title)
          // const Text(
          //   'Tu opinión importa',
          //   style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          //   textAlign: TextAlign.center,
          // ),
          // const SizedBox(height: 20),

          // Segmented Control (Toggle)
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onSegmentChanged(0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 0
                            ? _activeColor.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        border: _selectedIndex == 0
                            ? Border.all(color: _activeColor, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '¿Es un Bug? 🐞',
                        style: TextStyle(
                          color: _selectedIndex == 0
                              ? Colors.white
                              : Colors.white54,
                          fontWeight: _selectedIndex == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onSegmentChanged(1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 1
                            ? _activeColor.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        border: _selectedIndex == 1
                            ? Border.all(color: _activeColor, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '¿Una Idea? 💡',
                        style: TextStyle(
                          color: _selectedIndex == 1
                              ? Colors.white
                              : Colors.white54,
                          fontWeight: _selectedIndex == 1
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Input Field
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: 4,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              hintText: _selectedIndex == 0
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

          const SizedBox(height: 24),

          // Action Button
          GestureDetector(
            onTap: (_isLoading || _isSuccess) ? null : _submitFeedback,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 56,
              decoration: BoxDecoration(
                color: _isSuccess ? Colors.green : _activeColor,
                borderRadius: BorderRadius.circular(
                  _isLoading || _isSuccess ? 50 : 16,
                ),
              ),
              alignment: Alignment.center,
              child: _buildButtonContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    }

    if (_isSuccess) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check, color: Colors.white),
          SizedBox(width: 8),
          Text(
            '¡Gracias, lo revisaremos!',
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
}
