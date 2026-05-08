import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/flavors.dart';
import 'package:focus_flow/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;

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
              l10n.premiumFeature,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.unlockFeature(featureName),
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
            _buildPriceCard(l10n),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n.cancel,
                      style: const TextStyle(color: Colors.white60),
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
                          SnackBar(
                            content: Text(l10n.premiumActivated),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        // Lógica de compras reales (PRO - Futuro)
                        // TODO: Implementar In-App Purchases
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.purchasesSoon),
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
                    child: Text(l10n.getAccess),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.priceOnly, style: const TextStyle(color: Colors.white70)),
          Text(
            l10n.premiumPrice,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(l10n.oneTimePayment, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
