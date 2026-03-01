import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../../models/focus_state.dart';
import 'ambience_list.dart';
import 'mixer_controls_row.dart';
import 'mixer_header.dart';
import 'mixer_slider.dart';

class ExpandableSoundMixer extends StatefulWidget {
  final FocusState state;
  final FlutterBackgroundService service;

  const ExpandableSoundMixer({
    super.key,
    required this.state,
    required this.service,
  });

  @override
  State<ExpandableSoundMixer> createState() => _ExpandableSoundMixerState();
}

class _ExpandableSoundMixerState extends State<ExpandableSoundMixer>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  int _selectedTabIndex = 0; // 0: Mezclador, 1: Sonido de Fondo
  late final AnimationController _iconController;
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    if (widget.state.isPlayingMix) {
      _iconController.forward();
    }
  }

  @override
  void didUpdateWidget(ExpandableSoundMixer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.isPlayingMix != oldWidget.state.isPlayingMix) {
      if (widget.state.isPlayingMix) {
        _iconController.forward();
      } else {
        _iconController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.state.isPlayingMix;
    final state = widget.state;
    final service = widget.service;

    return Card(
      elevation: 0,
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPlaying
              ? Colors.blueAccent.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.05),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER
          MixerHeader(
            isPlaying: isPlaying,
            onTap: _toggleExpanded,
            expandAnimation: _expandAnimation,
          ),

          // CONTENT
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1.0,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
              child: Column(
                children: [
                  const Divider(color: Colors.white10),
                  
                  // Tab Selector
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        _buildTabButton('Mezclador', 0),
                        const SizedBox(width: 8),
                        _buildTabButton('Sonido de fondo', 1),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  if (_selectedTabIndex == 0) ...[
                    MixerSlider(
                      label: 'Lluvia',
                      icon: Icons.water_drop,
                      value: state.rainVolume,
                      onChanged: (v) => service.invoke('sendEvent', {'event': 'updateRainVolume', 'volume': v}),
                    ),
                    MixerSlider(
                      label: 'Fuego',
                      icon: Icons.local_fire_department,
                      value: state.fireVolume,
                      onChanged: (v) => service.invoke('sendEvent', {'event': 'updateFireVolume', 'volume': v}),
                    ),
                    MixerSlider(
                      label: 'Olas',
                      icon: Icons.waves,
                      value: state.brownNoiseVolume,
                      onChanged: (v) => service.invoke('sendEvent', {'event': 'updateBrownNoiseVolume', 'volume': v}),
                    ),
                    const SizedBox(height: 24),

                    // CONTROLS ROW
                    MixerControlsRow(
                      state: state,
                      service: service,
                      iconController: _iconController,
                      isPlaying: isPlaying,
                    ),
                  ] else ...[
                    AmbienceList(state: state, service: service),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blueAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blueAccent : Colors.white38,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
