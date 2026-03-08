import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/flavors.dart';

class PremiumFeatureDialog extends StatelessWidget {
  final String featureName;
  final String featureDescription;
  final VoidCallback? onPurchase;

  const PremiumFeatureDialog({
    super.key,
    required this.featureName,
    required this.featureDescription,
    this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'Función Premium',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Desbloquea "$featureName"',
              style: const TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              featureDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            _buildPriceCard(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);

                      if (F.appFlavor == Flavor.dev) {
                        // Simular compra enviando evento al servicio (Solo DEV)
                        FlutterBackgroundService().invoke('sendEvent', {
                          'event': 'togglePremium',
                        });
                        if (onPurchase != null) onPurchase!();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '¡Premium activado! Funcionalidad desbloqueada (DEV).',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        // Lógica de compras reales (PRO - Futuro)
                        // TODO: Implementar In-App Purchases
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Compras próximamente.'),
                            backgroundColor: Colors.amber,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      elevation: 0,
                    ),
                    child: const Text('Obtener'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('Solo ', style: TextStyle(color: Colors.white70)),
          Text(
            '4,99 €',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(' / pago único', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
