import 'package:flutter/material.dart';
import 'package:focus_flow/shared/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_flow/app/injection.dart';
import 'package:focus_flow/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import 'package:focus_flow/shared/theme/app_colors.dart';

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

    return BlocProvider(
      create: (context) => getIt<PremiumBloc>(),
      child: BlocConsumer<PremiumBloc, PremiumState>(
        listener: (context, state) {
          if (state.status == PremiumStatus.success) {
            Navigator.pop(context);
            if (onPurchase != null) onPurchase!();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.premiumActivated),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state.status == PremiumStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.purchasesSoon),
                backgroundColor: AppColors.accent,
              ),
            );
          }
        },
        builder: (context, state) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium, size: 48, color: AppColors.accent),
                  const SizedBox(height: 16),
                  Text(
                    l10n.premiumFeature,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.unlockFeature(featureName),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    featureDescription,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  _buildPriceCard(l10n),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: state.status == PremiumStatus.loading 
                              ? null 
                              : () => Navigator.pop(context),
                          child: Text(
                            l10n.cancel,
                            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: state.status == PremiumStatus.loading
                              ? null
                              : () {
                                  context.read<PremiumBloc>().add(PurchasePremiumRequested());
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.background,
                            elevation: 0,
                          ),
                          child: state.status == PremiumStatus.loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: AppColors.background,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.getAccess),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.priceOnly, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          Text(
            l10n.premiumPrice,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(l10n.oneTimePayment, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
