import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/features/focus_mode/presentation/models/focus_state.dart';
import 'package:focus_flow/l10n/app_localizations.dart';

class BreakSettingsView extends StatefulWidget {
  final FocusState state;
  final VoidCallback onBack;
  final Function(int?) onSave;

  const BreakSettingsView({
    super.key,
    required this.state,
    required this.onBack,
    required this.onSave,
  });

  @override
  State<BreakSettingsView> createState() => _BreakSettingsViewState();
}

class _BreakSettingsViewState extends State<BreakSettingsView> {
  int? _tempBreakMinutes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white70,
              ),
              onPressed: widget.onBack,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 48.0),
                  child: Text(
                    l10n.breaks,
                    style: const TextStyle(
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            l10n.breaksDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: 180,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: (widget.state.defaultBreakDuration?.inMinutes ?? 5) - 1,
            ),
            itemExtent: 44,
            onSelectedItemChanged: (int index) {
              _tempBreakMinutes = index + 1;
            },
            children: List.generate(
              60,
              (index) => Center(
                child: Text(
                  l10n.minOnly(index + 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: () {
              final finalMinutes = _tempBreakMinutes ??
                  (widget.state.defaultBreakDuration?.inMinutes ?? 5);
              widget.onSave(finalMinutes);
            },
            child: Text(
              l10n.accept,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.state.defaultBreakDuration != null)
          TextButton(
            onPressed: () => widget.onSave(null),
            child: Text(
              l10n.deletePreset,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
