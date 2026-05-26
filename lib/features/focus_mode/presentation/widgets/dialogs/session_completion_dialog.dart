import 'package:flutter/foundation.dart';
import 'dart:io' show File, Platform;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:focus_flow/core/utils/duration_extensions.dart';
import 'session_completion/stat_row.dart';
import 'session_completion/views.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';
import 'package:focus_flow/features/focus_mode/domain/services/photo_service.dart';
import 'package:focus_flow/features/session_history/domain/usecases/save_session_usecase.dart';
import 'package:focus_flow/features/session_history/domain/usecases/get_session_history_usecase.dart';
import 'package:focus_flow/core/usecases/usecase.dart';
import 'package:focus_flow/core/presentation/widgets/premium_loader.dart';
import '../components/shared/shader_button.dart';

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
  String _randomDogPhrase = '';
  String? _capturedPhotoPath;
  bool _isSavingPhoto = false;
  final TextEditingController _nameController = TextEditingController();
  bool _hasNameError = false;

  bool _validateName() {
    final enteredName = _nameController.text.trim();
    if (enteredName.isEmpty) {
      setState(() {
        _hasNameError = true;
      });
      return false;
    }
    setState(() {
      _hasNameError = false;
    });
    return true;
  }

  Future<void> _saveSessionName(String name) async {
    if (name.trim().isEmpty) return;
    try {
      final getHistory = GetIt.instance<GetSessionHistoryUseCase>();
      final result = await getHistory(NoParams());
      if (result is Success<List<FocusSession>, dynamic>) {
        final sessions = (result as Success<List<FocusSession>, dynamic>).value;
        if (sessions.isNotEmpty) {
          final currentGroupId = sessions.first.groupId;
          final saveSession = GetIt.instance<SaveSessionUseCase>();
          
          final sessionsToUpdate = sessions.where((s) => 
            s.groupId == currentGroupId && (s.sessionName == null || s.sessionName!.trim().isEmpty)
          ).toList();
          
          for (var session in sessionsToUpdate) {
            await saveSession(session.copyWith(sessionName: name.trim()));
          }
        }
      }
    } catch (e) {
      debugPrint('Error saving session name: $e');
    }
  }

  final List<String> _joyImages = [
    'assets/images/joy_2.jpeg',
    'assets/images/joy_3.jpeg',
    'assets/images/joy_4.JPG',
    'assets/images/joy_5.JPG',
  ];

  List<String> _getDogPhrases(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.dogPhrase1,
      l10n.dogPhrase2,
      l10n.dogPhrase3,
      l10n.dogPhrase4,
      l10n.dogPhrase5,
      l10n.dogPhrase6,
      l10n.dogPhrase7,
      l10n.dogPhrase8,
      l10n.dogPhrase9,
      l10n.dogPhrase10,
    ];
  }

  @override
  void initState() {
    super.initState();
    if (!widget.isPremium && !kIsWeb) {
      _loadInterstitialAd();
    }
    _randomJoyImage = _joyImages[math.Random().nextInt(_joyImages.length)];

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

    if (_randomDogPhrase.isEmpty) {
      final phrases = _getDogPhrases(context);
      _randomDogPhrase = phrases[math.Random().nextInt(phrases.length)];
    }
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
    if (!_validateName()) return;
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

  void _dismissDialog() async {
    if (!_validateName()) return;
    final enteredName = _nameController.text.trim();
    if (enteredName.isNotEmpty) {
      await _saveSessionName(enteredName);
    }
    FlutterBackgroundService().invoke('sendEvent', {'event': 'stopAlarm'});
    FlutterBackgroundService().invoke('sendEvent', {'event': 'resetTimer'});
    if (mounted) Navigator.of(context).pop();
  }

  String _getPerformanceMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!widget.isHardcoreMode || widget.totalPenaltyTime.inSeconds == 0) {
      return l10n.perfGood;
    }
    final seconds = widget.totalPenaltyTime.inSeconds;
    if (seconds <= 30) {
      return l10n.perfPerfect;
    }
    if (seconds <= 60) {
      return l10n.perfNotBad;
    }
    return l10n.perfMosquito;
  }

  Future<void> _takePhoto() async {
    setState(() {
      _isSavingPhoto = true;
    });
    try {
      final photoPath = await GetIt.instance<PhotoService>().captureStudyFace();
      if (photoPath != null) {
        final getHistory = GetIt.instance<GetSessionHistoryUseCase>();
        final result = await getHistory(NoParams());

        if (result is Success<List<FocusSession>, dynamic>) {
          final sessions =
              (result as Success<List<FocusSession>, dynamic>).value;
          if (sessions.isNotEmpty) {
            final currentGroupId = sessions.first.groupId;
            final lastSession = sessions.firstWhere(
              (s) => s.groupId == currentGroupId && (s.sessionName == null || s.sessionName!.trim().isEmpty),
              orElse: () => sessions.first,
            );
            final updatedSession = lastSession.copyWith(photoPath: photoPath);

            final saveSession = GetIt.instance<SaveSessionUseCase>();
            await saveSession(updatedSession);

            if (mounted) {
              setState(() {
                _capturedPhotoPath = photoPath;
              });
            }
          }
        } else {
          debugPrint('Failed to get session history to save photo');
        }
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPhoto = false;
        });
      }
    }
  }

  Widget _buildPhotoSection() {
    if (_capturedPhotoPath == null) {
      return Container(
        margin: const EdgeInsets.only(top: 20),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: _isSavingPhoto
              ? const SizedBox(
                  key: ValueKey('saving_photo_loader'),
                  height: 80,
                  child: PremiumLoader(
                    size: 80.0,
                    animationPath: 'assets/json/camara_animacion.json',
                  ),
                )
              : ShaderButton(
                  key: const ValueKey('take_photo_button'),
                  onPressed: _takePhoto,
                  width: 220,
                  height: 48,
                  child: const Text(
                    '¿Sonríes?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
        ),
      );
    }

    // Polaroid View
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: -0.04, // slight rotation
            child: Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Image.file(
                          File(_capturedPhotoPath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: _takePhoto,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '¡Foco completado! 🔥',
                    style: GoogleFonts.caveat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
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
              _buildHeader(context),
              const SizedBox(height: 16),
              Text(
                _getPerformanceMessage(context),
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              _buildStats(context),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                onChanged: (val) {
                  if (_hasNameError && val.trim().isNotEmpty) {
                    setState(() {
                      _hasNameError = false;
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: '¿Qué nombre tiene esta sesión?',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                  errorText: _hasNameError ? 'El nombre de la sesión es obligatorio' : null,
                  errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _hasNameError ? Colors.redAccent : Colors.white.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _hasNameError ? Colors.redAccent : Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _hasNameError ? Colors.redAccent : Colors.blueAccent, width: 1.5),
                  ),
                  prefixIcon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent),
                ),
              ),
              _buildPhotoSection(),
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

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
        Text(
          l10n.sessionCompletedTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  StatRow(
                    icon: Icons.phone_android_rounded,
                    label: l10n.timesLifted,
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
                    label: l10n.timeLost,
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
        child: Text(
          AppLocalizations.of(context)!.finishSession,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(
          l10n.valueYourTime,
          style: const TextStyle(
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
                  : Text(l10n.notMuch),
            ),
            ElevatedButton(
              onPressed: () {
                if (_validateName()) {
                  setState(() {
                    _showMoneyFlow = true;
                    _isStatsExpanded = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.yesValue),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }
}
