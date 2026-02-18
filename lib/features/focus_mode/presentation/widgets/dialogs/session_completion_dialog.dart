import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SessionCompletionDialog extends StatefulWidget {
  final int penaltyCount;
  final Duration totalPenaltyTime;
  final bool isHardcoreMode;
  final bool isPremium;
  final bool canRequestAds;

  const SessionCompletionDialog({
    super.key,
    required this.penaltyCount,
    required this.totalPenaltyTime,
    required this.isHardcoreMode,
    this.isPremium = false,
    this.canRequestAds = false,
  });

  @override
  State<SessionCompletionDialog> createState() =>
      _SessionCompletionDialogState();
}

class _SessionCompletionDialogState extends State<SessionCompletionDialog> {
  bool _showMoneyFlow = false;
  bool _showDonationPrompt = false;
  bool _isStatsExpanded = false;
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = false;
  late final String _randomJoyImage;
  late final String _randomDogPhrase;

  final List<String> _joyImages = [
    'assets/images/joy_2.jpeg',
    'assets/images/joy_3.jpeg',
    'assets/images/joy_4.JPG',
    'assets/images/joy_5.JPG',
  ];

  final List<String> _dogPhrases = [
    'Haciendo pedido por Amazon de un hueso gourmet... 🍖',
    'Calculando cuántas salchichas puede comprar con tu distracción... 🌭',
    'Tu falta de foco es su oportunidad de conseguir un juguete nuevo... 🧸',
    'Ahorrando para el curso de "Cómo ladrarle al cartero sin despertarte"... 📬',
    'Gracias por financiar su jubilación en el parque... 🌳',
    'Tu tiempo perdido se ha convertido en premios de bacon... 🥓',
    'Invirtiendo en el fondo de inversión "Pelotas de Tenis Ilimitadas"... 🎾',
    'Gestionando la suscripción premium de "Olores del Mundo"... 🐕',
    'Convertiremos tu dinero perdido en una cama ortopédica de lujo... 💤',
    'Tu distracción paga las sesiones de spa canino de este mes... 🧼',
  ];

  @override
  void initState() {
    super.initState();
    if (!widget.isPremium && !kIsWeb) {
      _loadInterstitialAd();
    }
    _randomJoyImage = _joyImages[math.Random().nextInt(_joyImages.length)];
    _randomDogPhrase = _dogPhrases[math.Random().nextInt(_dogPhrases.length)];

    // Expansión inicial automática después de un breve delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isStatsExpanded = true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (var image in _joyImages) {
      precacheImage(AssetImage(image), context);
    }
    precacheImage(const AssetImage('assets/images/joy_1.png'), context);
  }

  void _loadInterstitialAd() {
    if (_isAdLoading || kIsWeb) return;

    setState(() {
      _isAdLoading = true;
    });

    final String adUnitId = Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/1033173712'
        : 'ca-app-pub-3940256099942544/4411468910';

    InterstitialAd.load(
      adUnitId: adUnitId,
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
          if (mounted) {
            setState(() {
              _interstitialAd = ad;
              _isAdLoaded = true;
              _isAdLoading = false;
            });
          }
        },
        onAdFailedToLoad: (err) {
          debugPrint('InterstitialAd failed to load: $err');
          if (mounted) {
            setState(() {
              _isAdLoading = false;
              _isAdLoaded = false;
            });
          }
        },
      ),
    );
  }

  void _showAd() {
    if (widget.isPremium || kIsWeb) {
      _dismissDialog();
      return;
    }

    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      if (_isAdLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preparando anuncio... Inténtalo en un momento.'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _dismissDialog();
      }
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

  String get _performanceMessage {
    if (!widget.isHardcoreMode || widget.totalPenaltyTime.inSeconds == 0) {
      return 'Has mantenido el foco con éxito. ¡Gran trabajo!';
    }
    final seconds = widget.totalPenaltyTime.inSeconds;
    if (seconds <= 30) {
      return '¡Casi perfecto! Un pequeño desliz, pero lo has logrado.';
    } else if (seconds <= 60) {
      return 'No ha estado mal, pero necesitas un poco más de disciplina.';
    } else {
      return '¿Necesitas una brújula? Tienes menos concentración que un mosquito. ¡A la próxima mejor!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap:
                    (!widget.isHardcoreMode ||
                        widget.totalPenaltyTime.inSeconds == 0)
                    ? null
                    : () =>
                          setState(() => _isStatsExpanded = !_isStatsExpanded),
                child: MouseRegion(
                  cursor:
                      (!widget.isHardcoreMode ||
                          widget.totalPenaltyTime.inSeconds == 0)
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.click,
                  child: AnimatedRotation(
                    turns:
                        (_isStatsExpanded &&
                            widget.isHardcoreMode &&
                            widget.totalPenaltyTime.inSeconds > 0)
                        ? 0.05
                        : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.celebration,
                      color: Colors.amber,
                      size: 60,
                    ),
                  ),
                ),
              ),
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
              Text(
                _performanceMessage,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.fastOutSlowIn,
                child:
                    (widget.isHardcoreMode &&
                        (_isStatsExpanded ||
                            widget.totalPenaltyTime.inSeconds == 0))
                    ? Container(
                        margin: const EdgeInsets.only(top: 24),
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
                              color: widget.penaltyCount == 0
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(color: Colors.white10),
                            ),
                            _StatRow(
                              icon: Icons.timer_outlined,
                              label: 'Tiempo perdido',
                              value: _formatDuration(widget.totalPenaltyTime),
                              color: widget.totalPenaltyTime.inSeconds == 0
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              if (!_showMoneyFlow && !_showDonationPrompt) ...[
                if (!widget.isHardcoreMode ||
                    widget.totalPenaltyTime.inSeconds == 0)
                  ElevatedButton(
                    onPressed: _dismissDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Terminar sesión',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                else ...[
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
                            _isStatsExpanded = false;
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
                ],
              ] else if (_showMoneyFlow && !_showDonationPrompt) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    _randomJoyImage,
                    height: 260,
                    width: 280,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      width: 280,
                      color: Colors.white.withOpacity(0.05),
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                  'Si no valoras ese dinero, ¿te gustaría donarselo al amigo de la foto?',
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
                          _isStatsExpanded = true;
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
                          _isStatsExpanded = false;
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
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite, color: Colors.pink, size: 50),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/joy_1.png',
                        height: 260,
                        width: 280,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 260,
                          width: 280,
                          color: Colors.white.withOpacity(0.05),
                          child: const Icon(
                            Icons.favorite_border,
                            color: Colors.pink,
                            size: 60,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Text(
                  _randomDogPhrase,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
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
