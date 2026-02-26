import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:focus_flow/core/utils/duration_extensions.dart';
import 'session_completion/stat_row.dart';
import 'session_completion/views.dart';

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
  bool _isWaitingForAd = false;
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

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isStatsExpanded = true);
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

    setState(() => _isAdLoading = true);

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
              debugPrint('[AdMob] Failed to show ad: $error');
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
            // Si el usuario ya había pulsado el botón y estaba esperando
            if (_isWaitingForAd) {
              _isWaitingForAd = false;
              _showAd();
            }
          }
        },
        onAdFailedToLoad: (err) {
          debugPrint('[AdMob] InterstitialAd failed to load: $err');
          if (mounted) {
            setState(() {
              _isAdLoading = false;
              _isAdLoaded = false;
            });
            if (_isWaitingForAd) {
              _isWaitingForAd = false;
              _dismissDialog();
            }
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
      // Bloquear doble tap preventivamente
      setState(() {
        _isAdLoaded = false;
        _isWaitingForAd = true;
      });

      _interstitialAd!.setImmersiveMode(true);

      // Pequeño delay para asegurar que el SDK de AdMob y el Activity estén sincronizados
      // (evita el error de "The ad can not be shown when app is not in foreground")
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        try {
          _interstitialAd!.show();
        } catch (e) {
          debugPrint('[AdMob] Exception showing ad: $e');
          _dismissDialog();
        }
      });
    } else if (_isAdLoading) {
      setState(() => _isWaitingForAd = true);
    } else {
      // Si la carga falló antes, intentamos una vez más mostrando spinner
      setState(() => _isWaitingForAd = true);
      _loadInterstitialAd();
    }
  }

  void _dismissDialog() {
    FlutterBackgroundService().invoke('sendEvent', {'event': 'stopAlarm'});
    FlutterBackgroundService().invoke('sendEvent', {'event': 'resetTimer'});
    FlutterBackgroundService().invoke('sendEvent', {'event': 'resumeMix'});
    if (mounted) Navigator.of(context).pop();
  }

  String get _performanceMessage {
    if (!widget.isHardcoreMode || widget.totalPenaltyTime.inSeconds == 0) {
      return 'Has mantenido el foco con éxito. ¡Gran trabajo!';
    }
    final seconds = widget.totalPenaltyTime.inSeconds;
    if (seconds <= 30)
      return '¡Casi perfecto! Un pequeño desliz, pero lo has logrado.';
    if (seconds <= 60)
      return 'No ha estado mal, pero necesitas un poco más de disciplina.';
    return '¿Necesitas una brújula? Tienes menos concentración que un mosquito. ¡A la próxima mejor!';
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
              _buildHeader(),
              const SizedBox(height: 16),
              Text(
                _performanceMessage,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              _buildStats(),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        GestureDetector(
          onTap:
              (!widget.isHardcoreMode || widget.totalPenaltyTime.inSeconds == 0)
              ? null
              : () => setState(() => _isStatsExpanded = !_isStatsExpanded),
          child: AnimatedRotation(
            turns:
                (_isStatsExpanded &&
                    widget.isHardcoreMode &&
                    widget.totalPenaltyTime.inSeconds > 0)
                ? 0.05
                : 0,
            duration: const Duration(milliseconds: 300),
            child: const Icon(Icons.celebration, color: Colors.amber, size: 60),
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
      ],
    );
  }

  Widget _buildStats() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      child:
          (widget.isHardcoreMode &&
              (_isStatsExpanded || widget.totalPenaltyTime.inSeconds == 0))
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
                  StatRow(
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
                  StatRow(
                    icon: Icons.timer_outlined,
                    label: 'Tiempo perdido',
                    value: widget.totalPenaltyTime.toShortPrettyString(),
                    color: widget.totalPenaltyTime.inSeconds == 0
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildContent() {
    if (_showDonationPrompt) {
      return DonationPromptView(
        dogPhrase: _randomDogPhrase,
        onFinish: _dismissDialog,
      );
    }

    if (_showMoneyFlow) {
      return MoneyFlowView(
        imageAsset: _randomJoyImage,
        moneyLost: widget.totalPenaltyTime.calculateMoneyLost(),
        onBack: () => setState(() {
          _showMoneyFlow = false;
          _isStatsExpanded = true;
        }),
        onDonate: () => setState(() {
          _showDonationPrompt = true;
          _isStatsExpanded = false;
        }),
      );
    }

    return _buildInitialActions();
  }

  Widget _buildInitialActions() {
    if (!widget.isHardcoreMode || widget.totalPenaltyTime.inSeconds == 0) {
      return ElevatedButton(
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
      );
    }

    return Column(
      children: [
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
              onPressed: _isWaitingForAd ? null : _showAd,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white54,
                side: const BorderSide(color: Colors.white24),
              ),
              child: _isWaitingForAd
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    )
                  : const Text('No mucho'),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                _showMoneyFlow = true;
                _isStatsExpanded = false;
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sí, lo valoro'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }
}
