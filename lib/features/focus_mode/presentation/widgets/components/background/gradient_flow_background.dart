import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

class GradientFlowBackground extends StatefulWidget {
  final Widget? child;

  const GradientFlowBackground({super.key, this.child});

  @override
  State<GradientFlowBackground> createState() => _GradientFlowBackgroundState();
}

class _GradientFlowBackgroundState extends State<GradientFlowBackground>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() {
        _elapsedSeconds = elapsed.inMicroseconds / 1000000.0;
      });
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
    return ShaderBuilder((context, shader, child) {
      return CustomPaint(
        painter: _FlowPainter(shader: shader, time: _elapsedSeconds),
        child: widget.child ?? const SizedBox.expand(),
      );
    }, assetKey: 'shaders/gradient_flow.frag');
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

    // Check if we need to apply border radius
    // Since this is a painter, we should use drawRRect if needed.
    // However, it's often better to clip the widget that contains this painter.
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_FlowPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.shader != shader;
}
