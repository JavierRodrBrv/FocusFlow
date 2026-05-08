import 'package:flutter/material.dart';
import 'package:focus_flow/l10n/app_localizations.dart';

class MoneyFlowView extends StatelessWidget {
  final String imageAsset;
  final double moneyLost;
  final VoidCallback onBack;
  final VoidCallback onDonate;

  const MoneyFlowView({
    super.key,
    required this.imageAsset,
    required this.moneyLost,
    required this.onBack,
    required this.onDonate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            imageAsset,
            height: 260,
            width: 280,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 120,
              width: 280,
              color: Colors.white.withValues(alpha: 0.05),
              child: const Icon(Icons.broken_image, color: Colors.white24),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.timeLostEquivalent,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '${moneyLost.toStringAsFixed(2)}€',
          style: const TextStyle(
            color: Colors.greenAccent,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.donationQuestion,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: onBack,
              child: Text(
                l10n.noThanks,
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: onDonate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: Text(l10n.sure),
            ),
          ],
        ),
      ],
    );
  }
}

class DonationPromptView extends StatelessWidget {
  final String dogPhrase;
  final VoidCallback onFinish;

  const DonationPromptView({
    super.key,
    required this.dogPhrase,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
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
              color: Colors.white.withValues(alpha: 0.05),
              child: const Icon(
                Icons.favorite_border,
                color: Colors.pink,
                size: 60,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          dogPhrase,
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.donationFuture,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onFinish,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.comingSoon),
        ),
      ],
    );
  }
}
