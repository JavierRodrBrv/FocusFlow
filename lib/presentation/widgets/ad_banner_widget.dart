
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  AnchoredAdaptiveBannerAdSize? _adSize;
  bool _isAdLoaded = false;

  // TODO: Replace with your real Ad Unit ID for production.
  final adUnitId = 'ca-app-pub-3940256099942544/6300978111';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('[AdBannerWidget] didChangeDependencies called.');
    _loadAd();
  }

  Future<void> _loadAd() async {
    // Si ya hay un anuncio cargado o se está cargando, no hacer nada.
    if (_bannerAd != null && _isAdLoaded) {
      print('[AdBannerWidget] Ad already loaded or loading.');
      return;
    }

    print('[AdBannerWidget] Getting ad size...');
    // Obtener el ancho de la pantalla para el banner adaptativo.
    final width = MediaQuery.of(context).size.width.truncate();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    
    if (size == null) {
      print('[AdBannerWidget] ERROR: Unable to get adaptive ad size.');
      return;
    }
    print('[AdBannerWidget] Adaptive ad size obtained: ${size.width}x${size.height}');

    // Actualizar el estado con el tamaño calculado si es necesario.
    if (mounted) {
      setState(() {
        _adSize = size;
      });
    }

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: _adSize!,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('[AdBannerWidget] Ad loaded successfully.');
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          print('[AdBannerWidget] ERROR: Failed to load Ad: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    print('[AdBannerWidget] build called. isAdLoaded: $_isAdLoaded');
    if (_bannerAd != null && _isAdLoaded && _adSize != null) {
      return SizedBox(
        width: _adSize!.width.toDouble(),
        height: _adSize!.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    
    // Devuelve un contenedor con el alto esperado del anuncio mientras carga
    // para evitar saltos en la UI.
    return SizedBox(
      height: _adSize?.height.toDouble() ?? 50, // Default to 50 if size not yet known
    );
  }

  @override
  void dispose() {
    print('[AdBannerWidget] dispose: Disposing ad.');
    _bannerAd?.dispose();
    super.dispose();
  }
}
