import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';

class SessionCompletionDialog extends StatefulWidget {
  final int penaltyCount;
  final Duration totalPenaltyTime;

  const SessionCompletionDialog({
    super.key,
    required this.penaltyCount,
    required this.totalPenaltyTime,
  });

  @override
  State<SessionCompletionDialog> createState() =>
      _SessionCompletionDialogState();
}

class _SessionCompletionDialogState extends State<SessionCompletionDialog> {
  bool _showMoneyFlow = false;
  bool _showDonationPrompt = false;
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Test ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _dismissDialog();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _dismissDialog();
            },
          );
          _interstitialAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (err) {
          debugPrint('InterstitialAd failed to load: $err');
        },
      ),
    );
  }

  void _showAd() {
    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      // Fallback if ad is not loaded
      _dismissDialog();
    }
  }

  void _dismissDialog() {
    FlutterBackgroundService().invoke('sendEvent', {'event': 'stopAlarm'});
    FlutterBackgroundService().invoke('sendEvent', {'event': 'resetTimer'});
    FlutterBackgroundService().invoke('sendEvent', {'event': 'resumeMix'});
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }

  double get _moneyLost => widget.totalPenaltyTime.inSeconds * 0.50;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button dismissal
      child: AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, color: Colors.amber, size: 60),
              const SizedBox(height: 20),
              const Text(
                '¡Sesión Completada!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Has mantenido el foco con éxito. ¡Gran trabajo!',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              if (widget.penaltyCount > 0) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      _StatRow(
                        icon: Icons.phone_android_rounded,
                        label: 'Veces levantado',
                        value: '${widget.penaltyCount}',
                        color: Colors.orangeAccent,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: Colors.white10),
                      ),
                      _StatRow(
                        icon: Icons.timer_outlined,
                        label: 'Tiempo perdido',
                        value: _formatDuration(widget.totalPenaltyTime),
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              if (!_showMoneyFlow && !_showDonationPrompt) ...[
                const Text(
                  '¿Realmente valoras tu tiempo?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        _showAd();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: const Text('No mucho'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showMoneyFlow = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Sí, lo valoro'),
                    ),
                  ],
                ),
              ] else if (_showMoneyFlow && !_showDonationPrompt) ...[
                const Text(
                  'Ese tiempo perdido equivale a:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_moneyLost.toStringAsFixed(2)}€',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Si no valoras ese dinero, ¿te gustaría donarlo al desarrollador para apoyar el proyecto?',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showMoneyFlow = false;
                        });
                      },
                      child: const Text(
                        'No, gracias',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showDonationPrompt = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('¡Claro!'),
                    ),
                  ],
                ),
              ] else if (_showDonationPrompt) ...[
                const Icon(Icons.favorite, color: Colors.pink, size: 40),
                const SizedBox(height: 12),
                const Text(
                  '¡Eres increíble!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'En el futuro aquí podrás donar y dejar tu reseña. ¡Gracias por valorar nuestro trabajo!',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _dismissDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Próximamente...'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
