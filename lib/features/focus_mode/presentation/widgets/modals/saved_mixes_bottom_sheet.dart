import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import '../../models/focus_state.dart';

class SavedMixesBottomSheet extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;

  const SavedMixesBottomSheet({
    super.key,
    required this.state,
    required this.service,
  });

  static Future<void> show(
    BuildContext context,
    FocusState state,
    FlutterBackgroundService service,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          SavedMixesBottomSheet(state: state, service: service),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (state.savedMixes.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            l10n.noSavedMixes,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.savedMixesTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: state.savedMixes.length,
              separatorBuilder: (_, _) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final mix = state.savedMixes[index];
                final isSelected = mix.id == state.lastActivatedMixId;
                final isHistory =
                    mix.id == state.persistedLastMixId && !isSelected;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.greenAccent.withValues(alpha: 0.2)
                          : isHistory
                          ? Colors.grey.withValues(alpha: 0.2)
                          : Colors.blueAccent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSelected
                          ? Icons.check
                          : isHistory
                          ? Icons.history
                          : Icons.music_note,
                      color: isSelected
                          ? Colors.greenAccent
                          : isHistory
                          ? Colors.white70
                          : Colors.blueAccent,
                    ),
                  ),
                  title: Text(
                    mix.name,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.greenAccent
                          : isHistory
                          ? Colors.white70
                          : Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    l10n.mixDetail(
                      (mix.rainVolume * 100).toInt(),
                      (mix.fireVolume * 100).toInt(),
                      (mix.brownNoiseVolume * 100).toInt(),
                      isHistory ? l10n.lastActivatedLabel : "",
                    ),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  onTap: () {
                    service.invoke('sendEvent', {
                      'event': 'loadMix',
                      'mixId': mix.id,
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
