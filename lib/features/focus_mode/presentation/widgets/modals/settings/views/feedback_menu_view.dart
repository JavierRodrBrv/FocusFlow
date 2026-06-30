import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_flow/app/injection.dart';
import 'package:focus_flow/features/feedback/presentation/bloc/feedback_bloc.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import 'package:focus_flow/shared/theme/app_colors.dart';

class FeedbackMenuView extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSuccess;

  const FeedbackMenuView({
    super.key,
    required this.onBack,
    required this.onSuccess,
  });

  @override
  State<FeedbackMenuView> createState() => _FeedbackMenuViewState();
}

class _FeedbackMenuViewState extends State<FeedbackMenuView> {
  final TextEditingController _feedbackController = TextEditingController();
  final FocusNode _feedbackFocusNode = FocusNode();
  int _selectedIndex = 0; // 0 = Bug, 1 = Idea

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _feedbackFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _feedbackFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeColor = _selectedIndex == 0
        ? AppColors.error
        : AppColors.info;

    return BlocProvider(
      create: (context) => getIt<FeedbackBloc>(),
      child: BlocConsumer<FeedbackBloc, FeedbackState>(
        listener: (context, state) {
          if (state.status == FeedbackStatus.success) {
            HapticFeedback.heavyImpact();
            Future.delayed(const Duration(seconds: 2), widget.onSuccess);
          } else if (state.status == FeedbackStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.errorSending(state.errorMessage ?? '')),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: widget.onBack,
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 48.0),
                          child: Text(
                            l10n.feedback,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFeedbackSegment(
                          0,
                          l10n.bugReport,
                          activeColor,
                        ),
                      ),
                      Expanded(
                        child: _buildFeedbackSegment(
                          1,
                          l10n.featureIdea,
                          activeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _feedbackController,
                  focusNode: _feedbackFocusNode,
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    hintText: _selectedIndex == 0
                        ? l10n.bugHint
                        : l10n.ideaHint,
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: (state.status == FeedbackStatus.loading ||
                          state.status == FeedbackStatus.success)
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          context.read<FeedbackBloc>().add(SubmitFeedback(
                                message: _feedbackController.text,
                                type: _selectedIndex == 0 ? 'Bug' : 'Idea',
                              ));
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 56,
                    decoration: BoxDecoration(
                      color: state.status == FeedbackStatus.success
                          ? Colors.green
                          : activeColor,
                      borderRadius: BorderRadius.circular(
                        (state.status == FeedbackStatus.loading ||
                                state.status == FeedbackStatus.success)
                            ? 50
                            : 16,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _buildButtonContent(context, state, l10n),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedbackSegment(int index, String label, Color activeColor) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (_selectedIndex != index) {
          HapticFeedback.lightImpact();
          setState(() => _selectedIndex = index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: isSelected ? Border.all(color: activeColor, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(
    BuildContext context,
    FeedbackState state,
    AppLocalizations l10n,
  ) {
    if (state.status == FeedbackStatus.loading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(color: AppColors.textPrimary, strokeWidth: 2),
      );
    }
    if (state.status == FeedbackStatus.success) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check, color: AppColors.textPrimary),
          const SizedBox(width: 8),
          Text(
            l10n.thanks,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      );
    }
    return Text(
      l10n.sendFeedback,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }
}
