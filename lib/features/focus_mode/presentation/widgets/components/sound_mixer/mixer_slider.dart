import 'package:flutter/material.dart';

class MixerSlider extends StatefulWidget {
  final String label;
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;

  const MixerSlider({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  State<MixerSlider> createState() => _MixerSliderState();
}

class _MixerSliderState extends State<MixerSlider> {
  late double _currentValue;
  bool _isDragging = false;
  DateTime _lastUpdateTime = DateTime.now();
  DateTime _lastInteractionTime =
      DateTime.now().subtract(const Duration(seconds: 1));

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant MixerSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isUserInteracting = _isDragging ||
        DateTime.now().difference(_lastInteractionTime).inMilliseconds < 500;

    if (!isUserInteracting && widget.value != _currentValue) {
      setState(() => _currentValue = widget.value);
    }
  }

  void _handleChanged(double val) {
    setState(() {
      _currentValue = val;
      _lastInteractionTime = DateTime.now();
    });

    // Debounce to not saturate the background service
    final now = DateTime.now();
    if (now.difference(_lastUpdateTime) > const Duration(milliseconds: 16)) {
      widget.onChanged(val);
      _lastUpdateTime = now;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(widget.icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: _currentValue,
              activeColor: Colors.blueAccent,
              inactiveColor: Colors.white10,
              onChangeStart: (_) => setState(() => _isDragging = true),
              onChangeEnd: (val) {
                setState(() {
                  _isDragging = false;
                  _lastInteractionTime = DateTime.now();
                });
                widget.onChanged(val);
              },
              onChanged: _handleChanged,
            ),
          ),
        ),
        SizedBox(
          width: 35,
          child: Text(
            '${(_currentValue * 100).toInt()}%',
            style: const TextStyle(fontSize: 10, color: Colors.white38),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
