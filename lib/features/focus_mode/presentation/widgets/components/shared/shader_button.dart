import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

class ShaderButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final double width;
  final double height;

  const ShaderButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width = 200,
    this.height = 48,
  });

  @override
  State<ShaderButton> createState() => _ShaderButtonState();
}

class _ShaderButtonState extends State<ShaderButton>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (mounted) {
        setState(() {
          _elapsedSeconds = elapsed.inMicroseconds / 1000000.0;
        });
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ShaderBuilder(
          (context, shader, child) {
            return CustomPaint(
              painter: _FlowPainter(shader: shader, time: _elapsedSeconds),
              child: child,
            );
          },
          assetKey: 'shaders/button_gradient_flow.frag',
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

class _FlowPainter extends CustomPainter {
  final FragmentShader shader;
  final double time;

  _FlowPainter({required this.shader, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, time);
    shader.setFloat(1, size.width);
    shader.setFloat(2, size.height);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_FlowPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.shader != shader;
}
